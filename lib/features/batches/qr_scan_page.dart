import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'batch_detail_page.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Batch QR')),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) async {
          if (_isProcessing) return;
          final rawValue = capture.barcodes.first.rawValue;
          if (rawValue == null || rawValue.isEmpty) {
            return;
          }

          final batchId = _parseBatchId(rawValue);
          if (batchId == null) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid batch QR')),
            );
            return;
          }

          _isProcessing = true;
          await _controller.stop();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BatchDetailPage(batchId: batchId),
            ),
          );
        },
      ),
    );
  }

  String? _parseBatchId(String rawValue) {
    final uri = Uri.tryParse(rawValue);
    if (uri != null && uri.scheme == 'true_root' && uri.host == 'batch') {
      if (uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last;
      }
    }

    final matches = RegExp(r'(\\d+)').allMatches(rawValue).toList();
    if (matches.isNotEmpty) {
      return matches.last.group(1);
    }

    return null;
  }
}
