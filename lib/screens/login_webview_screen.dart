import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class LoginWebviewScreen extends StatefulWidget {
  const LoginWebviewScreen({super.key});

  @override
  State<LoginWebviewScreen> createState() => _LoginWebviewScreenState();
}

class _LoginWebviewScreenState extends State<LoginWebviewScreen> {
  late final WebViewController _controller;
  final _authService = AuthService();
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

            // Check if we've landed on YouTube after login
            if (url.contains('youtube.com') && !url.contains('accounts.google.com')) {
              await _extractCookiesAndFinish();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(
        'https://accounts.google.com/ServiceLogin?service=youtube&continue=https://www.youtube.com/',
      ));
  }

  Future<void> _extractCookiesAndFinish() async {
    try {
      // Get cookies via JavaScript
      final cookieString = await _controller.runJavaScriptReturningResult(
        'document.cookie',
      ) as String;

      // Parse cookies
      final cookies = <String, String>{};
      final cleanCookieString = cookieString.replaceAll('"', '');
      for (final cookie in cleanCookieString.split(';')) {
        final parts = cookie.trim().split('=');
        if (parts.length >= 2) {
          cookies[parts[0].trim()] = parts.sublist(1).join('=').trim();
        }
      }

      if (cookies.isNotEmpty) {
        await _authService.saveCookies(cookies);

        // Try to get user email
        String? email;
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
            email = emailStr;
          }
        } catch (_) {}

        if (mounted) {
          Navigator.pop(context, {'success': true, 'email': email});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          'YouTube Login',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            const LinearProgressIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceVariant,
            ),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
