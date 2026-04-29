from engine.application import Application, Context
from engine.renderer import Renderer
from typing import Callable
from browser import document, window, bind


def run(app_factory: Callable[[], Application]) -> None:
    canvas = document.querySelector("#app")

    canvas.setAttribute("width", int(window.innerWidth))
    canvas.setAttribute("height", int(window.innerHeight))

    previous_time = 0.0
    app = app_factory()
    app.renderer = Renderer(canvas)

    @bind(window, "resize")
    def onresize(ev):
        width, height = int(window.innerWidth), int(window.innerHeight)
        app.renderer.resize(width, height)

    def frame(time: float) -> None:
        nonlocal previous_time

        if previous_time == 0.0:
            previous_time = time
            window.requestAnimationFrame(frame)
            return

        dt = (time - previous_time) / 1000.0
        previous_time = time

        app.frame(Context(dt=dt, elapsed=time / 1000.0))
        window.requestAnimationFrame(frame)

    window.requestAnimationFrame(frame)
