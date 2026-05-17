using Tiled;
using Object = Tiled.Object;

namespace LastShot.Game;

public record MapObject(
    int Id,
    float X,
    float Y,
    float Width,
    float Height
)
{
    private static MapObject FromTiledObject(Object obj)
    {
        return obj.Type switch
        {
            "spawnpoint" => SpawnpointObject.FromTiledObject(obj),
            "transition" => TransitionObject.FromTiledObject(obj),
            "enemy" => EnemyObject.FromTiledObject(obj),
            _ => throw new ArgumentException($"Unknown object type: {obj.Type}")
        };
    }
}

public record SpawnpointObject(
    int Id,
    float X,
    float Y
) : MapObject(Id, X, Y, 0, 0)
{
    public static SpawnpointObject FromTiledObject(Object obj)
    {
        return new SpawnpointObject
        (
            obj.Id,
            obj.X,
            obj.Y
        );
    }
}

public record TransitionObject(
    int Id,
    float X,
    float Y,
    float Width,
    float Height
) : MapObject(Id, X, Y, Width, Height)
{
    public static TransitionObject FromTiledObject(Object obj)
    {
        return new TransitionObject
        (
            obj.Id,
            obj.X,
            obj.Y,
            obj.Width,
            obj.Height
        );
    }
}

public record EnemyObject(
    int Id,
    float X,
    float Y,
    float Width,
    float Height,
    int Hp,
    string Name
) : MapObject(Id, X, Y, Width, Height)
{
    public static EnemyObject FromTiledObject(Object obj)
    {
        return new EnemyObject
        (
            obj.Id,
            obj.X,
            obj.Y,
            obj.Width,
            obj.Height,
            ((ObjectPropertyInt)obj.Properties["hp"]).Int,
            ((ObjectPropertyString)obj.Properties["enemy_name"]).String
        );
    }
}