namespace LastShot.Game;

public record struct Animation(
    Texture2D Texture,
    AnimationFrame[] Frames,
    Vector2 Origin,
    float Scale
)
{
    public Sprite CurrentSprite => throw new NotImplementedException();

    public void Update()
    {
        throw new NotImplementedException();
    }

    public void Draw()
    {
        throw new NotImplementedException();
    }
}

public record struct AnimationFrame(
    Rectangle Source,
    float Duration,
    bool MirrorHorizontal,
    bool MirrorVertical
);
