from shutil import copytree, rmtree, make_archive
from os import makedirs
from pathlib import Path
from sys import stderr
from dataclasses import dataclass
import traceback


@dataclass
class Context:
    target_dir: Path
    source_dir: Path


def main() -> None:
    ctx = Context(
        target_dir=Path("build", "web"),
        source_dir=Path("."),
    )

    rm_target(ctx)

    try:
        copy_dir(ctx, Path("assets"), Path("assets"))
        copy_dir(ctx, Path("lib"), Path("."))
        copy_dir(ctx, Path("src"), Path("."))
    except Exception as e:
        print("ERROR: Could not copy files", file=stderr)
        traceback.print_exception(e, file=stderr)
        exit(1)

    print(f"Created {ctx.target_dir}/")

    zip_path = ctx.target_dir.parent.joinpath("web")
    try:
        make_archive(str(zip_path), format="zip", root_dir=ctx.target_dir)

    except Exception as e:
        print("ERROR: Could not create archive", file=stderr)
        traceback.print_exception(e, file=stderr)
        exit(1)

    print(f"Created {zip_path}.zip")


def rm_target(ctx: Context) -> None:
    rmtree(ctx.target_dir, ignore_errors=True)


def copy_dir(ctx: Context, source: Path, target: Path) -> None:
    makedirs(ctx.target_dir.joinpath(target), exist_ok=True)
    copytree(
        ctx.source_dir.joinpath(source),
        ctx.target_dir.joinpath(target),
        dirs_exist_ok=True,
    )


if __name__ == "__main__":
    main()
