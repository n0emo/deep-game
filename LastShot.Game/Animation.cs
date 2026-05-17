namespace LastShot.Game;

public record struct Animation(
    Texture2D Texture,
    AnimationFrame[] Frames,
    Vector2 Origin,
    float Scale,
    bool Loop
)
{
    private int _index = 0;
    private float _time = 0;

    public Sprite CurrentSprite
    {
        get
        {
            var frame = Frames[_index];
            var sprite = new Sprite(
                Texture,
                frame.Source,
                Scale,
                Origin,
                frame.MirrorHorizontal,
                frame.MirrorVertical
            );

            return sprite;
        }
    }

    public void Update()
    {
        if (Frames.Length <= 1) return;

        _time += Raylib.GetFrameTime() * 1000;
        if (_time > Frames[_index].Duration)
        {
            _time = 0;
            _index += 1;
            if (_index >= Frames.Length)
            {
                if (Loop)
                    _index = 0;
                else
                    _index = Frames.Length - 1;
            }
        }
    }

    public void Draw(Vector2 position)
    {
        CurrentSprite.Draw(position);
    }
}

public record struct AnimationFrame(
    Rectangle Source,
    float Duration,
    bool MirrorHorizontal,
    bool MirrorVertical
);