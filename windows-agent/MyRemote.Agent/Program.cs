using System.Net;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using System.Net.WebSockets;
using System.Text.Json;
using System.Security.Cryptography;
using System.Text;
using MyRemote.Agent.Controllers;
using QRCoder;

var builder = WebApplication.CreateBuilder(args);
builder.WebHost.UseUrls(builder.Configuration["urls"] ?? "http://0.0.0.0:8765");
var app = builder.Build();
var accessKey = Environment.GetEnvironmentVariable("MYREMOTE_KEY") ?? Convert.ToHexString(RandomNumberGenerator.GetBytes(16));
if (accessKey.Length < 16) throw new InvalidOperationException("MYREMOTE_KEY must contain at least 16 characters.");
Console.WriteLine($"Connection key: {accessKey}");
var controller = new InputController();
app.UseWebSockets(new WebSocketOptions { KeepAliveInterval = TimeSpan.FromSeconds(20) });
app.MapGet("/health", () => new { name = "MyRemote Agent", version = "0.1.0" });
app.MapGet("/", (HttpContext context) =>
{
context.Response.Headers.CacheControl = "no-store";
context.Response.Headers["X-Content-Type-Options"] = "nosniff";
context.Response.Headers["Referrer-Policy"] = "no-referrer";
return Results.Content("""
<!doctype html>
<html lang="ko"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src 'self'; style-src 'unsafe-inline';">
<meta name="referrer" content="no-referrer"><title>MyRemote 연결</title>
<style>body{font:16px system-ui,sans-serif;background:#f4f5fa;color:#20233a;margin:0;min-height:100vh;display:grid;place-items:center}.card{background:white;padding:32px;border-radius:24px;box-shadow:0 8px 35px #18204a18;text-align:center;max-width:420px;margin:20px}img{width:min(300px,75vw);height:auto}.hint{color:#555b70;line-height:1.65}.badge{color:#176b3a;background:#e7f7ed;padding:8px 14px;border-radius:999px;display:inline-block}</style></head>
<body><main class="card"><span class="badge">MyRemote Agent 실행 중</span><h1>휴대폰 연결</h1><img src="/pairing.png" alt="MyRemote 연결 QR 코드"><p class="hint">MyRemote 앱에서 <b>QR로 자동 입력</b>을 누르고 이 코드를 스캔하세요.</p><p class="hint">휴대폰과 PC를 같은 Wi-Fi에 연결하세요. 이 QR에는 일회성 연결 키가 포함되니 공유하지 마세요.</p></main></body></html>
""", "text/html; charset=utf-8");
});
app.MapGet("/pairing.png", (HttpContext context) =>
{
    if (context.Connection.RemoteIpAddress is not { } peer || !IPAddress.IsLoopback(peer))
        return Results.StatusCode(StatusCodes.Status403Forbidden);
    var address = NetworkInterface.GetAllNetworkInterfaces()
        .Where(n => n.OperationalStatus == OperationalStatus.Up)
        .SelectMany(n => n.GetIPProperties().UnicastAddresses)
        .Select(a => a.Address)
        .FirstOrDefault(a => a.AddressFamily == AddressFamily.InterNetwork && !IPAddress.IsLoopback(a))?.ToString() ?? "127.0.0.1";
    var payload = $"myremote://pair?host={address}&port=8765&key={Uri.EscapeDataString(accessKey)}";
    using var qr = new QRCodeGenerator();
    using var data = qr.CreateQrCode(payload, QRCodeGenerator.ECCLevel.Q);
    context.Response.Headers.CacheControl = "no-store";
    context.Response.Headers["X-Content-Type-Options"] = "nosniff";
    return Results.File(new PngByteQRCode(data).GetGraphic(12), "image/png");
});
app.Map("/ws", async context =>
{
    if (!context.WebSockets.IsWebSocketRequest)
    {
        context.Response.StatusCode = 400;
        return;
    }
    var supplied = context.Request.Headers.Authorization.ToString();
    if (!CryptographicOperations.FixedTimeEquals(Encoding.UTF8.GetBytes(supplied), Encoding.UTF8.GetBytes("Bearer " + accessKey)))
    {
        context.Response.StatusCode = 401;
        return;
    }
    using var socket = await context.WebSockets.AcceptWebSocketAsync();
    var peer = context.Connection.RemoteIpAddress;
    using var lifetime = CancellationTokenSource.CreateLinkedTokenSource(
        context.RequestAborted, app.Lifetime.ApplicationStopping);
    var token = lifetime.Token;
    app.Logger.LogInformation("Phone connected: {Peer}", peer);
    try
    {
        await Send(socket, new { type = "hello", name = Environment.MachineName, version = "0.1.0" }, token);
        var buffer = new byte[4096];
        while (socket.State == WebSocketState.Open)
        {
            using var message = new MemoryStream();
            WebSocketReceiveResult result;
            do
            {
                result = await socket.ReceiveAsync(new ArraySegment<byte>(buffer), token);
                if (result.MessageType == WebSocketMessageType.Close)
                {
                    await socket.CloseOutputAsync(WebSocketCloseStatus.NormalClosure, "Bye", token);
                    return;
                }
                if (result.MessageType != WebSocketMessageType.Text || message.Length + result.Count > 16384)
                {
                    await socket.CloseOutputAsync(WebSocketCloseStatus.PolicyViolation, "Text JSON up to 16 KiB required", token);
                    return;
                }
                message.Write(buffer, 0, result.Count);
            } while (!result.EndOfMessage);

            object response;
            try
            {
                using var json = JsonDocument.Parse(message.ToArray());
                var root = json.RootElement;
                if (root.ValueKind != JsonValueKind.Object ||
                    !root.TryGetProperty("type", out var type) || type.ValueKind != JsonValueKind.String)
                    throw new JsonException("A string type is required.");
                switch (type.GetString())
                {
                    case "ping":
                        response = new { type = "pong" };
                        break;
                    case "test_message":
                        if (!root.TryGetProperty("text", out var text) || text.ValueKind != JsonValueKind.String)
                            throw new JsonException("A string text is required.");
                        app.Logger.LogInformation("Message from {Peer}: {Text}", peer, JsonSerializer.Serialize(text.GetString()));
                        response = new { type = "message_received", text = text.GetString() };
                        break;
                    default:
                        response = controller.Execute(root);
                        break;
                }
            }
            catch (JsonException)
            {
                response = new { type = "error", message = "Expected a JSON object with string type and string text for test_message" };
            }
            catch (ArgumentException ex) { response = new { type = "error", message = ex.Message }; }
            catch (System.ComponentModel.Win32Exception) { response = new { type = "error", message = "Windows rejected input. Elevated applications cannot be controlled by a normal agent." }; }
            await Send(socket, response, token);
        }
    }
    catch (OperationCanceledException) { }
    catch (WebSocketException ex) { app.Logger.LogDebug(ex, "Connection closed"); }
    finally { app.Logger.LogInformation("Phone disconnected: {Peer}", peer); }
});

if (builder.Configuration["urls"] is null)
foreach (var address in NetworkInterface.GetAllNetworkInterfaces()
    .Where(n => n.OperationalStatus == OperationalStatus.Up)
    .SelectMany(n => n.GetIPProperties().UnicastAddresses)
    .Select(a => a.Address)
    .Where(a => a.AddressFamily == AddressFamily.InterNetwork && !IPAddress.IsLoopback(a)))
    Console.WriteLine($"Mobile connection: ws://{address}:8765/ws");

await app.RunAsync();

static Task Send(WebSocket socket, object value, CancellationToken token) =>
    socket.SendAsync(new ArraySegment<byte>(JsonSerializer.SerializeToUtf8Bytes(value)),
        WebSocketMessageType.Text, true, token);
