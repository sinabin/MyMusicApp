import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/auth_service.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Google 계정을 통한 YouTube 로그인을 WebView로 처리하는 화면.
///
/// 로그인 성공 시 쿠키를 [AuthService]에 저장하고,
/// 결과를 `Navigator.pop`으로 이전 화면에 전달.
class LoginWebviewScreen extends StatefulWidget {
  const LoginWebviewScreen({super.key});

  @override
  State<LoginWebviewScreen> createState() => _LoginWebviewScreenState();
}

class _LoginWebviewScreenState extends State<LoginWebviewScreen> {
  static const _loginUrl =
      'https://accounts.google.com/ServiceLogin?service=youtube&continue=https://www.youtube.com/';
  static const _youtubeHost = 'youtube.com';
  static const _googleAccountsHost = 'accounts.google.com';

  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) async {
            setState(() => _isLoading = false);

            if (url.contains(_youtubeHost) &&
                !url.contains(_googleAccountsHost)) {
              await _extractCookiesAndFinish();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_loginUrl));
  }

  @override
  void dispose() {
    _controller.setNavigationDelegate(NavigationDelegate());
    super.dispose();
  }

  /// WebView에서 쿠키를 추출하여 [AuthService]에 저장 후 화면 종료.
  Future<void> _extractCookiesAndFinish() async {
    try {
      final authService = context.read<AuthService>();

      final rawResult = await _controller.runJavaScriptReturningResult(
        'document.cookie',
      );

      final cookieString = rawResult.toString();
      if (cookieString.isEmpty) return;

      final cookies = _parseCookies(cookieString);

      if (cookies.isNotEmpty) {
        await authService.saveCookies(cookies);

        final email = await _tryExtractEmail();

        if (mounted) {
          Navigator.pop(context, {'success': true, 'email': email});
        }
      }
    } catch (e) {
      debugPrint('[LoginWebviewScreen] Cookie extraction failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login error: $e')),
        );
      }
    }
  }

  /// 쿠키 문자열을 파싱하여 Map으로 변환.
  Map<String, String> _parseCookies(String raw) {
    final cookies = <String, String>{};
    try {
      final cleaned = raw.replaceAll('"', '');
      for (final cookie in cleaned.split(';')) {
        final parts = cookie.trim().split('=');
        if (parts.length >= 2) {
          cookies[parts[0].trim()] = parts.sublist(1).join('=').trim();
        }
      }
    } catch (e) {
      debugPrint('[LoginWebviewScreen] Cookie parsing failed: $e');
    }
    return cookies;
  }

  /// WebView에서 사용자 이메일 추출 시도. 실패 시 null.
  Future<String?> _tryExtractEmail() async {
    try {
      final emailResult = await _controller.runJavaScriptReturningResult(
        '''
        (function() {
          var el = document.querySelector('[data-email]');
          if (el) return el.getAttribute('data-email');
          return '';
        })()
        ''',
      );
      final emailStr = emailResult.toString().replaceAll('"', '');
      if (emailStr.isNotEmpty && emailStr.contains('@')) {
        return emailStr;
      }
    } catch (e) {
      debugPrint('[LoginWebviewScreen] Email extraction failed: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = AppColorScheme.of(context);
    return Scaffold(
      backgroundColor: cs.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'YouTube Login',
          style: AppTextStyles.sectionHeader,
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: cs.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: SizedBox(
                width: AppSizes.indicatorSm,
                height: AppSizes.indicatorSm,
                child: CircularProgressIndicator(strokeWidth: AppSizes.strokeWidth, color: cs.primary),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            LinearProgressIndicator(
              color: cs.primary,
              backgroundColor: cs.surfaceVariant,
            ),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
