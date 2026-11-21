import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/room_controller.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../widgets/common_widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _facilityOptions = [
    'Projector',
    'AC',
    'Whiteboard',
    'Wi-Fi',
    'Power Outlets',
  ];

  final _searchCtrl = TextEditingController();
  bool _showFilters = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = context.read<RoomController>().filter.query;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyQuery(String value, {bool saveHistory = false}) {
    final ctrl = context.read<RoomController>();
    ctrl.updateSearchFilter(
      ctrl.filter.copyWith(query: value),
      saveQueryToHistory: saveHistory,
    );
  }

  void _toggleFacility(String facility) {
    final ctrl = context.read<RoomController>();
    final next = Set<String>.from(ctrl.filter.facilities);
    if (!next.remove(facility)) next.add(facility);
    ctrl.updateSearchFilter(ctrl.filter.copyWith(facilities: next));
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<RoomController>();
    final filter = ctrl.filter;
    final results = ctrl.searchResults;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // Search bar + filter toggle + QR scan matching P001-search.png
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onChanged: (v) => _applyQuery(v),
                    onSubmitted: (v) => _applyQuery(v, saveHistory: true),
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                _applyQuery('');
                              },
                            )
                          : IconButton(
                              icon: const Icon(Icons.qr_code_scanner, size: 20),
                              tooltip: 'Scan Room QR',
                              onPressed: () => context.push(AppRoutes.qrScan),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () => setState(() => _showFilters = !_showFilters),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _showFilters
                          ? AppColors.primary
                          : AppColors.inputBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.tune,
                      color: _showFilters
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Last Search
            if (ctrl.searchHistory.isNotEmpty) ...[
              const Text(
                'Last Search',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...ctrl.searchHistory.take(4).map(
                    (term) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => ctrl.removeSearchHistory(term),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              _searchCtrl.text = term;
                              _applyQuery(term, saveHistory: true);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.inputBg,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                term,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 14),
            ],

            // Filter section
            if (_showFilters) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  if (!filter.isEmpty)
                    TextButton(
                      onPressed: () {
                        _searchCtrl.clear();
                        ctrl.resetSearchFilters();
                      },
                      child: const Text(
                        'Reset',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Building chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ctrl.availableBuildings.map((b) {
                  final active = filter.building == b;
                  return FilterTag(
                    label: b.replaceFirst('Gedung ', ''),
                    selected: active,
                    onTap: () => ctrl.updateSearchFilter(
                      filter.copyWith(
                        building: () => active ? null : b,
                        floor: () => null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              // Floor chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ctrl.availableFloors.map((fl) {
                    final active = filter.floor == fl;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterTag(
                        label: 'Lt. $fl',
                        selected: active,
                        onTap: () => ctrl.updateSearchFilter(
                          filter.copyWith(floor: () => active ? null : fl),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              // Facility chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _facilityOptions.map((fac) {
                  return FilterTag(
                    label: fac,
                    selected: filter.facilities.contains(fac),
                    onTap: () => _toggleFacility(fac),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              // Minimum capacity slider
              Row(
                children: [
                  Text(
                    'Min. Capacity: ${filter.minCapacity}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: filter.minCapacity.toDouble(),
                      min: 0,
                      max: 60,
                      divisions: 12,
                      activeColor: AppColors.primary,
                      onChanged: (v) => ctrl.updateSearchFilter(
                        filter.copyWith(minCapacity: v.round()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Room Related results
            const Text(
              'Room Related',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (ctrl.isSearching)
              ...List.generate(3, (_) => const _SkeletonRoomCard())
            else if (results.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.search_off_rounded,
                      size: 44,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Pencarian tidak menemukan hasil. Mohon ubah kriteria.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: () {
                        _searchCtrl.clear();
                        ctrl.resetSearchFilters();
                      },
                      child: const Text('Reset Filter'),
                    ),
                  ],
                ),
              )
            else
              ...results.map(
                (room) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RoomCard(
                    room: room,
                    compact: true,
                    onTap: () =>
                        context.push(AppRoutes.roomDetailPath(room.roomId)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonRoomCard extends StatelessWidget {
  const _SkeletonRoomCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 110, color: AppColors.inputBg),
                const SizedBox(height: 8),
                Container(height: 10, width: 160, color: AppColors.inputBg),
                const SizedBox(height: 12),
                Container(height: 18, width: 70, color: AppColors.inputBg),
              ],
            ),
          ),
        ],
      ),
    );
  }
}