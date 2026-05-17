using System.Collections.Immutable;
using Tiled.Json;

namespace Tiled;

public class Loader
{
    public Loader(string basePath)
    {
        BasePath = basePath;
        Tilesets = ImmutableDictionary<string, Tileset>.Empty;
        Tilemaps = ImmutableDictionary<string, Tilemap>.Empty;
    }

    public string BasePath { get; init; }
    public ImmutableDictionary<string, Tileset> Tilesets { get; private set; }
    public ImmutableDictionary<string, Tilemap> Tilemaps { get; private set; }

    public Tileset LoadTileset(string path)
    {
        path = Path.Join(BasePath, path);

        if (!Path.HasExtension(path)) throw new MissingExtension(path);

        var ext = Path.GetExtension(path);
        return ext switch
        {
            ".tsj" => TilesetJsonExtensions.FromJson(File.ReadAllText(path)),
            ".tsx" => throw new NotImplementedException(),
            _ => throw new UnknownFileExtension(path, ext)
        };
    }

    public Tilemap LoadTilemap(string path)
    {
        path = Path.Join(BasePath, path);

        if (!Path.HasExtension(path)) throw new MissingExtension(path);

        var ext = Path.GetExtension(path);
        return ext switch
        {
            ".tmj" => throw new NotImplementedException(),
            ".tmx" => throw new NotImplementedException(),
            _ => throw new UnknownFileExtension(path, ext)
        };
    }
}

public class TiledException : Exception;

public class MissingExtension : TiledException
{
    private readonly string _path;

    public MissingExtension(string path)
    {
        _path = path;
    }

    public override string Message => $"File '{_path}' is missing extension";
}

public class UnknownFileExtension : TiledException
{
    private readonly string _ext;
    private readonly string _path;

    public UnknownFileExtension(string path, string ext)
    {
        _path = path;
        _ext = ext;
    }

    public override string Message => $"File '{_path}' has unknown extension '{_ext}'";
}