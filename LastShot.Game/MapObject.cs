namespace LastShot.Game;

public record MapObject(
    int Id,
    float X,
    float Y,
    float Width,
    float Height
)
{
    static MapObject FromTiledObject(Tiled.Object obj)
    {
        throw new NotImplementedException();
    }
}

public record SpawnpointObject(
    int Id,
    float X,
    float Y,
    float Width,
    float Height
) : MapObject(Id, X, Y, Width, Height)
{
    static SpawnpointObject FromTiledObject(Tiled.Object obj)
    {
        throw new NotImplementedException();
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
    static TransitionObject FromTiledObject(Tiled.Object obj)
    {
        throw new NotImplementedException();
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
    static EnemyObject FromTiledObject(Tiled.Object obj)
    {
        throw new NotImplementedException();
    }
}
