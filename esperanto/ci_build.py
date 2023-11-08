#!/usr/bin/env python3
import os
import argparse

from ecpt.packager import Packager

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("conanfile_path", help='Path to a folder containing a conanfile.py or to a recipe file e.g., '
                                               'my_folder/conanfile.py')
    args = parser.parse_args()

    if not os.path.exists(args.conanfile_path):
        print(f"ERROR: conanfile_path {args.conanfile_path} does not exist. cannot generate pipeline.")
        return

    conanfile_path = args.conanfile_path if os.path.isfile(args.conanfile_path) else os.path.join(args.conanfile_path, "conanfile.py")
    if not os.path.isabs(conanfile_path):
        conanfile_path = os.path.abspath(conanfile_path)

    build = Packager(ci_build=True)
    build.add_package(conanfile_path)
    build.add_configuration("default", "linux-ubuntu18.04-x86_64-gcc7-release")
    build.add_configuration("default", "linux-ubuntu22.04-x86_64-gcc11-release")
    build.report()

    build.run()


if __name__ == '__main__':
    main()
