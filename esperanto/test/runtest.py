#!/usr/bin/env python3
from argparse import ArgumentParser
from dataclasses import dataclass
from multiprocessing import Pool
from os import  environ
from os.path import exists, join, realpath, isdir
from pathlib import Path
from random import randrange
from support import command, do_parse_args, output
from sys import stderr
from tempfile import TemporaryDirectory
from typing import List
import re


DESCRIPTION="""For some limited IR tests, build a driver
and run both vector instructions and non vector instructions
and compare results."""

def main():
    args = parse_args()
    src = Path(realpath(__file__)).parent

    with Pool(16) as p:
        results = p.map(runp, [ (t, args) for t in get_tests(args)])

    for r,t in sorted(results, key=lambda x: x[1]):
        print(t,r)

    exit( any([r != "passed" for r,_ in results]) )


def parse_args():
    parser = ArgumentParser(DESCRIPTION)
    parser.add_argument("tests", nargs="+")
    parser.add_argument("--trace", action="store_true",
                        help="save simulator trace")
    parser.add_argument("--temp-dir",
                        help="Temporary directory for intermediates")
    args = do_parse_args(parser)
    # create a temporary directory if none
    # is specified. Otherwise wrap the argument
    # so it can be accessed via .name uniformly
    if args.temp_dir is None:
        args.temp_dir = TemporaryDirectory()
    else:
        args.temp_dir = DirName(args.temp_dir)
    return args


def get_tests(args):
    """Iterate over args expanding directories to all .ll files in 
       that directory"""
    for t in args.tests:
        if not isdir(t):
            yield t
        else:
            yield from [str(f) for f in Path(t).glob("*.ll")]


def runp(a):
    """Helper to unpack arguments and catch exceptions"""
    try: 
        return runtest(*a)
    except BaseException:
        if a[1].verbose:
            raise
        return ("exception", Path(a[0]).name)

    
def runtest(test, args):
    "Return the name of test and the result of running it"
    name = Path(test).name
    if not test.endswith(".ll"):
        return ("invalid test",  name)

    base = join(args.temp_dir.name, Path(test).stem)
    log = base + ".log"
    testcl = parse_test(test, base, args)
    if testcl is None:
        return ("unsupported test", name)

    # check for unsupported types
    u = [p for p in testcl.params if p.prim == "unknown"]
    if u:
        if args.verbose:
            for p in u:
                print("unsupported parameter type", p.src, test)            
        return ("unsupported parameter type", name)

    # build a driver for the tests which initializes
    # data and verifies vector and non-vector variants
    # provide the same results
    dfn = driver(testcl, args)

    # generate code using vector instructions
    # the relax attribute is needed for correct linking
    baseobj = base + "-vec.o"
    command(f"{LLC_FOR_TARGET} -filetype=obj -mattr=+relax --mcpu=et-soc1-min -target-abi lp64f " +
            f"-o {baseobj} {test}")

    # generate code using a baseline RISCV with similar features
    # the vector IR is lowered to scalar code using unmodified
    # llvm features.  We exclude masked intrinsics because there
    # is no baseline support for lowering them.
    novecobj = testcl.novec[:-3] + ".o"
    command(f"{LLC_FOR_TARGET} -filetype=obj -mattr=+m,+f,+c,-save-restore,+64bit,+relax -target-abi lp64f "
            + f"-o {novecobj} {testcl.novec}")
    
    drvobj = base + "-drv.o"
    command(f"{CC_FOR_TARGET} -c -O2 -o {drvobj} {dfn}")

    # link object files to build an executable. This may fail
    # if when the basline code generates a library call which
    # is not supported.
    exe = base + ".exe"
    p = run(log, [LD_FOR_TARGET, "-o", exe, baseobj, novecobj, drvobj], check=False)
    if p.returncode:
        return ("link failed", name)
    
    # The driver stores a return code in the global "num_errors"
    # here we find the virtual address of that variable
    num_errors_address = None
    for ln in output(f"{NM_FOR_TARGET} {exe}"):
        f = ln.split(' ')
        if f[1] == 'B' and f[2] == 'num_errors':
            num_errors_address = f[0]
            break
    else:
        return ("failed to find exit status", name)
        
    # now run a single thread simulation using the return
    # code for success or failure and also checking
    # the value stored in the location "num_errors" since
    # that records the programmatic exit status
    status = base + ".rc"
    cmd = [SIM_FOR_TARGET, "-elf_load", exe,
           "-single_thread",
           "-shires", "0x1",
           "-minions", "0x1",
           "-dump_addr", num_errors_address,
           "-dump_size", "4",
           "-dump_file", str(status),
    ]
    if args.trace:
        cmd.append("-l")
    with open(base + ".trace", "w") as trace:
        p = command(cmd, check=False, stdout= trace)
    rc = p.returncode
    if rc == 0:
        # check for program identifier errors now
        # stored in the status file.
        with open(status, "rb") as sf:
            rc = int.from_bytes(sf.read(4), "little")
        
    return ("passed" if rc == 0 else "failed", name)
    

def driver(testcl, args):
    """For the test, build a driver which has a pair
of variales for each parameter which are identically
initialized to random values. Then make calls to vector
and scalar variants and compare the results. The number
of differences are stored in a global 'num_errors'"""
    dfn = testcl.base + "-driver.c"
    with open(dfn, "w") as drv:
        declarations(testcl, testcl.fun, 'v', drv)
        declarations(testcl, testcl.fun_nv, 'nv', drv)
        print("int num_errors;", file=drv)
        print("int main(int args, char **argv ) {", file=drv)
        vardecls(testcl, testcl.fun, 'v', drv)
        vardecls(testcl, testcl.fun_nv, 'nv', drv)
        initialization(testcl, drv)
        invoke(testcl, testcl.fun, 'v', drv)
        invoke(testcl, testcl.fun_nv, 'nv', drv)
        print("\tint errors = 0;", file=drv)
        comparisons(testcl, drv);
        print("\tnum_errors = errors;",file=drv);
        print("\treturn errors;\n}", file=drv)
    return dfn


def declarations(testcl, fun, prefix, drv):
    "Generate a declaration for external function 'fun'"
    a = ",".join(p.asArg() for p in testcl.params)
    print(f"extern {testcl.ret} {fun}({a});", file=drv)

    
def vardecls(testcl, fun, prefix, drv):
    "Declara local variales for each parameter to test test function"
    for p in testcl.params:
        if p.vl:
            print(f"{p.prim} {prefix}{p.name}[{p.vl}];", file=drv)
        else:
            print(f"{p.prim} {prefix}{p.name};", file=drv)


def initialization(testcl, drv):
    "Initialize each pair of variables to the same random values"
    for p in testcl.params:
        if p.vl == 0:
            value = randrange(255)
            print(f"\tv{p.name} = {value};", file=drv)
            print(f"\tnv{p.name} = {value};", file=drv)
            continue
        for idx in range(p.vl):
            value = randrange(255)
            print(f"\tv{p.name}[{idx}] = {value};", file=drv)
            print(f"\tnv{p.name}[{idx}] = {value};", file=drv)


def invoke(testcl, fun, prefix, drv):
    "Generate the call to 'fun'"
    args = ",".join([ prefix + p.name for p in testcl.params ])
    if testcl.ret == "void":
        result = ""
    else:
        result = f"{testcl.ret} {prefix}result = "        
    print(f"\t{result}{fun}({args});",file=drv)


def comparisons(testcl,drv):
    """Generate comparisons to look for differences between
different pairs of value element by element"""
    for p in testcl.params:
        if p.vl == 0:
            continue
        for idx in range(p.vl):
            print(f"\terrors += (v{p.name}[{idx}] != nv{p.name}[{idx}]);",
                  file=drv)


def parse_params(params):
    "Parse the IR representation of the parameters of the test function"
    vars = []
    for p in params.split(","):
        ty, nm = p.split(" %")
        ty = ty.strip()
        nm = nm.replace(".", "_")
        prim, vl = TYPE_MAP.get(ty, ["unknown", 1]);
        vars.append(Parameter(p, prim,vl,nm))
    return vars


@dataclass
class Parameter:
    "Information about each parameter to the test function"
    src: str     # the IR representation
    prim: str    # C primitive type 
    vl: int      # vector length
    name: str    # parameter name
    def asArg(self):
        "Print this type as a formal parameter"
        if self.vl == 0:
            return self.prim
        return self.prim + "*"

@dataclass
class Test:
    "A representation of details about a test derived from the IR"
    src: str     # sourc efile name 
    base: str    # basename of src
    novec: str   # name of the file which is not vectorized
    fun: str     # name of test function
    fun_nv: str  # name of the non-vector function
    ret: str     # return type 
    params: List[Parameter]  # parameters of the function
    

def parse_test(test, base, args):
    """Parse the source test and return a Test object. Also build
a copy of the input with a different function name ('fun_nv') that
will be compiled without vector instructions"""
    novec = f"{base}-novec.ll"
    def_re = re.compile(r"^(define (.*) @)([a-zA-Z0-9]+)(\((.*)\).*)")

    # we skip this test if any input ine matches this RE
    # initially this excludes tests with masked memory operations
    skip_re = re.compile("^declare.*@llvm.masked")
    
    fun = None
    fun_nv = None
    with open(novec, "w") as nv:
        for line in output(f"{OPT_FOR_TARGET} -S -o - {test}"):
            if skip_re.match(line):
                return None
            if fun is not None:
                print(line,file=nv)
                continue

            # look for the function definition line
            m = def_re.match(line)
            if not m:
                print(line, file=nv)
                continue
            # save deatils from that.
            ret = m.group(2)
            if ret == "signext i32":
                ret = "int"
            fun = m.group(3)
            fun_nv = fun + "_nv"
            params = parse_params(m.group(5))
            print(m.group(1) + fun_nv + m.group(4), file=nv)

    return Test(test, base, novec, fun, fun_nv, ret, params)
            
@dataclass
class DirName:
    "A struct with a .name field"
    name: str


def run(log, cmd, **kwrds):
    "Wrapper to run 'cmd' saving stdout/stderr to log"
    with open(log, "w") as log:
        kwrds['stderr'] = log
        kwrds['stdout'] = log
        return command(cmd, **kwrds)


# map IR types to a C primitive type and a
# vector length were 0 indicates a scalar.
TYPE_MAP = { "<8 x i32>*" : [ "unsigned", 8 ],
          "<8 x float>*" : [ "float" , 8 ],
          "float" : ["float", 0],
          "<8 x i8>*" : ["unsighed char", 8],
          "<8 x i16>*" : ["unsighed char", 8],
          "i8*" : ["unsigned char", 32],
          "i16*" : ["unsigned short", 16],
}

INSTALL_DIR = environ.get("INSTALL_DIR", None)
if not INSTALL_DIR:
    print("Set environment variable INSTALL_DIR to installation directory",
          file=stderr)
    exit (1)

CC_FOR_TARGET  = f"{INSTALL_DIR}/bin/sysemu-clang"
LD_FOR_TARGET  = f"{INSTALL_DIR}/bin/sysemu-ld"
LLC_FOR_TARGET = f"{INSTALL_DIR}/bin/llc"
NM_FOR_TARGET  = f"{INSTALL_DIR}/bin/llvm-nm"
OPT_FOR_TARGET = f"{INSTALL_DIR}/bin/opt"
SIM_FOR_TARGET = f"{INSTALL_DIR}/bin/sys_emu"

if __name__ == "__main__":
    main()
