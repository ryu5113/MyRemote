param([string]$Endpoint = 'ws://127.0.0.1:8765/ws')
$ErrorActionPreference = 'Stop'
$socket = [System.Net.WebSockets.ClientWebSocket]::new()
$deadline = [System.Threading.CancellationTokenSource]::new(15000)
function Receive-Json {
    $buffer = New-Object byte[] 16384
    $data = [System.IO.MemoryStream]::new()
    try {
        do {
            $part = $socket.ReceiveAsync([ArraySegment[byte]]::new($buffer), $deadline.Token).GetAwaiter().GetResult()
            if ($part.MessageType -ne [System.Net.WebSockets.WebSocketMessageType]::Text) { throw 'Expected text response' }
            $data.Write($buffer, 0, $part.Count)
        } while (-not $part.EndOfMessage)
        return ([Text.Encoding]::UTF8.GetString($data.ToArray()) | ConvertFrom-Json)
    } finally { $data.Dispose() }
}
try {
    $socket.ConnectAsync([Uri]$Endpoint, $deadline.Token).GetAwaiter().GetResult()
    if ((Receive-Json).type -ne 'hello') { throw 'Missing hello' }
    $sample = 'Hello Windows ' + [char]0xD55C + [char]0xAE00
    $cases = @(
        @{ payload = '{"type":"ping"}'; expected = 'pong' },
        @{ payload = (@{type='test_message';text=$sample} | ConvertTo-Json -Compress); expected = 'message_received' },
        @{ payload = '{'; expected = 'error' },
        @{ payload = '{"type":"unknown"}'; expected = 'error' },
        @{ payload = '{"type":"test_message","text":12}'; expected = 'error' },
        @{ payload = '{"type":"ping"}'; expected = 'pong' }
    )
    foreach ($case in $cases) {
        $bytes = [Text.Encoding]::UTF8.GetBytes($case.payload)
        $socket.SendAsync([ArraySegment[byte]]::new($bytes), [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $deadline.Token).GetAwaiter().GetResult()
        $response = Receive-Json
        if ($response.type -ne $case.expected) { throw "Unexpected response: $($response.type)" }
        if ($response.type -eq 'message_received' -and $response.text -ne $sample) { throw 'Unicode round trip failed' }
    }
    $socket.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, 'Done', $deadline.Token).GetAwaiter().GetResult()
    Write-Output 'PASS: hello, ping, Unicode echo, validation, connection remains usable.'
} finally { $socket.Dispose(); $deadline.Dispose() }
