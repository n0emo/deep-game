from typing import Literal, overload

class IMG:
    def __init__(self, /, *, src: str) -> None: ...

class CANVAS:
    @property
    def width(self) -> float: ...
    @width.setter
    def width(self, value: float) -> None: ...
    @property
    def height(self) -> float: ...
    @height.setter
    def height(self, value: float) -> None: ...
    @overload
    def getContext(self, contextType: Literal["2d"]) -> CanvasRenderingContext2D: ...
    @overload
    def getContext(self, contextType: Literal["webgl"]) -> WebGLRenderingContext: ...
    @overload
    def getContext(self, contextType: Literal["webgl2"]) -> WebGL2RenderingContext: ...
    @overload
    def getContext(self, contextType: Literal["webgpu"]) -> GPUCanvasContext: ...
    @overload
    def getContext(
        self, contextType: Literal["bitmaprenderer"]
    ) -> ImageBitmapRenderingContext: ...

class CanvasRenderingContext2D:
    @property
    def fillStyle(self) -> str: ...
    @fillStyle.setter
    def fillStyle(self, value: str) -> None: ...
    def fillRect(self, x: float, y: float, width: float, height: float) -> None: ...
    @overload
    def drawImage(self, image: IMG, dx: float, dy: float) -> None: ...
    @overload
    def drawImage(
        self, image: IMG, dx: float, dy: float, dWidth: float, dHeight: float
    ) -> None: ...
    @overload
    def drawImage(
        self,
        image: IMG,
        sx: float,
        sy: float,
        sWidth: float,
        sHeight: float,
        dx: float,
        dy: float,
        dWidth: float,
        dHeight: float,
    ) -> None: ...

class WebGLRenderingContext:
    pass

class WebGL2RenderingContext:
    pass

class GPUCanvasContext:
    pass

class ImageBitmapRenderingContext:
    pass
