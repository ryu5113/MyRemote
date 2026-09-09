using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text.Json;
using System.Diagnostics;

namespace MyRemote.Agent.Controllers;

public sealed class InputController
{
    public object Execute(JsonElement command)
    {
        var type = Text(command, "type");
        switch (type)
        {
            case "mouse_move":
                Send(Mouse(1, Number(command, "dx", -1000, 1000), Number(command, "dy", -1000, 1000)));
                break;
            case "mouse_click":
                var button = Text(command, "button");
                if (button != "left" && button != "right") throw new ArgumentException("Unknown mouse button");
                Send(Mouse(button == "left" ? 2u : 8u), Mouse(button == "left" ? 4u : 16u));
                break;
            case "mouse_scroll":
                Send(Mouse(0x800, data: unchecked((uint)Number(command, "delta", -1200, 1200))));
                break;
            case "keyboard":
                var text = Text(command, "text");
                if (text.Length > 2000) throw new ArgumentException("Text exceeds 2000 UTF-16 units");
                if (text.Length > 0) Send(text.SelectMany(c => new[] { Key(0, c, 4), Key(0, c, 6) }).ToArray());
                break;
            case "key":
                Tap(Text(command, "key") switch {
                    "enter" => 0x0D, "escape" => 0x1B, "tab" => 9, "backspace" => 8,
                    "left" => 0x25, "up" => 0x26, "right" => 0x27, "down" => 0x28,
                    _ => throw new ArgumentException("Unsupported key") });
                break;
            case "volume":
                Tap(Text(command, "action") switch { "up" => 0xAF, "down" => 0xAE, "mute" => 0xAD, _ => throw new ArgumentException("Unsupported volume action") });
                break;
            case "media":
                Tap(Text(command, "action") switch { "play_pause" => 0xB3, "next" => 0xB0, "previous" => 0xB1, "stop" => 0xB2, _ => throw new ArgumentException("Unsupported media action") });
                break;
            case "system":
                if (Text(command, "action") != "lock") throw new ArgumentException("Only lock is available");
                if (!LockWorkStation()) throw new Win32Exception(Marshal.GetLastWin32Error());
                break;
            case "launch":
                var name = Text(command, "name");
                var target = name switch
                {
                    "chrome" => "chrome.exe", "edge" => "msedge.exe", "notepad" => "notepad.exe",
                    "calculator" => "calc.exe", _ => throw new ArgumentException("Application is not allow-listed")
                };
                Process.Start(new ProcessStartInfo(target) { UseShellExecute = true });
                break;
            default: throw new ArgumentException("Unsupported command");
        }
        return new { type = "command_completed", command = type };
    }

    private static string Text(JsonElement root, string key) =>
        root.TryGetProperty(key, out var value) && value.ValueKind == JsonValueKind.String
            ? value.GetString()! : throw new ArgumentException($"Missing string: {key}");
    private static int Number(JsonElement root, string key, int min, int max) =>
        root.TryGetProperty(key, out var value) && value.ValueKind == JsonValueKind.Number && value.TryGetInt32(out var number) && number >= min && number <= max
            ? number : throw new ArgumentException($"Invalid integer: {key} ({min}..{max})");
    private static Input Mouse(uint flags, int x = 0, int y = 0, uint data = 0) => new() { Type = 0, Data = new Union { Mouse = new MouseInput { Dx = x, Dy = y, Flags = flags, MouseData = data } } };
    private static Input Key(ushort key, ushort scan = 0, uint flags = 0) => new() { Type = 1, Data = new Union { Keyboard = new KeyboardInput { Vk = key, Scan = scan, Flags = flags } } };
    private static void Tap(ushort key)
    {
        var flags = key is >= 0x25 and <= 0x28 ? 1u : 0u;
        Send(Key(key, flags: flags), Key(key, flags: flags | 2));
    }
    private static void Send(params Input[] inputs)
    {
        if (SendInput((uint)inputs.Length, inputs, Marshal.SizeOf<Input>()) != inputs.Length)
            throw new Win32Exception(Marshal.GetLastWin32Error());
    }
    [StructLayout(LayoutKind.Sequential)] private struct Input { public uint Type; public Union Data; }
    [StructLayout(LayoutKind.Explicit)] private struct Union {
        [FieldOffset(0)] public MouseInput Mouse;
        [FieldOffset(0)] public KeyboardInput Keyboard;
    }
    [StructLayout(LayoutKind.Sequential)] private struct MouseInput { public int Dx, Dy; public uint MouseData, Flags, Time; public UIntPtr Extra; }
    [StructLayout(LayoutKind.Sequential)] private struct KeyboardInput { public ushort Vk, Scan; public uint Flags, Time; public UIntPtr Extra; }
    [DllImport("user32.dll", SetLastError = true)] private static extern uint SendInput(uint count, Input[] inputs, int size);
    [DllImport("user32.dll", SetLastError = true)] private static extern bool LockWorkStation();
}
