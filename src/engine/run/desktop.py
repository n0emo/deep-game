from typing import Callable
from engine.application import Application, Context
from engine.renderer import Renderer
from sys import stderr
import pyray
import traceback


def run(app_factory: Callable[[], Application]) -> None:
    pyray.init_window(800, 600, "Python")
    pyray.init_audio_device()

    app = app_factory()
    app.renderer = Renderer()

    result = 0

    try:
        while not pyray.window_should_close():
            pyray.begin_drawing()
            ctx = Context(dt=pyray.get_frame_time(), elapsed=pyray.get_time())
            app.frame(ctx)
            pyray.end_drawing()

    except Exception as e:
        traceback.print_exception(e, file=stderr)
        result = 1

    pyray.close_audio_device()
    pyray.close_window()

    exit(result)
