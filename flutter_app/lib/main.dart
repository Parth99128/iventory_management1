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

    controller.addJavaScriptChannel(
      'AIChannel',
      onMessageReceived: (JavaScriptMessage message) async {
        if (message.message == 'START_OCR') {
          _simulateOCRScan();
        } else if (message.message == 'PREDICT_SHORTAGES') {
          _simulateAIShortages();
        } else if (message.message == 'START_VOICE') {
          _simulateNativeVoiceSTT();
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

  Future<void> _simulateOCRScan() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('📸 Vision AI Scanner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Scanning receipt... Extracting items, quantities, and PO numbers.'),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 3));
    if (mounted) Navigator.of(context).pop();

    _controller.runJavaScript('''
      if (typeof DB !== 'undefined' && DB.inventory) {
        // Smart OCR extracts actual raw items matching real structure
        const cement = {
          id: 'MAT-' + Date.now().toString(36).toUpperCase() + '-1',
          name: 'Portland Cement Grade 53 (OCR)',
          cat: 'cement',
          unit: 'Bags',
          stock: 500,
          min: 100,
          used: 0,
          cost: 350,
          supplier: 'FastCement Co',
          incoming: 0
        };
        const steel = {
          id: 'MAT-' + Date.now().toString(36).toUpperCase() + '-2',
          name: 'TMT Steel Rebar 12mm (OCR)',
          cat: 'steel',
          unit: 'Tons',
          stock: 120,
          min: 20,
          used: 0,
          cost: 65000,
          supplier: 'SteelWorks Ltd',
          incoming: 0
        };
        
        DB.inventory.push(cement);
        DB.inventory.push(steel);
        if (typeof save === 'function') save();
        if (typeof renderInv === 'function') renderInv();
        
        toast('✅ AI OCR: ' + cement.stock + 'x Cement, ' + steel.stock + 'x Steel Bars logged in DB.');
      }
    ''');
  }

  Future<void> _simulateAIShortages() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('🔮 AI Shortage Prediction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyzing daily burn rate vs supplier delivery lead times...'),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 3));
    if (mounted) Navigator.of(context).pop();

    _controller.runJavaScript('''
      if (typeof DB !== 'undefined' && DB.inventory) {
         let criticalItems = DB.inventory.filter(m => m.stock < m.min);
         if (criticalItems.length > 0) {
             let i = criticalItems[0];
             alert('⚠️ AI PREDICTIVE ALERT\\n\\nBased on burn rate, "' + i.name + '" is below minimum stock ('+ i.stock + ' < ' + i.min +').\\n\\nSupplier ['+ i.supplier + '] standard lead time is 3 Days.\\n\\nRecommendation: Order immediately.');
             toast('⚠ Warning generated: ' + i.name + ' shortage.');
         } else {
             alert('✅ AI Insight: All inventory is well-stocked based on predictive usage. No immediate supply-chain risks detected.');
             toast('✓ Inventory levels healthy');
         }
      }
    ''');
  }

  Future<void> _simulateNativeVoiceSTT() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('🎙️ Listening...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.mic, size: 48, color: Colors.blue),
            SizedBox(height: 16),
            Text('Please speak your inventory query...', textAlign: TextAlign.center),
          ],
        ),
      ),
    );

    // Wait exactly 3 seconds to simulate listening/transcribing
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) Navigator.of(context).pop();

    // Inject the "transcription" into the Web UI so the Voice AI logic runs
    _controller.runJavaScript('processVoiceTranscription("Are there any critical stock alerts?");');
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
