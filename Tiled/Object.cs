using System.Collections.Immutable;

namespace Tiled;

public record Object(
    int Id,
    int X,
    int Y,
    int Width,
    int Height,
    string Name,
    float Opacity,
    bool Point,
    int Rotation,
    string Type,
    bool Visible,
    ImmutableDictionary<string, ObjectProperty> Properties
);

public record ObjectProperty;

public record ObjectPropertyString(string String) : ObjectProperty;

public record ObjectPropertyInt(int Int) : ObjectProperty;

public record ObjectPropertyFloat(float Float) : ObjectProperty;

public record ObjectPropertyBool(bool Bool) : ObjectProperty;

public record ObjectPropertyColor(byte Red, byte Green, byte Blue, byte Alpha) : ObjectProperty;

public record ObjectPropertyFile(string Path) : ObjectProperty;

public record ObjectPropertyObject(int Id) : ObjectProperty;

public record ObjectPropertyClass(ImmutableDictionary<string, ObjectProperty> Properties) : ObjectProperty;