import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class SoundService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.alarm_app/sounds',
  );

  // 오디오 플레이어 인스턴스
  static final AudioPlayer _audioPlayer = AudioPlayer();

  // 현재 재생 중인 소리 경로
  static String? _currentlyPlayingSound;

  // raw 디렉토리의 소리 파일 목록 가져오기
  static Future<List<String>> getRawSoundFiles() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod(
        'getRawSoundFiles',
      );
      return result.map((file) => file.toString()).toList();
    } on PlatformException catch (e) {
      print('플랫폼 채널 오류: $e');
      // 오류 발생 시 기본 소리 목록 반환
      return ['sample_music', 'sample_music2'];
    }
  }

  // 소리 파일 이름을 사용자 친화적인 이름으로 변환
  static String getSoundDisplayName(String soundPath) {
    switch (soundPath) {
      case 'default':
        return '기본 알람';
      case 'none':
        return '소리 없음';
      case 'sample_music':
        return '샘플 음악 1';
      case 'sample_music2':
        return '샘플 음악 2';
      default:
        // 파일 이름에서 확장자 제거하고 언더스코어를 공백으로 변환
        final name = soundPath.replaceAll('_', ' ');
        // 첫 글자를 대문자로 변환
        return name.length > 0
            ? name[0].toUpperCase() + name.substring(1)
            : name;
    }
  }

  // 소리 재생
  static Future<void> playSound(String soundPath) async {
    try {
      // 이미 재생 중인 소리가 있으면 중지
      await stopSound();

      // 현재 재생 중인 소리 경로 설정
      _currentlyPlayingSound = soundPath;
      print('재생 시작: $_currentlyPlayingSound');

      if (soundPath == 'default') {
        // 기본 알람 소리 재생 (시스템 소리)
        // 시스템 기본 알람 소리는 없으므로 첫 번째 raw 소리 파일 사용
        final sounds = await getRawSoundFiles();
        if (sounds.isNotEmpty) {
          // 첫 번째 사운드 파일을 기본값으로 사용
          print('기본 알람 재생 시도: ${sounds[0]}');
          await _audioPlayer.setAsset(
            'android/app/src/main/res/raw/${sounds[0]}',
          );
        }
      } else if (soundPath != 'none') {
        // raw 디렉토리의 소리 파일 재생
        print('재생 시도: $soundPath');
        await _audioPlayer.setAsset('android/app/src/main/res/raw/$soundPath');
      }

      // 재생 완료 리스너 설정
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _currentlyPlayingSound = null;
          print('재생 완료: $soundPath');
        }
      });

      await _audioPlayer.play();
    } catch (e) {
      print('소리 재생 오류: $e');
      // 오류 발생 시 대체 방법 시도
      try {
        if (soundPath != 'none') {
          final fileName = soundPath == 'default' ? 'sample_music' : soundPath;
          print('대체 방법으로 재생 시도: $fileName');

          // 다른 방식으로 시도 - 직접 리소스 ID 사용
          final packageName = await _getPackageName();
          final uri = 'android.resource://$packageName/raw/$fileName';
          print('URI로 재생 시도: $uri');
          await _audioPlayer.setUrl(uri);

          // 재생 완료 리스너 설정
          _audioPlayer.playerStateStream.listen((state) {
            if (state.processingState == ProcessingState.completed) {
              _currentlyPlayingSound = null;
              print('재생 완료 (대체 방법): $soundPath');
            }
          });

          await _audioPlayer.play();
        }
      } catch (e2) {
        print('대체 방법 재생 오류: $e2');
        _currentlyPlayingSound = null;
      }
    }
  }

  // 패키지 이름 가져오기
  static Future<String> _getPackageName() async {
    try {
      final String packageName = await _channel.invokeMethod('getPackageName');
      return packageName;
    } catch (e) {
      print('패키지 이름 가져오기 오류: $e');
      return 'com.example.alarm_app_test';
    }
  }

  // 소리 중지
  static Future<void> stopSound() async {
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
        print('소리 중지: $_currentlyPlayingSound');
      }
      _currentlyPlayingSound = null;
    } catch (e) {
      print('소리 중지 오류: $e');
      _currentlyPlayingSound = null;
    }
  }

  // 현재 재생 중인 소리 경로 반환
  static String? getCurrentlyPlayingSound() {
    return _currentlyPlayingSound;
  }

  // 리소스 해제
  static void dispose() {
    _audioPlayer.dispose();
  }
}
