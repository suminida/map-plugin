/// 데이터 버전을 관리하는 클래스
/// 버전 형식: v.YYYY.NNNNNN (예: v.2025.000001)
class VersionManager {
  /// 새로운 버전 생성
  ///
  /// [currentVersion] - 현재 버전 (null이면 새로 생성)
  ///
  /// 반환값: 새로운 버전 문자열
  String generateVersion([String? currentVersion]) {
    final now = DateTime.now();
    final currentYear = now.year;

    // 현재 버전이 없으면 새로 생성
    if (currentVersion == null || currentVersion.isEmpty) {
      return 'v.$currentYear.000001';
    }

    // 현재 버전 파싱
    final parts = currentVersion.split('.');
    if (parts.length != 3 || parts[0] != 'v') {
      throw FormatException('Invalid version format: $currentVersion');
    }

    final year = int.tryParse(parts[1]);
    final sequence = int.tryParse(parts[2]);

    if (year == null || sequence == null) {
      throw FormatException('Invalid version format: $currentVersion');
    }

    // 년도가 변경되었으면 시퀀스 초기화
    if (year != currentYear) {
      return 'v.$currentYear.000001';
    }

    // 같은 년도면 시퀀스 증가
    final newSequence = sequence + 1;
    final paddedSequence = newSequence.toString().padLeft(6, '0');

    return 'v.$currentYear.$paddedSequence';
  }

  /// 버전 문자열이 유효한지 검증
  bool isValidVersion(String version) {
    final parts = version.split('.');
    if (parts.length != 3 || parts[0] != 'v') {
      return false;
    }

    final year = int.tryParse(parts[1]);
    final sequence = int.tryParse(parts[2]);

    if (year == null || sequence == null) {
      return false;
    }

    if (year < 2000 || year > 9999) {
      return false;
    }

    if (sequence < 1 || sequence > 999999) {
      return false;
    }

    return true;
  }

  /// 버전 비교 (v1 > v2 이면 1, v1 == v2 이면 0, v1 < v2 이면 -1)
  int compareVersions(String v1, String v2) {
    if (!isValidVersion(v1) || !isValidVersion(v2)) {
      throw FormatException('Invalid version format');
    }

    final parts1 = v1.split('.');
    final parts2 = v2.split('.');

    final year1 = int.parse(parts1[1]);
    final year2 = int.parse(parts2[1]);

    if (year1 != year2) {
      return year1.compareTo(year2);
    }

    final seq1 = int.parse(parts1[2]);
    final seq2 = int.parse(parts2[2]);

    return seq1.compareTo(seq2);
  }

  /// 버전에서 년도 추출
  int getYear(String version) {
    if (!isValidVersion(version)) {
      throw FormatException('Invalid version format: $version');
    }

    final parts = version.split('.');
    return int.parse(parts[1]);
  }

  /// 버전에서 시퀀스 번호 추출
  int getSequence(String version) {
    if (!isValidVersion(version)) {
      throw FormatException('Invalid version format: $version');
    }

    final parts = version.split('.');
    return int.parse(parts[2]);
  }
}