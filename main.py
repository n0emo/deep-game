import asyncio
import platform
import pyray as rl
from lastshot.game import Game


async def main():
    rl.init_window(500, 500, "Hello")
    game = Game()

    if platform.system() == "Emscripten":
        platform.window.window_resize()  # type: ignore

    while not rl.window_should_close():
        game.update()
        game.draw()
        await asyncio.sleep(0)

    rl.close_window()


asyncio.run(main())
