import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bloc/tracking_monitor_cubit.dart';
import '../models/tracked_vehicle.dart';

/// Driver List Panel Widget
///
/// Displays a scrollable list of tracked vehicles/drivers with:
/// - Real-time status updates
/// - Filter options
/// - Search functionality
/// - On-demand location requests
/// - Sort options
class DriverListPanel extends StatefulWidget {
  final TrackingMonitorCubit cubit;
  final Function(TrackedVehicle) onDriverSelected;
  final Future<void> Function(int driverId) onRequestLocation;

  const DriverListPanel({
    Key? key,
    required this.cubit,
    required this.onDriverSelected,
    required this.onRequestLocation,
  }) : super(key: key);

  @override
  State<DriverListPanel> createState() => _DriverListPanelState();
}

class _DriverListPanelState extends State<DriverListPanel>
    with SingleTickerProviderStateMixin {
  StreamSubscription<Map<int, TrackedVehicle>>? _vehiclesSubscription;
  StreamSubscription<TrackedVehicle?>? _selectedVehicleSubscription;
  StreamSubscription<VehicleFilter>? _filterSubscription;

  TrackedVehicle? _selectedVehicle;
  VehicleFilter _currentFilter = VehicleFilter.all;
  String _searchQuery = '';
  VehicleSortOption _sortOption = VehicleSortOption.name;
  bool _isRequestingLocation = false;
  int? _requestingDriverId;
  Timer? _debounceTimer;
  
  late AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    _setupListeners();
  }

  void _setupListeners() {
    _vehiclesSubscription = widget.cubit.vehiclesStream.distinct().listen((vehicles) {
      debugPrint('📋 DriverListPanel: Received ${vehicles.length} vehicles');
      if (mounted) {
        setState(() {}); // Trigger rebuild on vehicle updates
      }
    });

    _selectedVehicleSubscription =
        widget.cubit.selectedVehicleStream.distinct().listen((vehicle) {
      if (mounted) {
        setState(() {
          _selectedVehicle = vehicle;
        });
      }
    });

    _filterSubscription = widget.cubit.filterStream.distinct().listen((filter) {
      if (mounted) {
        setState(() {
          _currentFilter = filter;
        });
      }
    });
  }

  @override
  void dispose() {
    _vehiclesSubscription?.cancel();
    _selectedVehicleSubscription?.cancel();
    _filterSubscription?.cancel();
    _listAnimationController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  List<TrackedVehicle> _getFilteredAndSortedVehicles() {
    var vehicles = widget.cubit.getFilteredVehicles().values.toList();
    debugPrint('🔍 Filtered vehicles before search: ${vehicles.length}');

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      vehicles = vehicles.where((v) {
        final query = _searchQuery.toLowerCase();
        return v.vehicleName.toLowerCase().contains(query) ||
            v.driverName.toLowerCase().contains(query) ||
            v.licensePlate?.toLowerCase().contains(query) == true;
      }).toList();
      debugPrint('🔍 Filtered vehicles after search: ${vehicles.length}');
    }

    // Sort
    switch (_sortOption) {
      case VehicleSortOption.name:
        vehicles.sort((a, b) => a.vehicleName.compareTo(b.vehicleName));
        break;
      case VehicleSortOption.status:
        vehicles.sort((a, b) => a.statusText.compareTo(b.statusText));
        break;
      case VehicleSortOption.lastUpdate:
        vehicles.sort((a, b) => b.lastUpdateTime.compareTo(a.lastUpdateTime));
        break;
    }

    return vehicles;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(child: _buildVehicleList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.people,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Drivers & Vehicles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                StreamBuilder<int>(
                  stream: widget.cubit.onlineVehiclesCountStream,
                  initialData: 0,
                  builder: (context, snapshot) {
                    final count = snapshot.hasData ? snapshot.data! : 0;
                    debugPrint('📊 DriverListPanel online count: $count');
                    return Text(
                      '$count online',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    );
                  },
                ),
              ],
            ),
          ),
          PopupMenuButton<VehicleSortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: (option) {
              setState(() {
                _sortOption = option;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: VehicleSortOption.name,
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha),
                    SizedBox(width: 8),
                    Text('Name'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: VehicleSortOption.status,
                child: Row(
                  children: [
                    Icon(Icons.traffic),
                    SizedBox(width: 8),
                    Text('Status'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: VehicleSortOption.lastUpdate,
                child: Row(
                  children: [
                    Icon(Icons.access_time),
                    SizedBox(width: 8),
                    Text('Last Update'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Semantics(
        label: 'Search drivers or vehicles',
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search drivers or vehicles...',
            prefixIcon: const Icon(Icons.search, semanticLabel: 'Search icon'),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, semanticLabel: 'Clear search'),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                      HapticFeedback.lightImpact();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: (value) {
            // Debounce search to avoid excessive rebuilds
            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() {
                  _searchQuery = value;
                });
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: VehicleFilter.values.map((filter) {
          final isSelected = _currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getFilterLabel(filter)),
              selected: isSelected,
              onSelected: (selected) {
                widget.cubit.setFilter(filter);
              },
              avatar: Icon(
                _getFilterIcon(filter),
                size: 18,
                color: isSelected ? Colors.white : null,
              ),
              selectedColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getFilterLabel(VehicleFilter filter) {
    switch (filter) {
      case VehicleFilter.all:
        return 'All';
      case VehicleFilter.online:
        return 'Online';
      case VehicleFilter.offline:
        return 'Offline';
      case VehicleFilter.onTrip:
        return 'On Trip';
      case VehicleFilter.available:
        return 'Available';
    }
  }

  IconData _getFilterIcon(VehicleFilter filter) {
    switch (filter) {
      case VehicleFilter.all:
        return Icons.grid_view;
      case VehicleFilter.online:
        return Icons.wifi;
      case VehicleFilter.offline:
        return Icons.wifi_off;
      case VehicleFilter.onTrip:
        return Icons.local_shipping;
      case VehicleFilter.available:
        return Icons.check_circle;
    }
  }

  Widget _buildVehicleList() {
    final vehicles = _getFilteredAndSortedVehicles();

    if (vehicles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No vehicles found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try adjusting your search'
                    : 'Waiting for vehicle updates...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Trigger refresh on parent
        HapticFeedback.mediumImpact();
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: vehicles.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context).dividerColor,
        ),
        itemBuilder: (context, index) {
        final vehicle = vehicles[index];
        final isSelected = _selectedVehicle?.vehicleId == vehicle.vehicleId;
        final isRequesting = _isRequestingLocation && _requestingDriverId == vehicle.driverId;

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _listAnimationController,
            curve: Interval(
              index * 0.1,
              0.5 + (index * 0.1),
              curve: Curves.easeOut,
            ),
          )),
          child: FadeTransition(
            opacity: _listAnimationController,
            child: _VehicleListItem(
              vehicle: vehicle,
              isSelected: isSelected,
              isRequestingLocation: isRequesting,
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onDriverSelected(vehicle);
              },
              onRequestLocation: () async {
                setState(() {
                  _isRequestingLocation = true;
                  _requestingDriverId = vehicle.driverId;
                });
                HapticFeedback.mediumImpact();
                try {
                  await widget.onRequestLocation(vehicle.driverId);
                } finally {
                  if (mounted) {
                    setState(() {
                      _isRequestingLocation = false;
                      _requestingDriverId = null;
                    });
                  }
                }
              },
            ),
          ),
        );
      },
      ),
    );
  }
}

class _VehicleListItem extends StatelessWidget {
  final TrackedVehicle vehicle;
  final bool isSelected;
  final bool isRequestingLocation;
  final VoidCallback onTap;
  final Future<void> Function() onRequestLocation;

  const _VehicleListItem({
    required this.vehicle,
    required this.isSelected,
    required this.isRequestingLocation,
    required this.onTap,
    required this.onRequestLocation,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Semantics(
      label: '${vehicle.vehicleName}, driver ${vehicle.driverName}, status ${vehicle.statusText}',
      selected: isSelected,
      child: Material(
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Status indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: statusColor,
                      width: isSelected ? 3 : 2,
                    ),
                  ),
                  child: Icon(
                    vehicle.isOnTrip ? Icons.local_shipping : Icons.person,
                    color: statusColor,
                    size: 24,
                  ),
                ),

              const SizedBox(width: 12),

              // Vehicle info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.vehicleName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle.driverName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            vehicle.statusText,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          vehicle.formattedTimeSinceUpdate,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[500],
                                    fontSize: 10,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action button
              if (!vehicle.isOnline || vehicle.isStale)
                isRequestingLocation
                    ? const SizedBox(
                        width: 40,
                        height: 40,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.refresh),
                        iconSize: 20,
                        tooltip: 'Request location',
                        onPressed: onRequestLocation,
                      )
              else
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  semanticLabel: 'View details',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (vehicle.statusColor) {
      case VehicleStatusColor.onTrip:
        return Colors.green;
      case VehicleStatusColor.available:
        return Colors.blue;
      case VehicleStatusColor.busy:
        return Colors.orange;
      case VehicleStatusColor.offline:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

enum VehicleSortOption {
  name,
  status,
  lastUpdate,
}
