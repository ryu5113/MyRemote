#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'
$agentPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../artifacts/windows-agent/MyRemote.Agent.exe'))
if (-not (Test-Path -LiteralPath $agentPath)) { throw 'Build the Windows agent first.' }
if (Get-NetFirewallRule -Name MyRemoteAgentPrivate -ErrorAction SilentlyContinue) {
    Write-Output 'MyRemoteAgentPrivate already exists. Inspect its settings in Windows Firewall if the executable was moved.'
    return
}
New-NetFirewallRule -Name MyRemoteAgentPrivate -DisplayName 'MyRemote Agent (Private LAN)' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8765 -Program $agentPath -Profile Private -RemoteAddress LocalSubnet | Out-Null
Write-Output 'Allowed this agent executable on TCP 8765 for the private local subnet only.'
