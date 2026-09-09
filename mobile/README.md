# MyRemote Mobile

Android용 Flutter PC 리모컨입니다. 실행과 인증 키 사용법은 [프로젝트 안내](../README.md)를 참고하세요.

## 실행

```powershell
flutter pub get
flutter run
```

## 검증 및 빌드

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

현재 인증 키는 메모리에만 유지됩니다. Agent를 재시작하면 새 키를 입력합니다.
