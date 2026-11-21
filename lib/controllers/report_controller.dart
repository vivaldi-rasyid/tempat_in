import 'package:flutter/foundation.dart';

import '../models/room_report.dart';
import '../repositories/repositories.dart';

class ReportController extends ChangeNotifier {
  static const List<String> problemTypes = [
    'Status tidak sesuai',
    'Kerusakan AC',
    'Lampu mati',
    'Kebersihan',
    'Lainnya',
  ];

  final ReportRepository _repo;
  bool _isSubmitting = false;

  ReportController(this._repo);

  bool get isSubmitting => _isSubmitting;

  /// Pure validation helper so it can be tested independently of the UI.
  static String? validateProblemType(String? type) {
    if (type == null || type.trim().isEmpty) {
      return 'Pilih jenis masalah terlebih dahulu.';
    }
    return null;
  }

  Future<RoomReport> submitReport({
    required String roomId,
    required String userId,
    required String? type,
    required String description,
    String? photoPath,
  }) async {
    final error = validateProblemType(type);
    if (error != null) throw FormatException(error);

    _isSubmitting = true;
    notifyListeners();
    try {
      final report = RoomReport(
        reportId: 'rep-${DateTime.now().millisecondsSinceEpoch}',
        roomId: roomId,
        userId: userId,
        type: type!.trim(),
        description: description.trim(),
        photoPath: photoPath,
        createdAt: DateTime.now(),
      );
      return await _repo.submitReport(report);
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}