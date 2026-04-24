set windows-shell := ["powershell"]

ext := if os_family() == "windows" { "bat" } else { "sh" }

build-debug:
    ./scripts/build_debug.{{ ext }}

build-release:
    ./scripts/build_release.{{ ext }}

hot-reload:
    ./scripts/build_hot_reload.{{ ext }}

hot-reload-watch:
    watchexec -w source './scripts/build_hot_reload.{{ ext }}'

build-web:
    ./scripts/build_web.{{ ext }}
