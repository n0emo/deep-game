using System.Runtime.InteropServices.JavaScript;
using System.Runtime.Versioning;

namespace LastShot.Web;

public static partial class Application
{
    private static Game.Game _game = null!;

    public static void Main()
    {
        _game = new Game.Game();
        _game.Init();
    }

    [SupportedOSPlatform("browser")]
    [JSExport]
    // ReSharper disable once MemberCanBePrivate.Global
    public static void UpdateFrame()
    {
        _game.Frame();
    }
}