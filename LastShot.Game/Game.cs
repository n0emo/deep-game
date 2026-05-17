using Tiled;

namespace LastShot.Game;

public sealed class Game
{
    private Music _music;
    private bool _running;
    private Texture2D _texture;
    private Loader _tiledLoader;

    public bool Running
    {
        get
        {
#if BROWSER
            return _running;
#else
            return _running && !Raylib.WindowShouldClose();
#endif
        }
    }

    public void Init()
    {
        _running = true;
        Raylib.SetConfigFlags(ConfigFlags.ResizableWindow);
        Raylib.InitWindow(800, 450, "DeepGame");
        Raylib.InitAudioDevice();
        Raylib.SetAudioStreamBufferSizeDefault(4096);
        Raylib.SetTargetFPS(60);

        _tiledLoader = new Loader("assets");
        var tileset = _tiledLoader.LoadTileset("tilesets/steampunk.tsj");
        Console.WriteLine(tileset);

        _texture = Raylib.LoadTexture("./assets/sprites/background-main-menu.png");
        _music = Raylib.LoadMusicStream("./assets/audio/music-menu.ogg");

        Raylib.PlayMusicStream(_music);
    }

    public void Deinit()
    {
        Raylib.CloseAudioDevice();
        Raylib.CloseWindow();
    }

    public void Frame()
    {
        Raylib.UpdateMusicStream(_music);

        Raylib.BeginDrawing();
        Raylib.ClearBackground(Raylib.GetColor(0x231d29ff));

        var width = Math.Min(Raylib.GetScreenWidth(), Raylib.GetScreenHeight());
        var center = Raylib.GetScreenCenter();
        var source = new Rectangle { X = 0, Y = 0, Width = _texture.Width, Height = _texture.Height };
        var dest = new Rectangle
        { X = center.X - width * 0.5f, Y = center.Y - width * 0.5f, Width = width, Height = width };
        Raylib.DrawTexturePro(_texture, source, dest, Vector2.Zero, 0, Color.White);

        Raylib.DrawFPS(10, 10);
        Raylib.EndDrawing();
    }
}