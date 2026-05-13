# /// script
# dependencies = [
#   "raylib",
# ]
# ///

import asyncio
from lastshot.game import Game
import pyray as rl


async def main() -> None:
    rl.set_config_flags(rl.ConfigFlags.FLAG_WINDOW_RESIZABLE)
    rl.init_window(800, 600, "Hello from pygbag")
    rl.init_audio_device()
    game = Game()

    while game.running:
        rl.begin_drawing()
        game.frame()
        rl.end_drawing()

        await asyncio.sleep(0)

    rl.close_audio_device()
    rl.close_window()


asyncio.run(main())
