set windows-shell := ["powershell"]

ext := if os_family() == "windows" { "bat" } else { "sh" }

[private]
@default:
    just --list --unsorted

prepare: publish-desktop publish-web

run:
    dotnet watch --project LastShot.Desktop

publish-desktop:
    dotnet publish -c Release LastShot.Desktop

publish-web:
    dotnet publish -c Release LastShot.Web

serve: publish-web
    dotnet serve \
        --port 8000 \
        --mime .wasm=application/wasm \
        --mime .js=text/javascript \
        --mime .json=application/json \
        --directory 'LastShot.Web/bin/Release/net10.0/browser-wasm/AppBundle/'
