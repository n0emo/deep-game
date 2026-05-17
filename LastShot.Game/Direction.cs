namespace LastShot.Game;

public enum Direction
{
    Up,
    Down,
    Left,
    Right,
}

public static class DirectionExtensions
{
    public static Vector2 IntoVector2(this Direction direction)
    {
        throw new NotImplementedException();
    }

    public static Point IntoPoint(this Direction direction)
    {
        throw new NotImplementedException();
    }
}
