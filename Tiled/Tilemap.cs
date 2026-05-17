namespace Tiled;

public record struct Tilemap(
    int Width,
    int Height,
    bool Infinite,
    int NextLayerId,
    int NextObjectId,
    string Orientation,
    int TileWidth,
    int TileHeight,
    string Type,
    Layer[] Layers
);