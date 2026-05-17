using System.Diagnostics.CodeAnalysis;
using System.Text.Json;

namespace Tiled.Json;

public static class TilesetJsonExtensions
{
    public static Tileset FromJson(string data)
    {
        var d = JsonSerializer.Deserialize(
                data, typeof(TilesetDescriptor), TiledJsonContext.Default) as TilesetDescriptor;
        if (d is null)
        {
            throw new JsonException("Error parsing tileset");
        }

        return TilesetJsonExtensions.FromDescriptor(d);
    }

    internal static Tileset FromDescriptor(TilesetDescriptor d)
    {
        var types = d.tiles.Select(t => (t.id, t.type)).ToDictionary();
        var tiles = new TilesetTile[d.tilecount];
        for (int id = 0; id < tiles.Length; id++)
        {
            var (x, y) = Math.DivRem(id, d.tilewidth);
            (x, y) = (x * d.tilewidth, y * d.tilewidth);
            // TODO: Margin
            // TODO: Spacing
            var frame = new Frame { X = x, Y = y, W = d.tilewidth, H = d.tileheight };
            var type = types.GetValueOrDefault(id);
            tiles[id] = new TilesetTile { Type = type, Frame = frame };
        }

        return new Tileset
        {
            Image = new Image
            {
                Source = d.image,
                Width = d.imagewidth,
                Height = d.imageheight,
            },
            Tiles = tiles,
            Columns = d.columns,
            TileCount = d.tilecount,
            TileWidth = d.tilewidth,
            TileHeight = d.tileheight,
            Margin = d.margin,
            Spacing = d.spacing,
        };
    }
}

internal record TilesetDescriptor
(
    int columns,
    string image,
    int imageheight,
    int imagewidth,
    int margin,
    string name,
    int spacing,
    int tilecount,
    string tiledversion,
    int tileheight,
    TilesetTileDescriptor[] tiles,
    int tilewidth,
    string type,
    string version
);

internal record TilesetTileDescriptor
(
    int id,
    string type
);
