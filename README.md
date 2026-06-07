# EXIF Room

> **EXIF 시각화 프로젝트**

<p align="left">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter Badge"/>
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart Badge"/>
  <img src="https://img.shields.io/badge/Platform-Web%20%7C%20Windows-lightgrey?style=for-the-badge" alt="Platform Badge"/>
</p>

### [EXIF Room 바로가기](https://juhyunb05.github.io/EXIF_Room)

---

## 프로젝트 소개

**EXIF Room**은 이용자가 업로드한 사진 속의 **EXIF 메타데이터**(카메라 제조사, 모델, 렌즈 기종, 셔터스피드, 조리개 값, ISO 감도, 촬영 일시 등)를 자동으로 안전하게 분석하고, 이를 세련되고 모던한 분위기의 카드 레이아웃(포스터 프레임)으로 디자인하여 하나의 소장용 이미지로 새롭게 조화시켜주는 플러터 기반 어플리케이션입니다.

---

## 핵심 기능

- **EXIF 메타데이터 자동 파싱**: 사진을 가져오는 즉시 촬영 기기와 노출 값 등의 고급 카메라 데이터를 자동으로 즉석 추출합니다.
- **HEIC 이미지 자동 인코딩 (Web 지원)**: 웹 브라우저에서도 까다로운 고효율 이미지 규격(HEIC/HEIF)을 JPG 형식으로 클라이언트 측에서 즉석 변환하여 렌더링을 가능케 합니다.
- **기기 저장 및 플랫폼 공유**: 생성한 아름다운 포스터 카드를 기기 사진 보관함에 즉시 다운로드하거나, OS 표준 공유 시트(`share_plus`)를 이용해 SNS 및 메신저에 바로 전송합니다.
- **지능형 프로젝트 아카이브**:
  - 생성한 사진 작업물이 손실되지 않도록 전용 로컬 데이터베이스에 보관하여 목록화합니다.
  - **안전한 삭제 관리**: 개별 혹은 일괄 데이터 소멸 시 주소 레코드뿐만 아니라 기기 저장 공간을 좀먹는 이미지 임시 파일들까지 **물리적으로 동시 영구 삭제**하여 기기 찌꺼기 파일을 남기지 않습니다.
- **세련된 디자인**: PRETENDARD 프리미엄 폰트와 통일감 있는 미니멀 다크 디자인 시스템이 기본 적용되어 있습니다.

---

## 기술 스택 및 의존성

- **Core**: Flutter, Dart
- **Database**: [Hive](https://pub.dev/packages/hive) & [Hive Flutter](https://pub.dev/packages/hive_flutter) (빠르고 가벼운 로컬 IndexedDB/NoSQL 저장소)
- **EXIF Parser**: [exif](https://pub.dev/packages/exif) (이미지 헤더 바이너리 구조 해독)
- **Image Processing**: [image](https://pub.dev/packages/image), [image_picker](https://pub.dev/packages/image_picker), [heic_to_png_jpg](https://pub.dev/packages/heic_to_png_jpg)
- **Native OS Integration**: 
  - [path_provider](https://pub.dev/packages/path_provider) & [file_selector](https://pub.dev/packages/file_selector) (파일 관리)
  - [flutter_file_dialog](https://pub.dev/packages/flutter_file_dialog) (네이티브 저장 다이얼로그)
  - [share_plus](https://pub.dev/packages/share_plus) (OS 공유 엔진)
  - [url_launcher](https://pub.dev/packages/url_launcher) (외부 웹브라우징 연동)

---

## 개인정보 및 데이터 보호 원칙

이 앱은 이용자의 프라이버시를 완벽히 존중하며, 다음 정책을 충족합니다:

1. **외부 서버 미사용**: 이용자의 어떠한 사진 정보, EXIF 위치 정보, 개인 식별 데이터도 외부 서버나 제3의 플랫폼으로 **수집, 전송, 업로드하지 않습니다.**
2. **샌드박스 내부 처리**: 모든 연산과 이미지 변환은 브라우저 세션(IndexedDB) 또는 모바일 기기 내부 샌드박스 영역 안에서만 온전히 실행되고 안전하게 로컬 저장됩니다.
3. **완전한 통제권**: 사용자가 앱의 "모든 데이터 지우기" 혹은 특정 이미지를 삭제하는 즉시 기기에서 해당 파일들이 물리적으로 완전히 삭제되어 폐기됩니다.