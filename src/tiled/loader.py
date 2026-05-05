from pathlib import Path
from .tilemap import Tilemap, TileLayer, ObjectLayer, Layer, Object, Tile, ObjectValue
from .tileset import Tileset, TilesetTile
import json
from engine import Rectangle, Texture
from typing import Dict, List, Tuple


class Loader:
    __tilesets: Dict[str, Tileset]
    __tilemaps: Dict[str, Tilemap]

    def __init__(self) -> None:
        self.__tilesets = {}
        self.__tilemaps = {}

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

        tiles: List[TilesetTile] = []

        for id in range(tilecount):
            x = id % width * tilewidth
            y = id // width * tileheight
            frame = Rectangle(x=x, y=y, w=tilewidth, h=tileheight)
            tile = TilesetTile(type="", frame=frame)
            tiles.append(tile)

        for tile in data["tiles"]:
            id = tile["id"]
            tiles[id] = TilesetTile(type=tile["type"], frame=tiles[id].frame)

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

    def load_tilemap(self, path: Path) -> Tilemap:
        data = None
        path = path.resolve()
        path_str = str(path)

        with open(str(path)) as f:
            data = json.load(f)

        if path_str in self.__tilemaps:
            return self.__tilemaps[path_str]

        tilesets = []

        for tileset in data["tilesets"]:
            source_path = path.parent.joinpath(tileset["source"])
            source = self.load_tileset(source_path)
            tilesets.append((tileset["firstgid"], source))

        layers: List[Layer] = []

        for layer in data["layers"]:
            match layer["type"]:
                case "tilelayer":
                    tile_layer = self.__parse_tile_layer(layer, tilesets)
                    layers.append(tile_layer)
                case "objectgroup":
                    object_layer = self.__parse_object_layer(layer)
                    layers.append(object_layer)
                case _:
                    raise ValueError(f"Unknown layer type: {layer['type']}")

        tilemap = Tilemap(
            compressionlevel=data["compressionlevel"],
            height=data["height"],
            width=data["width"],
            infinite=data["infinite"],
            nextlayerid=data["nextlayerid"],
            nextobjectid=data["nextobjectid"],
            orientation=data["orientation"],
            renderorder=data["renderorder"],
            tiledversion=data["tiledversion"],
            tileheight=data["tileheight"],
            tilewidth=data["tilewidth"],
            type=data["type"],
            version=data["version"],
            layers=layers,
        )

        self.__tilemaps[path_str] = tilemap

        return tilemap

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

    def __parse_tile_layer(
        self, layer: Dict, tilesets: List[Tuple[int, Tileset]]
    ) -> TileLayer:

        tiles = []
        for gid in layer["data"]:
            flipped_horizontally = bool(gid & 0x80000000)
            flipped_vertically = bool(gid & 0x40000000)
            flipped_diagonally = bool(gid & 0x20000000)
            rotated_hex120 = bool(gid & 0x10000000)

            gid = gid & 0x0FFFFFFF
            if gid == 0:
                tiles.append(Tile())
                continue

            for firstgid, tileset in tilesets[::-1]:
                if gid >= firstgid:
                    id = gid - firstgid
                    tileset_tile = tileset.get_tile(id)
                    tile = Tile(
                        type=tileset_tile.type,
                        frame=tileset_tile.frame,
                        texture=tileset.texture,
                        flipped_diagonally=flipped_diagonally,
                        flipped_horizontally=flipped_horizontally,
                        flipped_vertically=flipped_vertically,
                        rotated_hex120=rotated_hex120,
                    )
                    tiles.append(tile)
                    break

        return TileLayer(
            id=layer["id"],
            x=layer["x"],
            y=layer["y"],
            width=layer["width"],
            height=layer["height"],
            name=layer["name"],
            layer_class=layer["class"],
            opacity=layer["opacity"],
            visible=layer["visible"],
            tiles=tiles,
        )

    def __parse_object_layer(self, layer: Dict) -> ObjectLayer:
        objects = []

        for object in layer["objects"]:
            properties: Dict[str, ObjectValue] = {}

            for prop in object.get("properties", []):
                name = prop["name"]
                value = prop["value"]

                match prop["type"]:
                    case "string":
                        properties[name] = str(value)
                    case "int":
                        properties[name] = int(value)
                    case _:
                        raise ValueError(f"Unknown property type: {prop['type']}")

            obj = Object(
                width=object["width"],
                height=object["height"],
                x=object["x"],
                y=object["y"],
                id=object["id"],
                name=object["name"],
                opacity=object["opacity"],
                point=object.get("point", False),
                rotation=object["rotation"],
                type=object["type"],
                visible=object["visible"],
                properties=properties,
            )

            objects.append(obj)

        return ObjectLayer(
            id=layer["id"],
            x=layer["x"],
            y=layer["y"],
            name=layer["name"],
            layer_class=layer["class"],
            opacity=layer["opacity"],
            visible=layer["visible"],
            objects=objects,
        )
