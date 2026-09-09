param([string]$Endpoint = 'ws://127.0.0.1:8765/ws', [string]$AccessKey = $env:MYREMOTE_KEY)
$ErrorActionPreference = 'Stop'
$socket = [System.Net.WebSockets.ClientWebSocket]::new()
$socket.Options.SetRequestHeader('Authorization', "Bearer $AccessKey")
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
    $unauthorized = [System.Net.WebSockets.ClientWebSocket]::new()
    try {
        $unauthorized.ConnectAsync([Uri]$Endpoint, $deadline.Token).GetAwaiter().GetResult() | Out-Null
        throw 'Unauthenticated connection was accepted'
    } catch [System.Net.WebSockets.WebSocketException] {
        Write-Output 'PASS: unauthenticated connection rejected'
    } finally { $unauthorized.Dispose() }
    $socket.ConnectAsync([Uri]$Endpoint, $deadline.Token).GetAwaiter().GetResult() | Out-Null
    if ((Receive-Json).type -ne 'hello') { throw 'Missing hello' }
    $sample = 'Hello Windows ' + [char]0xD55C + [char]0xAE00
    $cases = @(
        @{ payload = '{"type":"ping"}'; expected = 'pong' },
        @{ payload = (@{type='test_message';text=$sample} | ConvertTo-Json -Compress); expected = 'message_received'; fragment = $true },
        @{ payload = '{'; expected = 'error' },
        @{ payload = '{"type":"unknown"}'; expected = 'error' },
        @{ payload = '{"type":"test_message","text":12}'; expected = 'error' },
        @{ payload = '{"type":"mouse_move","dx":99999,"dy":0}'; expected = 'error' },
        @{ payload = '{"type":"mouse_click","button":"unknown"}'; expected = 'error' },
        @{ payload = '{"type":"key","key":"unsupported"}'; expected = 'error' },
        @{ payload = '{"type":"mouse_move","dx":0,"dy":0}'; expected = 'command_completed' },
        @{ payload = '{"type":"keyboard","text":""}'; expected = 'command_completed' },
        @{ payload = '{"type":"ping"}'; expected = 'pong' }
    )
    foreach ($case in $cases) {
        $bytes = [Text.Encoding]::UTF8.GetBytes($case.payload)
        if ($case.fragment) {
            $split = $bytes.Length - 3
            $socket.SendAsync([ArraySegment[byte]]::new($bytes, 0, $split), [System.Net.WebSockets.WebSocketMessageType]::Text, $false, $deadline.Token).GetAwaiter().GetResult() | Out-Null
            $socket.SendAsync([ArraySegment[byte]]::new($bytes, $split, $bytes.Length - $split), [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $deadline.Token).GetAwaiter().GetResult() | Out-Null
        } else {
            $socket.SendAsync([ArraySegment[byte]]::new($bytes), [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $deadline.Token).GetAwaiter().GetResult() | Out-Null
        }
        $response = Receive-Json
        if ($response.type -ne $case.expected) { throw "Unexpected response: $($response.type)" }
        if ($response.type -eq 'message_received' -and $response.text -ne $sample) { throw 'Unicode round trip failed' }
    }
    $socket.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, 'Done', $deadline.Token).GetAwaiter().GetResult() | Out-Null
    Write-Output 'PASS: hello, ping, fragmented Unicode echo, invalid commands, Windows zero-movement input, connection remains usable.'
} finally { $socket.Dispose(); $deadline.Dispose() }
