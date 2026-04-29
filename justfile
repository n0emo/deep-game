set windows-shell := ["powershell"]

ext := if os_family() == "windows" { "bat" } else { "sh" }

[private]
@default:
    just --list --unsorted

run:
    uv run jurigged -v ./src/main.py

check:
    uv run mypy src
    uv run ruff check

format:
    uv run ruff format

prepare: check format

build-web:
    uv run ./src/build_web.py

serve:
    uv run -m http.server -d ./build/web

odin-prepare:
    odinfmt source -w
    just hot-reload
    just build-debug
    just build-release
    just build-web

odin-build-debug:
    ./scripts/build_debug.{{ ext }}

odin-build-release:
    ./scripts/build_release.{{ ext }}

odin-hot-reload:
    ./scripts/build_hot_reload.{{ ext }}

odin-hot-reload-watch:
    watchexec -w source './scripts/build_hot_reload.{{ ext }}'

odin-build-web:
    ./scripts/build_web.{{ ext }}
