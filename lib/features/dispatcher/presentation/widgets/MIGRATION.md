# Dispatcher Widgets Reorganization - Migration Guide

## Overview
This document outlines the reorganization of the dispatcher widgets folder to follow a more consistent domain-driven structure.

**Date:** 2025-12-22
**Status:** Completed

---

## What Changed

### Previous Structure
```
widgets/
├── change_location_sheet.dart
├── dispatcher_action_fab.dart
├── dispatcher_add_passenger_sheet.dart
├── dispatcher_add_trip_passenger_sheet.dart
├── dispatcher_app_bar.dart
├── dispatcher_footer.dart
├── dispatcher_search_field.dart
├── dispatcher_secondary_header.dart
├── dispatcher_unified_header.dart
├── dispatcher_widgets.dart
├── passenger_quick_actions_sheet.dart
├── select_trip_for_absence_sheet.dart
├── passengers/ (4 files)
├── search_filter/ (2 files)
└── trips_filter/ (2 files)
```

### New Structure
```
widgets/
├── common/                      # Shared/reusable components
│   ├── dispatcher_app_bar.dart
│   ├── dispatcher_footer.dart
│   ├── dispatcher_action_fab.dart
│   ├── dispatcher_search_field.dart
│   └── dispatcher_widgets.dart  # Barrel export file
├── headers/                     # Header components
│   ├── dispatcher_unified_header.dart
│   └── dispatcher_secondary_header.dart
├── passengers/                  # Passenger-related widgets
│   ├── empty_passengers_view.dart
│   ├── passengers_list_section.dart
│   ├── passenger_stats_row.dart
│   ├── passenger_tile.dart
│   ├── dispatcher_add_passenger_sheet.dart
│   ├── passenger_quick_actions_sheet.dart
│   └── change_location_sheet.dart
└── trips/                       # Trip-related widgets
    ├── dispatcher_add_trip_passenger_sheet.dart
    ├── select_trip_for_absence_sheet.dart
    ├── trip_search_bar.dart (from search_filter/)
    ├── advanced_filter_sheet.dart (from search_filter/)
    ├── trips_search_bar.dart (from trips_filter/)
    └── trips_advanced_filter_sheet.dart (from trips_filter/)
```

---

## Migration Path for Imports

### Common Widgets
| Old Import | New Import |
|------------|------------|
| `import '../widgets/dispatcher_app_bar.dart';` | `import '../widgets/common/dispatcher_app_bar.dart';` |
| `import '../widgets/dispatcher_footer.dart';` | `import '../widgets/common/dispatcher_footer.dart';` |
| `import '../widgets/dispatcher_action_fab.dart';` | `import '../widgets/common/dispatcher_action_fab.dart';` |
| `import '../widgets/dispatcher_search_field.dart';` | `import '../widgets/common/dispatcher_search_field.dart';` |

### Header Widgets
| Old Import | New Import |
|------------|------------|
| `import '../widgets/dispatcher_unified_header.dart';` | `import '../widgets/headers/dispatcher_unified_header.dart';` |
| `import '../widgets/dispatcher_secondary_header.dart';` | `import '../widgets/headers/dispatcher_secondary_header.dart';` |

### Passenger Widgets
| Old Import | New Import |
|------------|------------|
| `import '../widgets/dispatcher_add_passenger_sheet.dart';` | `import '../widgets/passengers/dispatcher_add_passenger_sheet.dart';` |
| `import '../widgets/passenger_quick_actions_sheet.dart';` | `import '../widgets/passengers/passenger_quick_actions_sheet.dart';` |
| `import '../widgets/change_location_sheet.dart';` | `import '../widgets/passengers/change_location_sheet.dart';` |

### Trip Widgets
| Old Import | New Import |
|------------|------------|
| `import '../widgets/dispatcher_add_trip_passenger_sheet.dart';` | `import '../widgets/trips/dispatcher_add_trip_passenger_sheet.dart';` |
| `import '../widgets/select_trip_for_absence_sheet.dart';` | `import '../widgets/trips/select_trip_for_absence_sheet.dart';` |
| `import '../widgets/search_filter/trip_search_bar.dart';` | `import '../widgets/trips/trip_search_bar.dart';` |
| `import '../widgets/search_filter/advanced_filter_sheet.dart';` | `import '../widgets/trips/advanced_filter_sheet.dart';` |
| `import '../widgets/trips_filter/trips_search_bar.dart';` | `import '../widgets/trips/trips_search_bar.dart';` |
| `import '../widgets/trips_filter/trips_advanced_filter_sheet.dart';` | `import '../widgets/trips/trips_advanced_filter_sheet.dart';` |

---

## Alternative: Use Barrel Export

Instead of updating individual imports, you can use the barrel export file:

```dart
// Instead of multiple imports:
import '../widgets/common/dispatcher_app_bar.dart';
import '../widgets/common/dispatcher_footer.dart';
import '../widgets/headers/dispatcher_unified_header.dart';

// Use single barrel import:
import '../widgets/common/dispatcher_widgets.dart';
```

The `dispatcher_widgets.dart` file now exports all widgets from all subdirectories.

---

## Files Updated

### Screens Updated (21 files)
1. `dispatcher_groups_screen.dart`
2. `dispatcher_trips_screen.dart`
3. `dispatcher_vehicles_screen.dart`
4. `dispatcher_passengers_board_screen.dart`
5. `dispatcher_passenger_detail_screen.dart`
6. `dispatcher_create_trip_screen.dart`
7. `dispatcher_edit_trip_screen.dart`
8. `dispatcher_trip_detail_screen.dart`
9. `dispatcher_trip_passengers_screen.dart`
10. `dispatcher_group_detail_screen.dart`
11. `dispatcher_group_passengers_screen.dart`
12. `dispatcher_create_group_screen.dart`
13. `dispatcher_edit_group_screen.dart`
14. `dispatcher_create_passenger_screen.dart`
15. `dispatcher_edit_passenger_screen.dart`
16. `dispatcher_create_vehicle_screen.dart`
17. `screens/create_trip/widgets/passenger_selection_sheet.dart`

### Widget Files Moved (20 files)
- 5 common widgets
- 2 header widgets
- 7 passenger widgets
- 6 trip widgets

---

## Benefits of New Structure

### 1. Better Organization
- Widgets are grouped by domain (common, headers, passengers, trips)
- Easier to find related widgets
- Clear separation of concerns

### 2. Scalability
- New widgets can be added to appropriate domain folders
- Easier to navigate as the codebase grows

### 3. Consistency
- Follows domain-driven design principles
- Matches the overall architecture of the app

### 4. Maintainability
- Related widgets are co-located
- Easier to refactor domain-specific widgets

---

## Breaking Changes

None. All imports have been updated automatically, and the `dispatcher_widgets.dart` barrel export provides backward compatibility if needed.

---

## Git History

Files were moved using `git mv` to preserve file history where possible. Some files from untracked directories (`search_filter/`, `trips_filter/`) were moved with regular `mv` commands.

---

## Next Steps

1. Consider creating index files for each subdirectory if needed
2. Update any documentation that references the old structure
3. Review any external packages or tools that might reference these paths

---

## Questions or Issues?

If you encounter any import issues after this reorganization, check:
1. The import path matches the new structure
2. The file exists in the new location
3. Consider using the barrel export `dispatcher_widgets.dart` for simplicity
