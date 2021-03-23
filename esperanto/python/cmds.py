#!/usr/bin/env python3
#
# This modue includes commands to sugar over
# subprocess.run for common usage patterns.
#

from subprocess import check_output, run
from sys import stderr
from tempfile import TemporaryFile
import logging
dry_run = False
verbose = False
logger = logging.getLogger()
logging.basicConfig(
    format="{asctime} ({filename}:{lineno}) {levelname}: {message}",
    level=logging.WARN,
    style="{",
)

def do_parse_args(parser, verbose_init=None):
    "add some deafult args to parser and return parsed args"
    parser.add_argument("--dry-run", action='store_true')
    parser.add_argument("-v", "--verbose", action='store_true')
    args = parser.parse_args()
    global dry_run, verbose
    dry_run = args.dry_run
    verbose = dry_run or args.verbose if verbose_init is None else verbose_init
    setup_logging(verbose)
    return args


def command(cmd, **keywords):
    "Evaluate cmd"
    if isinstance(cmd, str):
        cmd = cmd.split()
    return _command(cmd, keywords)


def shell(cmd, **keywords):
    "Evaluate 'cmd' as input to a shell"
    keywords['shell'] = True
    return _command(cmd, keywords)


def _command(cmd, keywords):
    "Common function to evaluate a command"
    if 'check' not in keywords:
        keywords['check'] = True
    if 'input' in keywords:
        if 'encoding' not in keywords:
            keywords['encoding'] = 'utf-8'
    if verbose:
        c = keywords.get('cwd', '.')
        inp = keywords.get('input',None)
        text = cmd if isinstance(cmd,str) else " ".join(cmd)
        if text == "bash" and isinstance(inp,str):
            text = inp
        logger.debug(c + ": " + text)
        if dry_run:
            return
    if 'stderr' in keywords:
        return run(cmd, **keywords)
    with TemporaryFile() as err:
        try:
            return run(cmd, stderr=err, **keywords)
        except:
            err.seek(0)
            stderr.write(err.read().decode('utf-8'))
            raise


def output(cmd, **keywords):
    "Return the output from 'cmd' as a list of lines"
    if isinstance(cmd, str):
        cmd = cmd.split()
    if 'encoding' not in keywords:
        keywords['encoding'] = 'utf-8'
    first = keywords.pop('first', False)
    if verbose:
        c = keywords.get('cwd', '.')
        logger.debug(c + ": " + cmd if isinstance(cmd,str) else " ".join(cmd))
    if 'stderr' in keywords:
        text = check_output(cmd, **keywords)
    else:
        with TemporaryFile() as err:
            try:
                text = check_output(cmd, stderr=err, **keywords)
            except:
                err.seek(0)
                stderr.write(err.read().decode('utf-8'))
                raise
    if not first:
        return text.splitlines()
    if verbose:
        c = keywords.get('cwd', '.')
        logger.debug(c + ": " + ' '.join(cmd))
        if dry_run:
            return
    return text.split("\n", 1)[0]


def setup_logging(debug=False):
    """set custom logging format
    enable INFO/DEBUG logger for this file"""
    logger.setLevel(logging.DEBUG if debug else logging.INFO)
    return logger


def log_msg(text):
    "Print log message"
    logger.debug(text)


if __name__ == "__main__":
    logger.info("info 1")
    setup_logging(debug=True)
    logger.info("info 2")
