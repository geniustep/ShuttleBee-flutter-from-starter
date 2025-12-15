import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/loading/shimmer_loading.dart';
import '../../../../shared/widgets/states/empty_state.dart';
import '../../domain/entities/passenger_group_line.dart';
import '../providers/dispatcher_passenger_providers.dart';
import '../providers/dispatcher_partner_providers.dart';
import '../widgets/dispatcher_app_bar.dart';

class DispatcherPassengerDetailScreen extends ConsumerWidget {
  final int passengerId;

  const DispatcherPassengerDetailScreen({
    super.key,
    required this.passengerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync =
        ref.watch(dispatcherPassengerProfileProvider(passengerId));
    final linesAsync = ref.watch(dispatcherPassengerLinesProvider(passengerId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const DispatcherAppBar(title: 'تفاصيل الراكب'),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dispatcherPassengerProfileProvider(passengerId));
          ref.invalidate(dispatcherPassengerLinesProvider(passengerId));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            profileAsync.when(
              data: (p) {
                if (p == null) {
                  return const EmptyState(
                    icon: Icons.person_off_rounded,
                    title: 'الراكب غير موجود',
                    message: 'قد يكون تم حذفه أو لا تملك صلاحية الوصول.',
                  );
                }

                return _HeaderCard(
                  name: p.name,
                  active: p.active,
                  contact: p.shortContact,
                  address: p.addressLine,
                );
              },
              loading: () => const ShimmerCard(height: 110),
              error: (e, _) => _ErrorBox(error: e.toString()),
            ),
            const SizedBox(height: 12),
            profileAsync.when(
              data: (p) {
                if (p == null) return const SizedBox.shrink();

                return _InfoSection(
                  title: 'إعدادات النقل',
                  children: [
                    _kv('اتجاه الرحلات', _directionLabel(p.tripDirection)),
                    _kv('إشعارات تلقائية', p.autoNotification ? 'نعم' : 'لا'),
                    _kv('GPS للصعود', p.useGpsForPickup ? 'نعم' : 'لا'),
                    _kv('GPS للشركة للنزول', p.useGpsForDropoff ? 'نعم' : 'لا'),
                    _kv('Latitude', p.latitude?.toString() ?? '-'),
                    _kv('Longitude', p.longitude?.toString() ?? '-'),
                    _kv(
                        'محطة صعود افتراضية',
                        p.defaultPickupStopName ??
                            (p.defaultPickupStopId?.toString() ?? '-')),
                    _kv(
                        'محطة نزول افتراضية',
                        p.defaultDropoffStopName ??
                            (p.defaultDropoffStopId?.toString() ?? '-')),
                  ],
                );
              },
              loading: () => const ShimmerCard(height: 170),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            profileAsync.when(
              data: (p) {
                if (p == null) return const SizedBox.shrink();
                final note = (p.shuttleNotes ?? '').trim();
                return _InfoSection(
                  title: 'ملاحظات',
                  children: [
                    Text(
                      note.isEmpty ? '—' : note,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const ShimmerCard(height: 120),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            linesAsync.when(
              data: (lines) => _LinesSection(
                passengerId: passengerId,
                lines: lines,
              ),
              loading: () => const ShimmerCard(height: 180),
              error: (e, _) => _ErrorBox(error: e.toString()),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              k,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _directionLabel(String v) {
    switch (v) {
      case 'pickup':
        return 'صعود فقط';
      case 'dropoff':
        return 'نزول فقط';
      default:
        return 'صعود ونزول';
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final String name;
  final bool active;
  final String contact;
  final String address;

  const _HeaderCard({
    required this.name,
    required this.active,
    required this.contact,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.dispatcherGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child:
                const Icon(Icons.person_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        active ? 'نشط' : 'غير نشط',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (contact.isNotEmpty)
                  Text(
                    contact,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                if (address.isNotEmpty)
                  Text(
                    address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _LinesSection extends ConsumerWidget {
  final int passengerId;
  final List<PassengerGroupLine> lines;

  const _LinesSection({
    required this.passengerId,
    required this.lines,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assigned = lines.where((l) => l.groupId != null).toList();
    final unassigned = lines.where((l) => l.groupId == null).toList();

    if (lines.isEmpty) {
      return const EmptyState(
        icon: Icons.groups_rounded,
        title: 'لا توجد بيانات مجموعات',
        message: 'لم يتم العثور على سجل ربط لهذا الراكب.',
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'المجموعات',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            if (assigned.isEmpty)
              const Text(
                'غير مدرج في أي مجموعة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.textSecondary,
                ),
              ),
            ...assigned.map((l) => _lineTile(context, ref, l)),
            if (unassigned.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'سجل غير مدرجين',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...unassigned.map((l) => _lineTile(context, ref, l)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _lineTile(BuildContext context, WidgetRef ref, PassengerGroupLine l) {
    final subtitleParts = <String>[];
    final pickup = l.pickupInfoDisplay?.trim();
    final dropoff = l.dropoffInfoDisplay?.trim();
    if (pickup != null && pickup.isNotEmpty) subtitleParts.add('صعود: $pickup');
    if (dropoff != null && dropoff.isNotEmpty)
      subtitleParts.add('نزول: $dropoff');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.dispatcherPrimary.withValues(alpha: 0.12),
        foregroundColor: AppColors.dispatcherPrimary,
        child: const Icon(Icons.groups_rounded),
      ),
      title: Text(
        l.groupName ?? 'غير مدرجين',
        style:
            const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        'مقاعد: ${l.seatCount}${subtitleParts.isEmpty ? '' : '\n${subtitleParts.join('\n')}'}',
        style: const TextStyle(
          fontFamily: 'Cairo',
          color: AppColors.textSecondary,
          height: 1.3,
        ),
      ),
      isThreeLine: subtitleParts.isNotEmpty,
      trailing: PopupMenuButton<String>(
        tooltip: 'إجراءات',
        onSelected: (v) async {
          switch (v) {
            case 'unassign':
              if (l.groupId == null) return;
              HapticFeedback.lightImpact();
              await ref
                  .read(dispatcherPassengerActionsProvider.notifier)
                  .unassignFromGroup(
                    lineId: l.id,
                    groupId: l.groupId!,
                  );
              break;
          }
        },
        itemBuilder: (ctx) => [
          PopupMenuItem(
            value: 'unassign',
            enabled: l.groupId != null,
            child: const Row(
              children: [
                Icon(Icons.person_remove_alt_1_rounded, color: AppColors.error),
                SizedBox(width: 10),
                Text(
                  'إزالة من المجموعة',
                  style: TextStyle(fontFamily: 'Cairo', color: AppColors.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String error;

  const _ErrorBox({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style:
                  const TextStyle(fontFamily: 'Cairo', color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
