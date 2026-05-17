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
    public static Sprite FromTexture(Texture2D texture)
    {
        return new Sprite(
            texture,
            new Rectangle(0, 0, texture.Width, texture.Height),
            1,
            Vector2.Zero,
            false,
            false
        );
    }

    public void Draw(Vector2 position)
    {
        var dest = new Rectangle(0, 0, Source.Width, Source.Height);
        // TODO: Rotation
        Raylib.DrawTexturePro(Texture, Source, dest, Origin, Scale, Color.White);
    }
}