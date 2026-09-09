using System.Net;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using System.Net.WebSockets;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);
builder.WebHost.UseUrls("http://0.0.0.0:8765");
var app = builder.Build();
app.UseWebSockets(new WebSocketOptions { KeepAliveInterval = TimeSpan.FromSeconds(20) });
app.MapGet("/health", () => new { name = "MyRemote Agent", version = "0.1.0" });
app.Map("/ws", async context =>
{
    if (!context.WebSockets.IsWebSocketRequest)
    {
        context.Response.StatusCode = 400;
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
                        response = new { type = "error", message = "Unsupported command" };
                        break;
                }
            }
            catch (JsonException)
            {
                response = new { type = "error", message = "Expected a JSON object with string type and string text for test_message" };
            }
            await Send(socket, response, token);
        }
    }
    catch (OperationCanceledException) { }
    catch (WebSocketException ex) { app.Logger.LogDebug(ex, "Connection closed"); }
    finally { app.Logger.LogInformation("Phone disconnected: {Peer}", peer); }
});

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
