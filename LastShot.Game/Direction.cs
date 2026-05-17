namespace LastShot.Game;

public enum Direction
{
    Up,
    Down,
    Left,
    Right
}

public static class DirectionExtensions
{
    public static Vector2 IntoVector2(this Direction direction)
    {
        return direction switch
        {
            Direction.Up => new Vector2(0, -1),
            Direction.Down => new Vector2(0, 1),
            Direction.Left => new Vector2(-1, 0),
            Direction.Right => new Vector2(1, 0),
            _ => throw new ArgumentOutOfRangeException(nameof(direction), $"Not expected direction value: {direction}")
        };
    }

    public static Point IntoPoint(this Direction direction)
    {
        return direction switch
        {
            Direction.Up => new Point(0, -1),
            Direction.Down => new Point(0, 1),
            Direction.Left => new Point(-1, 0),
            Direction.Right => new Point(1, 0),
            _ => throw new ArgumentOutOfRangeException(nameof(direction), $"Not expected direction value: {direction}")
        };
    }
}