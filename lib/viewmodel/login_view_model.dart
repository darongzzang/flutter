import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

import '../kakao_login.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel({
    GoogleSignIn? googleSignIn,
    KakaoLogin? kakaoLogin,
  })  : _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']),
        _kakaoLogin = kakaoLogin ?? KakaoLogin();

  final GoogleSignIn _googleSignIn;
  final KakaoLogin _kakaoLogin;

  bool _isGoogleSigningIn = false;
  bool _isKakaoSigningIn = false;

  bool get isGoogleSigningIn => _isGoogleSigningIn;
  bool get isKakaoSigningIn => _isKakaoSigningIn;

  Future<bool> signInWithGoogle() async {
    if (_isGoogleSigningIn) return false;
    _isGoogleSigningIn = true;
    notifyListeners();

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (error) {
      debugPrint('FirebaseAuthException: ${error.message}');
      return false;
    } catch (error) {
      debugPrint('Google sign-in error: $error');
      return false;
    } finally {
      _isGoogleSigningIn = false;
      notifyListeners();
    }
  }

  Future<KakaoLoginResult> signInWithKakao() async {
    if (_isKakaoSigningIn) {
      return KakaoLoginResult(
        isSuccess: false,
        errorMessage: '카카오 로그인이 이미 진행 중입니다.',
      );
    }
    _isKakaoSigningIn = true;
    notifyListeners();

    try {
      return await _kakaoLogin.signIn();
    } finally {
      _isKakaoSigningIn = false;
      notifyListeners();
    }
  }
}
