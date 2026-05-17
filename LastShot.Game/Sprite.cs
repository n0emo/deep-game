namespace LastShot.Game;

public record struct Sprite(
    Texture2D Texture,
    Rectangle Source,
    float Scale,
    Vector2 Origin,
    bool MirrorHorizontal,
    bool MirrorVertical
)
{
    public static Sprite FromTexture(Texture2D texture) => throw new NotImplementedException();

    public void Draw(Vector2 position)
    {
        throw new NotImplementedException();
    }
};
