namespace LastShot.Desktop;

internal static class Program
{
    [STAThread]
    public static void Main()
    {
        var game = new Game.Game();
        game.Init();

        try
        {
            while (game.Running) game.Frame();
        }
        finally
        {
            game.Deinit();
        }
    }
}