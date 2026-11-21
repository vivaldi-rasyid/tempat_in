import 'package:flutter/foundation.dart';

import '../core/constants.dart';

class SettingsController extends ChangeNotifier {
  bool _notificationsEnabled = true;
  Duration _warningLeadTime = AppConstants.defaultCheckoutWarningLead;
  bool _simulateCalendarFailure = false;
  bool _simulateOffline = false;

  bool get notificationsEnabled => _notificationsEnabled;
  Duration get warningLeadTime => _warningLeadTime;
  bool get simulateCalendarFailure => _simulateCalendarFailure;
  bool get simulateOffline => _simulateOffline;

  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  void setWarningLeadTime(Duration value) {
    _warningLeadTime = value;
    notifyListeners();
  }

  void setSimulateCalendarFailure(bool value) {
    _simulateCalendarFailure = value;
    notifyListeners();
  }

  void setSimulateOffline(bool value) {
    _simulateOffline = value;
    notifyListeners();
  }
}