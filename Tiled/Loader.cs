using System.Collections.Immutable;

namespace Tiled;

public class Loader
{
    public string BasePath { get; init; }
    public ImmutableDictionary<string, Tileset> Tilesets { get; private set; }
    public ImmutableDictionary<string, Tilemap> Tilemaps { get; private set; }

    public Loader(string basePath)
    {
        BasePath = basePath;
        Tilesets = ImmutableDictionary<string, Tileset>.Empty;
        Tilemaps = ImmutableDictionary<string, Tilemap>.Empty;
    }

    public Tileset LoadTileset(string path)
    {
        path = Path.Join(BasePath, path);

        if (!Path.HasExtension(path))
        {
            throw new MissingExtension(path);
        }

        var ext = Path.GetExtension(path);
        return ext switch
        {
            ".tsj" => Tiled.Json.TilesetJsonExtensions.FromJson(File.ReadAllText(path)),
            ".tsx" => throw new NotImplementedException(),
            _ => throw new UnknownFileExtension(path, ext),
        };
    }

    public Tilemap LoadTilemap(string path)
    {
        path = Path.Join(BasePath, path);

        if (!Path.HasExtension(path))
        {
            throw new MissingExtension(path);
        }

        var ext = Path.GetExtension(path);
        return ext switch
        {
            ".tmj" => throw new NotImplementedException(),
            ".tmx" => throw new NotImplementedException(),
            _ => throw new UnknownFileExtension(path, ext),
        };
    }
}

public class TiledException : Exception;

public class MissingExtension : TiledException
{
    private string _path;

    public MissingExtension(string path)
    {
        _path = path;
    }

    public override string Message => $"File '{_path}' is missing extension";
}

public class UnknownFileExtension : TiledException
{
    private string _path;
    private string _ext;

    public UnknownFileExtension(string path, string ext)
    {
        _path = path;
        _ext = ext;
    }

    public override string Message => $"File '{_path}' has unknown extension '{_ext}'";
}
