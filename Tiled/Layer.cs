namespace Tiled;

public record Layer(
    int Id,
    int X,
    int Y,
    string Name,
    string LayerClass,
    float Opacity,
    bool Visible
);

public record TileLayer(
    int Id,
    int X,
    int Y,
    string Name,
    string LayerClass,
    float Opacity,
    bool Visible,
    int Width,
    int Height,
    TilemapTile[] Tiles
) : Layer(Id, X, Y, Name, LayerClass, Opacity, Visible);

public record ObjectLayer(
    int Id,
    int X,
    int Y,
    string Name,
    string LayerClass,
    float Opacity,
    bool Visible,
    Object[] Objects
) : Layer(Id, X, Y, Name, LayerClass, Opacity, Visible);

public record struct TilemapTile(
    string? Type,
    Frame frame,
    Image Image,
    bool FlippedHorizontally,
    bool FlippedVertically,
    bool FlippedDiagonally,
    bool RotatedHex120
);