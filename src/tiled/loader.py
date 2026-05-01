from pathlib import Path
from .tilemap import Tilemap
from .tileset import Tileset, Tile
import json
from engine import Rectangle, Texture
from typing import Dict


class Loader:
    __tilesets: Dict[str, Tileset]

    def __init__(self) -> None:
        self.__tilesets = {}

    def load_tileset(self, path: Path) -> Tileset:
        data = None
        with open(str(path)) as f:
            data = json.load(f)
        name = data["name"]

        if name in self.__tilesets:
            return self.__tilesets[name]

        image = data["image"]
        imagepath = path.parent.joinpath(image)
        texture = Texture.load(imagepath)

        tilecount = data["tilecount"]
        tileheight = data["tileheight"]
        tilewidth = data["tilewidth"]
        imageheight = data["imageheight"]
        imagewidth = data["imagewidth"]

        width = imagewidth // tilewidth
        height = imageheight // tileheight

        tiles = []

        for id in range(tilecount):
            x = id % width * tilewidth
            y = id // height * tileheight
            frame = Rectangle(x=x, y=y, w=tilewidth, h=tileheight)
            tile = Tile(type="", frame=frame)
            tiles.append(tile)

        for tile in data["tiles"]:
            id = tile["id"]
            tiles[id] = Tile(type=tile["type"], frame=tiles[id].frame)

        tileset = Tileset(
            texture=texture,
            columns=data["columns"],
            image=image,
            imageheight=imageheight,
            imagewidth=imagewidth,
            margin=data["margin"],
            name=name,
            spacing=data["spacing"],
            tilecount=tilecount,
            tiledversion=data["tiledversion"],
            tileheight=tileheight,
            tilewidth=tilewidth,
            type=data["type"],
            version=data["version"],
            tiles=tiles,
        )
        self.__tilesets[name] = tileset
        return tileset

    def load_tilemap(self, path: Path) -> None:
        raise NotImplementedError()

    def get_tilemap(self, name: str) -> Tilemap:
        raise NotImplementedError()

    def get_tileset(self, name: str) -> Tileset:
        raise NotImplementedError()

    def unload_tilset(self, name: str) -> None:
        raise NotImplementedError()

    def unload_tilemap(self, name: str) -> None:
        raise NotImplementedError()

    def unload_all(self) -> None:
        raise NotImplementedError()
