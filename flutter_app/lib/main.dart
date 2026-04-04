import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

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
        primaryColor: const Color(0xFFC8541A),
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
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _voiceText = "";

  @override
  void initState() {
    super.initState();
    
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
      rootBundle.loadString('assets/index.html').then((html) {
        controller.loadHtmlString(html);
      });
    } else {
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFFFFFFFF))
        ..loadFlutterAsset('assets/index.html');
    }

    _controller = controller;
  }

  Future<void> _realOCRScan() async {
    // Request camera permission
    var status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      _controller.runJavaScript("openSheet('addItem');");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission granted! Ready to scan (Please enter details manually for now).')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission denied.')),
      );
    }
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
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
        }
      },
      onError: (errorNotification) {
         if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Speech error: $errorNotification')),
         );
      },
    );

    if (!mounted) return;
    if (available) {
      _showVoiceDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available or permission denied.')),
      );
    }
  }

  void _showVoiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('🎙️ Voice Assistant'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_isListening ? 'Listening...' : 'Tap Mic to speak, then Submit'),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      if (!_isListening) {
                        _speech.listen(
                          onResult: (result) {
                            setState(() {
                              _voiceText = result.recognizedWords;
                            });
                          },
                        );
                        setState(() {
                          _isListening = true;
                        });
                      } else {
                        _speech.stop();
                        setState(() {
                          _isListening = false;
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: _isListening ? Colors.red : Colors.blue,
                      child: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(_voiceText.isEmpty ? "No speech detected" : _voiceText, textAlign: TextAlign.center),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _speech.stop();
                    _voiceText = "";
                    _isListening = false;
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _speech.stop();
                    final query = _voiceText;
                    _voiceText = "";
                    _isListening = false;
                    Navigator.of(context).pop();

                    if (query.isNotEmpty) {
                      _controller.runJavaScript('processVoiceTranscription("\${query.replaceAll('"', '\\"')}");');
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
