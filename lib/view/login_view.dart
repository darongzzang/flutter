import 'package:flutter/material.dart';

import '../viewmodel/login_view_model.dart';
import '../widgets/image_login_button.dart';
import 'ble_scan_view.dart';
import 'login_failure_view.dart';

const String _kakaoButtonAsset = 'assets/images/kakao_login_button.png';
const String _googleButtonAsset = 'assets/images/google_logo.png';
const double _loginButtonHeight = 52;
const double _kakaoButtonAspectRatio = 300 / 45;
const double _kakaoButtonWidth = _loginButtonHeight * _kakaoButtonAspectRatio;

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final LoginViewModel _viewModel;

  /// 상태 초기화
  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel();
    _viewModel.addListener(_handleViewModelChanged);
  }

  /// 위젯 정리
  @override
  void dispose() {
    _viewModel.removeListener(_handleViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  ///viewModel 상태 바뀔 때마다 UI 갱신
  void _handleViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleGoogleLogin() async {
    final didSucceed = await _viewModel.signInWithGoogle();
    if (!mounted) return;
    _goToResultPage(didSucceed);
  }

  Future<void> _handleKakaoLogin() async {
    final result = await _viewModel.signInWithKakao();
    if (!mounted) return;
    if (result.isSuccess) {
      _goToResultPage(true);
    } else {
      final message =
          result.errorMessage ?? '카카오 로그인에 실패했어요. 잠시 후 다시 시도해 주세요.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      _goToResultPage(false);
    }
  }

  void _goToResultPage(bool isSuccess) {
    final Widget destination =
        isSuccess ? const BleScanView() : const LoginFailureView();

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('간편 로그인'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                '로그인 방법을 선택해 주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 32),
              ImageLoginButton(
                assetPath: _googleButtonAsset,
                width: _kakaoButtonWidth,
                height: _loginButtonHeight,
                fallbackLabel: 'Google 로그인',
                fallbackBackgroundColor: Colors.white,
                fallbackTextColor: Colors.black87,
                progressColor: const Color(0xFF4285F4),
                isLoading: _viewModel.isGoogleSigningIn,
                onTap: _handleGoogleLogin,
              ),
              const SizedBox(height: 16),
              ImageLoginButton(
                assetPath: _kakaoButtonAsset,
                width: _kakaoButtonWidth,
                height: _loginButtonHeight,
                fallbackLabel: '카카오로 시작하기',
                fallbackBackgroundColor: const Color(0xFFFEE500),
                fallbackTextColor: Colors.black87,
                progressColor: Colors.black87,
                isLoading: _viewModel.isKakaoSigningIn,
                onTap: _handleKakaoLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
