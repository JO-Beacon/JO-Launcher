<div align="center">

  <img src="assets/icon/app-icon-plateless.svg" alt="JO-Launcher" width="100" />
  <h1>JO-Launcher</h1>

  <h2>Minecraft: Java Edition을 위한 Windows 데스크톱 런처입니다. Linux 지원은 계획 중입니다.</h2>

  <p>
    <a href="https://jo-beacon.github.io/JO-Launcher/">공식 사이트</a> ·
    <a href="https://github.com/JO-Beacon/JO-Launcher">GitHub</a> ·
    <a href="https://github.com/JO-Beacon/JO-Launcher/releases/latest">최신 릴리스</a>
  </p>

  <p>
    <a href="README.en.md">English</a> ·
    <a href="README.md">简体中文</a> ·
    <a href="README.zh-TW.md">繁體中文</a> ·
    <a href="README.ja.md">日本語</a> ·
    <b>한국어</b> ·
    <a href="README.de.md">Deutsch</a> ·
    <a href="README.es.md">Español</a> ·
    <a href="README.fr.md">Français</a> ·
    <a href="README.pt-BR.md">Português</a> ·
    <a href="README.sv.md">Svenska</a>
  </p>

</div>

## 요구 사항

- Windows 10 또는 11, 64비트
- 실행할 Minecraft 버전에 맞는 Java 런타임(자동 감지, 버전별 수동 지정 가능)
- Minecraft: Java Edition을 보유한 Microsoft 계정
- 로그인용 자체 Azure 애플리케이션(클라이언트) ID

## 기능

- 설치된 Minecraft 버전 실행
- 버전별 설정: Java 런타임, 메모리 제한, JVM 인수
- 설치된 RAM을 기준으로 메모리 자동 계획, 버전별 재정의 가능
- 버전 폴더 또는 zip 가져오기, 이름 변경, 삭제
- 진단 로그(설정 → 로그)로 문제 해결
- 버전별 게임 디렉터리: 저장, 설정, 모드가 각 버전 폴더에 저장되어 버전 간 격리
- 장치 코드 흐름으로 Microsoft 로그인. 설정 → 계정에서 자체 Azure 애플리케이션(클라이언트) ID를 입력하거나 `JO_MS_CLIENT_ID` / `JOL_MS_CLIENT_ID` 환경 변수 사용
- 10개 UI 언어: English, 简体中文, 繁體中文, 日本語, 한국어, Deutsch, Español, Français, Português, Svenska
- 어두운 테마, 밝은 테마, 시스템 테마 따르기
- 실행 파일 옆의 포터블 `.minecraft` 폴더를 우선 사용하고, 없으면 `%APPDATA%\.minecraft` 사용

## 디렉터리 구조

```text
core/                 platform-independent C++20 core
  auth/               Microsoft / Xbox / Minecraft sign-in
  launch/             version manifests, Java detection, process launch
  mc/                 version scanning and per-version settings
  net/                HTTP transport
  platform/           OS backends: HTTP, key storage, process
platform/win32/       Win32 + Direct2D shell
assets/icon/          icon sources (SVG); the .ico is generated, not tracked
tools/                build helpers and binary checks
third_party/          bundled third-party sources
```

## 빌드(Windows)

Visual Studio 2022 또는 2026의 C++ 워크로드(또는 해당 Build Tools), CMake 3.25+, Pillow가 포함된 Python 3가 필요합니다. 아이콘은 버전 관리에 포함되지 않으므로 빌드 전에 `python tools/export-icons.py`를 실행하세요(헤드리스 Edge 또는 Chrome으로 SVG에서 각 크기를 생성합니다).

선택 사항(실험적): [JO-DraftUI](https://github.com/JO-Beacon/JO-DraftUI)를 저장소와 같은 위치에 체크아웃하고 구성할 때 `-DJO_USE_DRAFTUI=ON`을 넘기면 사용합니다. 기본값은 꺼짐이며 없어도 빌드됩니다. 화면은 아직 직접 작성한 Direct2D 코드로 그립니다.

```powershell
python tools/export-icons.py
cmake -S . -B build/native -A x64
cmake --build build/native --config Release
```

결과:

```text
build/native/Release/JO-Launcher.exe
```

실행 파일은 MSVC 런타임에 정적으로 링크됩니다.

## 상태

현재 구현된 UI는 Win32 셸뿐입니다. Linux의 HTTP, 비밀 저장소, 프로세스 백엔드는 `core/platform/`에 있지만 GTK 셸은 아직 시작하지 않았습니다.

## 라이선스

JO-Launcher는 Apache License 2.0에 따라 라이선스됩니다. 자세한 내용은 [LICENSE](./LICENSE)를 참조하세요.
아이콘(`assets/icon/`, `platform/win32/app.ico`, 사이트 아이콘)은 Apache License 2.0 적용 대상이 아니며 모든 권리가 유보됩니다. 아무것도 수정하지 않아 공식 버전과 동일한 JO-Launcher에는 함께 배포할 수 있지만, fork·이름 변경·버전 번호 변경을 포함해 어떤 변경이라도 있으면 교체해야 합니다. 자세한 내용은 [assets/icon/LICENSE](./assets/icon/LICENSE)를 참조하세요.
재배포 시 [NOTICE](./NOTICE)를 포함하고 그 안에 참조된 제3자 고지를 유지해야 합니다. 개인정보 처리방침: [PRIVACY.md](./PRIVACY.md).

Minecraft 공식 제품이 아닙니다. Mojang 또는 Microsoft의 승인이나 관련이 없습니다. Minecraft, Mojang, Microsoft, Xbox는 Microsoft Corporation 또는 그 계열사의 상표입니다.
