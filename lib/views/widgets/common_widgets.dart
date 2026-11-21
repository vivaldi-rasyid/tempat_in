import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/room.dart';

class StatusBadge extends StatelessWidget {
  final RoomStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      RoomStatus.available => AppColors.statusAvailable,
      RoomStatus.occupied => AppColors.statusOccupied,
      RoomStatus.reserved => AppColors.statusReserved,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class FacilityChip extends StatelessWidget {
  final String label;

  const FacilityChip({super.key, required this.label});

  IconData _iconFor(String facility) {
    final f = facility.toLowerCase();
    if (f.contains('wi-fi') || f.contains('wifi')) return Icons.wifi;
    if (f.contains('ac')) return Icons.ac_unit;
    if (f.contains('projector') || f.contains('tv')) return Icons.tv;
    if (f.contains('power')) return Icons.power;
    if (f.contains('whiteboard')) return Icons.dashboard_outlined;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(label), size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class FilterTag extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterTag({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFBDBDBD),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class RoomCard extends StatelessWidget {
  final Room room;
  final bool isBookmarked;
  final VoidCallback? onToggleBookmark;
  final VoidCallback onTap;
  final bool compact;

  const RoomCard({
    super.key,
    required this.room,
    required this.onTap,
    this.isBookmarked = false,
    this.onToggleBookmark,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return compact ? _buildHorizontalListCard() : _buildCarouselCard();
  }

  Widget _buildCarouselCard() {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _RoomImage(url: room.imageUrls.first, height: 148, width: 240),
                if (onToggleBookmark != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: InkWell(
                      onTap: onToggleBookmark,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isBookmarked ? Icons.flag : Icons.outlined_flag,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${room.building} • Lt. ${room.floor}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      StatusBadge(status: room.status),
                      const SizedBox(width: 8),
                      Text(
                        '${room.capacity} seats',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      _RedArrowButton(onTap: onTap),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalListCard() {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _RoomImage(
                url: room.imageUrls.first,
                height: 76,
                width: 76,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${room.building} • Lt. ${room.floor}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StatusBadge(status: room.status),
                      const SizedBox(width: 8),
                      Text(
                        '${room.capacity} seats',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _RedArrowButton(onTap: onTap),
          ],
        ),
      ),
    );
  }
}

class _RoomImage extends StatelessWidget {
  final String url;
  final double height;
  final double width;

  const _RoomImage({
    required this.url,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      height: height,
      width: width,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        width: width,
        color: AppColors.inputBg,
        alignment: Alignment.center,
        child: const Icon(Icons.meeting_room, color: AppColors.textSecondary),
      ),
    );
  }
}

class _RedArrowButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RedArrowButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
      ),
    );
  }
}