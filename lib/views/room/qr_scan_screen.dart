import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../controllers/room_controller.dart';
import '../../core/constants.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final code = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (code == null || code.isEmpty) return;
    final room = context.read<RoomController>().getById(code);
    if (room == null) return;
    _handled = true;
    context.pushReplacement(AppRoutes.roomDetailPath(room.roomId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Room QR')),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  // shortcut: mock scan button for emulators without a camera; remove in production.
                  onPressed: () =>
                      context.pushReplacement(AppRoutes.roomDetailPath('rm-01')),
                  child: const Text('Simulate Scan (TULT-0701)'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}