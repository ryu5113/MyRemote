# MyRemote

Flutter Android 앱과 C#/.NET Windows Agent의 LAN PC 리모컨 프로젝트입니다.

## 구현 범위

- 모바일: IPv4와 연결 키 입력, 연결/해제, 터치패드, 좌/우클릭, 스크롤 버튼, 한글/영문 입력, 특수키, 미디어·볼륨 버튼.
- Agent: PC IP 출력, 연결/해제 로그, JSON 메시지 처리, 메시지 크기 제한(16 KiB).
- Android 인터넷 권한과 LAN 평문 WebSocket 설정.

Agent 실행 때마다 임의의 128비트 연결 키가 생성됩니다. 앱에서 이 키를 입력해야 제어할 수 있습니다. 고정 키는 `MYREMOTE_KEY` 환경 변수(16자 이상)로 설정할 수 있습니다. TLS는 아직 미구현이므로 신뢰하는 개인 LAN에서만 사용하며 인터넷에 포트를 공개하지 마세요. 관리자 권한으로 실행 중인 앱과 UAC 화면은 일반 권한 Agent에서 제어할 수 없습니다.

두 손가락 스크롤도 지원합니다. 아직 미구현: 드래그 앤 드롭, 단축키 조합, 시스템 전원, 프로그램 실행, Wake-on-LAN, 장치 저장/자동검색, TV, Watch, Scene, 파일 공유, TLS·배포 서명. 전체 로드맵의 완성 버전으로 표시하지 않습니다.

## 준비

Windows용 .NET 8 SDK, Flutter SDK, Android SDK가 필요합니다. `.NET Runtime`만으로는 빌드할 수 없습니다.

네이티브 Android 프로젝트가 생성되어 포함되어 있습니다. 새 환경에서는 Flutter와 Android SDK 설치 후 `mobile`에서 `flutter pub get`을 실행하세요. 네이티브 파일을 다시 생성해야 할 때만 다음 준비 스크립트를 사용합니다.

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

USB 디버깅을 켠 Android 기기를 연결한 다음 앱에서 IP와 Agent의 연결 키 입력 → 연결을 누릅니다. 터치패드는 PC 포인터를 움직이며, 문자 입력 버튼은 현재 PC에서 선택된 입력란에 텍스트를 입력합니다. 테스트 메시지 버튼은 입력 제어 없이 통신만 확인합니다.

## 검증

```powershell
dotnet build windows-agent/MyRemote.Agent
powershell -ExecutionPolicy Bypass -File scripts/test-agent.ps1 -AccessKey '<Agent 연결 키>'
```

테스트 스크립트는 실행 중인 Agent에 연결하여 hello, ping, 한글 메시지, 잘못된 JSON, 미지원 명령을 확인합니다. 앱에서는 연결 해제, 재연결, 잘못된 IP, 서버 종료 시 상태 변경도 확인하세요.

개발 환경에 .NET SDK 8.0.425, Flutter 3.47.2(Dart 3.13.2), Android Studio를 설치했습니다. Agent 빌드와 로컬 WebSocket 통신·인증 거부 테스트, Flutter 서비스 테스트를 수행했습니다. Android 휴대폰과 Windows GUI 입력 동작은 별도 실기기 검증이 필요합니다.

프로토콜: [protocol/protocol.md](protocol/protocol.md)
검증 결과와 남은 작업: [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md)

## 배포 파일과 재현 가능한 검증

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify.ps1
powershell -ExecutionPolicy Bypass -File scripts/build.ps1
powershell -ExecutionPolicy Bypass -File scripts/smoke-agent.ps1
```

`artifacts/windows-agent/MyRemote.Agent.exe`는 .NET 런타임을 포함한 Windows x64 실행 파일입니다. Android 테스트 APK는 `artifacts/MyRemote-debug.apk`에 생성합니다. 디버그 서명이며 스토어 배포용 APK가 아닙니다.

`scripts/build.ps1 -Preview`로 작은 최적화 APK도 만들 수 있습니다. ARM64 휴대폰용 파일은 `artifacts/MyRemote-arm64-v8a-preview.apk`입니다. 이 파일도 테스트용 서명을 사용합니다. ARMv7 및 x86_64용 파일은 각각 해당 아키텍처 이름으로 생성합니다. 기기 아키텍처를 모르면 모든 지원 아키텍처가 들어 있는 `MyRemote-debug.apk`를 사용하세요.

방화벽에 막혀 휴대폰이 연결되지 않으면 관리자 PowerShell에서 `scripts/allow-agent-firewall.ps1`을 실행할 수 있습니다. 생성한 Agent 실행 파일에 한해 개인 네트워크의 같은 서브넷에서 TCP 8765 접근을 허용합니다. 자동으로 방화벽을 변경하지는 않습니다.
