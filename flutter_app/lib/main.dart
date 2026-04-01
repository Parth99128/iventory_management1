import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
// Import for Android features.
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import for iOS features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

void main() {
  runApp(const InventoryApp());
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BuildCore Construction OS',
      theme: ThemeData(
        primaryColor: const Color(0xFFC8541A), // Matches --ac from HTML
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC8541A)),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const WebAppScreen(),
    );
  }
}

class WebAppScreen extends StatefulWidget {
  const WebAppScreen({super.key});

  @override
  State<WebAppScreen> createState() => _WebAppScreenState();
}

class _WebAppScreenState extends State<WebAppScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    
    // Configure WebViewController
    late final PlatformWebViewControllerCreationParams params;
    if (kIsWeb) {
      params = const PlatformWebViewControllerCreationParams();
    } else if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    if (kIsWeb) {
      // The web platform does not support setJavaScriptMode or loadFlutterAsset
      // Instead, we load the raw HTML string directly from assets.
      rootBundle.loadString('assets/index.html').then((html) {
        controller.loadHtmlString(html);
      });
    } else {
      // Configuration for real Android/iOS mobile devices
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFFFFFFFF))
        ..loadFlutterAsset('assets/index.html');
    }

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // SafeArea ensures we don't overlap with the system UI
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
