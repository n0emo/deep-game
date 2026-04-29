from dataclasses import dataclass


@dataclass
class Color:
    r: int
    g: int
    b: int
    a: int = 255


WHITE = Color(255, 255, 255, 255)
BLACK = Color(0, 0, 0, 255)
RED = Color(255, 0, 0, 255)
GREEN = Color(0, 255, 0, 255)
BLUE = Color(0, 0, 255, 255)
