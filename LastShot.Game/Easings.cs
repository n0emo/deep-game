namespace LastShot.Game;

public static class Easings
{
    public static double InExpo(double a, double b, double t)
    {
        if (t != 0) t = Math.Pow(2, 10 * t - 10);

        return Lerp(a, b, t);
    }

    public static double InBackSquare(double a, double b, double t)
    {
        return Lerp(a, b, t * t);
    }

    public static double Lerp(double a, double b, double t)
    {
        return a * (1 - t) + b * t;
    }
}