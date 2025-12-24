import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/enums/enums.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../models/trips_filter_model.dart';
import '../../providers/trips_filter_provider.dart';

/// نافذة الفلتر المتقدم للرحلات
class TripsAdvancedFilterSheet extends ConsumerStatefulWidget {
  const TripsAdvancedFilterSheet({super.key});

  @override
  ConsumerState<TripsAdvancedFilterSheet> createState() =>
      _TripsAdvancedFilterSheetState();
}

class _TripsAdvancedFilterSheetState
    extends ConsumerState<TripsAdvancedFilterSheet> {
  late Set<TripState> _selectedStates;
  late Set<TripType> _selectedTypes;
  late bool _onlyWithDriver;
  late bool _onlyWithVehicle;
  late bool _onlyWithGps;
  late bool _onlyWithCompanion;
  late TripsSortOption _sortBy;

  @override
  void initState() {
    super.initState();
    final currentState = ref.read(tripsFilterProvider);
    _selectedStates = Set.from(currentState.tripStates);
    _selectedTypes = Set.from(currentState.tripTypes);
    _onlyWithDriver = currentState.onlyWithDriver;
    _onlyWithVehicle = currentState.onlyWithVehicle;
    _onlyWithGps = currentState.onlyWithGps;
    _onlyWithCompanion = currentState.onlyWithCompanion;
    _sortBy = currentState.sortBy;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.dispatcherPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: AppColors.dispatcherPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.advancedFilters,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _resetFilters,
                      child: Text(
                        l10n.reset,
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // فلتر حالة الرحلة
                    _buildSectionTitle(l10n.tripStatus, Icons.info_rounded),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: TripState.values.map((state) {
                        final isSelected = _selectedStates.contains(state);
                        return FilterChip(
                          label: Text(
                            state.getLocalizedLabel(context),
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedStates.add(state);
                              } else {
                                _selectedStates.remove(state);
                              }
                            });
                          },
                          backgroundColor: state.color.withValues(alpha: 0.1),
                          selectedColor: state.color.withValues(alpha: 0.2),
                          checkmarkColor: state.color,
                          labelStyle: TextStyle(
                            color: state.color,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // فلتر نوع الرحلة
                    _buildSectionTitle(l10n.tripType, Icons.directions_bus_rounded),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: TripType.values.map((type) {
                        final isSelected = _selectedTypes.contains(type);
                        final color = type == TripType.pickup
                            ? AppColors.primary
                            : AppColors.success;
                        return FilterChip(
                          label: Text(
                            type.getLabel('ar'),
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTypes.add(type);
                              } else {
                                _selectedTypes.remove(type);
                              }
                            });
                          },
                          backgroundColor: color.withValues(alpha: 0.1),
                          selectedColor: color.withValues(alpha: 0.2),
                          checkmarkColor: color,
                          labelStyle: TextStyle(
                            color: color,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // الخيارات الإضافية
                    _buildSectionTitle(l10n.options, Icons.settings_rounded),
                    const SizedBox(height: 8),
                    _buildSwitchTile(
                      l10n.onlyWithDriver,
                      Icons.person_rounded,
                      _onlyWithDriver,
                      (value) => setState(() => _onlyWithDriver = value),
                    ),
                    _buildSwitchTile(
                      l10n.onlyWithVehicle,
                      Icons.directions_bus_rounded,
                      _onlyWithVehicle,
                      (value) => setState(() => _onlyWithVehicle = value),
                    ),
                    _buildSwitchTile(
                      l10n.onlyWithGps,
                      Icons.gps_fixed_rounded,
                      _onlyWithGps,
                      (value) => setState(() => _onlyWithGps = value),
                    ),
                    _buildSwitchTile(
                      'مع مرافق فقط',
                      Icons.person_add_alt_rounded,
                      _onlyWithCompanion,
                      (value) => setState(() => _onlyWithCompanion = value),
                    ),

                    const SizedBox(height: 24),

                    // خيارات الترتيب
                    _buildSectionTitle('الترتيب', Icons.sort_rounded),
                    const SizedBox(height: 12),
                    ..._buildSortOptions(context),

                    const SizedBox(height: 80), // مساحة للأزرار
                  ],
                ),
              ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            l10n.cancel,
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.dispatcherPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            l10n.apply,
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.dispatcherPrimary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
            ),
          ),
        ],
      ),
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.dispatcherPrimary,
    );
  }

  List<Widget> _buildSortOptions(BuildContext context) {
    final options = [
      (TripsSortOption.defaultOrder, 'الترتيب الافتراضي', Icons.format_list_numbered_rounded),
      (TripsSortOption.nameAsc, 'الاسم (أ-ي)', Icons.sort_by_alpha_rounded),
      (TripsSortOption.nameDesc, 'الاسم (ي-أ)', Icons.sort_by_alpha_rounded),
      (TripsSortOption.timeAsc, 'الوقت (الأقدم أولاً)', Icons.access_time_rounded),
      (TripsSortOption.timeDesc, 'الوقت (الأحدث أولاً)', Icons.access_time_filled_rounded),
      (TripsSortOption.stateOrder, 'حسب الحالة', Icons.playlist_add_check_rounded),
    ];

    return options.map((option) {
      final isSelected = _sortBy == option.$1;
      return RadioListTile<TripsSortOption>(
        contentPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Icon(
              option.$3,
              size: 18,
              color: isSelected ? AppColors.dispatcherPrimary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              option.$2,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.dispatcherPrimary : null,
              ),
            ),
          ],
        ),
        value: option.$1,
        groupValue: _sortBy,
        onChanged: (value) {
          if (value != null) {
            setState(() => _sortBy = value);
          }
        },
        activeColor: AppColors.dispatcherPrimary,
      );
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      _selectedStates.clear();
      _selectedTypes.clear();
      _onlyWithDriver = false;
      _onlyWithVehicle = false;
      _onlyWithGps = false;
      _onlyWithCompanion = false;
      _sortBy = TripsSortOption.defaultOrder;
    });
  }

  void _applyFilters() {
    // تطبيق جميع الفلاتر باستخدام الدوال المخصصة في الـ Notifier

    // مسح الفلاتر أولاً
    ref.read(tripsFilterProvider.notifier).clearAllFilters();

    // تطبيق الفلاتر الجديدة
    for (final state in _selectedStates) {
      ref.read(tripsFilterProvider.notifier).toggleTripState(state);
    }

    for (final type in _selectedTypes) {
      ref.read(tripsFilterProvider.notifier).toggleTripType(type);
    }

    if (_onlyWithDriver) {
      ref.read(tripsFilterProvider.notifier).toggleWithDriver(true);
    }

    if (_onlyWithVehicle) {
      ref.read(tripsFilterProvider.notifier).toggleWithVehicle(true);
    }

    if (_onlyWithGps) {
      ref.read(tripsFilterProvider.notifier).toggleWithGps(true);
    }

    if (_onlyWithCompanion) {
      ref.read(tripsFilterProvider.notifier).toggleWithCompanion(true);
    }

    if (_sortBy != TripsSortOption.defaultOrder) {
      ref.read(tripsFilterProvider.notifier).setSortOption(_sortBy);
    }

    Navigator.pop(context);
  }
}
