import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
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

    controller.addJavaScriptChannel(
      'AIChannel',
      onMessageReceived: (JavaScriptMessage message) async {
        if (message.message == 'START_OCR') {
          _realOCRScan();
        } else if (message.message == 'PREDICT_SHORTAGES') {
          _realAIShortages();
        } else if (message.message == 'START_VOICE') {
          _realVoiceSTT();
        }
      },
    );

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

  Future<void> _realOCRScan() async {
    // Instead of injecting dummy OCR data, redirect the user to the manual entry form
    _controller.runJavaScript("openSheet('addItem');");
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OCR requires Native camera setup. Please enter details manually for live data.')),
    );
  }

  Future<void> _realAIShortages() async {
    _controller.runJavaScript('''
      if (typeof DB !== 'undefined' && DB.inventory) {
         let criticalItems = DB.inventory.filter(m => m.stock < m.min);
         if (criticalItems.length > 0) {
             let msg = '⚠️ CRITICAL ALERTS\\n\\nThe following items are below minimum stock:\\n';
             criticalItems.forEach(i => {
                msg += `- \${i.name}: \${i.stock} (Min: \${i.min})\\n`;
             });
             alert(msg);
             toast('⚠ Warning: Shortages detected.');
         } else {
             alert('✅ All inventory levels are healthy based on live data.');
             toast('✓ Inventory levels healthy');
         }
      }
    ''');
  }

  Future<void> _realVoiceSTT() async {
    final TextEditingController textController = TextEditingController();
    final String? query = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🎙️ Voice Assistant (Text Input)'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Type your inventory query...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(textController.text),
            child: const Text('Submit Search'),
          ),
        ],
      ),
    );

    if (query != null && query.isNotEmpty) {
      // Pass the user's live query to the JS engine
      _controller.runJavaScript('processVoiceTranscription("${query.replaceAll('"', '\\"')}");');
    }
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
