import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class KakaoLoginResult {
  KakaoLoginResult({
    required this.isSuccess,
    this.nickname,
    this.errorMessage,
  });

  final bool isSuccess;
  final String? nickname;
  final String? errorMessage;
}

class KakaoLogin {
  Future<KakaoLoginResult> signIn() async {
    try {
      final bool canUseKakaoTalk = await isKakaoTalkInstalled();
      await (canUseKakaoTalk
          ? UserApi.instance.loginWithKakaoTalk()
          : UserApi.instance.loginWithKakaoAccount());

      final user = await UserApi.instance.me();
      final nickname = user.kakaoAccount?.profile?.nickname;

      return KakaoLoginResult(isSuccess: true, nickname: nickname);
    } on KakaoAuthException catch (error) {
      return KakaoLoginResult(
        isSuccess: false,
        errorMessage: error.message ?? '카카오 인증 과정에서 오류가 발생했습니다.',
      );
    } on KakaoClientException catch (error) {
      return KakaoLoginResult(
        isSuccess: false,
        errorMessage: error.message ?? '카카오 서비스에 연결하지 못했습니다.',
      );
    } catch (error) {
      return KakaoLoginResult(
        isSuccess: false,
        errorMessage: '카카오 로그인 중 문제가 발생했습니다. (${error.toString()})',
      );
    }
  }
}
