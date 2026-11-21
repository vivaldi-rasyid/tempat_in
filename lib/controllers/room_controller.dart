import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/room.dart';
import '../repositories/mock/mock_data.dart';
import '../repositories/repositories.dart';

class RoomSearchFilter {
  final String query;
  final String? building;
  final int? floor;
  final int minCapacity;
  final Set<String> facilities;

  const RoomSearchFilter({
    this.query = '',
    this.building,
    this.floor,
    this.minCapacity = 0,
    this.facilities = const {},
  });

  bool get isEmpty =>
      query.trim().isEmpty &&
      building == null &&
      floor == null &&
      minCapacity == 0 &&
      facilities.isEmpty;

  RoomSearchFilter copyWith({
    String? query,
    String? Function()? building,
    int? Function()? floor,
    int? minCapacity,
    Set<String>? facilities,
  }) {
    return RoomSearchFilter(
      query: query ?? this.query,
      building: building != null ? building() : this.building,
      floor: floor != null ? floor() : this.floor,
      minCapacity: minCapacity ?? this.minCapacity,
      facilities: facilities ?? this.facilities,
    );
  }
}

class RoomController extends ChangeNotifier {
  final RoomRepository _repo;
  StreamSubscription<List<Room>>? _sub;

  List<Room> _rooms = [];
  RoomCategory _selectedCategory = RoomCategory.classroom;
  final Set<String> _bookmarkedIds = {'rm-01', 'rm-03'};
  final List<String> _searchHistory = List.of(MockData.initialSearchHistory);

  // Tracks which user manually marked a room occupied ("Saya Masuk").
  final Map<String, String> _manualOccupantByRoom = {};
  // Tracks recent status flips per room for rapid-flip anomaly detection.
  final Map<String, List<DateTime>> _flipTimestamps = {};

  RoomSearchFilter _filter = const RoomSearchFilter();
  List<Room> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchTimer;

  RoomController(this._repo) {
    _init();
  }

  List<Room> get rooms => List.unmodifiable(_rooms);
  RoomCategory get selectedCategory => _selectedCategory;
  Set<String> get bookmarkedIds => Set.unmodifiable(_bookmarkedIds);
  List<String> get searchHistory => List.unmodifiable(_searchHistory);
  RoomSearchFilter get filter => _filter;
  List<Room> get searchResults => List.unmodifiable(_searchResults);
  bool get isSearching => _isSearching;

  List<String> get availableBuildings =>
      _rooms.map((r) => r.building).toSet().toList()..sort();

  List<int> get availableFloors {
    final source = _filter.building == null
        ? _rooms
        : _rooms.where((r) => r.building == _filter.building);
    return source.map((r) => r.floor).toSet().toList()..sort();
  }

  Future<void> _init() async {
    _rooms = await _repo.getRooms();
    _searchResults = applySearchFilter(_rooms, _filter);
    notifyListeners();
    _sub = _repo.watchRooms().listen((updated) {
      _rooms = updated;
      if (!_isSearching) {
        _searchResults = applySearchFilter(_rooms, _filter);
      }
      notifyListeners();
    });
  }

  Room? getById(String roomId) {
    for (final r in _rooms) {
      if (r.roomId == roomId) return r;
    }
    return null;
  }

  void selectCategory(RoomCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void toggleBookmark(String roomId) {
    if (!_bookmarkedIds.remove(roomId)) {
      _bookmarkedIds.add(roomId);
    }
    notifyListeners();
  }

  bool isBookmarked(String roomId) => _bookmarkedIds.contains(roomId);

  List<Room> get availableNow =>
      _rooms.where((r) => r.status == RoomStatus.available).toList();

  List<Room> get recommendedRooms {
    final byCategory =
        _rooms.where((r) => r.category == _selectedCategory).toList();
    final terms = _searchHistory.map((e) => e.toLowerCase()).toList();
    byCategory.sort((a, b) => _score(b, terms).compareTo(_score(a, terms)));
    return byCategory;
  }

  int _score(Room room, List<String> terms) {
    var score = room.status == RoomStatus.available ? 10 : 0;
    if (_bookmarkedIds.contains(room.roomId)) score += 4;
    for (final t in terms) {
      if (room.building.toLowerCase().contains(t)) score += 5;
      if (room.name.toLowerCase().contains(t)) score += 5;
      if (room.facilities.any((f) => f.toLowerCase().contains(t))) score += 3;
    }
    return score;
  }

  /// Pure filter function: matches ALL active criteria AND requires Available.
  static List<Room> applySearchFilter(
    List<Room> source,
    RoomSearchFilter filter,
  ) {
    final q = filter.query.trim().toLowerCase();
    return source.where((room) {
      if (room.status != RoomStatus.available) return false;
      if (q.isNotEmpty) {
        final haystack =
            '${room.name} ${room.building} ${room.facilities.join(' ')} ${room.description}'
                .toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      if (filter.building != null && room.building != filter.building) {
        return false;
      }
      if (filter.floor != null && room.floor != filter.floor) return false;
      if (room.capacity < filter.minCapacity) return false;
      if (filter.facilities.isNotEmpty) {
        final roomFacs = room.facilities.map(_normFacility).toSet();
        for (final req in filter.facilities) {
          if (!roomFacs.contains(_normFacility(req))) return false;
        }
      }
      return true;
    }).toList(growable: false);
  }

  static String _normFacility(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  void updateSearchFilter(
    RoomSearchFilter next, {
    bool saveQueryToHistory = false,
    Duration delay = const Duration(milliseconds: 350),
  }) {
    _filter = next;
    final trimmed = next.query.trim();
    if (saveQueryToHistory && trimmed.isNotEmpty) {
      _searchHistory.removeWhere(
        (e) => e.toLowerCase() == trimmed.toLowerCase(),
      );
      _searchHistory.insert(0, trimmed);
      if (_searchHistory.length > 8) _searchHistory.removeLast();
    }

    _searchTimer?.cancel();
    if (delay == Duration.zero) {
      _isSearching = false;
      _searchResults = applySearchFilter(_rooms, _filter);
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();
    _searchTimer = Timer(delay, () {
      _isSearching = false;
      _searchResults = applySearchFilter(_rooms, _filter);
      notifyListeners();
    });
  }

  void removeSearchHistory(String term) {
    _searchHistory.remove(term);
    notifyListeners();
  }

  void resetSearchFilters() {
    updateSearchFilter(const RoomSearchFilter(), delay: Duration.zero);
  }

  // --- Crowdsourcing & Status Actions ---

  String? manualOccupantOf(String roomId) => _manualOccupantByRoom[roomId];

  bool isOccupiedByCurrentUser(String roomId, String userId) =>
      _manualOccupantByRoom[roomId] == userId;

  bool hasRapidStatusFlips(String roomId) {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 5));
    final list = _flipTimestamps[roomId] ?? const [];
    return list.where((t) => t.isAfter(cutoff)).length >= 4;
  }

  void _recordFlip(String roomId) {
    final list = _flipTimestamps.putIfAbsent(roomId, () => []);
    list.add(DateTime.now());
    if (list.length > 10) list.removeAt(0);
  }

  Future<Room> markOccupiedManual(String roomId, String userId) async {
    _manualOccupantByRoom[roomId] = userId;
    _recordFlip(roomId);
    final updated = await _repo.updateRoomStatus(
      roomId,
      RoomStatus.occupied,
      RoomUpdateSource.manual,
    );
    _syncLocal(updated);
    return updated;
  }

  Future<Room> confirmOccupied(String roomId) async {
    final updated = await _repo.updateRoomStatus(
      roomId,
      RoomStatus.occupied,
      RoomUpdateSource.manual,
    );
    _syncLocal(updated);
    return updated;
  }

  Future<Room> markAvailableManual(String roomId) async {
    _manualOccupantByRoom.remove(roomId);
    _recordFlip(roomId);
    final updated = await _repo.updateRoomStatus(
      roomId,
      RoomStatus.available,
      RoomUpdateSource.manual,
    );
    _syncLocal(updated);
    return updated;
  }

  Future<Room> setStatusFromCheckIn(
    String roomId,
    RoomStatus status, {
    String? occupantUserId,
  }) async {
    if (status == RoomStatus.occupied && occupantUserId != null) {
      _manualOccupantByRoom[roomId] = occupantUserId;
    } else if (status == RoomStatus.available) {
      _manualOccupantByRoom.remove(roomId);
    }
    _recordFlip(roomId);
    final updated = await _repo.updateRoomStatus(
      roomId,
      status,
      RoomUpdateSource.checkIn,
    );
    _syncLocal(updated);
    return updated;
  }

  void _syncLocal(Room updated) {
    final idx = _rooms.indexWhere((r) => r.roomId == updated.roomId);
    if (idx != -1) {
      _rooms = List.of(_rooms)..[idx] = updated;
      _searchResults = applySearchFilter(_rooms, _filter);
      notifyListeners();
    }
  }

  /// Deterministic mock historical-usage prediction per room.
  String predictedAvailability(Room room) {
    final hash = room.roomId.codeUnits.fold<int>(0, (a, b) => a + b);
    if (room.status == RoomStatus.available) {
      final busyStart = 10 + (hash % 4);
      return 'Usually busy ${busyStart.toString().padLeft(2, '0')}:00–${(busyStart + 2).toString().padLeft(2, '0')}:00';
    }
    final freeHour = (DateTime.now().hour + 1 + (hash % 2)).clamp(8, 20);
    return 'Likely free at ${freeHour.toString().padLeft(2, '0')}:00';
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}