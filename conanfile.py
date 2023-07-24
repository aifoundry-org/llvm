from conan import ConanFile
from conan.errors import ConanInvalidConfiguration
from conan.tools.apple import is_apple_os
from conan.tools.build import cross_building, check_min_cppstd
from conan.tools.cmake import CMake, CMakeDeps, CMakeToolchain, cmake_layout
from conan.tools.env import VirtualBuildEnv
from conan.tools.files import apply_conandata_patches, load, save, rmdir
from conan.tools.scm import Version
import os
import re
import json
import textwrap


projects = [
    'clang',
    'clang-tools-extra',
    'compiler-rt',
    'debuginfo-tests',
    'libc',
    'libclc',
    'libcxx',
    'libcxxabi',
    'libunwind',
    'lld',
    'lldb',
    'mlir',
    'openmp',
    'parallel-libs',
    'polly',
    'pstl'
]

default_projects = [
    'clang',
    'clang-tools-extra'
]


def remove_prefix(text, prefix):
    """
    obs, in python > 3.9 there's also text.removeprefix(prefix)
    """
    if text.startswith(prefix):
        return text[len(prefix):]
    return text


class EsperantoLlvmConan(ConanFile):
    name = "esperanto-llvm"
    version = "11.1.0"
    description = "The LLVM Project is a collection of modular and reusable compiler and toolchain technologies"
    url = "git@gitlab.com:esperantotech/software/esperanto-llvm.git"
    homepage = "https://gitlab.com/esperantotech/software/esperanto-llvm"
    license = "Apache-2.0"
    topics = "cpp", "compiler", "tooling", "clang"

    settings = "os", "arch", "compiler", "build_type"

    no_copy_source = True

    options = {**{ 'with_' + project : [True, False] for project in projects }, **{
        'shared': [True, False],
        'shared_components': [True, False],
        'fPIC': [True, False],
        'components': 'ANY',
        'targets': 'ANY',
        'exceptions': [True, False],
        'rtti': [True, False],
        'threads': [True, False],
        'lto': ['On', 'Off', 'Full', 'Thin'],
        'static_stdlib': [True, False],
        'unwind_tables': [True, False],
        'expensive_checks': [True, False],
        'use_perf': [True, False],
        'use_sanitizer': [
            'Address',
            'Memory',
            'MemoryWithOrigins',
            'Undefined',
            'Thread',
            'DataFlow',
            'Address;Undefined',
            'None'
        ],
        'use_linker': ['bfd', 'gold', 'lld'],
        'with_ffi': [True, False],
        'with_zlib': [True, False],
        'with_xml2': [True, False],
        'verbose': [True, False],
        'define_cc': [True, False],
        'define_cxx': [True, False],
    }}
    default_options = {**{ 'with_' + project : project in default_projects for project in projects }, **{
        'shared': False,
        'shared_components': False,
        'fPIC': True,
        'components': 'all',
        'targets': 'RISCV',
        'exceptions': True,
        'rtti': True,
        'threads': True,
        'lto': 'Off',
        'static_stdlib': False,
        'unwind_tables': True,
        'expensive_checks': False,
        'use_perf': False,
        'use_sanitizer': 'None',
        'use_linker': 'gold',
        'with_ffi': True,
        'with_zlib': True,
        'with_xml2': True,
        'verbose': False,
        'define_cc': False,
        'define_cxx': False,
    }}

    python_requires = "conan-common/[>=1.1.0 <2.0.0]"

    def export(self):
        register_scm_coordinates = self.python_requires["conan-common"].module.register_scm_coordinates
        register_scm_coordinates(self)

    def config_options(self):
        if self.settings.os == 'Windows':
            del self.options.fPIC
            del self.options.with_zlib
            del self.options.with_xml2

    def configure(self):
        if self.options.shared:
            self.options.rm_safe("fPIC")

    def layout(self):
        cmake_layout(self)

    def requirements(self):
        if self.options.with_ffi:
            self.requires('libffi/3.3')
        if self.options.get_safe('with_zlib', False):
            self.requires('zlib/1.2.13')
        if self.options.get_safe('with_xml2', False):
            self.requires('libxml2/2.9.10')

    def validate(self):
        if self.settings.compiler.get_safe("cppstd"):
            check_min_cppstd(self, '14')

        if self.settings.os == "Macos" and self.options.shared:  # Shared builds disabled in Macos
            message = 'Shared builds not currently supported'
            raise ConanInvalidConfiguration(message)
        if self.settings.os == 'Windows' and self.options.shared:
            message = 'Shared builds not supported on Windows'
            raise ConanInvalidConfiguration(message)
        if self.options.exceptions and not self.options.rtti:
            message = 'Cannot enable exceptions without rtti support'
            raise ConanInvalidConfiguration(message)
        if cross_building(self, skip_x64_x86=True):
            raise ConanInvalidConfiguration('Cross-building not implemented')

        if self.options.shared_components:
            self.output.warn("Building LLVM components as shared libraries is discouraged by LLVM mantainers. Proceeding as best effort. Be advised.")

    def build_requirements(self):
        # Required by upstream https://github.com/microsoft/onnxruntime/blob/v1.14.1/cmake/CMakeLists.txt#L5
        self.tool_requires("cmake/[>=3.24 <4]")

    def export_sources(self):
        copy_sources_if_scm_dirty = self.python_requires["conan-common"].module.copy_sources_if_scm_dirty
        copy_sources_if_scm_dirty(self)

    def source(self):
        get_sources_if_scm_pristine = self.python_requires["conan-common"].module.get_sources_if_scm_pristine
        get_sources_if_scm_pristine(self)

    def _enabled_projects(self):
        return [project for project in projects if getattr(self.options, 'with_' + project)]

    def generate(self):
        enabled_projects = self._enabled_projects()
        self.output.info('Enabled LLVM subprojects: {}'.format(', '.join(enabled_projects)))

        tc = CMakeToolchain(self)
        # we cannot allow CMakeToolchain to automatically inject BUILD_SHARED_LIBS
        tc.blocks.remove("shared")

        tc.variables['CMAKE_VERBOSE_MAKEFILE'] = self.options.verbose

        tc.variables['CMAKE_SKIP_RPATH'] = True if not self.options.shared else False
        tc.variables['CMAKE_POSITION_INDEPENDENT_CODE'] = \
            self.options.get_safe('fPIC', default=False) or self.options.shared

        if not self.options.shared:
            tc.variables['DISABLE_LLVM_LINK_LLVM_DYLIB'] = True
        # tc.variables['LLVM_LINK_DYLIB'] = self.options.shared

        tc.variables['LLVM_TARGET_ARCH'] = "riscv64" # 'host' if we would like to target x86_64
        tc.variables['LLVM_TARGETS_TO_BUILD'] = self.options.targets
        tc.variables['LLVM_BUILD_LLVM_DYLIB'] = self.options.shared and not self.options.shared_components
        tc.variables['LLVM_LINK_LLVM_DYLIB'] = self.options.shared and not self.options.shared_components  # Reduces tools binary size
        # Not recommended, see note: https://llvm.org/docs/BuildingADistribution.html#general-distribution-guidance
        tc.variables['BUILD_SHARED_LIBS'] = self.options.shared and self.options.shared_components

        tc.variables['LLVM_DYLIB_COMPONENTS'] = self.options.components
        tc.variables['LLVM_ENABLE_PIC'] = self.options.get_safe('fPIC', default=False)

        if self.settings.compiler == 'Visual Studio':
            build_type = str(self.settings.build_type).upper()
            tc.variables['LLVM_USE_CRT_{}'.format(build_type)] = self.settings.compiler.runtime

        tc.variables['LLVM_ABI_BREAKING_CHECKS'] = 'WITH_ASSERTS'
        tc.variables['LLVM_ENABLE_WARNINGS'] = True
        tc.variables['LLVM_ENABLE_PEDANTIC'] = True
        tc.variables['LLVM_ENABLE_WERROR'] = False

        tc.variables['LLVM_TEMPORARILY_ALLOW_OLD_TOOLCHAIN'] = True
        tc.variables['LLVM_USE_RELATIVE_PATHS_IN_DEBUG_INFO'] = False
        tc.variables['LLVM_BUILD_INSTRUMENTED_COVERAGE'] = False
        tc.variables['LLVM_OPTIMIZED_TABLEGEN'] = False
        tc.variables['LLVM_REVERSE_ITERATION'] = False
        tc.variables['LLVM_ENABLE_BINDINGS'] = False
        tc.variables['LLVM_CCACHE_BUILD'] = False

        tc.variables['LLVM_INCLUDE_TOOLS'] = True  # self.options.shared
        tc.variables['LLVM_INCLUDE_EXAMPLES'] = False
        tc.variables['LLVM_INCLUDE_TESTS'] = False
        tc.variables['LLVM_INCLUDE_BENCHMARKS'] = False
        tc.variables['LLVM_APPEND_VC_REV'] = False
        tc.variables['LLVM_BUILD_DOCS'] = False
        tc.variables['LLVM_ENABLE_IDE'] = False
        tc.variables['LLVM_ENABLE_TERMINFO'] = False

        tc.variables['LLVM_ENABLE_EH'] = self.options.exceptions
        tc.variables['LLVM_ENABLE_RTTI'] = self.options.rtti
        tc.variables['LLVM_ENABLE_THREADS'] = self.options.threads
        tc.variables['LLVM_ENABLE_LTO'] = self.options.lto
        tc.variables['LLVM_STATIC_LINK_CXX_STDLIB'] = self.options.static_stdlib
        tc.variables['LLVM_ENABLE_UNWIND_TABLES'] = self.options.unwind_tables
        tc.variables['LLVM_ENABLE_EXPENSIVE_CHECKS'] = self.options.expensive_checks
        tc.variables['LLVM_ENABLE_ASSERTIONS'] = self.settings.build_type == 'Debug'

        tc.variables['LLVM_USE_NEWPM'] = False
        tc.variables['LLVM_USE_OPROFILE'] = False
        tc.variables['LLVM_USE_PERF'] = self.options.use_perf
        if self.options.use_sanitizer == 'None':
            tc.variables['LLVM_USE_SANITIZER'] = ''
        else:
            tc.variables['LLVM_USE_SANITIZER'] = self.options.use_sanitizer
        tc.variables['LLVM_USE_LINKER'] = self.options.use_linker

        tc.variables['LLVM_ENABLE_Z3_SOLVER'] = False
        tc.variables['LLVM_ENABLE_LIBPFM'] = False
        tc.variables['LLVM_ENABLE_LIBEDIT'] = False
        tc.variables['LLVM_ENABLE_FFI'] = self.options.with_ffi
        tc.variables['LLVM_ENABLE_ZLIB'] = self.options.get_safe('with_zlib', False)
        tc.variables['LLVM_ENABLE_LIBXML2'] = self.options.get_safe('with_xml2', False)

        tc.variables["LLVM_ENABLE_PROJECTS"] = ";".join(enabled_projects)

        tc.variables["CONAN_PROVIDED_LIBXML2"] = "TRUE" if self.options.get_safe('with_xml2', False) else "FALSE"

        tc.preprocessor_definitions["ESPERANTO"] = "1"

        tc.generate()

        tc = CMakeDeps(self)
        tc.generate()

        tc = VirtualBuildEnv(self)
        tc.generate(scope="build")

    def build(self):
        cmake = CMake(self)
        cmake.configure(build_script_folder="llvm")
        cmake.build()

    def package(self):
        cmake = CMake(self)
        cmake.install()

        for project in self._enabled_projects():
            self.copy(
                'LICENSE.TXT',
                src=os.path.join(self.source_folder, project),
                dst='licenses',
                keep_path=False)

        cmake_folder = os.path.join(self.package_folder, "lib", "cmake")
        components = self._create_components_from_cmake_target_file(os.path.join(cmake_folder, "llvm", "LLVMExports.cmake"))
        if self.options.get_safe("with_clang"):
            clang_components = self._create_components_from_cmake_target_file(os.path.join(cmake_folder, "clang", "ClangTargets.cmake"))
            components.update(clang_components)
        self._create_components_file_from_cmake_components(components)
        rmdir(self, cmake_folder)

        self._create_cmake_module_compatibility_layer(os.path.join(self.package_folder, self._module_file_rel_path))


    @property
    def _llvm_native_arch(self):
        selected_arch_in_conan = self.settings_build.arch if self.options.targets == "host" else self.settings.arch

        llvm_native_arch = {
            "i286": "X86",
            "i386": "X86",
            "i486": "X86",
            "i586": "X86",
            "i686": "X86",
            "x86": "X86",
            "amd64": "X86",
            "x86_64": "X86",
            "sparc": "Sparc",
            "powerpc": "PowerPC",
            "ppc64le": "PowerPC",
            "aarch64": "AArch64",
            "arm64": "AArch64",
            "arm": "ARM",
            "avr": "AVR",
            "mips": "Mips",
            "xcore": "XCore",
            "msp430": "MSP430",
            "hexagon": "Hexagon",
            "s390x": "SystemZ",
            "wasm32": "WebAssembly",
            "wasm64": "WebAssembly",
            "riscv32": "RISCV",
            "riscv64": "RISCV"
        }.get(str(selected_arch_in_conan))
        if not llvm_native_arch:
            self.output.warn("Could not find llvm_native_arch")
        return llvm_native_arch

    def _create_cmake_module_compatibility_layer(self, module_file):
        llvm_native_arch=self._llvm_native_arch
        self.output.info(f"llvm_native_arch {llvm_native_arch}")
        llvm_targets_to_build=str(self.options.targets)
        if 'host' in llvm_targets_to_build:
            llvm_targets_to_build = llvm_targets_to_build.replace("host", self._llvm_native_arch)
        self.output.info(f"llvm_targets_to_build {llvm_targets_to_build}")

        content = textwrap.dedent("""\
set(LLVM_NATIVE_ARCH {llvm_native_arch})
set(LLVM_TARGETS_TO_BUILD {llvm_targets_to_build})
set(LLVM_TARGET_LIBRARIES ${{llvm_COMPONENT_NAMES}})
set(LLVM_AVAILABLE_LIBS ) # todo
set(LLVM_ALL_TARGETS
  AArch64
  AMDGPU
  ARM
  BPF
  Hexagon
  Lanai
  Mips
  MSP430
  NVPTX
  PowerPC
  RISCV
  Sparc
  SystemZ
  WebAssembly
  X86
  XCore
  )

# is_llvm_target_library(
#   library
#     Name of the LLVM library to check
#   return_var
#     Output variable name
#   ALL_TARGETS;INCLUDED_TARGETS;OMITTED_TARGETS
#     ALL_TARGETS - default looks at the full list of known targets
#     INCLUDED_TARGETS - looks only at targets being configured
#     OMITTED_TARGETS - looks only at targets that are not being configured
# )
function(is_llvm_target_library library return_var)
  cmake_parse_arguments(ARG "ALL_TARGETS;INCLUDED_TARGETS;OMITTED_TARGETS" "" "" ${{ARGN}})
  # Sets variable `return_var' to ON if `library' corresponds to a
  # LLVM supported target. To OFF if it doesn't.
  set(${{return_var}} OFF PARENT_SCOPE)
  string(TOUPPER "${{library}}" capitalized_lib)
  if(ARG_INCLUDED_TARGETS)
    string(TOUPPER "${{LLVM_TARGETS_TO_BUILD}}" targets)
  elseif(ARG_OMITTED_TARGETS)
    set(omitted_targets ${{LLVM_ALL_TARGETS}})
    list(REMOVE_ITEM omitted_targets ${{LLVM_TARGETS_TO_BUILD}})
    string(TOUPPER "${{omitted_targets}}" targets)
  else()
    string(TOUPPER "${{LLVM_ALL_TARGETS}}" targets)
  endif()
  foreach(t ${{targets}})
    if( capitalized_lib STREQUAL t OR
        capitalized_lib STREQUAL "${{t}}" OR
        capitalized_lib STREQUAL "${{t}}DESC" OR
        capitalized_lib STREQUAL "${{t}}CODEGEN" OR
        capitalized_lib STREQUAL "${{t}}ASMPARSER" OR
        capitalized_lib STREQUAL "${{t}}ASMPRINTER" OR
        capitalized_lib STREQUAL "${{t}}DISASSEMBLER" OR
        capitalized_lib STREQUAL "${{t}}INFO" OR
        capitalized_lib STREQUAL "${{t}}UTILS" )
      set(${{return_var}} ON PARENT_SCOPE)
      break()
    endif()
  endforeach()
endfunction(is_llvm_target_library)

# This is a variant intended for the final user:
# Map LINK_COMPONENTS to actual libnames.
function(llvm_map_components_to_libnames out_libs)
  set( link_components ${{ARGN}} )
  string(TOUPPER "${{llvm_COMPONENT_NAMES}}" capitalized_libs)

  # Expand some keywords:
  list(FIND LLVM_TARGETS_TO_BUILD "${{LLVM_NATIVE_ARCH}}" have_native_backend)
  list(FIND link_components "engine" engine_required)
  if( NOT engine_required EQUAL -1 )
    list(FIND LLVM_TARGETS_WITH_JIT "${{LLVM_NATIVE_ARCH}}" have_jit)
    if( NOT have_native_backend EQUAL -1 AND NOT have_jit EQUAL -1 )
      list(APPEND link_components "jit")
      list(APPEND link_components "native")
    else()
      list(APPEND link_components "interpreter")
    endif()
  endif()
  list(FIND link_components "native" native_required)
  if( NOT native_required EQUAL -1 )
    if( NOT have_native_backend EQUAL -1 )
      list(APPEND link_components ${{LLVM_NATIVE_ARCH}})
    endif()
  endif()

  # Translate symbolic component names to real libraries:
  foreach(c ${{link_components}})
    # add codegen, asmprinter, asmparser, disassembler
    list(FIND LLVM_TARGETS_TO_BUILD ${{c}} idx)
    if( NOT idx LESS 0 )
      if( TARGET LLVM${{c}}CodeGen )
        list(APPEND expanded_components "LLVM${{c}}CodeGen")
      else()
        if( TARGET LLVM${{c}} )
          list(APPEND expanded_components "LLVM${{c}}")
        else()
          message(FATAL_ERROR "Target ${{c}} is not in the set of libraries.")
        endif()
      endif()
      if( TARGET LLVM${{c}}AsmParser )
        list(APPEND expanded_components "LLVM${{c}}AsmParser")
      endif()
      if( TARGET LLVM${{c}}AsmPrinter )
        list(APPEND expanded_components "LLVM${{c}}AsmPrinter")
      endif()
      if( TARGET LLVM${{c}}Desc )
        list(APPEND expanded_components "LLVM${{c}}Desc")
      endif()
      if( TARGET LLVM${{c}}Disassembler )
        list(APPEND expanded_components "LLVM${{c}}Disassembler")
      endif()
      if( TARGET LLVM${{c}}Info )
        list(APPEND expanded_components "LLVM${{c}}Info")
      endif()
      if( TARGET LLVM${{c}}Utils )
        list(APPEND expanded_components "LLVM${{c}}Utils")
      endif()
    elseif( c STREQUAL "native" )
      # already processed
    elseif( c STREQUAL "nativecodegen" )
      list(APPEND expanded_components "LLVM${{LLVM_NATIVE_ARCH}}CodeGen")
      if( TARGET LLVM${{LLVM_NATIVE_ARCH}}Desc )
        list(APPEND expanded_components "LLVM${{LLVM_NATIVE_ARCH}}Desc")
      endif()
      if( TARGET LLVM${{LLVM_NATIVE_ARCH}}Info )
        list(APPEND expanded_components "LLVM${{LLVM_NATIVE_ARCH}}Info")
      endif()
    elseif( c STREQUAL "backend" )
      # same case as in `native'.
    elseif( c STREQUAL "engine" )
      # already processed
    elseif( c STREQUAL "all" )
      list(APPEND expanded_components ${{LLVM_AVAILABLE_LIBS}})
    elseif( c STREQUAL "AllTargetsCodeGens" )
      # Link all the codegens from all the targets
      foreach(t ${{LLVM_TARGETS_TO_BUILD}})
        if( TARGET LLVM${{t}}CodeGen)
          list(APPEND expanded_components "LLVM${{t}}CodeGen")
        endif()
      endforeach(t)
    elseif( c STREQUAL "AllTargetsAsmPrinters" )
      # Link all the asm printers from all the targets
      foreach(t ${{LLVM_TARGETS_TO_BUILD}})
        if( TARGET LLVM${{t}}AsmPrinter )
          list(APPEND expanded_components "LLVM${{t}}AsmPrinter")
        endif()
      endforeach(t)
    elseif( c STREQUAL "AllTargetsAsmParsers" )
      # Link all the asm parsers from all the targets
      foreach(t ${{LLVM_TARGETS_TO_BUILD}})
        if( TARGET LLVM${{t}}AsmParser )
          list(APPEND expanded_components "LLVM${{t}}AsmParser")
        endif()
      endforeach(t)
    elseif( c STREQUAL "AllTargetsDescs" )
      # Link all the descs from all the targets
      foreach(t ${{LLVM_TARGETS_TO_BUILD}})
        if( TARGET LLVM${{t}}Desc )
          list(APPEND expanded_components "LLVM${{t}}Desc")
        endif()
      endforeach(t)
    elseif( c STREQUAL "AllTargetsDisassemblers" )
      # Link all the disassemblers from all the targets
      foreach(t ${{LLVM_TARGETS_TO_BUILD}})
        if( TARGET LLVM${{t}}Disassembler )
          list(APPEND expanded_components "LLVM${{t}}Disassembler")
        endif()
      endforeach(t)
    elseif( c STREQUAL "AllTargetsInfos" )
      # Link all the infos from all the targets
      foreach(t ${{LLVM_TARGETS_TO_BUILD}})
        if( TARGET LLVM${{t}}Info )
          list(APPEND expanded_components "LLVM${{t}}Info")
        endif()
      endforeach(t)
    else( NOT idx LESS 0 )
      # Canonize the component name:
      string(TOUPPER "${{c}}" capitalized)
      list(FIND capitalized_libs LLVM${{capitalized}} lib_idx)
      if( lib_idx LESS 0 )
        # The component is unknown. Maybe is an omitted target?
        is_llvm_target_library(${{c}} iltl_result OMITTED_TARGETS)
        if(iltl_result)
          # A missing library to a directly referenced omitted target would be bad.
          message(FATAL_ERROR "Library '${{c}}' is a direct reference to a target library for an omitted target.")
        else()
          # If it is not an omitted target we should assume it is a component
          # that hasn't yet been processed by CMake. Missing components will
          # cause errors later in the configuration, so we can safely assume
          # that this is valid here.
          list(APPEND expanded_components LLVM${{c}})
        endif()
      else( lib_idx LESS 0 )
        list(GET LLVM_AVAILABLE_LIBS ${{lib_idx}} canonical_lib)
        list(APPEND expanded_components ${{canonical_lib}})
      endif( lib_idx LESS 0 )
    endif( NOT idx LESS 0 )
  endforeach(c)

  set(${{out_libs}} ${{expanded_components}} PARENT_SCOPE)
endfunction()
        """.format(llvm_native_arch=self._llvm_native_arch, llvm_targets_to_build=llvm_targets_to_build)
                                  )
        save(self, module_file, content)

    def _create_components_from_cmake_target_file(self, llvm_target_file_path):
        components = {}

        llvm_target_file = open(llvm_target_file_path, "r")
        llvm_target_content = llvm_target_file.read()
        llvm_target_file.close()

        conan_requires_targets = {}
        conan_requires_paths = {}
        if self.options.get_safe("with_ffi", False):
            conan_requires_targets["ffi::ffi"] = "libffi::libffi"  # untested
            conan_requires_paths["libffi/3.3"] = "libffi::libffi"  # untested
        if self.options.get_safe('with_zlib', False):
            conan_requires_targets["ZLIB::ZLIB"] = "zlib::zlib"
            conan_requires_paths['zlib/1.2.13'] = "zlib::zlib"
        if self.options.get_safe('with_xml2', False):
            conan_requires_targets["LibXml2::LibXml2"] = "libxml2::libxml2"
            conan_requires_paths["libxml2/2.9.10"] = "libxml2::libxml2"

        cmake_functions = re.findall(r"(?P<func>add_library|set_target_properties)[\n|\s]*\([\n|\s]*(?P<args>[^)]*)\)", llvm_target_content)
        for (cmake_function_name, cmake_function_args) in cmake_functions:
            cmake_function_args = re.split(r"[\s|\n]+", cmake_function_args, maxsplit=2)

            cmake_imported_target_name = cmake_function_args[0]
            potential_lib_name = cmake_imported_target_name

            components.setdefault(potential_lib_name, {"cmake_target": cmake_imported_target_name})

            if cmake_function_name == "add_library":
                cmake_imported_target_type = cmake_function_args[1]
                if cmake_imported_target_type in ["STATIC", "SHARED"]:
                    components[potential_lib_name]["libs"] = [remove_prefix(potential_lib_name, "lib")] if potential_lib_name == "libclang" else [potential_lib_name]
            elif cmake_function_name == "set_target_properties":
                target_properties = re.findall(r"(?P<property>INTERFACE_COMPILE_DEFINITIONS|INTERFACE_INCLUDE_DIRECTORIES|INTERFACE_LINK_LIBRARIES)[\n|\s]+(?P<values>.+)", cmake_function_args[2])
                for target_property in target_properties:
                    property_type = target_property[0]
                    if property_type == "INTERFACE_LINK_LIBRARIES":
                        values_list = target_property[1].replace('"', "").split(";")
                        for dependency in values_list:
                            conan_dependency = False
                            for reference in conan_requires_paths.keys():
                                if reference in dependency:  # if substring (ref) in path (dependency)
                                    conan_dependency = conan_requires_paths[reference]
                                    break
                            if dependency.startswith("LLVM"): # LLVM targets
                                components[potential_lib_name].setdefault("requires", []).append(dependency)
                            elif os.path.exists(dependency) and conan_dependency:  # conan deps (paths to local cache)
                                components[potential_lib_name].setdefault("requires", []).append(conan_dependency)
                            elif dependency in conan_requires_targets: # conan dependencies (target matches)
                                dependency = conan_requires_targets[dependency]
                                components[potential_lib_name].setdefault("requires", []).append(dependency)
                            else: # system libs or frameworks
                                if self.settings.os in ["Linux", "FreeBSD"]:
                                    if "-lpthread" in dependency or dependency == "Threads::Threads":
                                        components[potential_lib_name].setdefault("system_libs", []).append("pthread")
                                    elif "-lm" in dependency or dependency == "m":
                                        components[potential_lib_name].setdefault("system_libs", []).append("m")
                                    elif "-lrt" in dependency:
                                        components[potential_lib_name].setdefault("system_libs", []).append("rt")
                                elif self.settings.os == "Windows":
                                    for system_lib in ["bcrypt", "advapi32", "dbghelp"]:
                                        if system_lib in dependency:
                                            components[potential_lib_name].setdefault("system_libs", []).append(system_lib)
                                elif is_apple_os(self.settings.os):
                                    for framework in ["CoreFoundation"]:
                                        if framework in dependency:
                                            components[potential_lib_name].setdefault("frameworks", []).append(framework)
                    elif property_type == "INTERFACE_COMPILE_DEFINITIONS":
                        values_list = target_property[1].replace('"', "").split(";")
                        for definition in values_list:
                            components[potential_lib_name].setdefault("defines", []).append(definition)
                    elif property_type == "INTERFACE_INCLUDE_DIRECTORIES":
                        values_list = target_property[1].replace('"', "").split(";")
                        for include in values_list:
                            components[potential_lib_name].setdefault("includedirs", []).append(include)
        return components

    def _create_components_file_from_cmake_components(self, components):
        # Save components informations in json file
        with open(self._components_helper_filepath, "w") as json_file:
            json.dump(components, json_file, indent=4)

    @property
    def _module_file_rel_path(self):
        return os.path.join("lib", "cmake", "conan-esperanto-{}-utils.cmake".format(self.name))

    @property
    def _components_helper_filepath(self):
        return os.path.join(self.package_folder, "lib", "components.json")

    def package_info(self):
        self.cpp_info.set_property("cmake_file_name", "LLVM")
        self.cpp_info.set_property("cmake_target_name", "LLVM::LLVM")
        self.cpp_info.set_property("cmake_build_modules", [self._module_file_rel_path])
        self.cpp_info.set_property("pkg_config_name", "llvm")

        self.cpp_info.includedirs = ["include"]
        self.cpp_info.libdirs = ["lib"]
        self.cpp_info.resdirs = ["share"]
        self.cpp_info.bindirs = ["bin", "libexec"]

        # components
        components_json_file = load(self, self._components_helper_filepath)
        llvm_components = json.loads(components_json_file)
        for pkgconfig_name, values in llvm_components.items():
            cmake_target = values["cmake_target"]
            self.cpp_info.components[pkgconfig_name].set_property("cmake_target_name", "LLVM::{}".format(cmake_target))
            self.cpp_info.components[pkgconfig_name].set_property("cmake_target_aliases", [cmake_target])
            self.cpp_info.components[pkgconfig_name].set_property("pkg_config_name", pkgconfig_name)
            self.cpp_info.components[pkgconfig_name].includedirs = ["include"]
            self.cpp_info.components[pkgconfig_name].libdirs = ["lib"]
            self.cpp_info.components[pkgconfig_name].libs = values.get("libs", [])
            self.cpp_info.components[pkgconfig_name].defines = values.get("defines", [])
            self.cpp_info.components[pkgconfig_name].system_libs = values.get("system_libs", [])
            self.cpp_info.components[pkgconfig_name].frameworks = values.get("frameworks", [])
            self.cpp_info.components[pkgconfig_name].requires = values.get("requires", [])

            self.cpp_info.components[pkgconfig_name].names["cmake_find_package"] = cmake_target
            self.cpp_info.components[pkgconfig_name].names["cmake_find_package_multi"] = cmake_target

        bin_path = os.path.join(self.package_folder, "bin")
        lib_path = os.path.join(self.package_folder, "lib")
        if self.options.define_cc:
            self.runenv_info.define("CC", os.path.join(bin_path, "clang"))
        if self.options.define_cxx:
            self.runenv_info.define("CXX", os.path.join(bin_path, "clang++"))

        # this will survive in v2?
        self.output.info("Appending PATH environment variable: {}".format(bin_path))
        self.env_info.PATH.append(bin_path)

        # TODO: to remove in conan v2 once old virtualrunenv is removed
        if self.options.define_cc:
            self.buildenv_info.prepend_path('CC', os.path.join(bin_path, "clang"))
        if self.options.define_cxx:
            self.buildenv_info.prepend_path('CXX', os.path.join(bin_path, "clang++"))

        # TODO: to remove in conan v2 once cmake_find_package* generators removed
        self.cpp_info.names["cmake_find_package"] = "LLVM"
        self.cpp_info.names["cmake_find_package_multi"] = "LLVM"
        self.cpp_info.build_modules["cmake_find_package"] = [self._module_file_rel_path]

