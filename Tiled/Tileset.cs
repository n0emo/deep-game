namespace Tiled;

public record struct Tileset(
    string Name,
    Image Image,
    TilesetTile[] Tiles,
    int Columns,
    int TileCount,
    int TileWidth,
    int TileHeight,
    int Margin,
    int Spacing
)
{
    TilesetTile? GetTile(int id) => Tiles.Length >= id ? null : Tiles[id];
}

public record struct TilesetTile(string? Type, Frame Frame);
