using System.Text.Json;
using System.Text.Json.Serialization;

namespace Tiled.Json;

[JsonSerializable(typeof(TilesetDescriptor))]
internal partial class TiledJsonContext : JsonSerializerContext
{
    public static JsonSerializerOptions SerializerOptions => new JsonSerializerOptions
    {
        TypeInfoResolver = TiledJsonContext.Default,
    };
}
