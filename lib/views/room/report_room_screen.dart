import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/report_controller.dart';
import '../../controllers/room_controller.dart';
import '../../core/theme.dart';

class ReportRoomScreen extends StatefulWidget {
  final String roomId;

  const ReportRoomScreen({super.key, required this.roomId});

  @override
  State<ReportRoomScreen> createState() => _ReportRoomScreenState();
}

class _ReportRoomScreenState extends State<ReportRoomScreen> {
  final _descController = TextEditingController();
  final _picker = ImagePicker();

  String? _selectedType;
  String? _photoPath;
  bool _confirmedAccurate = false;
  String? _typeError;

  bool get _hasUnsavedInput =>
      _selectedType != null ||
      _descController.text.trim().isNotEmpty ||
      _photoPath != null;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleBack() async {
    if (!_hasUnsavedInput) {
      if (mounted) context.pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Laporan?'),
        content: const Text(
          'Perubahan yang sudah diisi tidak akan dikirim.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Lanjut Isi'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) context.pop();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Ambil Foto dari Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Hapus Foto'),
                onTap: () {
                  setState(() => _photoPath = null);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await _picker.pickImage(source: source, imageQuality: 75);
    if (picked != null && mounted) {
      setState(() => _photoPath = picked.path);
    }
  }

  Future<void> _submit() async {
    final error = ReportController.validateProblemType(_selectedType);
    setState(() => _typeError = error);
    if (error != null) return;

    final userId = context.read<AuthController>().currentUser?.userId ?? 'usr-001';
    final reportCtrl = context.read<ReportController>();
    try {
      await reportCtrl.submitReport(
        roomId: widget.roomId,
        userId: userId,
        type: _selectedType,
        description: _descController.text,
        photoPath: _photoPath,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Berhasil'),
          content: const Text('Laporan berhasil dikirim.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = context.read<RoomController>().getById(widget.roomId);
    final isSubmitting = context.watch<ReportController>().isSubmitting;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar matching P005-report.png
                Row(
                  children: [
                    IconButton(
                      onPressed: _handleBack,
                      icon: const Icon(Icons.chevron_left, size: 28),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const Expanded(
                      child: Text(
                        'Report Room',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _handleBack,
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  "What's Your\nProblem?",
                  style: TextStyle(
                    fontSize: 28,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (room != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${room.name} •${room.building}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                // Problem type dropdown
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  hint: const Text('Pilih jenis masalah'),
                  decoration: InputDecoration(
                    errorText: _typeError,
                    fillColor: AppColors.inputBg,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: ReportController.problemTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedType = val;
                      _typeError = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Multiline description box
                Stack(
                  children: [
                    TextField(
                      controller: _descController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Jelaskan detail kondisi ruangan (opsional)...',
                        fillColor: AppColors.inputBg,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const Positioned(
                      right: 14,
                      bottom: 12,
                      child: Icon(
                        Icons.edit,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Photo evidence picker box
                InkWell(
                  onTap: _pickPhoto,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    height: 190,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _photoPath != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(File(_photoPath!), fit: BoxFit.cover),
                              Positioned(
                                right: 10,
                                top: 10,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  radius: 16,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    onPressed: () =>
                                        setState(() => _photoPath = null),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 36,
                                color: AppColors.primary,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tambahkan foto bukti (opsional)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                // Validation / confirmation checkbox row matching wireframe
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _confirmedAccurate,
                      activeColor: AppColors.primary,
                      onChanged: (v) =>
                          setState(() => _confirmedAccurate = v ?? false),
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          'Saya menyatakan laporan ini sesuai kondisi ruangan saat ini.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isSubmitting ? null : _submit,
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Send Report'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}