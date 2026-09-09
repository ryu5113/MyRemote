# MyRemote 통합 리모컨 앱 개발 방향

## 1. 프로젝트 개요

**프로젝트명(가칭): MyRemote**

스마트폰을 이용하여 Windows 노트북/PC, 스마트 TV 등 여러 장치를 하나의
앱에서 제어하는 통합 리모컨 앱을 개발한다.

초기에는 **Android 스마트폰 → Windows PC 제어** 기능을 MVP로 완성하고,
이후 TV 제어, 파일/클립보드 공유, 자동화(Scene), Galaxy Watch, 외부
원격접속 기능으로 단계적으로 확장한다.

------------------------------------------------------------------------

## 2. 핵심 개발 방향

기존의 PC 리모컨, 원격제어, 스마트 TV 리모컨 기능을 통합하는 것을 목표로
한다.

주요 방향은 다음과 같다.

-   스마트폰을 PC의 무선 터치패드/마우스로 사용
-   스마트폰 키보드를 이용한 PC 문자 입력
-   PC 미디어 및 볼륨 제어
-   PC 잠금, 종료, 재시작 및 Wake-on-LAN
-   PC 프로그램 실행
-   파일 및 클립보드 공유
-   Samsung/LG/Google TV 등 스마트 TV 제어
-   여러 장치를 하나의 앱에 등록하여 통합 관리
-   여러 명령을 하나의 버튼으로 실행하는 Scene 자동화
-   Galaxy Watch를 이용한 간단한 PC/TV 제어
-   장기적으로 외부 인터넷을 통한 안전한 원격제어

------------------------------------------------------------------------

## 3. 전체 개발 로드맵

  단계   개발 내용                    목표 결과
  ------ ---------------------------- ---------------------------------
  1      기본 프로젝트 및 통신 구조   Android ↔ Windows 연결
  2      PC 자동 검색 및 페어링       같은 Wi-Fi에서 PC 검색/인증
  3      터치패드/마우스              스마트폰으로 PC 마우스 제어
  4      키보드                       스마트폰 → PC 문자 입력
  5      미디어/볼륨                  재생, 정지, 이전/다음, 볼륨
  6      PC 시스템 제어               잠금, 종료, 재시작
  7      프로그램 실행                Chrome, PowerPoint 등 실행
  8      Wake-on-LAN                  네트워크를 통한 PC 켜기
  9      파일/클립보드                PC ↔ 스마트폰 데이터 공유
  10     TV 리모컨                    Samsung/LG/Google TV 제어
  11     Scene 자동화                 영화보기, 회의모드 등 복합 명령
  12     Galaxy Watch                 워치에서 PC/TV 제어
  13     외부접속                     집/회사 밖에서 원격제어
  14     보안/배포                    인증·암호화·설치 프로그램 완성

------------------------------------------------------------------------

## 4. 기술 구성

### 4.1 모바일 앱

-   **Flutter**
-   우선 Android 지원
-   향후 iOS 확장 가능
-   WebSocket 기반 실시간 통신

### 4.2 Windows Agent

-   **C# / .NET**
-   Windows 백그라운드/Tray 프로그램으로 발전
-   스마트폰에서 받은 명령을 Windows API에 전달
-   마우스, 키보드, 미디어, 전원, 프로그램 실행 등을 담당

### 4.3 기본 구조

``` text
┌──────────────────────────────┐
│        Android Phone         │
│                              │
│        Flutter App           │
│      MyRemote Client         │
└──────────────┬───────────────┘
               │
               │ Wi-Fi / WebSocket
               │
┌──────────────▼───────────────┐
│        Windows Laptop        │
│                              │
│       MyRemote Agent         │
│          C# / .NET           │
├──────────────────────────────┤
│ Mouse Controller             │
│ Keyboard Controller          │
│ Media Controller             │
│ System Controller            │
│ Application Launcher         │
│ File Transfer                │
└──────────────────────────────┘
```

------------------------------------------------------------------------

## 5. 통신 방식

초기 버전은 같은 Wi-Fi 네트워크에서 **WebSocket**을 사용한다.

### 마우스 이동

``` json
{
  "type": "mouse_move",
  "dx": 15,
  "dy": -8
}
```

### 마우스 클릭

``` json
{
  "type": "mouse_click",
  "button": "left"
}
```

### 키보드 입력

``` json
{
  "type": "keyboard",
  "text": "안녕하세요"
}
```

### 볼륨 조절

``` json
{
  "type": "volume",
  "action": "up"
}
```

### PC 잠금

``` json
{
  "type": "system",
  "action": "lock"
}
```

명령 형식을 공통화하여 향후 Windows뿐 아니라 TV와 다른 장치에도 확장할
수 있도록 설계한다.

------------------------------------------------------------------------

## 6. 프로젝트 구조

``` text
MyRemote/
│
├─ mobile/
│   ├─ lib/
│   │   ├─ main.dart
│   │   ├─ screens/
│   │   │   ├─ home_screen.dart
│   │   │   ├─ device_screen.dart
│   │   │   ├─ touchpad_screen.dart
│   │   │   └─ keyboard_screen.dart
│   │   ├─ services/
│   │   │   ├─ websocket_service.dart
│   │   │   ├─ discovery_service.dart
│   │   │   └─ device_service.dart
│   │   └─ models/
│   │       └─ remote_device.dart
│   └─ pubspec.yaml
│
├─ windows-agent/
│   ├─ MyRemote.Agent/
│   │   ├─ Program.cs
│   │   ├─ Network/
│   │   │   └─ WebSocketServer.cs
│   │   ├─ Controllers/
│   │   │   ├─ MouseController.cs
│   │   │   ├─ KeyboardController.cs
│   │   │   ├─ MediaController.cs
│   │   │   └─ SystemController.cs
│   │   └─ Models/
│   │       └─ RemoteCommand.cs
│   └─ MyRemote.sln
│
├─ protocol/
│   └─ protocol.md
│
└─ README.md
```

------------------------------------------------------------------------

## 7. 1차 MVP 목표

첫 번째 버전에서는 기능을 과도하게 확장하지 않고 다음 흐름을 완성한다.

1.  Windows에서 MyRemote Agent 실행
2.  Agent가 PC의 IP와 WebSocket 포트를 제공
3.  Android 앱에서 PC IP 입력
4.  같은 Wi-Fi를 통해 Windows Agent에 연결
5.  연결 상태 확인
6.  테스트 메시지를 PC로 전송
7.  이후 터치패드/마우스 제어 기능 추가

### 1차 성공 기준

``` text
Android Phone
      │
      │ WebSocket
      ▼
Windows Agent
      │
      └─ "Hello Windows" 메시지 수신
```

이 통신이 안정적으로 동작하면 마우스와 키보드 기능 개발로 넘어간다.

------------------------------------------------------------------------

## 8. PC 제어 기능 확장

### 터치패드

스마트폰 화면을 노트북 터치패드처럼 사용한다.

-   손가락 이동 → 마우스 포인터 이동
-   탭 → 좌클릭
-   길게 누르기/별도 영역 → 우클릭
-   두 손가락 이동 → 스크롤
-   드래그 지원

### 키보드

-   스마트폰 키보드 문자 입력
-   Enter, ESC, Tab
-   방향키
-   Ctrl/Alt/Shift 조합
-   한글/영문 입력 처리

### 미디어

-   재생/일시정지
-   이전/다음
-   볼륨 증가/감소
-   음소거

### 시스템

-   PC 잠금
-   종료
-   재시작
-   Wake-on-LAN

### 프로그램 실행

사용자가 자주 사용하는 프로그램을 등록하여 스마트폰에서 실행한다.

예:

-   Chrome
-   Edge
-   PowerPoint
-   Excel
-   메모장
-   사용자 지정 프로그램

------------------------------------------------------------------------

## 9. TV 제어 확장

PC 제어가 안정화된 후 스마트 TV를 추가한다.

지원 후보:

-   Samsung Smart TV
-   LG Smart TV
-   Google TV / Android TV

공통 인터페이스를 사용하여 제조사별 구현을 분리한다.

``` text
DeviceController
│
├─ WindowsController
├─ SamsungTVController
├─ LGTVController
└─ GoogleTVController
```

TV 기본 기능:

-   전원
-   볼륨
-   채널
-   방향키
-   OK
-   뒤로가기
-   Home
-   문자 입력
-   Netflix/YouTube 등 앱 실행

------------------------------------------------------------------------

## 10. Scene 자동화

여러 장치의 명령을 하나의 버튼으로 묶어 실행하는 기능이다.

### 영화 보기

``` text
[영화 보기]

TV 전원 ON
    ↓
노트북 Wake-on-LAN
    ↓
TV HDMI 입력 변경
    ↓
Netflix 실행
    ↓
TV 볼륨 설정
```

### 프레젠테이션

``` text
[프레젠테이션]

노트북 깨우기
    ↓
PowerPoint 실행
    ↓
TV/디스플레이 연결
    ↓
스마트폰을 발표 리모컨으로 변경
```

Scene 기능은 단순 리모컨 앱과 차별화되는 핵심 기능으로 발전시킨다.

------------------------------------------------------------------------

## 11. Galaxy Watch 확장

스마트폰 앱과 연동하여 Galaxy Watch에서도 자주 사용하는 명령을 실행할 수
있도록 한다.

예:

-   PC 잠금
-   PC 켜기
-   미디어 재생/정지
-   이전/다음
-   TV 볼륨
-   TV 전원
-   Scene 실행

워치에서는 복잡한 화면 제어보다 자주 사용하는 명령을 빠르게 실행하는
것에 초점을 둔다.

------------------------------------------------------------------------

## 12. 보안 방향

원격제어 앱이므로 보안을 초기 설계부터 고려한다.

향후 적용할 주요 항목:

-   최초 연결 시 6자리 인증번호
-   QR Code 페어링
-   기기별 인증 토큰
-   등록되지 않은 장치의 접근 차단
-   통신 암호화
-   인증 토큰 안전한 저장
-   위험 명령 추가 확인
-   연결된 장치 관리 및 연결 해제
-   외부접속 시 강화된 인증 적용

특히 종료/재시작/파일 접근 등의 기능은 인증된 기기만 실행할 수 있도록
한다.

------------------------------------------------------------------------

## 13. 최종 목표

최종적으로 다음과 같은 형태의 통합 리모컨 플랫폼을 목표로 한다.

``` text
             MyRemote
                │
       ┌────────┼────────┐
       │        │        │
     Phone    Watch    Tablet
       │        │        │
       └────────┼────────┘
                │
         MyRemote Protocol
                │
     ┌──────────┼──────────┐
     │          │          │
 Windows PC  Smart TV   기타 장치
```

사용자는 하나의 앱에서 자신의 PC와 TV를 등록하고, 장치별 리모컨뿐 아니라
여러 장치를 동시에 제어하는 자동화 기능까지 사용할 수 있도록 한다.

------------------------------------------------------------------------

## 14. 실제 개발 진행 순서

### Phase 1 --- 기반 구축

-   Flutter 프로젝트 생성
-   Windows Agent 프로젝트 생성
-   WebSocket 서버/클라이언트 구현
-   Android ↔ Windows 통신 테스트

### Phase 2 --- 기본 PC 리모컨

-   터치패드
-   마우스 클릭
-   스크롤
-   키보드

### Phase 3 --- PC 확장 기능

-   볼륨
-   미디어
-   잠금
-   종료/재시작
-   프로그램 실행
-   Wake-on-LAN

### Phase 4 --- 편의 기능

-   PC 자동 검색
-   QR 페어링
-   장치 저장
-   즐겨찾기
-   파일/클립보드 공유

### Phase 5 --- TV

-   TV 자동 검색
-   제조사별 Controller
-   TV 리모컨 UI
-   앱 실행

### Phase 6 --- 통합 자동화

-   Scene
-   사용자 정의 버튼
-   명령 조합
-   즐겨찾는 Scene

### Phase 7 --- 확장

-   Galaxy Watch
-   외부 인터넷 연결
-   보안 강화
-   정식 배포

------------------------------------------------------------------------

## 15. 다음 작업

다음 개발 작업은 **Phase 1의 실제 실행 가능한 프로젝트 생성**이다.

우선 다음 두 프로그램을 만든다.

1.  **MyRemote Mobile**
    -   Flutter Android 앱
    -   Windows Agent IP 입력
    -   WebSocket 연결
    -   연결 상태 표시
    -   테스트 메시지 전송
2.  **MyRemote Windows Agent**
    -   C#/.NET 기반
    -   WebSocket 서버 실행
    -   연결된 스마트폰 표시
    -   스마트폰에서 받은 메시지 출력

두 프로그램의 통신이 확인되면 바로 **스마트폰 터치패드 → Windows 실제
마우스 이동** 기능 개발을 시작한다.
