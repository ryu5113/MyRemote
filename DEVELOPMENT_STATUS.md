# 개발 및 검증 현황 — 2026-09-09

## 현재 실행 가능한 기능

- Flutter Android 클라이언트와 Windows x64 Agent.
- IP와 Agent 연결 키를 사용하는 WebSocket 접속, 연결 해제/재연결, 상태 표시.
- 터치패드 포인터 이동, 좌/우클릭, 두 손가락 및 버튼 스크롤.
- 한글/영문 Unicode 입력, Enter/Esc/Tab/Backspace와 방향키.
- 미디어 이전/다음/재생·일시정지, 볼륨 증가/감소와 음소거.
- Agent의 128비트 임의 연결 키, 인증 실패 접속 거부, 메시지 크기 및 명령 값 검증.
- PC 화면에서 개인 LAN 주소를 포함한 로컬 QR 페어링 엔드포인트와 Android QR 스캔 UI.

## 확인한 결과

- .NET Windows 빌드 및 런타임 포함 x64 배포 실행 파일 생성 성공.
- 실제 배포 실행 파일에서 인증 없는 접속 거부, hello/ping, 분할 UTF-8 메시지 왕복, 잘못된 명령 이후 정상 요청 처리 통과.
- 실제 Windows SendInput 호출은 포인터를 움직이지 않는 (0, 0) 입력으로 성공 여부 확인.
- Flutter 정적 분석: 문제 없음.
- Flutter 테스트 5개 통과: 잘못된 IP, 인증 헤더·연결·메시지·재연결, 두 손가락 스크롤, 좌/우클릭 제스처, 포인터 이동 제스처.
- Android 디버그 APK 빌드 및 APK v2 서명 검사 통과. 패키지 `com.myremote.myremote`, 최소 API 24, target/compile API 36.
- 최적화 미리보기 APK(테스트용 서명)도 빌드·서명 검사 통과: ARMv7 13.9MB, ARM64 16.4MB, x86_64 17.8MB.
- PowerShell 스크립트 문법 검사 통과.

## 설치한 개발 환경

- .NET SDK 8.0.425.
- Flutter stable 3.47.2 / Dart 3.13.2: `C:/Users/user/develop/flutter`.
- Android Studio 2026.1.4.7와 포함된 Java 25.0.3.
- Android SDK: `C:/Users/user/AppData/Local/Android/Sdk`, 플랫폼 36, Build Tools 36.0.0, NDK 28.2.13676358.
- 새 Android CLI에서 저장소 메타데이터 오류가 발생하여 공식 command-line tools 19.0으로 복구. 실패한 도구/NDK 파일은 삭제하지 않고 백업.
- Flutter 사용자 PATH와 Android SDK/JDK 경로 등록. 기존 IDE는 다시 시작해야 환경 변수를 읽을 수 있음.

## 아직 검증하지 못한 부분

사용자가 현재 휴대폰을 연결할 수 없어 실제 Android 휴대폰 설치·Wi-Fi 연결·Windows 앱의 한글 입력 및 미디어 반응은 미검증입니다. 테스트용 APK는 스토어 배포용 서명을 갖추지 않았습니다. TLS가 없으므로 연결 키가 포함된 통신은 신뢰하는 개인 LAN에서만 사용합니다.

## 로드맵에 남은 개발

드래그 앤 드롭과 Ctrl/Alt/Shift 조합, 장치 저장·자동검색, 지속적 기기별 페어링, Tray UI, 시스템 전원·프로그램 실행·Wake-on-LAN, 파일/클립보드, TV 제조사별 연동, Scene, Watch, 외부 연결, TLS와 정식 서명/설치 프로그램은 후속 구현입니다. 현재 버전을 전체 로드맵이 완성된 제품으로 간주하지 않습니다.
