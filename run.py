#!/usr/bin/env python3
"""Build, run, and test HabitCal.

Standard library only; works with the Python 3.9 that ships with macOS.

    ./run.py run              build the Debug app and open it (quits a running copy first)
    ./run.py build            build the Debug app
    ./run.py open             open the last build without rebuilding
    ./run.py stop             quit the running Debug app
    ./run.py test             unit tests (HabitCalKit)
    ./run.py uitest [Suite]   UI tests, all or one suite/test (drives the real screen)
    ./run.py lint             format check
    ./run.py format           fix formatting in place
    ./run.py clean            delete the build folder
"""

import argparse
import os
import shutil
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.abspath(__file__))
DERIVED = os.path.join(ROOT, "build", "dd")
APP = os.path.join(DERIVED, "Build", "Products", "Debug", "HabitCal.app")
APP_BINARY = os.path.join(APP, "Contents", "MacOS", "HabitCal")
SOURCES = ["HabitCal", "HabitCalKit", "HabitCalUITests"]
XCODEBUILD = [
    "xcodebuild",
    "-project", "HabitCal.xcodeproj",
    "-scheme", "HabitCal",
    "-destination", "platform=macOS",
    "-derivedDataPath", DERIVED,
]


def sh(cmd):
    """Run a command from the project root; exit with its status if it fails."""
    print("$ " + " ".join(cmd), flush=True)
    code = subprocess.call(cmd, cwd=ROOT)
    if code != 0:
        sys.exit(code)


def build(args):
    sh(XCODEBUILD + ["build", "-quiet"])
    print("Built " + os.path.relpath(APP, ROOT))


def stop(args):
    # Match the Debug build's binary path only, so an installed copy keeps running.
    if subprocess.call(["pkill", "-f", APP_BINARY]) == 0:
        print("Quit the running Debug app.")
        time.sleep(0.5)
    else:
        print("The Debug app wasn't running.")


def open_app(args):
    if not os.path.isdir(APP):
        sys.exit("No build yet. Run: ./run.py build")
    sh(["open", APP])
    print("HabitCal is in the menu bar.")


def run(args):
    build(args)
    stop(args)
    open_app(args)


def test(args):
    sh(["swift", "test", "--package-path", "HabitCalKit"])


def uitest(args):
    cmd = XCODEBUILD + ["test"]
    if args.only:
        cmd += ["-only-testing:HabitCalUITests/" + args.only]
    print("UI tests drive the real screen. Don't use the Mac until they finish.")
    sh(cmd)


def lint(args):
    sh(["swift", "format", "lint", "--recursive", "--strict"] + SOURCES)


def fmt(args):
    sh(["swift", "format", "--in-place", "--recursive"] + SOURCES)


def clean(args):
    path = os.path.join(ROOT, "build")
    if os.path.isdir(path):
        shutil.rmtree(path)
        print("Deleted build/")
    else:
        print("Nothing to clean.")


def main():
    parser = argparse.ArgumentParser(
        description="Build, run, and test HabitCal.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__.split("\n\n", 2)[2],
    )
    sub = parser.add_subparsers(dest="command", metavar="command")
    sub.required = True
    commands = [
        ("run", run, "build the Debug app and open it"),
        ("build", build, "build the Debug app"),
        ("open", open_app, "open the last build without rebuilding"),
        ("stop", stop, "quit the running Debug app"),
        ("test", test, "unit tests (HabitCalKit)"),
        ("uitest", uitest, "UI tests; optionally one suite or Suite/test"),
        ("lint", lint, "format check"),
        ("format", fmt, "fix formatting in place"),
        ("clean", clean, "delete the build folder"),
    ]
    for name, func, help_text in commands:
        p = sub.add_parser(name, help=help_text)
        p.set_defaults(func=func)
        if name == "uitest":
            p.add_argument("only", nargs="?", help="e.g. HabitFormUITests or HabitFormUITests/testAddIsDisabledWithoutADay")
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
