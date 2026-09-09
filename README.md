# MyRemote

개발 방향 문서 7절·15절의 Phase 1: Flutter Android 앱과 C#/.NET Windows Agent의 LAN WebSocket 통신 프로젝트입니다.

## 구현 범위

- 모바일: IPv4 입력, 연결/해제, 연결 상태, 메시지 전송, 응답 기록, Ping.
- Agent: PC IP 출력, 연결/해제 로그, JSON 메시지 처리, 메시지 크기 제한(16 KiB).
- Android 인터넷 권한과 LAN 평문 WebSocket 설정.

마우스·키보드·TV·Watch·Scene 등은 후속 단계이며 아직 구현하지 않았습니다. 현재 서버는 테스트 메시지만 처리하며 PC를 제어하지 않습니다. 인증과 TLS는 미구현이므로 신뢰하는 로컬 네트워크에서 테스트하세요.

## 준비

Windows용 .NET 8 SDK, Flutter SDK, Android SDK가 필요합니다. `.NET Runtime`만으로는 빌드할 수 없습니다.

Flutter SDK가 없던 환경에서 작성되어 네이티브 Android/Gradle 생성 파일은 포함하지 않았습니다. SDK 설치 후 프로젝트 루트에서 다음 명령을 한 번 실행하면 기존 Dart 소스와 AndroidManifest를 유지하면서 누락된 파일을 생성합니다.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/prepare-mobile.ps1
```

## 실행

```powershell
dotnet run --project windows-agent/MyRemote.Agent
```

Agent에 출력된 IP 중 휴대폰과 같은 Wi-Fi의 주소를 사용합니다. Windows 방화벽 알림이 표시되면 개인 네트워크에서 접근을 허용하세요. Kestrel 서버이므로 관리자 실행이나 HTTP URL 예약은 필요하지 않습니다.

별도 터미널:

```powershell
cd mobile
flutter run
```

USB 디버깅을 켠 Android 기기를 연결한 다음 앱에서 IP 입력 → 연결 → `Hello Windows` 전송을 누릅니다. Agent 로그와 모바일의 `message_received` 응답을 모두 확인합니다.

## 검증

```powershell
dotnet build windows-agent/MyRemote.Agent
powershell -ExecutionPolicy Bypass -File scripts/test-agent.ps1
```

테스트 스크립트는 실행 중인 Agent에 연결하여 hello, ping, 한글 메시지, 잘못된 JSON, 미지원 명령을 확인합니다. 앱에서는 연결 해제, 재연결, 잘못된 IP, 서버 종료 시 상태 변경도 확인하세요.

현재 작업 환경에는 .NET SDK와 Flutter SDK가 없어 빌드 및 실기기 통신 검증은 수행하지 못했습니다.

프로토콜: [protocol/protocol.md](protocol/protocol.md)
