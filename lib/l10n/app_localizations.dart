import 'package:flutter/material.dart';

/// App localizations
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  /// Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
    Locale('fr'),
  ];

  /// Localization delegate
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Get current instance
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// Check if RTL
  bool get isRtl => locale.languageCode == 'ar';

  /// Get current language name
  String get currentLanguageName {
    switch (locale.languageCode) {
      case 'ar':
        return 'العربية';
      case 'fr':
        return 'Français';
      default:
        return 'English';
    }
  }

  /// Translations map
  static final Map<String, Map<String, String>> _translations = {
    'en': {
      // App
      'app_name': 'ShuttleBee',
      'app_title': 'ShuttleBee Transport',

      // General
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'close': 'Close',
      'search': 'Search',
      'retry': 'Retry',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
      'add': 'Add',
      'update': 'Update',
      'create': 'Create',
      'view': 'View',
      'back': 'Back',
      'next': 'Next',
      'previous': 'Previous',
      'done': 'Done',
      'skip': 'Skip',
      'continue_text': 'Continue',
      'submit': 'Submit',
      'select': 'Select',
      'select_all': 'Select All',
      'clear': 'Clear',
      'clear_all': 'Clear All',
      'refresh': 'Refresh',
      'filter': 'Filter',
      'filters': 'Filters',
      'sort': 'Sort',
      'sort_by': 'Sort by',
      'ascending': 'Ascending',
      'descending': 'Descending',
      'apply': 'Apply',
      'reset': 'Reset',
      'more': 'More',
      'less': 'Less',
      'show_more': 'Show more',
      'show_less': 'Show less',
      'details': 'Details',
      'info': 'Info',
      'warning': 'Warning',
      'required': 'Required',
      'optional': 'Optional',
      'actions': 'Actions',
      'options': 'Options',
      'all': 'All',
      'none': 'None',
      'active': 'Active',
      'inactive': 'Inactive',
      'enabled': 'Enabled',
      'disabled': 'Disabled',
      'header': 'Header',
      'footer': 'Footer',
      'status': 'Status',
      'name': 'Name',
      'description': 'Description',
      'date': 'Date',
      'time': 'Time',
      'start': 'Start',
      'end': 'End',
      'from': 'From',
      'to': 'To',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'tomorrow': 'Tomorrow',
      'now': 'Now',
      'total': 'Total',
      'count': 'Count',
      'amount': 'Amount',
      'note': 'Note',
      'notes': 'Notes',
      'comment': 'Comment',
      'comments': 'Comments',
      'message': 'Message',
      'copy': 'Copy',
      'copied': 'Copied',
      'share': 'Share',
      'download': 'Download',
      'upload': 'Upload',
      'export': 'Export',
      'import': 'Import',
      'print': 'Print',
      'help': 'Help',
      'about': 'About',
      'contact': 'Contact',
      'phone': 'Phone',
      'address': 'Address',
      'location': 'Location',

      // Auth
      'login': 'Login',
      'logout': 'Logout',
      'sign_in': 'Sign In',
      'sign_out': 'Sign Out',
      'sign_up': 'Sign Up',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'username': 'Username',
      'server_url': 'Server URL',
      'database': 'Database',
      'remember_me': 'Remember me',
      'forgot_password': 'Forgot password?',
      'reset_password': 'Reset Password',
      'change_password': 'Change Password',
      'login_success': 'Login successful',
      'login_failed': 'Login failed',
      'invalid_credentials': 'Invalid username or password',
      'logout_confirm': 'Are you sure you want to logout?',
      'select_company': 'Select Company',
      'welcome_back': 'Welcome back',
      'session_expired': 'Session expired, please login again',

      // Home & Navigation
      'home': 'Home',
      'dashboard': 'Dashboard',
      'welcome': 'Welcome',
      'quick_actions': 'Quick Actions',
      'recent_activities': 'Recent Activities',
      'overview': 'Overview',
      'analytics': 'Analytics',
      'reports': 'Reports',
      'monitor': 'Monitor',
      'monitoring': 'Monitoring',

      // Settings
      'settings': 'Settings',
      'profile': 'Profile',
      'account': 'Account',
      'preferences': 'Preferences',
      'appearance': 'Appearance',
      'language': 'Language',
      'theme': 'Theme',
      'light': 'Light',
      'dark': 'Dark',
      'system': 'System',
      'light_mode': 'Light Mode',
      'dark_mode': 'Dark Mode',
      'system_default': 'System Default',

      // Number & Date Format Settings
      'number_format': 'Number Format',
      'numeral_system': 'Numeral System',
      'western_numerals': 'Western Numerals (0-9)',
      'arabic_numerals': 'Arabic Numerals (٠-٩)',
      'date_format': 'Date Format',
      'date_format_short': 'Short',
      'date_format_medium': 'Medium',
      'date_format_long': 'Long',
      'date_format_full': 'Full',
      'date_format_short_example': '01/12/2024',
      'date_format_medium_example': '01 Dec 2024',
      'date_format_long_example': '01 December 2024',
      'date_format_full_example': 'Sunday, 01 December 2024',
      'notifications_settings': 'Notification Settings',
      'privacy_security': 'Privacy & Security',
      'about_app': 'About App',
      'version': 'Version',
      'privacy_policy': 'Privacy Policy',
      'terms_of_service': 'Terms of Service',
      'general': 'General',

      // Offline & Sync
      'offline': 'Offline',
      'online': 'Online',
      'offline_mode': 'Offline Mode',
      'sync': 'Sync',
      'synced': 'Synced',
      'syncing': 'Syncing...',
      'sync_complete': 'Sync complete',
      'sync_failed': 'Sync failed',
      'sync_status': 'Sync Status',
      'pending_operations': 'Pending Operations',
      'no_pending_operations': 'No pending operations',
      'last_sync': 'Last sync',
      'offline_banner': "You're working offline",
      'data_saved_offline': 'Data saved offline',
      'will_sync_when_online': 'Will sync when online',
      'cache_management': 'Cache Management',
      'clear_cache': 'Clear Cache',
      'online_now': 'Online now',

      // Notifications
      'notifications': 'Notifications',
      'no_notifications': 'No notifications',
      'mark_all_read': 'Mark all as read',
      'new_notification': 'New notification',
      'notification_settings': 'Notification Settings',
      'push_notifications': 'Push Notifications',
      'email_notifications': 'Email Notifications',

      // Search
      'search_placeholder': 'Search...',
      'no_results': 'No results found',
      'recent_searches': 'Recent Searches',
      'search_results': 'Search Results',
      'search_for': 'Search for',
      'voice_search': 'Voice Search',

      // Errors
      'error_generic': 'Something went wrong',
      'error_network': 'Network error',
      'error_server': 'Server error',
      'error_timeout': 'Connection timed out',
      'error_no_connection': 'No internet connection',
      'error_unauthorized': 'Unauthorized access',
      'error_not_found': 'Not found',
      'error_validation': 'Validation error',
      'try_again': 'Try again',
      'something_went_wrong': 'Something went wrong',

      // Empty States
      'empty_data': 'No data available',
      'empty_list': 'The list is empty',
      'no_items': 'No items',
      'no_data': 'No data',
      'nothing_here': 'Nothing here yet',

      // Trips
      'trips': 'Trips',
      'trips_management': 'Trips Management',
      'trip': 'Trip',
      'trip_details': 'Trip Details',
      'create_trip': 'Create Trip',
      'edit_trip': 'Edit Trip',
      'start_trip': 'Start Trip',
      'end_trip': 'End Trip',
      'cancel_trip': 'Cancel Trip',
      'trip_history': 'Trip History',
      'trip_status': 'Trip Status',
      'scheduled': 'Scheduled',
      'in_progress': 'In Progress',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
      'pending': 'Pending',
      'departure': 'Departure',
      'arrival': 'Arrival',
      'departure_time': 'Departure Time',
      'arrival_time': 'Arrival Time',
      'estimated_time': 'Estimated Time',
      'duration': 'Duration',
      'distance': 'Distance',
      'route': 'Route',
      'routes': 'Routes',
      'no_trips': 'No trips',
      'upcoming_trips': 'Upcoming Trips',
      'past_trips': 'Past Trips',
      'active_trips': 'Active Trips',
      'live_tracking': 'Live Tracking',
      'track_trip': 'Track Trip',
      'planned': 'Planned',
      'ongoing': 'Ongoing',
      'draft': 'Draft',
      'clear_filters': 'Clear Filters',
      'create_new_trip': 'Create New Trip',
      'search_trip': 'Search for a trip/driver/vehicle...',
      'no_trips_for_day': 'No trips scheduled for this day',
      'no_results_matching': 'No results matching',
      'no_results_for_filters': 'No results matching filters',
      'advanced_filters': 'Advanced Filters',
      'trip_type': 'Trip Type',
      'with_driver': 'With Driver',
      'with_vehicle': 'With Vehicle',
      'with_gps': 'With GPS',
      'only_with_driver': 'Only trips with a driver',
      'only_with_vehicle': 'Only trips with a vehicle',
      'only_with_gps': 'Only trips with GPS',
      'select_date': 'Select Date',
      'companion': 'Companion',
      'no_companion': 'No Companion',
      'status_and_time': 'Status & Time',
      'driver_and_vehicle': 'Driver & Vehicle',
      'not_assigned': 'Not Assigned',
      'plate_number': 'Plate Number',
      'started_actually': 'Actually Started',
      'ended_actually': 'Actually Ended',
      'are_you_sure_start': 'Do you want to start this trip now?',
      'are_you_sure_end': 'Do you want to end this trip?',
      'are_you_sure_cancel':
          'Are you sure you want to cancel this trip? This action cannot be undone.',
      'trip_started': 'Trip started',
      'trip_ended': 'Trip ended',
      'trip_cancelled': 'Trip cancelled',
      'failed_to_start': 'Failed to start trip',
      'failed_to_end': 'Failed to end trip',
      'failed_to_cancel': 'Failed to cancel trip',
      'back_to_trips': 'Back to Trips',
      'trip_not_found': 'Trip not found',
      'generate_from_group': 'Generate from Group',
      'manual_trip': 'Manual Trip',
      'generate_trips': 'Generate Trips',
      'generate_trips_from_group': 'Generate trips from a group',
      'select_group_to_generate':
          'Select an existing group to automatically generate trips based on its schedules',
      'create_manual_trip': 'Create a trip manually',
      'create_manual_trip_desc':
          'Manually specify trip details without relying on a group schedule',
      'basic_info': 'Basic Information',
      'trip_name': 'Trip Name',
      'trip_name_example': 'Example: Morning Trip - North Area',
      'generation_options': 'Generation Options',
      'weeks_to_generate': 'Weeks to Generate',
      'will_generate_trips': 'Will generate trips for',
      'weeks_ahead': 'weeks ahead based on group schedules',
      'week': 'week',
      'generating': 'Generating...',
      'creating': 'Creating...',
      'no_active_groups': 'No active groups. Create a group first.',
      'no_drivers_available': 'No drivers available',
      'trips_generated_successfully': 'trips generated successfully',
      'view_all_trips': 'View All Trips',
      'generated_trips': 'Generated Trips',
      'and_more': 'and',
      'more_trips': 'more trips...',
      'no_trips_generated':
          'No trips generated. Make sure the group has schedules.',
      'companion_optional': 'Companion (Optional)',
      'select_companion': 'Select Companion',
      'select_driver': 'Select Driver',
      'select_group': 'Select Group',
      'select_vehicle': 'Select Vehicle',
      'no_group': 'No Group',
      'no_vehicle': 'No Vehicle',
      'no_license_plate': 'No License Plate',
      'please_select_driver': 'Please select a driver',
      'failed_to_load_groups': 'Failed to load groups',
      'error_creating_trip': 'Error creating trip',
      'cannot_access_trip_repository': 'Cannot access trip repository',

      // Passengers
      'passengers': 'Passengers',
      'passengers_management': 'Passengers Management',
      'passenger': 'Passenger',
      'passenger_details': 'Passenger Details',
      'add_passenger': 'Add Passenger',
      'edit_passenger': 'Edit Passenger',
      'remove_passenger': 'Remove Passenger',
      'passenger_count': 'Passenger Count',
      'passenger_list': 'Passenger List',
      'no_passengers': 'No passengers',
      'board_passenger': 'Board Passenger',
      'drop_passenger': 'Drop Passenger',
      'boarding': 'Boarding',
      'boarded': 'Boarded',
      'dropped': 'Dropped',
      'not_boarded': 'Not Boarded',
      'absent': 'Absent',
      'present': 'Present',
      'all_passengers': 'All Passengers',
      'unassigned': 'Unassigned',
      'by_groups': 'By Groups',
      'distribution_board': 'Distribution Board',
      'search_all_passengers': 'Search all passengers...',
      'search_unassigned': 'Search unassigned...',
      'search_group': 'Search for a group...',
      'quick_search_board': 'Quick search in board...',
      'add_new_passenger': 'Add New Passenger',
      'no_matching_results': 'No matching results',
      'no_passengers_in_system': 'No passengers in the system.',
      'all_assigned_to_groups':
          'All current passengers are assigned to groups.',
      'create_group_first': 'Create a group first then add passengers.',
      'move_to_group': 'Move to Group',
      'move': 'Move',
      'assign': 'Assign',
      'empty': 'Empty',
      'pickup': 'Pickup',
      'dropoff': 'Drop-off',
      'edit_profile': 'Edit Profile',
      'change_location': 'Change Location',
      'mark_absent': 'Mark Absent',
      'cannot_connect_server': 'Cannot connect to server',
      'absence_recorded': 'Absence recorded for',
      'in': 'in',
      'absence_failed': 'Failed to record absence',
      'father': 'Father',
      'mother': 'Mother',
      'no_groups_available': 'No groups available',

      // Vehicles
      'vehicles': 'Vehicles',
      'vehicles_management': 'Vehicles Management',
      'vehicle': 'Vehicle',
      'vehicle_details': 'Vehicle Details',
      'add_vehicle': 'Add Vehicle',
      'edit_vehicle': 'Edit Vehicle',
      'vehicle_number': 'Vehicle Number',
      'license_plate': 'License Plate',
      'vehicle_type': 'Vehicle Type',
      'capacity': 'Capacity',
      'seats': 'Seats',
      'available_seats': 'Available Seats',
      'no_vehicles': 'No vehicles',
      'bus': 'Bus',
      'van': 'Van',
      'car': 'Car',

      // Groups
      'groups': 'Groups',
      'groups_management': 'Groups Management',
      'group': 'Group',
      'group_details': 'Group Details',
      'create_group': 'Create Group',
      'edit_group': 'Edit Group',
      'group_name': 'Group Name',
      'group_members': 'Group Members',
      'add_to_group': 'Add to Group',
      'remove_from_group': 'Remove from Group',
      'no_groups': 'No groups',
      'schedules': 'Schedules',
      'schedule': 'Schedule',
      'new_group': 'New Group',
      'search_group_hint': 'Search for a group...',
      'active_only': 'Active Only',
      'with_destination': 'With Destination',
      'linked_to_driver': 'Linked to Driver',
      'linked_to_vehicle': 'Linked to Vehicle',
      'has_destination': 'Has Destination',
      'group_filters': 'Group Filters',
      'showing_of': 'Showing',
      'of_text': 'of',
      'no_groups_found': 'No groups found',
      'no_matching_search': 'No results matching search',
      'no_groups_created': 'No groups created yet',
      'generate_trip': 'Generate Trip',
      'manage_schedules': 'Manage Schedules',
      'view_passengers': 'View Passengers',
      'delete_group': 'Delete Group',
      'delete_group_title': 'Delete Group',
      'delete_group_confirm':
          'Are you sure you want to delete group "{name}"?\n\nThis action cannot be undone.',
      'group_deleted': 'Group "{name}" deleted successfully',
      'failed_to_delete_group': 'Failed to delete group, try again',
      'passenger_singular': 'passenger',
      'both_pickup_dropoff': 'Pickup & Drop-off',

      // Stops
      'stops': 'Stops',
      'stop': 'Stop',
      'stop_details': 'Stop Details',
      'add_stop': 'Add Stop',
      'edit_stop': 'Edit Stop',
      'stop_name': 'Stop Name',
      'stop_order': 'Stop Order',
      'pickup_stop': 'Pickup Stop',
      'dropoff_stop': 'Drop-off Stop',
      'no_stops': 'No stops',

      // Driver
      'driver': 'Driver',
      'drivers': 'Drivers',
      'driver_details': 'Driver Details',
      'assign_driver': 'Assign Driver',
      'driver_name': 'Driver Name',
      'driving': 'Driving',
      'driver_home': 'Driver Home',
      'start_driving': 'Start Driving',
      'stop_driving': 'Stop Driving',

      // Dispatcher
      'dispatcher': 'Dispatcher',
      'dispatchers': 'Dispatchers',
      'dispatch': 'Dispatch',
      'dispatcher_home': 'Dispatcher Home',
      'assign_trip': 'Assign Trip',

      // Manager
      'manager': 'Manager',
      'managers': 'Managers',
      'manager_home': 'Manager Home',
      'manager_dashboard': 'Manager Dashboard',

      // Guardian
      'guardian': 'Guardian',
      'guardians': 'Guardians',
      'guardian_home': 'Guardian Home',
      'my_children': 'My Children',
      'child': 'Child',
      'children': 'Children',

      // Map
      'map': 'Map',
      'maps': 'Maps',
      'view_on_map': 'View on Map',
      'current_location': 'Current Location',
      'get_directions': 'Get Directions',
      'navigation': 'Navigation',

      // Time & Date
      'minutes': 'minutes',
      'hours': 'hours',
      'days': 'days',
      'weeks': 'weeks',
      'months': 'months',
      'years': 'years',
      'ago': 'ago',
      'in_future': 'in',
      'just_now': 'Just now',
      'morning': 'Morning',
      'afternoon': 'Afternoon',
      'evening': 'Evening',
      'night': 'Night',
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',
      'per_trip': 'Per Trip',
      'monthly': 'Monthly',
      'per_term': 'Per Term',
      'billing_cycle': 'Billing Cycle',

      // Holidays
      'holidays': 'Holidays',
      'holiday': 'Holiday',
      'add_holiday': 'Add Holiday',
      'edit_holiday': 'Edit Holiday',
      'holiday_name': 'Holiday Name',
      'holiday_date': 'Holiday Date',
      'no_holidays': 'No holidays',

      // Reports
      'generate_report': 'Generate Report',
      'export_pdf': 'Export PDF',
      'export_excel': 'Export Excel',
      'daily_report': 'Daily Report',
      'weekly_report': 'Weekly Report',
      'monthly_report': 'Monthly Report',

      // Stats
      'statistics': 'Statistics',
      'stats': 'Stats',
      'today_statistics': 'Today\'s Statistics',
      'total_trips': 'Total Trips',
      'total_trips_today': 'Total Trips Today',
      'total_passengers': 'Total Passengers',
      'total_vehicles': 'Total Vehicles',
      'total_distance': 'Total Distance',
      'average': 'Average',
      'performance': 'Performance',
      'efficiency': 'Efficiency',
      'fleet_status': 'Fleet Status',
      'fleet_utilization': 'Fleet Utilization Rate',
      'fleet_in_use': 'of fleet in use',
      'active_vehicles': 'Active Vehicles',
      'active_drivers': 'Active Drivers',
      'ongoing_trips': 'Ongoing Trips',
      'live_monitoring': 'Live Monitoring',
      'active_trips_now': 'active trips now',
      'view_sync_status': 'View Sync Status',

      // Companies
      'company': 'Company',
      'companies': 'Companies',
      'current_company': 'Current Company',
      'switch_company': 'Switch Company',
      'multi_company': 'Multi-Company',

      // Permissions & Roles
      'permissions': 'Permissions',
      'roles': 'Roles',
      'admin': 'Admin',
      'user': 'User',
      'access_denied': 'Access Denied',

      // Biometric
      'biometric_auth': 'Biometric Authentication',
      'enable_biometric': 'Enable Biometric',
      'use_fingerprint': 'Use Fingerprint',
      'use_face_id': 'Use Face ID',

      // Camera & Files
      'camera': 'Camera',
      'gallery': 'Gallery',
      'pick_image': 'Pick Image',
      'pick_file': 'Pick File',
      'upload_file': 'Upload File',
      'download_file': 'Download File',
      'file_manager': 'File Manager',

      // Confirmation dialogs
      'are_you_sure': 'Are you sure?',
      'confirm_delete': 'Are you sure you want to delete this?',
      'confirm_cancel': 'Are you sure you want to cancel?',
      'confirm_logout': 'Are you sure you want to logout?',
      'changes_not_saved': 'Changes not saved',
      'discard_changes': 'Discard changes?',

      // Success messages
      'saved_successfully': 'Saved successfully',
      'deleted_successfully': 'Deleted successfully',
      'updated_successfully': 'Updated successfully',
      'created_successfully': 'Created successfully',
      'operation_successful': 'Operation successful',

      // Onboarding
      'get_started': 'Get Started',
      'welcome_to_app': 'Welcome to ShuttleBee',
      'onboarding_title_1': 'Track Your Trips',
      'onboarding_title_2': 'Real-time Updates',
      'onboarding_title_3': 'Safe & Reliable',
      'onboarding_desc_1':
          'Monitor all your transportation activities in one place',
      'onboarding_desc_2': 'Get instant notifications about trip status',
      'onboarding_desc_3': 'Ensure safe transportation for everyone',

      // Validation
      'field_required': 'This field is required',
      'invalid_email': 'Invalid email address',
      'password_too_short': 'Password is too short',
      'passwords_dont_match': 'Passwords do not match',
      'invalid_phone': 'Invalid phone number',
      'invalid_input': 'Invalid input',

      // Misc
      'real_time_updates': 'Real-time Updates',
      'connected': 'Connected',
      'audit_trail': 'Audit Trail',
      'form_builder': 'Form Builder',
      'required_field': 'Required Field',
      'revenue': 'Revenue',
      'orders': 'Orders',
      'customers': 'Customers',
      'sales_overview': 'Sales Overview',
      'orders_by_status': 'Orders by Status',

      // Role Switcher
      'view_as': 'View as',
      'original': 'Original',
      'original_role': 'Original Role',
      'return': 'Return',
      'you_are_viewing_as': 'You are viewing the app as',
      'switched_to_view': 'Switched to view',
      'returned_to_view': 'Returned to view',
      'switch_role': 'Switch Role',
    },
    'ar': {
      // App
      'app_name': 'شاتل بي',
      'app_title': 'شاتل بي للنقل',

      // General
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'success': 'نجاح',
      'cancel': 'إلغاء',
      'confirm': 'تأكيد',
      'save': 'حفظ',
      'delete': 'حذف',
      'edit': 'تعديل',
      'close': 'إغلاق',
      'search': 'بحث',
      'retry': 'إعادة المحاولة',
      'yes': 'نعم',
      'no': 'لا',
      'ok': 'حسناً',
      'add': 'إضافة',
      'update': 'تحديث',
      'create': 'إنشاء',
      'view': 'عرض',
      'back': 'رجوع',
      'next': 'التالي',
      'previous': 'السابق',
      'done': 'تم',
      'skip': 'تخطي',
      'continue_text': 'متابعة',
      'submit': 'إرسال',
      'select': 'اختيار',
      'select_all': 'اختيار الكل',
      'clear': 'مسح',
      'clear_all': 'مسح الكل',
      'refresh': 'تحديث',
      'filter': 'تصفية',
      'filters': 'المرشحات',
      'sort': 'ترتيب',
      'sort_by': 'ترتيب حسب',
      'ascending': 'تصاعدي',
      'descending': 'تنازلي',
      'apply': 'تطبيق',
      'reset': 'إعادة تعيين',
      'more': 'المزيد',
      'less': 'أقل',
      'show_more': 'عرض المزيد',
      'show_less': 'عرض أقل',
      'details': 'التفاصيل',
      'info': 'معلومات',
      'warning': 'تحذير',
      'required': 'مطلوب',
      'optional': 'اختياري',
      'actions': 'الإجراءات',
      'options': 'الخيارات',
      'all': 'الكل',
      'none': 'لا شيء',
      'active': 'نشط',
      'inactive': 'غير نشط',
      'enabled': 'مفعّل',
      'disabled': 'معطّل',
      'header': 'رأس الصفحة',
      'footer': 'تذييل الصفحة',
      'status': 'الحالة',
      'name': 'الاسم',
      'description': 'الوصف',
      'date': 'التاريخ',
      'time': 'الوقت',
      'start': 'بداية',
      'end': 'نهاية',
      'from': 'من',
      'to': 'إلى',
      'today': 'اليوم',
      'yesterday': 'أمس',
      'tomorrow': 'غداً',
      'now': 'الآن',
      'total': 'المجموع',
      'count': 'العدد',
      'amount': 'المبلغ',
      'note': 'ملاحظة',
      'notes': 'ملاحظات',
      'comment': 'تعليق',
      'comments': 'تعليقات',
      'message': 'رسالة',
      'copy': 'نسخ',
      'copied': 'تم النسخ',
      'share': 'مشاركة',
      'download': 'تنزيل',
      'upload': 'رفع',
      'export': 'تصدير',
      'import': 'استيراد',
      'print': 'طباعة',
      'help': 'مساعدة',
      'about': 'حول',
      'contact': 'اتصال',
      'phone': 'الهاتف',
      'address': 'العنوان',
      'location': 'الموقع',

      // Auth
      'login': 'تسجيل الدخول',
      'logout': 'تسجيل الخروج',
      'sign_in': 'تسجيل الدخول',
      'sign_out': 'تسجيل الخروج',
      'sign_up': 'إنشاء حساب',
      'register': 'تسجيل',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'confirm_password': 'تأكيد كلمة المرور',
      'username': 'اسم المستخدم',
      'server_url': 'عنوان الخادم',
      'database': 'قاعدة البيانات',
      'remember_me': 'تذكرني',
      'forgot_password': 'نسيت كلمة المرور؟',
      'reset_password': 'إعادة تعيين كلمة المرور',
      'change_password': 'تغيير كلمة المرور',
      'login_success': 'تم تسجيل الدخول بنجاح',
      'login_failed': 'فشل تسجيل الدخول',
      'invalid_credentials': 'اسم المستخدم أو كلمة المرور غير صحيحة',
      'logout_confirm': 'هل أنت متأكد من تسجيل الخروج؟',
      'select_company': 'اختر الشركة',
      'welcome_back': 'مرحباً بعودتك',
      'session_expired': 'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى',

      // Home & Navigation
      'home': 'الرئيسية',
      'dashboard': 'لوحة التحكم',
      'welcome': 'مرحباً',
      'quick_actions': 'إجراءات سريعة',
      'recent_activities': 'الأنشطة الأخيرة',
      'overview': 'نظرة عامة',
      'analytics': 'التحليلات',
      'reports': 'التقارير',
      'monitor': 'المراقبة',
      'monitoring': 'المراقبة',

      // Settings
      'settings': 'الإعدادات',
      'profile': 'الملف الشخصي',
      'account': 'الحساب',
      'preferences': 'التفضيلات',
      'appearance': 'المظهر',
      'language': 'اللغة',
      'theme': 'السمة',
      'light': 'فاتح',
      'dark': 'داكن',
      'system': 'النظام',
      'light_mode': 'الوضع الفاتح',
      'dark_mode': 'الوضع الداكن',
      'system_default': 'الإعداد الافتراضي',

      // Number & Date Format Settings
      'number_format': 'تنسيق الأرقام',
      'numeral_system': 'نظام الأرقام',
      'western_numerals': 'أرقام فرنسية (0-9)',
      'arabic_numerals': 'أرقام عربية (٠-٩)',
      'date_format': 'تنسيق التاريخ',
      'date_format_short': 'مختصر',
      'date_format_medium': 'متوسط',
      'date_format_long': 'طويل',
      'date_format_full': 'كامل',
      'date_format_short_example': '01/12/2024',
      'date_format_medium_example': '01 ديسمبر 2024',
      'date_format_long_example': '01 ديسمبر 2024',
      'date_format_full_example': 'الأحد، 01 ديسمبر 2024',
      'notifications_settings': 'إعدادات الإشعارات',
      'privacy_security': 'الخصوصية والأمان',
      'about_app': 'حول التطبيق',
      'version': 'الإصدار',
      'privacy_policy': 'سياسة الخصوصية',
      'terms_of_service': 'شروط الخدمة',
      'general': 'عام',

      // Offline & Sync
      'offline': 'غير متصل',
      'online': 'متصل',
      'offline_mode': 'وضع عدم الاتصال',
      'sync': 'مزامنة',
      'synced': 'متزامن',
      'syncing': 'جاري المزامنة...',
      'sync_complete': 'تمت المزامنة',
      'sync_failed': 'فشلت المزامنة',
      'sync_status': 'حالة المزامنة',
      'pending_operations': 'العمليات المعلقة',
      'no_pending_operations': 'لا توجد عمليات معلقة',
      'last_sync': 'آخر مزامنة',
      'offline_banner': 'أنت تعمل بدون اتصال',
      'data_saved_offline': 'تم حفظ البيانات محلياً',
      'will_sync_when_online': 'ستتم المزامنة عند الاتصال',
      'cache_management': 'إدارة ذاكرة التخزين المؤقت',
      'clear_cache': 'مسح ذاكرة التخزين المؤقت',
      'online_now': 'متصل الآن',

      // Notifications
      'notifications': 'الإشعارات',
      'no_notifications': 'لا توجد إشعارات',
      'mark_all_read': 'تحديد الكل كمقروء',
      'new_notification': 'إشعار جديد',
      'notification_settings': 'إعدادات الإشعارات',
      'push_notifications': 'إشعارات الدفع',
      'email_notifications': 'إشعارات البريد الإلكتروني',

      // Search
      'search_placeholder': 'بحث...',
      'no_results': 'لم يتم العثور على نتائج',
      'recent_searches': 'عمليات البحث الأخيرة',
      'search_results': 'نتائج البحث',
      'search_for': 'البحث عن',
      'voice_search': 'البحث الصوتي',

      // Errors
      'error_generic': 'حدث خطأ ما',
      'error_network': 'خطأ في الشبكة',
      'error_server': 'خطأ في الخادم',
      'error_timeout': 'انتهت مهلة الاتصال',
      'error_no_connection': 'لا يوجد اتصال بالإنترنت',
      'error_unauthorized': 'وصول غير مصرح',
      'error_not_found': 'غير موجود',
      'error_validation': 'خطأ في التحقق',
      'try_again': 'حاول مرة أخرى',
      'something_went_wrong': 'حدث خطأ ما',

      // Empty States
      'empty_data': 'لا توجد بيانات',
      'empty_list': 'القائمة فارغة',
      'no_items': 'لا توجد عناصر',
      'no_data': 'لا توجد بيانات',
      'nothing_here': 'لا يوجد شيء هنا بعد',

      // Trips
      'trips': 'الرحلات',
      'trips_management': 'إدارة الرحلات',
      'trip': 'رحلة',
      'trip_details': 'تفاصيل الرحلة',
      'create_trip': 'إنشاء رحلة',
      'edit_trip': 'تعديل الرحلة',
      'start_trip': 'بدء الرحلة',
      'end_trip': 'إنهاء الرحلة',
      'cancel_trip': 'إلغاء الرحلة',
      'trip_history': 'سجل الرحلات',
      'trip_status': 'حالة الرحلة',
      'scheduled': 'مجدول',
      'in_progress': 'قيد التنفيذ',
      'completed': 'مكتمل',
      'cancelled': 'ملغي',
      'pending': 'قيد الانتظار',
      'departure': 'المغادرة',
      'arrival': 'الوصول',
      'departure_time': 'وقت المغادرة',
      'arrival_time': 'وقت الوصول',
      'estimated_time': 'الوقت المقدر',
      'duration': 'المدة',
      'distance': 'المسافة',
      'route': 'المسار',
      'routes': 'المسارات',
      'no_trips': 'لا توجد رحلات',
      'upcoming_trips': 'الرحلات القادمة',
      'past_trips': 'الرحلات السابقة',
      'active_trips': 'الرحلات النشطة',
      'live_tracking': 'التتبع المباشر',
      'track_trip': 'تتبع الرحلة',
      'planned': 'مخططة',
      'ongoing': 'جارية',
      'draft': 'مسودة',
      'clear_filters': 'مسح الفلاتر',
      'create_new_trip': 'إنشاء رحلة جديدة',
      'search_trip': 'ابحث عن رحلة/سائق/مركبة...',
      'no_trips_for_day': 'لا توجد رحلات مجدولة لهذا اليوم',
      'no_results_matching': 'لا توجد نتائج مطابقة',
      'no_results_for_filters': 'لا توجد نتائج مطابقة للفلاتر',
      'advanced_filters': 'فلترة متقدمة',
      'trip_type': 'نوع الرحلة',
      'with_driver': 'بسائق',
      'with_vehicle': 'بمركبة',
      'with_gps': 'مع GPS',
      'only_with_driver': 'فقط الرحلات التي لها سائق',
      'only_with_vehicle': 'فقط الرحلات التي لها مركبة',
      'only_with_gps': 'فقط الرحلات التي لديها GPS',
      'select_date': 'اختيار التاريخ',
      'companion': 'المرافق',
      'no_companion': 'بدون مرافق',
      'status_and_time': 'الحالة والوقت',
      'driver_and_vehicle': 'السائق والمركبة',
      'not_assigned': 'لم يتم التعيين',
      'plate_number': 'رقم اللوحة',
      'started_actually': 'بدأت فعلياً',
      'ended_actually': 'انتهت فعلياً',
      'are_you_sure_start': 'هل تريد بدء هذه الرحلة الآن؟',
      'are_you_sure_end': 'هل تريد إنهاء هذه الرحلة؟',
      'are_you_sure_cancel':
          'هل أنت متأكد من إلغاء هذه الرحلة؟ لا يمكن التراجع عن هذا الإجراء.',
      'trip_started': 'تم بدء الرحلة',
      'trip_ended': 'تم إنهاء الرحلة',
      'trip_cancelled': 'تم إلغاء الرحلة',
      'failed_to_start': 'فشل بدء الرحلة',
      'failed_to_end': 'فشل إنهاء الرحلة',
      'failed_to_cancel': 'فشل إلغاء الرحلة',
      'back_to_trips': 'العودة للرحلات',
      'trip_not_found': 'الرحلة غير موجودة',
      'generate_from_group': 'من مجموعة',
      'manual_trip': 'رحلة يدوية',
      'generate_trips': 'توليد الرحلات',
      'generate_trips_from_group': 'توليد رحلات من مجموعة',
      'select_group_to_generate':
          'اختر مجموعة موجودة لتوليد الرحلات تلقائياً بناءً على جداولها المحددة',
      'create_manual_trip': 'إنشاء رحلة يدوياً',
      'create_manual_trip_desc':
          'قم بتحديد تفاصيل الرحلة يدوياً بدون الاعتماد على جدول مجموعة',
      'basic_info': 'المعلومات الأساسية',
      'trip_name': 'اسم الرحلة',
      'trip_name_example': 'مثال: رحلة الصباح - المنطقة الشمالية',
      'generation_options': 'خيارات التوليد',
      'weeks_to_generate': 'عدد الأسابيع للتوليد',
      'will_generate_trips': 'سيتم توليد الرحلات لـ',
      'weeks_ahead': 'قادمة بناءً على جداول المجموعة',
      'week': 'أسبوع',
      'generating': 'جاري التوليد...',
      'creating': 'جاري الإنشاء...',
      'no_active_groups': 'لا توجد مجموعات نشطة. قم بإنشاء مجموعة أولاً.',
      'no_drivers_available': 'لا توجد سائقين متاحين',
      'trips_generated_successfully': 'تم توليد الرحلات بنجاح',
      'view_all_trips': 'عرض جميع الرحلات',
      'generated_trips': 'الرحلات المولدة',
      'and_more': 'و',
      'more_trips': 'رحلة أخرى...',
      'no_trips_generated':
          'لم يتم توليد أي رحلات. تأكد من وجود جداول للمجموعة.',
      'companion_optional': 'المرافق (اختياري)',
      'select_companion': 'اختر المرافق',
      'select_driver': 'اختر السائق',
      'select_group': 'اختر المجموعة',
      'select_vehicle': 'اختر المركبة',
      'no_group': 'بدون مجموعة',
      'no_vehicle': 'بدون مركبة',
      'no_license_plate': 'بدون لوحة',
      'please_select_driver': 'يرجى اختيار السائق',
      'failed_to_load_groups': 'فشل في تحميل المجموعات',
      'error_creating_trip': 'خطأ في إنشاء الرحلة',
      'cannot_access_trip_repository': 'لا يمكن الوصول إلى مستودع الرحلات',

      // Passengers
      'passengers': 'الركاب',
      'passengers_management': 'إدارة الركاب',
      'passenger': 'راكب',
      'passenger_details': 'تفاصيل الراكب',
      'add_passenger': 'إضافة راكب',
      'edit_passenger': 'تعديل الراكب',
      'remove_passenger': 'إزالة الراكب',
      'passenger_count': 'عدد الركاب',
      'passenger_list': 'قائمة الركاب',
      'no_passengers': 'لا يوجد ركاب',
      'board_passenger': 'صعود الراكب',
      'drop_passenger': 'نزول الراكب',
      'boarding': 'صعود',
      'boarded': 'صعد',
      'dropped': 'نزل',
      'not_boarded': 'لم يصعد',
      'absent': 'غائب',
      'present': 'حاضر',
      'all_passengers': 'جميع الركاب',
      'unassigned': 'غير مدرجين',
      'by_groups': 'حسب المجموعات',
      'distribution_board': 'لوحة التوزيع',
      'search_all_passengers': 'ابحث في جميع الركاب...',
      'search_unassigned': 'ابحث في غير المدرجين...',
      'search_group': 'ابحث عن مجموعة...',
      'quick_search_board': 'بحث سريع في اللوحة...',
      'add_new_passenger': 'إضافة راكب جديد',
      'no_matching_results': 'لا توجد نتائج مطابقة',
      'no_passengers_in_system': 'لا يوجد ركاب في النظام.',
      'all_assigned_to_groups': 'كل الركاب الحاليين مرتبطين بمجموعات.',
      'create_group_first': 'أنشئ مجموعة أولاً ثم أضف الركّاب.',
      'move_to_group': 'نقل إلى مجموعة',
      'move': 'نقل',
      'assign': 'تعيين',
      'empty': 'فارغ',
      'pickup': 'صعود',
      'dropoff': 'نزول',
      'edit_profile': 'تعديل الملف الشخصي',
      'change_location': 'تغيير الموقع',
      'mark_absent': 'تسجيل غياب',
      'cannot_connect_server': 'لا يمكن الاتصال بالخادم',
      'absence_recorded': 'تم تسجيل غياب',
      'in': 'في',
      'absence_failed': 'فشل تسجيل الغياب',
      'father': 'الأب',
      'mother': 'الأم',
      'no_groups_available': 'لا توجد مجموعات متاحة',

      // Vehicles
      'vehicles': 'المركبات',
      'vehicles_management': 'إدارة المركبات',
      'vehicle': 'مركبة',
      'vehicle_details': 'تفاصيل المركبة',
      'add_vehicle': 'إضافة مركبة',
      'edit_vehicle': 'تعديل المركبة',
      'vehicle_number': 'رقم المركبة',
      'license_plate': 'لوحة الترخيص',
      'vehicle_type': 'نوع المركبة',
      'capacity': 'السعة',
      'seats': 'المقاعد',
      'available_seats': 'المقاعد المتاحة',
      'no_vehicles': 'لا توجد مركبات',
      'bus': 'حافلة',
      'van': 'فان',
      'car': 'سيارة',

      // Groups
      'groups': 'المجموعات',
      'groups_management': 'إدارة المجموعات',
      'group': 'مجموعة',
      'group_details': 'تفاصيل المجموعة',
      'create_group': 'إنشاء مجموعة',
      'edit_group': 'تعديل المجموعة',
      'group_name': 'اسم المجموعة',
      'group_members': 'أعضاء المجموعة',
      'add_to_group': 'إضافة إلى المجموعة',
      'remove_from_group': 'إزالة من المجموعة',
      'no_groups': 'لا توجد مجموعات',
      'schedules': 'الجداول',
      'schedule': 'جدول',
      'new_group': 'مجموعة جديدة',
      'search_group_hint': 'ابحث عن مجموعة...',
      'active_only': 'نشطة فقط',
      'with_destination': 'لها وجهة',
      'linked_to_driver': 'مرتبطة بسائق',
      'linked_to_vehicle': 'مرتبطة بمركبة',
      'has_destination': 'لها وجهة',
      'group_filters': 'فلترة المجموعات',
      'showing_of': 'عرض',
      'of_text': 'من',
      'no_groups_found': 'لا توجد مجموعات',
      'no_matching_search': 'لم يتم العثور على نتائج للبحث',
      'no_groups_created': 'لم يتم إنشاء أي مجموعة بعد',
      'generate_trip': 'توليد رحلة',
      'manage_schedules': 'إدارة الجداول',
      'view_passengers': 'عرض الركاب',
      'delete_group': 'حذف المجموعة',
      'delete_group_title': 'حذف المجموعة',
      'delete_group_confirm':
          'هل أنت متأكد من حذف مجموعة "{name}"؟\n\nهذه العملية لا يمكن التراجع عنها.',
      'group_deleted': 'تم حذف المجموعة "{name}" بنجاح',
      'failed_to_delete_group': 'تعذر حذف المجموعة، حاول مرة أخرى',
      'passenger_singular': 'راكب',
      'both_pickup_dropoff': 'صعود ونزول',

      // Stops
      'stops': 'المحطات',
      'stop': 'محطة',
      'stop_details': 'تفاصيل المحطة',
      'add_stop': 'إضافة محطة',
      'edit_stop': 'تعديل المحطة',
      'stop_name': 'اسم المحطة',
      'stop_order': 'ترتيب المحطة',
      'pickup_stop': 'محطة الركوب',
      'dropoff_stop': 'محطة النزول',
      'no_stops': 'لا توجد محطات',

      // Driver
      'driver': 'السائق',
      'drivers': 'السائقون',
      'driver_details': 'تفاصيل السائق',
      'assign_driver': 'تعيين سائق',
      'driver_name': 'اسم السائق',
      'driving': 'قيادة',
      'driver_home': 'صفحة السائق',
      'start_driving': 'بدء القيادة',
      'stop_driving': 'إيقاف القيادة',

      // Dispatcher
      'dispatcher': 'المنسق',
      'dispatchers': 'المنسقون',
      'dispatch': 'تنسيق',
      'dispatcher_home': 'صفحة المنسق',
      'assign_trip': 'تعيين رحلة',

      // Manager
      'manager': 'المدير',
      'managers': 'المديرون',
      'manager_home': 'صفحة المدير',
      'manager_dashboard': 'لوحة تحكم المدير',

      // Guardian
      'guardian': 'ولي الأمر',
      'guardians': 'أولياء الأمور',
      'guardian_home': 'صفحة ولي الأمر',
      'my_children': 'أطفالي',
      'child': 'طفل',
      'children': 'أطفال',

      // Map
      'map': 'خريطة',
      'maps': 'خرائط',
      'view_on_map': 'عرض على الخريطة',
      'current_location': 'الموقع الحالي',
      'get_directions': 'الحصول على الاتجاهات',
      'navigation': 'الملاحة',

      // Time & Date
      'minutes': 'دقائق',
      'hours': 'ساعات',
      'days': 'أيام',
      'weeks': 'أسابيع',
      'months': 'أشهر',
      'years': 'سنوات',
      'ago': 'منذ',
      'in_future': 'بعد',
      'just_now': 'الآن',
      'morning': 'صباحاً',
      'afternoon': 'ظهراً',
      'evening': 'مساءً',
      'night': 'ليلاً',
      'monday': 'الإثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
      'saturday': 'السبت',
      'sunday': 'الأحد',
      'per_trip': 'لكل رحلة',
      'monthly': 'شهرياً',
      'per_term': 'لكل فصل',
      'billing_cycle': 'دورة الفوترة',

      // Holidays
      'holidays': 'العطل',
      'holiday': 'عطلة',
      'add_holiday': 'إضافة عطلة',
      'edit_holiday': 'تعديل العطلة',
      'holiday_name': 'اسم العطلة',
      'holiday_date': 'تاريخ العطلة',
      'no_holidays': 'لا توجد عطل',

      // Reports
      'generate_report': 'إنشاء تقرير',
      'export_pdf': 'تصدير PDF',
      'export_excel': 'تصدير Excel',
      'daily_report': 'تقرير يومي',
      'weekly_report': 'تقرير أسبوعي',
      'monthly_report': 'تقرير شهري',

      // Stats
      'statistics': 'الإحصائيات',
      'stats': 'إحصائيات',
      'today_statistics': 'إحصائيات اليوم',
      'total_trips': 'إجمالي الرحلات',
      'total_trips_today': 'إجمالي الرحلات',
      'total_passengers': 'إجمالي الركاب',
      'total_vehicles': 'إجمالي المركبات',
      'total_distance': 'إجمالي المسافة',
      'average': 'المتوسط',
      'performance': 'الأداء',
      'efficiency': 'الكفاءة',
      'fleet_status': 'حالة الأسطول',
      'fleet_utilization': 'معدل استخدام الأسطول',
      'fleet_in_use': 'من الأسطول قيد الاستخدام',
      'active_vehicles': 'المركبات النشطة',
      'active_drivers': 'السائقين النشطين',
      'ongoing_trips': 'رحلات جارية',
      'live_monitoring': 'المراقبة الحية',
      'active_trips_now': 'رحلة نشطة الآن',
      'view_sync_status': 'عرض حالة المزامنة',

      // Companies
      'company': 'الشركة',
      'companies': 'الشركات',
      'current_company': 'الشركة الحالية',
      'switch_company': 'تبديل الشركة',
      'multi_company': 'شركات متعددة',

      // Permissions & Roles
      'permissions': 'الصلاحيات',
      'roles': 'الأدوار',
      'admin': 'مدير',
      'user': 'مستخدم',
      'access_denied': 'الوصول مرفوض',

      // Biometric
      'biometric_auth': 'المصادقة البيومترية',
      'enable_biometric': 'تمكين المصادقة البيومترية',
      'use_fingerprint': 'استخدام البصمة',
      'use_face_id': 'استخدام التعرف على الوجه',

      // Camera & Files
      'camera': 'الكاميرا',
      'gallery': 'المعرض',
      'pick_image': 'اختر صورة',
      'pick_file': 'اختر ملف',
      'upload_file': 'رفع ملف',
      'download_file': 'تنزيل ملف',
      'file_manager': 'مدير الملفات',

      // Confirmation dialogs
      'are_you_sure': 'هل أنت متأكد؟',
      'confirm_delete': 'هل أنت متأكد من الحذف؟',
      'confirm_cancel': 'هل أنت متأكد من الإلغاء؟',
      'confirm_logout': 'هل أنت متأكد من تسجيل الخروج؟',
      'changes_not_saved': 'لم يتم حفظ التغييرات',
      'discard_changes': 'تجاهل التغييرات؟',

      // Success messages
      'saved_successfully': 'تم الحفظ بنجاح',
      'deleted_successfully': 'تم الحذف بنجاح',
      'updated_successfully': 'تم التحديث بنجاح',
      'created_successfully': 'تم الإنشاء بنجاح',
      'operation_successful': 'تمت العملية بنجاح',

      // Onboarding
      'get_started': 'ابدأ',
      'welcome_to_app': 'مرحباً بك في شاتل بي',
      'onboarding_title_1': 'تتبع رحلاتك',
      'onboarding_title_2': 'تحديثات فورية',
      'onboarding_title_3': 'آمن وموثوق',
      'onboarding_desc_1': 'راقب جميع أنشطة النقل في مكان واحد',
      'onboarding_desc_2': 'احصل على إشعارات فورية عن حالة الرحلة',
      'onboarding_desc_3': 'ضمان نقل آمن للجميع',

      // Validation
      'field_required': 'هذا الحقل مطلوب',
      'invalid_email': 'عنوان البريد الإلكتروني غير صالح',
      'password_too_short': 'كلمة المرور قصيرة جداً',
      'passwords_dont_match': 'كلمات المرور غير متطابقة',
      'invalid_phone': 'رقم الهاتف غير صالح',
      'invalid_input': 'إدخال غير صالح',

      // Misc
      'real_time_updates': 'التحديثات الفورية',
      'connected': 'متصل',
      'audit_trail': 'سجل التدقيق',
      'form_builder': 'منشئ النماذج',
      'required_field': 'حقل مطلوب',
      'revenue': 'الإيرادات',
      'orders': 'الطلبات',
      'customers': 'العملاء',
      'sales_overview': 'نظرة عامة على المبيعات',
      'orders_by_status': 'الطلبات حسب الحالة',

      // Role Switcher
      'view_as': 'عرض كـ',
      'original': 'الأصلي',
      'original_role': 'الدور الأصلي',
      'return': 'العودة',
      'you_are_viewing_as': 'أنت تعرض التطبيق كـ',
      'switched_to_view': 'تم التبديل إلى عرض',
      'returned_to_view': 'تم العودة إلى عرض',
      'switch_role': 'تبديل الدور',
    },
    'fr': {
      // App
      'app_name': 'ShuttleBee',
      'app_title': 'ShuttleBee Transport',

      // General
      'loading': 'Chargement...',
      'error': 'Erreur',
      'success': 'Succès',
      'cancel': 'Annuler',
      'confirm': 'Confirmer',
      'save': 'Enregistrer',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'close': 'Fermer',
      'search': 'Rechercher',
      'retry': 'Réessayer',
      'yes': 'Oui',
      'no': 'Non',
      'ok': 'OK',
      'add': 'Ajouter',
      'update': 'Mettre à jour',
      'create': 'Créer',
      'view': 'Voir',
      'back': 'Retour',
      'next': 'Suivant',
      'previous': 'Précédent',
      'done': 'Terminé',
      'skip': 'Passer',
      'continue_text': 'Continuer',
      'submit': 'Soumettre',
      'select': 'Sélectionner',
      'select_all': 'Tout sélectionner',
      'clear': 'Effacer',
      'clear_all': 'Tout effacer',
      'refresh': 'Actualiser',
      'filter': 'Filtrer',
      'filters': 'Filtres',
      'sort': 'Trier',
      'sort_by': 'Trier par',
      'ascending': 'Croissant',
      'descending': 'Décroissant',
      'apply': 'Appliquer',
      'reset': 'Réinitialiser',
      'more': 'Plus',
      'less': 'Moins',
      'show_more': 'Afficher plus',
      'show_less': 'Afficher moins',
      'details': 'Détails',
      'info': 'Info',
      'warning': 'Avertissement',
      'required': 'Obligatoire',
      'optional': 'Optionnel',
      'actions': 'Actions',
      'options': 'Options',
      'all': 'Tout',
      'none': 'Aucun',
      'active': 'Actif',
      'inactive': 'Inactif',
      'enabled': 'Activé',
      'disabled': 'Désactivé',
      'header': 'En-tête',
      'footer': 'Pied de page',
      'status': 'Statut',
      'name': 'Nom',
      'description': 'Description',
      'date': 'Date',
      'time': 'Heure',
      'start': 'Début',
      'end': 'Fin',
      'from': 'De',
      'to': 'À',
      'today': "Aujourd'hui",
      'yesterday': 'Hier',
      'tomorrow': 'Demain',
      'now': 'Maintenant',
      'total': 'Total',
      'count': 'Nombre',
      'amount': 'Montant',
      'note': 'Note',
      'notes': 'Notes',
      'comment': 'Commentaire',
      'comments': 'Commentaires',
      'message': 'Message',
      'copy': 'Copier',
      'copied': 'Copié',
      'share': 'Partager',
      'download': 'Télécharger',
      'upload': 'Téléverser',
      'export': 'Exporter',
      'import': 'Importer',
      'print': 'Imprimer',
      'help': 'Aide',
      'about': 'À propos',
      'contact': 'Contact',
      'phone': 'Téléphone',
      'address': 'Adresse',
      'location': 'Emplacement',

      // Auth
      'login': 'Connexion',
      'logout': 'Déconnexion',
      'sign_in': 'Se connecter',
      'sign_out': 'Se déconnecter',
      'sign_up': "S'inscrire",
      'register': "S'enregistrer",
      'email': 'Email',
      'password': 'Mot de passe',
      'confirm_password': 'Confirmer le mot de passe',
      'username': "Nom d'utilisateur",
      'server_url': 'URL du serveur',
      'database': 'Base de données',
      'remember_me': 'Se souvenir de moi',
      'forgot_password': 'Mot de passe oublié?',
      'reset_password': 'Réinitialiser le mot de passe',
      'change_password': 'Changer le mot de passe',
      'login_success': 'Connexion réussie',
      'login_failed': 'Échec de la connexion',
      'invalid_credentials': "Nom d'utilisateur ou mot de passe invalide",
      'logout_confirm': 'Êtes-vous sûr de vouloir vous déconnecter?',
      'select_company': 'Sélectionner une entreprise',
      'welcome_back': 'Bon retour',
      'session_expired': 'Session expirée, veuillez vous reconnecter',

      // Home & Navigation
      'home': 'Accueil',
      'dashboard': 'Tableau de bord',
      'welcome': 'Bienvenue',
      'quick_actions': 'Actions rapides',
      'recent_activities': 'Activités récentes',
      'overview': 'Vue d\'ensemble',
      'analytics': 'Analyses',
      'reports': 'Rapports',
      'monitor': 'Surveiller',
      'monitoring': 'Surveillance',

      // Settings
      'settings': 'Paramètres',
      'profile': 'Profil',
      'account': 'Compte',
      'preferences': 'Préférences',
      'appearance': 'Apparence',
      'language': 'Langue',
      'theme': 'Thème',
      'light': 'Clair',
      'dark': 'Sombre',
      'system': 'Système',
      'light_mode': 'Mode clair',
      'dark_mode': 'Mode sombre',
      'system_default': 'Par défaut du système',

      // Number & Date Format Settings
      'number_format': 'Format des nombres',
      'numeral_system': 'Système numérique',
      'western_numerals': 'Chiffres occidentaux (0-9)',
      'arabic_numerals': 'Chiffres arabes (٠-٩)',
      'date_format': 'Format de date',
      'date_format_short': 'Court',
      'date_format_medium': 'Moyen',
      'date_format_long': 'Long',
      'date_format_full': 'Complet',
      'date_format_short_example': '01/12/2024',
      'date_format_medium_example': '01 déc. 2024',
      'date_format_long_example': '01 décembre 2024',
      'date_format_full_example': 'dimanche 01 décembre 2024',
      'notifications_settings': 'Paramètres de notification',
      'privacy_security': 'Confidentialité et sécurité',
      'about_app': "À propos de l'application",
      'version': 'Version',
      'privacy_policy': 'Politique de confidentialité',
      'terms_of_service': "Conditions d'utilisation",
      'general': 'Général',

      // Offline & Sync
      'offline': 'Hors ligne',
      'online': 'En ligne',
      'offline_mode': 'Mode hors ligne',
      'sync': 'Synchroniser',
      'synced': 'Synchronisé',
      'syncing': 'Synchronisation...',
      'sync_complete': 'Synchronisation terminée',
      'sync_failed': 'Échec de la synchronisation',
      'sync_status': 'État de synchronisation',
      'pending_operations': 'Opérations en attente',
      'no_pending_operations': 'Aucune opération en attente',
      'last_sync': 'Dernière synchronisation',
      'offline_banner': 'Vous travaillez hors ligne',
      'data_saved_offline': 'Données sauvegardées localement',
      'will_sync_when_online': 'Sera synchronisé en ligne',
      'cache_management': 'Gestion du cache',
      'clear_cache': 'Vider le cache',
      'online_now': 'En ligne maintenant',

      // Notifications
      'notifications': 'Notifications',
      'no_notifications': 'Aucune notification',
      'mark_all_read': 'Tout marquer comme lu',
      'new_notification': 'Nouvelle notification',
      'notification_settings': 'Paramètres de notification',
      'push_notifications': 'Notifications push',
      'email_notifications': 'Notifications par email',

      // Search
      'search_placeholder': 'Rechercher...',
      'no_results': 'Aucun résultat trouvé',
      'recent_searches': 'Recherches récentes',
      'search_results': 'Résultats de recherche',
      'search_for': 'Rechercher',
      'voice_search': 'Recherche vocale',

      // Errors
      'error_generic': "Une erreur s'est produite",
      'error_network': 'Erreur réseau',
      'error_server': 'Erreur serveur',
      'error_timeout': 'Délai de connexion expiré',
      'error_no_connection': 'Pas de connexion internet',
      'error_unauthorized': 'Accès non autorisé',
      'error_not_found': 'Non trouvé',
      'error_validation': 'Erreur de validation',
      'try_again': 'Réessayer',
      'something_went_wrong': "Quelque chose s'est mal passé",

      // Empty States
      'empty_data': 'Aucune donnée disponible',
      'empty_list': 'La liste est vide',
      'no_items': 'Aucun élément',
      'no_data': 'Aucune donnée',
      'nothing_here': 'Rien ici pour le moment',

      // Trips
      'trips': 'Trajets',
      'trips_management': 'Gestion des Trajets',
      'trip': 'Trajet',
      'trip_details': 'Détails du trajet',
      'create_trip': 'Créer un trajet',
      'edit_trip': 'Modifier le trajet',
      'start_trip': 'Démarrer le trajet',
      'end_trip': 'Terminer le trajet',
      'cancel_trip': 'Annuler le trajet',
      'trip_history': 'Historique des trajets',
      'trip_status': 'Statut du trajet',
      'scheduled': 'Planifié',
      'in_progress': 'En cours',
      'completed': 'Terminé',
      'cancelled': 'Annulé',
      'pending': 'En attente',
      'departure': 'Départ',
      'arrival': 'Arrivée',
      'departure_time': 'Heure de départ',
      'arrival_time': "Heure d'arrivée",
      'estimated_time': 'Temps estimé',
      'duration': 'Durée',
      'distance': 'Distance',
      'route': 'Itinéraire',
      'routes': 'Itinéraires',
      'no_trips': 'Aucun trajet',
      'upcoming_trips': 'Trajets à venir',
      'past_trips': 'Trajets passés',
      'active_trips': 'Trajets actifs',
      'live_tracking': 'Suivi en direct',
      'track_trip': 'Suivre le trajet',
      'planned': 'Planifié',
      'ongoing': 'En cours',
      'draft': 'Brouillon',
      'clear_filters': 'Effacer les filtres',
      'create_new_trip': 'Créer un nouveau trajet',
      'search_trip': 'Rechercher un trajet/chauffeur/véhicule...',
      'no_trips_for_day': 'Aucun trajet prévu pour ce jour',
      'no_results_matching': 'Aucun résultat correspondant',
      'no_results_for_filters': 'Aucun résultat correspondant aux filtres',
      'advanced_filters': 'Filtres avancés',
      'trip_type': 'Type de trajet',
      'with_driver': 'Avec chauffeur',
      'with_vehicle': 'Avec véhicule',
      'with_gps': 'Avec GPS',
      'only_with_driver': 'Seulement les trajets avec un chauffeur',
      'only_with_vehicle': 'Seulement les trajets avec un véhicule',
      'only_with_gps': 'Seulement les trajets avec GPS',
      'select_date': 'Sélectionner la date',
      'companion': 'Accompagnateur',
      'no_companion': 'Sans accompagnateur',
      'status_and_time': 'Statut & Heure',
      'driver_and_vehicle': 'Chauffeur & Véhicule',
      'not_assigned': 'Non assigné',
      'plate_number': "Numéro de plaque",
      'started_actually': 'Commencé effectivement',
      'ended_actually': 'Terminé effectivement',
      'are_you_sure_start': 'Voulez-vous démarrer ce trajet maintenant?',
      'are_you_sure_end': 'Voulez-vous terminer ce trajet?',
      'are_you_sure_cancel':
          'Êtes-vous sûr de vouloir annuler ce trajet? Cette action ne peut pas être annulée.',
      'trip_started': 'Trajet démarré',
      'trip_ended': 'Trajet terminé',
      'trip_cancelled': 'Trajet annulé',
      'failed_to_start': 'Échec du démarrage du trajet',
      'failed_to_end': 'Échec de la fin du trajet',
      'failed_to_cancel': "Échec de l'annulation du trajet",
      'back_to_trips': 'Retour aux trajets',
      'trip_not_found': 'Trajet non trouvé',
      'generate_from_group': 'Depuis un groupe',
      'manual_trip': 'Trajet manuel',
      'generate_trips': 'Générer des trajets',
      'generate_trips_from_group': 'Générer des trajets depuis un groupe',
      'select_group_to_generate':
          'Sélectionnez un groupe existant pour générer automatiquement des trajets basés sur ses horaires',
      'create_manual_trip': 'Créer un trajet manuellement',
      'create_manual_trip_desc':
          'Spécifiez manuellement les détails du trajet sans dépendre d\'un horaire de groupe',
      'basic_info': 'Informations de base',
      'trip_name': 'Nom du trajet',
      'trip_name_example': 'Exemple: Trajet du matin - Zone Nord',
      'generation_options': 'Options de génération',
      'weeks_to_generate': 'Semaines à générer',
      'will_generate_trips': 'Générera des trajets pour',
      'weeks_ahead': 'semaines à venir basés sur les horaires du groupe',
      'week': 'semaine',
      'generating': 'Génération...',
      'creating': 'Création...',
      'no_active_groups': 'Aucun groupe actif. Créez d\'abord un groupe.',
      'no_drivers_available': 'Aucun chauffeur disponible',
      'trips_generated_successfully': 'trajets générés avec succès',
      'view_all_trips': 'Voir tous les trajets',
      'generated_trips': 'Trajets générés',
      'and_more': 'et',
      'more_trips': 'trajets de plus...',
      'no_trips_generated':
          'Aucun trajet généré. Assurez-vous que le groupe a des horaires.',
      'companion_optional': 'Accompagnateur (Optionnel)',
      'select_companion': 'Sélectionner un accompagnateur',
      'select_driver': 'Sélectionner le chauffeur',
      'select_group': 'Sélectionner le groupe',
      'select_vehicle': 'Sélectionner le véhicule',
      'no_group': 'Aucun groupe',
      'no_vehicle': 'Aucun véhicule',
      'no_license_plate': 'Aucune plaque',
      'please_select_driver': 'Veuillez sélectionner un chauffeur',
      'failed_to_load_groups': 'Échec du chargement des groupes',
      'error_creating_trip': 'Erreur lors de la création du trajet',
      'cannot_access_trip_repository':
          'Impossible d\'accéder au référentiel de trajets',

      // Passengers
      'passengers': 'Passagers',
      'passengers_management': 'Gestion des Passagers',
      'passenger': 'Passager',
      'passenger_details': 'Détails du passager',
      'add_passenger': 'Ajouter un passager',
      'edit_passenger': 'Modifier le passager',
      'remove_passenger': 'Retirer le passager',
      'passenger_count': 'Nombre de passagers',
      'passenger_list': 'Liste des passagers',
      'no_passengers': 'Aucun passager',
      'board_passenger': 'Embarquer le passager',
      'drop_passenger': 'Déposer le passager',
      'boarding': 'Embarquement',
      'boarded': 'Embarqué',
      'dropped': 'Déposé',
      'not_boarded': 'Non embarqué',
      'absent': 'Absent',
      'present': 'Présent',
      'all_passengers': 'Tous les passagers',
      'unassigned': 'Non assignés',
      'by_groups': 'Par groupes',
      'distribution_board': 'Tableau de distribution',
      'search_all_passengers': 'Rechercher tous les passagers...',
      'search_unassigned': 'Rechercher non assignés...',
      'search_group': 'Rechercher un groupe...',
      'quick_search_board': 'Recherche rapide dans le tableau...',
      'add_new_passenger': 'Ajouter un nouveau passager',
      'no_matching_results': 'Aucun résultat correspondant',
      'no_passengers_in_system': 'Aucun passager dans le système.',
      'all_assigned_to_groups':
          'Tous les passagers actuels sont assignés à des groupes.',
      'create_group_first':
          "Créez d'abord un groupe puis ajoutez des passagers.",
      'move_to_group': 'Déplacer vers un groupe',
      'move': 'Déplacer',
      'assign': 'Assigner',
      'empty': 'Vide',
      'pickup': 'Embarquement',
      'dropoff': 'Débarquement',
      'edit_profile': 'Modifier le profil',
      'change_location': 'Changer l\'emplacement',
      'mark_absent': 'Marquer absent',
      'cannot_connect_server': 'Impossible de se connecter au serveur',
      'absence_recorded': 'Absence enregistrée pour',
      'in': 'dans',
      'absence_failed': 'Échec de l\'enregistrement de l\'absence',
      'father': 'Père',
      'mother': 'Mère',
      'no_groups_available': 'Aucun groupe disponible',

      // Vehicles
      'vehicles': 'Véhicules',
      'vehicles_management': 'Gestion des Véhicules',
      'vehicle': 'Véhicule',
      'vehicle_details': 'Détails du véhicule',
      'add_vehicle': 'Ajouter un véhicule',
      'edit_vehicle': 'Modifier le véhicule',
      'vehicle_number': 'Numéro du véhicule',
      'license_plate': "Plaque d'immatriculation",
      'vehicle_type': 'Type de véhicule',
      'capacity': 'Capacité',
      'seats': 'Places',
      'available_seats': 'Places disponibles',
      'no_vehicles': 'Aucun véhicule',
      'bus': 'Bus',
      'van': 'Fourgon',
      'car': 'Voiture',

      // Groups
      'groups': 'Groupes',
      'groups_management': 'Gestion des Groupes',
      'group': 'Groupe',
      'group_details': 'Détails du groupe',
      'create_group': 'Créer un groupe',
      'edit_group': 'Modifier le groupe',
      'group_name': 'Nom du groupe',
      'group_members': 'Membres du groupe',
      'add_to_group': 'Ajouter au groupe',
      'remove_from_group': 'Retirer du groupe',
      'no_groups': 'Aucun groupe',
      'schedules': 'Horaires',
      'schedule': 'Horaire',
      'new_group': 'Nouveau groupe',
      'search_group_hint': 'Rechercher un groupe...',
      'active_only': 'Actifs seulement',
      'with_destination': 'Avec destination',
      'linked_to_driver': 'Lié à un chauffeur',
      'linked_to_vehicle': 'Lié à un véhicule',
      'has_destination': 'A une destination',
      'group_filters': 'Filtres de groupes',
      'showing_of': 'Affichage de',
      'of_text': 'sur',
      'no_groups_found': 'Aucun groupe trouvé',
      'no_matching_search': 'Aucun résultat correspondant à la recherche',
      'no_groups_created': 'Aucun groupe créé pour le moment',
      'generate_trip': 'Générer un trajet',
      'manage_schedules': 'Gérer les horaires',
      'view_passengers': 'Voir les passagers',
      'delete_group': 'Supprimer le groupe',
      'delete_group_title': 'Supprimer le groupe',
      'delete_group_confirm':
          'Êtes-vous sûr de vouloir supprimer le groupe "{name}"?\n\nCette action ne peut pas être annulée.',
      'group_deleted': 'Groupe "{name}" supprimé avec succès',
      'failed_to_delete_group': 'Échec de la suppression du groupe, réessayez',
      'passenger_singular': 'passager',
      'both_pickup_dropoff': 'Embarquement & Débarquement',

      // Stops
      'stops': 'Arrêts',
      'stop': 'Arrêt',
      'stop_details': "Détails de l'arrêt",
      'add_stop': 'Ajouter un arrêt',
      'edit_stop': "Modifier l'arrêt",
      'stop_name': "Nom de l'arrêt",
      'stop_order': "Ordre de l'arrêt",
      'pickup_stop': 'Arrêt de prise en charge',
      'dropoff_stop': 'Arrêt de dépôt',
      'no_stops': 'Aucun arrêt',

      // Driver
      'driver': 'Chauffeur',
      'drivers': 'Chauffeurs',
      'driver_details': 'Détails du chauffeur',
      'assign_driver': 'Assigner un chauffeur',
      'driver_name': 'Nom du chauffeur',
      'driving': 'Conduite',
      'driver_home': 'Accueil chauffeur',
      'start_driving': 'Commencer à conduire',
      'stop_driving': 'Arrêter de conduire',

      // Dispatcher
      'dispatcher': 'Répartiteur',
      'dispatchers': 'Répartiteurs',
      'dispatch': 'Répartition',
      'dispatcher_home': 'Accueil répartiteur',
      'assign_trip': 'Assigner un trajet',

      // Manager
      'manager': 'Gestionnaire',
      'managers': 'Gestionnaires',
      'manager_home': 'Accueil gestionnaire',
      'manager_dashboard': 'Tableau de bord gestionnaire',

      // Guardian
      'guardian': 'Tuteur',
      'guardians': 'Tuteurs',
      'guardian_home': 'Accueil tuteur',
      'my_children': 'Mes enfants',
      'child': 'Enfant',
      'children': 'Enfants',

      // Map
      'map': 'Carte',
      'maps': 'Cartes',
      'view_on_map': 'Voir sur la carte',
      'current_location': 'Position actuelle',
      'get_directions': 'Obtenir un itinéraire',
      'navigation': 'Navigation',

      // Time & Date
      'minutes': 'minutes',
      'hours': 'heures',
      'days': 'jours',
      'weeks': 'semaines',
      'months': 'mois',
      'years': 'ans',
      'ago': 'il y a',
      'in_future': 'dans',
      'just_now': "À l'instant",
      'morning': 'Matin',
      'afternoon': 'Après-midi',
      'evening': 'Soir',
      'night': 'Nuit',
      'monday': 'Lundi',
      'tuesday': 'Mardi',
      'wednesday': 'Mercredi',
      'thursday': 'Jeudi',
      'friday': 'Vendredi',
      'saturday': 'Samedi',
      'sunday': 'Dimanche',
      'per_trip': 'Par trajet',
      'monthly': 'Mensuel',
      'per_term': 'Par trimestre',
      'billing_cycle': 'Cycle de facturation',

      // Holidays
      'holidays': 'Vacances',
      'holiday': 'Vacance',
      'add_holiday': 'Ajouter une vacance',
      'edit_holiday': 'Modifier la vacance',
      'holiday_name': 'Nom de la vacance',
      'holiday_date': 'Date de la vacance',
      'no_holidays': 'Aucune vacance',

      // Reports
      'generate_report': 'Générer un rapport',
      'export_pdf': 'Exporter en PDF',
      'export_excel': 'Exporter en Excel',
      'daily_report': 'Rapport quotidien',
      'weekly_report': 'Rapport hebdomadaire',
      'monthly_report': 'Rapport mensuel',

      // Stats
      'statistics': 'Statistiques',
      'stats': 'Stats',
      'total_trips': 'Total des trajets',
      'total_passengers': 'Total des passagers',
      'total_vehicles': 'Total des véhicules',
      'total_distance': 'Distance totale',
      'average': 'Moyenne',
      'performance': 'Performance',
      'efficiency': 'Efficacité',

      // Companies
      'company': 'Entreprise',
      'companies': 'Entreprises',
      'current_company': 'Entreprise actuelle',
      'switch_company': "Changer d'entreprise",
      'multi_company': 'Multi-entreprises',

      // Permissions & Roles
      'permissions': 'Permissions',
      'roles': 'Rôles',
      'admin': 'Administrateur',
      'user': 'Utilisateur',
      'access_denied': 'Accès refusé',

      // Biometric
      'biometric_auth': 'Authentification biométrique',
      'enable_biometric': "Activer l'authentification biométrique",
      'use_fingerprint': "Utiliser l'empreinte digitale",
      'use_face_id': 'Utiliser Face ID',

      // Camera & Files
      'camera': 'Caméra',
      'gallery': 'Galerie',
      'pick_image': 'Choisir une image',
      'pick_file': 'Choisir un fichier',
      'upload_file': 'Téléverser un fichier',
      'download_file': 'Télécharger un fichier',
      'file_manager': 'Gestionnaire de fichiers',

      // Confirmation dialogs
      'are_you_sure': 'Êtes-vous sûr?',
      'confirm_delete': 'Êtes-vous sûr de vouloir supprimer?',
      'confirm_cancel': 'Êtes-vous sûr de vouloir annuler?',
      'confirm_logout': 'Êtes-vous sûr de vouloir vous déconnecter?',
      'changes_not_saved': 'Modifications non enregistrées',
      'discard_changes': 'Abandonner les modifications?',

      // Success messages
      'saved_successfully': 'Enregistré avec succès',
      'deleted_successfully': 'Supprimé avec succès',
      'updated_successfully': 'Mis à jour avec succès',
      'created_successfully': 'Créé avec succès',
      'operation_successful': 'Opération réussie',

      // Onboarding
      'get_started': 'Commencer',
      'welcome_to_app': 'Bienvenue sur ShuttleBee',
      'onboarding_title_1': 'Suivez vos trajets',
      'onboarding_title_2': 'Mises à jour en temps réel',
      'onboarding_title_3': 'Sûr et fiable',
      'onboarding_desc_1':
          'Surveillez toutes vos activités de transport en un seul endroit',
      'onboarding_desc_2':
          'Recevez des notifications instantanées sur le statut du trajet',
      'onboarding_desc_3': 'Assurez un transport sécurisé pour tous',

      // Validation
      'field_required': 'Ce champ est obligatoire',
      'invalid_email': 'Adresse email invalide',
      'password_too_short': 'Le mot de passe est trop court',
      'passwords_dont_match': 'Les mots de passe ne correspondent pas',
      'invalid_phone': 'Numéro de téléphone invalide',
      'invalid_input': 'Entrée invalide',

      // Misc
      'real_time_updates': 'Mises à jour en temps réel',
      'connected': 'Connecté',
      'disconnected': 'Déconnecté',
      'audit_trail': "Piste d'audit",
      'form_builder': 'Créateur de formulaires',
      'required_field': 'Champ obligatoire',
      'revenue': 'Revenu',
      'orders': 'Commandes',
      'customers': 'Clients',
      'sales_overview': 'Aperçu des ventes',
      'orders_by_status': 'Commandes par statut',
    },
  };

  /// Get translation
  String translate(String key) {
    return _translations[locale.languageCode]?[key] ??
        _translations['en']?[key] ??
        key;
  }

  // === Convenience Getters ===

  // App
  String get appName => translate('app_name');
  String get appTitle => translate('app_title');

  // General
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get cancel => translate('cancel');
  String get confirm => translate('confirm');
  String get save => translate('save');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get close => translate('close');
  String get search => translate('search');
  String get retry => translate('retry');
  String get yes => translate('yes');
  String get no => translate('no');
  String get ok => translate('ok');
  String get add => translate('add');
  String get update => translate('update');
  String get create => translate('create');
  String get view => translate('view');
  String get back => translate('back');
  String get next => translate('next');
  String get previous => translate('previous');
  String get done => translate('done');
  String get skip => translate('skip');
  String get continueText => translate('continue_text');
  String get submit => translate('submit');
  String get select => translate('select');
  String get selectAll => translate('select_all');
  String get clear => translate('clear');
  String get clearAll => translate('clear_all');
  String get refresh => translate('refresh');
  String get filter => translate('filter');
  String get filters => translate('filters');
  String get sort => translate('sort');
  String get sortBy => translate('sort_by');
  String get ascending => translate('ascending');
  String get descending => translate('descending');
  String get apply => translate('apply');
  String get reset => translate('reset');
  String get more => translate('more');
  String get less => translate('less');
  String get showMore => translate('show_more');
  String get showLess => translate('show_less');
  String get details => translate('details');
  String get info => translate('info');
  String get warning => translate('warning');
  String get required => translate('required');
  String get optional => translate('optional');
  String get actions => translate('actions');
  String get options => translate('options');
  String get all => translate('all');
  String get none => translate('none');
  String get active => translate('active');
  String get inactive => translate('inactive');
  String get enabled => translate('enabled');
  String get disabled => translate('disabled');
  String get status => translate('status');
  String get name => translate('name');
  String get description => translate('description');
  String get date => translate('date');
  String get time => translate('time');
  String get start => translate('start');
  String get end => translate('end');
  String get from => translate('from');
  String get to => translate('to');
  String get today => translate('today');
  String get yesterday => translate('yesterday');
  String get tomorrow => translate('tomorrow');
  String get now => translate('now');
  String get total => translate('total');
  String get count => translate('count');
  String get amount => translate('amount');
  String get note => translate('note');
  String get notes => translate('notes');
  String get comment => translate('comment');
  String get comments => translate('comments');
  String get message => translate('message');
  String get copy => translate('copy');
  String get copied => translate('copied');
  String get share => translate('share');
  String get download => translate('download');
  String get upload => translate('upload');
  String get exportText => translate('export');
  String get importText => translate('import');
  String get print => translate('print');
  String get help => translate('help');
  String get about => translate('about');
  String get contact => translate('contact');
  String get phone => translate('phone');
  String get address => translate('address');
  String get location => translate('location');
  String get header => translate('header');
  String get footer => translate('footer');

  // Auth
  String get login => translate('login');
  String get logout => translate('logout');
  String get signIn => translate('sign_in');
  String get signOut => translate('sign_out');
  String get signUp => translate('sign_up');
  String get register => translate('register');
  String get email => translate('email');
  String get password => translate('password');
  String get confirmPassword => translate('confirm_password');
  String get username => translate('username');
  String get serverUrl => translate('server_url');
  String get database => translate('database');
  String get rememberMe => translate('remember_me');
  String get forgotPassword => translate('forgot_password');
  String get resetPassword => translate('reset_password');
  String get changePassword => translate('change_password');
  String get loginSuccess => translate('login_success');
  String get loginFailed => translate('login_failed');
  String get invalidCredentials => translate('invalid_credentials');
  String get logoutConfirm => translate('logout_confirm');
  String get selectCompany => translate('select_company');
  String get welcomeBack => translate('welcome_back');
  String get sessionExpired => translate('session_expired');

  // Home & Navigation
  String get home => translate('home');
  String get dashboard => translate('dashboard');
  String get welcome => translate('welcome');
  String get quickActions => translate('quick_actions');
  String get recentActivities => translate('recent_activities');
  String get overview => translate('overview');
  String get analytics => translate('analytics');
  String get reports => translate('reports');
  String get monitor => translate('monitor');
  String get monitoring => translate('monitoring');

  // Settings
  String get settings => translate('settings');
  String get profile => translate('profile');
  String get account => translate('account');
  String get preferences => translate('preferences');
  String get appearance => translate('appearance');
  String get language => translate('language');
  String get theme => translate('theme');
  String get light => translate('light');
  String get dark => translate('dark');
  String get system => translate('system');
  String get lightMode => translate('light_mode');
  String get darkMode => translate('dark_mode');
  String get systemDefault => translate('system_default');
  String get notificationsSettings => translate('notifications_settings');
  String get privacySecurity => translate('privacy_security');
  String get aboutApp => translate('about_app');
  String get version => translate('version');
  String get privacyPolicy => translate('privacy_policy');
  String get termsOfService => translate('terms_of_service');
  String get general => translate('general');

  // Offline & Sync
  String get offline => translate('offline');
  String get online => translate('online');
  String get offlineMode => translate('offline_mode');
  String get sync => translate('sync');
  String get synced => translate('synced');
  String get syncing => translate('syncing');
  String get syncComplete => translate('sync_complete');
  String get syncFailed => translate('sync_failed');
  String get syncStatus => translate('sync_status');
  String get pendingOperations => translate('pending_operations');
  String get noPendingOperations => translate('no_pending_operations');
  String get lastSync => translate('last_sync');
  String get offlineBanner => translate('offline_banner');
  String get dataSavedOffline => translate('data_saved_offline');
  String get willSyncWhenOnline => translate('will_sync_when_online');
  String get cacheManagement => translate('cache_management');
  String get clearCache => translate('clear_cache');
  String get onlineNow => translate('online_now');

  // Notifications
  String get notifications => translate('notifications');
  String get noNotifications => translate('no_notifications');
  String get markAllRead => translate('mark_all_read');
  String get newNotification => translate('new_notification');
  String get notificationSettings => translate('notification_settings');
  String get pushNotifications => translate('push_notifications');
  String get emailNotifications => translate('email_notifications');

  // Search
  String get searchPlaceholder => translate('search_placeholder');
  String get noResults => translate('no_results');
  String get recentSearches => translate('recent_searches');
  String get searchResults => translate('search_results');
  String get searchFor => translate('search_for');
  String get voiceSearch => translate('voice_search');

  // Errors
  String get errorGeneric => translate('error_generic');
  String get errorNetwork => translate('error_network');
  String get errorServer => translate('error_server');
  String get errorTimeout => translate('error_timeout');
  String get errorNoConnection => translate('error_no_connection');
  String get errorUnauthorized => translate('error_unauthorized');
  String get errorNotFound => translate('error_not_found');
  String get errorValidation => translate('error_validation');
  String get tryAgain => translate('try_again');
  String get somethingWentWrong => translate('something_went_wrong');

  // Empty States
  String get emptyData => translate('empty_data');
  String get emptyList => translate('empty_list');
  String get noItems => translate('no_items');
  String get noData => translate('no_data');
  String get nothingHere => translate('nothing_here');

  // Trips
  String get trips => translate('trips');
  String get tripsManagement => translate('trips_management');
  String get trip => translate('trip');
  String get tripDetails => translate('trip_details');
  String get createTrip => translate('create_trip');
  String get editTrip => translate('edit_trip');
  String get startTrip => translate('start_trip');
  String get endTrip => translate('end_trip');
  String get cancelTrip => translate('cancel_trip');
  String get tripHistory => translate('trip_history');
  String get tripStatus => translate('trip_status');
  String get scheduled => translate('scheduled');
  String get inProgress => translate('in_progress');
  String get completed => translate('completed');
  String get cancelled => translate('cancelled');
  String get pending => translate('pending');
  String get departure => translate('departure');
  String get arrival => translate('arrival');
  String get departureTime => translate('departure_time');
  String get arrivalTime => translate('arrival_time');
  String get estimatedTime => translate('estimated_time');
  String get duration => translate('duration');
  String get distance => translate('distance');
  String get route => translate('route');
  String get routes => translate('routes');
  String get noTrips => translate('no_trips');
  String get upcomingTrips => translate('upcoming_trips');
  String get pastTrips => translate('past_trips');
  String get activeTrips => translate('active_trips');
  String get liveTracking => translate('live_tracking');
  String get trackTrip => translate('track_trip');

  // Passengers
  String get passengers => translate('passengers');
  String get passengersManagement => translate('passengers_management');
  String get passenger => translate('passenger');
  String get passengerDetails => translate('passenger_details');
  String get addPassenger => translate('add_passenger');
  String get editPassenger => translate('edit_passenger');
  String get removePassenger => translate('remove_passenger');
  String get passengerCount => translate('passenger_count');
  String get passengerList => translate('passenger_list');
  String get noPassengers => translate('no_passengers');
  String get boardPassenger => translate('board_passenger');
  String get dropPassenger => translate('drop_passenger');
  String get boarding => translate('boarding');
  String get boarded => translate('boarded');
  String get dropped => translate('dropped');
  String get notBoarded => translate('not_boarded');
  String get absent => translate('absent');
  String get present => translate('present');
  String get allPassengers => translate('all_passengers');
  String get unassigned => translate('unassigned');
  String get byGroups => translate('by_groups');
  String get distributionBoard => translate('distribution_board');
  String get searchAllPassengers => translate('search_all_passengers');
  String get searchUnassigned => translate('search_unassigned');
  String get searchGroup => translate('search_group');
  String get quickSearchBoard => translate('quick_search_board');
  String get addNewPassenger => translate('add_new_passenger');
  String get noMatchingResults => translate('no_matching_results');
  String get noPassengersInSystem => translate('no_passengers_in_system');
  String get allAssignedToGroups => translate('all_assigned_to_groups');
  String get createGroupFirst => translate('create_group_first');
  String get moveToGroup => translate('move_to_group');
  String get move => translate('move');
  String get assign => translate('assign');
  String get empty => translate('empty');
  String get pickup => translate('pickup');
  String get dropoff => translate('dropoff');
  String get editProfile => translate('edit_profile');
  String get changeLocation => translate('change_location');
  String get markAbsent => translate('mark_absent');
  String get cannotConnectServer => translate('cannot_connect_server');
  String get absenceRecorded => translate('absence_recorded');
  String get inText => translate('in');
  String get absenceFailed => translate('absence_failed');
  String get father => translate('father');
  String get mother => translate('mother');
  String get noGroupsAvailable => translate('no_groups_available');

  // Vehicles
  String get vehicles => translate('vehicles');
  String get vehiclesManagement => translate('vehicles_management');
  String get vehicle => translate('vehicle');
  String get vehicleDetails => translate('vehicle_details');
  String get addVehicle => translate('add_vehicle');
  String get editVehicle => translate('edit_vehicle');
  String get vehicleNumber => translate('vehicle_number');
  String get licensePlate => translate('license_plate');
  String get vehicleType => translate('vehicle_type');
  String get capacity => translate('capacity');
  String get seats => translate('seats');
  String get availableSeats => translate('available_seats');
  String get noVehicles => translate('no_vehicles');
  String get bus => translate('bus');
  String get van => translate('van');
  String get car => translate('car');

  // Groups
  String get groups => translate('groups');
  String get groupsManagement => translate('groups_management');
  String get group => translate('group');
  String get groupDetails => translate('group_details');
  String get createGroup => translate('create_group');
  String get editGroup => translate('edit_group');
  String get groupName => translate('group_name');
  String get groupMembers => translate('group_members');
  String get addToGroup => translate('add_to_group');
  String get removeFromGroup => translate('remove_from_group');
  String get noGroups => translate('no_groups');
  String get schedules => translate('schedules');
  String get schedule => translate('schedule');

  // Stops
  String get stops => translate('stops');
  String get stop => translate('stop');
  String get stopDetails => translate('stop_details');
  String get addStop => translate('add_stop');
  String get editStop => translate('edit_stop');
  String get stopName => translate('stop_name');
  String get stopOrder => translate('stop_order');
  String get pickupStop => translate('pickup_stop');
  String get dropoffStop => translate('dropoff_stop');
  String get noStops => translate('no_stops');

  // Driver
  String get driver => translate('driver');
  String get drivers => translate('drivers');
  String get driverDetails => translate('driver_details');
  String get assignDriver => translate('assign_driver');
  String get driverName => translate('driver_name');
  String get driving => translate('driving');
  String get driverHome => translate('driver_home');
  String get startDriving => translate('start_driving');
  String get stopDriving => translate('stop_driving');

  // Dispatcher
  String get dispatcher => translate('dispatcher');
  String get dispatchers => translate('dispatchers');
  String get dispatch => translate('dispatch');
  String get dispatcherHome => translate('dispatcher_home');
  String get assignTrip => translate('assign_trip');

  // Manager
  String get manager => translate('manager');
  String get managers => translate('managers');
  String get managerHome => translate('manager_home');
  String get managerDashboard => translate('manager_dashboard');

  // Guardian
  String get guardian => translate('guardian');
  String get guardians => translate('guardians');
  String get guardianHome => translate('guardian_home');
  String get myChildren => translate('my_children');
  String get child => translate('child');
  String get children => translate('children');

  // Map
  String get map => translate('map');
  String get maps => translate('maps');
  String get viewOnMap => translate('view_on_map');
  String get currentLocation => translate('current_location');
  String get getDirections => translate('get_directions');
  String get navigation => translate('navigation');

  // Time & Date
  String get minutes => translate('minutes');
  String get hours => translate('hours');
  String get days => translate('days');
  String get weeks => translate('weeks');
  String get months => translate('months');
  String get years => translate('years');
  String get ago => translate('ago');
  String get inFuture => translate('in_future');
  String get justNow => translate('just_now');
  String get morning => translate('morning');
  String get afternoon => translate('afternoon');
  String get evening => translate('evening');
  String get night => translate('night');

  // Holidays
  String get holidays => translate('holidays');
  String get holiday => translate('holiday');
  String get addHoliday => translate('add_holiday');
  String get editHoliday => translate('edit_holiday');
  String get holidayName => translate('holiday_name');
  String get holidayDate => translate('holiday_date');
  String get noHolidays => translate('no_holidays');

  // Reports
  String get generateReport => translate('generate_report');
  String get exportPdf => translate('export_pdf');
  String get exportExcel => translate('export_excel');
  String get dailyReport => translate('daily_report');
  String get weeklyReport => translate('weekly_report');
  String get monthlyReport => translate('monthly_report');

  // Stats
  String get statistics => translate('statistics');
  String get stats => translate('stats');
  String get todayStatistics => translate('today_statistics');
  String get totalTrips => translate('total_trips');
  String get totalTripsToday => translate('total_trips_today');
  String get totalPassengers => translate('total_passengers');
  String get totalVehicles => translate('total_vehicles');
  String get totalDistance => translate('total_distance');
  String get average => translate('average');
  String get performance => translate('performance');
  String get efficiency => translate('efficiency');
  String get fleetStatus => translate('fleet_status');
  String get fleetUtilization => translate('fleet_utilization');
  String get fleetInUse => translate('fleet_in_use');
  String get activeVehicles => translate('active_vehicles');
  String get activeDrivers => translate('active_drivers');
  String get ongoingTrips => translate('ongoing_trips');
  String get liveMonitoring => translate('live_monitoring');
  String get activeTripsNow => translate('active_trips_now');
  String get viewSyncStatus => translate('view_sync_status');
  // Note: disconnected is already available from Offline & Sync section

  // Companies
  String get company => translate('company');
  String get companies => translate('companies');
  String get currentCompany => translate('current_company');
  String get switchCompany => translate('switch_company');
  String get multiCompany => translate('multi_company');

  // Permissions & Roles
  String get permissions => translate('permissions');
  String get roles => translate('roles');
  String get admin => translate('admin');
  String get user => translate('user');
  String get accessDenied => translate('access_denied');

  // Biometric
  String get biometricAuth => translate('biometric_auth');
  String get enableBiometric => translate('enable_biometric');
  String get useFingerprint => translate('use_fingerprint');
  String get useFaceId => translate('use_face_id');

  // Camera & Files
  String get camera => translate('camera');
  String get gallery => translate('gallery');
  String get pickImage => translate('pick_image');
  String get pickFile => translate('pick_file');
  String get uploadFile => translate('upload_file');
  String get downloadFile => translate('download_file');
  String get fileManager => translate('file_manager');

  // Confirmation dialogs
  String get areYouSure => translate('are_you_sure');
  String get confirmDelete => translate('confirm_delete');
  String get confirmCancel => translate('confirm_cancel');
  String get confirmLogout => translate('confirm_logout');
  String get changesNotSaved => translate('changes_not_saved');
  String get discardChanges => translate('discard_changes');

  // Success messages
  String get savedSuccessfully => translate('saved_successfully');
  String get deletedSuccessfully => translate('deleted_successfully');
  String get updatedSuccessfully => translate('updated_successfully');
  String get createdSuccessfully => translate('created_successfully');
  String get operationSuccessful => translate('operation_successful');

  // Onboarding
  String get getStarted => translate('get_started');
  String get welcomeToApp => translate('welcome_to_app');
  String get onboardingTitle1 => translate('onboarding_title_1');
  String get onboardingTitle2 => translate('onboarding_title_2');
  String get onboardingTitle3 => translate('onboarding_title_3');
  String get onboardingDesc1 => translate('onboarding_desc_1');
  String get onboardingDesc2 => translate('onboarding_desc_2');
  String get onboardingDesc3 => translate('onboarding_desc_3');

  // Validation
  String get fieldRequired => translate('field_required');
  String get invalidEmail => translate('invalid_email');
  String get passwordTooShort => translate('password_too_short');
  String get passwordsDontMatch => translate('passwords_dont_match');
  String get invalidPhone => translate('invalid_phone');
  String get invalidInput => translate('invalid_input');

  // Misc
  String get realTimeUpdates => translate('real_time_updates');
  String get connected => translate('connected');
  String get disconnected => translate('disconnected');
  String get auditTrail => translate('audit_trail');
  String get formBuilder => translate('form_builder');
  String get requiredField => translate('required_field');
  String get revenue => translate('revenue');
  String get orders => translate('orders');
  String get customers => translate('customers');
  String get salesOverview => translate('sales_overview');
  String get ordersByStatus => translate('orders_by_status');

  // Role Switcher
  String get viewAs => translate('view_as');
  String get original => translate('original');
  String get originalRole => translate('original_role');
  String get returnText => translate('return');
  String get youAreViewingAs => translate('you_are_viewing_as');
  String get switchedToView => translate('switched_to_view');
  String get returnedToView => translate('returned_to_view');
  String get switchRole => translate('switch_role');

  // Additional Trip Getters
  String get planned => translate('planned');
  String get ongoing => translate('ongoing');
  String get draft => translate('draft');
  String get clearFilters => translate('clear_filters');
  String get createNewTrip => translate('create_new_trip');
  String get searchTrip => translate('search_trip');
  String get noTripsForDay => translate('no_trips_for_day');
  String get noResultsMatching => translate('no_results_matching');
  String get noResultsForFilters => translate('no_results_for_filters');
  String get advancedFilters => translate('advanced_filters');
  String get tripType => translate('trip_type');
  String get withDriver => translate('with_driver');
  String get withVehicle => translate('with_vehicle');
  String get withGps => translate('with_gps');
  String get onlyWithDriver => translate('only_with_driver');
  String get onlyWithVehicle => translate('only_with_vehicle');
  String get onlyWithGps => translate('only_with_gps');
  String get selectDate => translate('select_date');
  String get companion => translate('companion');
  String get noCompanion => translate('no_companion');
  String get statusAndTime => translate('status_and_time');
  String get driverAndVehicle => translate('driver_and_vehicle');
  String get notAssigned => translate('not_assigned');
  String get plateNumber => translate('plate_number');
  String get startedActually => translate('started_actually');
  String get endedActually => translate('ended_actually');
  String get areYouSureStart => translate('are_you_sure_start');
  String get areYouSureEnd => translate('are_you_sure_end');
  String get areYouSureCancel => translate('are_you_sure_cancel');
  String get tripStarted => translate('trip_started');
  String get tripEnded => translate('trip_ended');
  String get tripCancelled => translate('trip_cancelled');
  String get failedToStart => translate('failed_to_start');
  String get failedToEnd => translate('failed_to_end');
  String get failedToCancel => translate('failed_to_cancel');
  String get backToTrips => translate('back_to_trips');
  String get tripNotFound => translate('trip_not_found');
  String get generateFromGroup => translate('generate_from_group');
  String get manualTrip => translate('manual_trip');
  String get generateTrips => translate('generate_trips');
  String get generateTripsFromGroup => translate('generate_trips_from_group');
  String get selectGroupToGenerate => translate('select_group_to_generate');
  String get createManualTrip => translate('create_manual_trip');
  String get createManualTripDesc => translate('create_manual_trip_desc');
  String get basicInfo => translate('basic_info');
  String get tripName => translate('trip_name');
  String get tripNameExample => translate('trip_name_example');
  String get generationOptions => translate('generation_options');
  String get weeksToGenerate => translate('weeks_to_generate');
  String get willGenerateTrips => translate('will_generate_trips');
  String get weeksAhead => translate('weeks_ahead');
  String get week => translate('week');
  String get generating => translate('generating');
  String get creating => translate('creating');
  String get noActiveGroups => translate('no_active_groups');
  String get noDriversAvailable => translate('no_drivers_available');
  String get tripsGeneratedSuccessfully =>
      translate('trips_generated_successfully');
  String get viewAllTrips => translate('view_all_trips');
  String get generatedTrips => translate('generated_trips');
  String get andMore => translate('and_more');
  String get moreTrips => translate('more_trips');
  String get noTripsGenerated => translate('no_trips_generated');
  String get companionOptional => translate('companion_optional');
  String get selectCompanion => translate('select_companion');
  String get selectDriver => translate('select_driver');
  String get selectGroup => translate('select_group');
  String get selectVehicle => translate('select_vehicle');
  String get noGroup => translate('no_group');
  String get noVehicle => translate('no_vehicle');
  String get noLicensePlate => translate('no_license_plate');
  String get pleaseSelectDriver => translate('please_select_driver');
  String get failedToLoadGroups => translate('failed_to_load_groups');
  String get errorCreatingTrip => translate('error_creating_trip');
  String get cannotAccessTripRepository =>
      translate('cannot_access_trip_repository');

  // Additional Group Getters
  String get newGroup => translate('new_group');
  String get searchGroupHint => translate('search_group_hint');
  String get activeOnly => translate('active_only');
  String get withDestination => translate('with_destination');
  String get linkedToDriver => translate('linked_to_driver');
  String get linkedToVehicle => translate('linked_to_vehicle');
  String get hasDestination => translate('has_destination');
  String get groupFilters => translate('group_filters');
  String get showingOf => translate('showing_of');
  String get ofText => translate('of_text');
  String get noGroupsFound => translate('no_groups_found');
  String get noMatchingSearch => translate('no_matching_search');
  String get noGroupsCreated => translate('no_groups_created');
  String get generateTrip => translate('generate_trip');
  String get manageSchedules => translate('manage_schedules');
  String get viewPassengers => translate('view_passengers');
  String get deleteGroup => translate('delete_group');
  String get deleteGroupTitle => translate('delete_group_title');
  String get deleteGroupConfirm => translate('delete_group_confirm');
  String get groupDeleted => translate('group_deleted');
  String get failedToDeleteGroup => translate('failed_to_delete_group');
  String get passengerSingular => translate('passenger_singular');
  String get bothPickupDropoff => translate('both_pickup_dropoff');

  // Weekdays
  String get monday => translate('monday');
  String get tuesday => translate('tuesday');
  String get wednesday => translate('wednesday');
  String get thursday => translate('thursday');
  String get friday => translate('friday');
  String get saturday => translate('saturday');
  String get sunday => translate('sunday');

  // Billing
  String get perTrip => translate('per_trip');
  String get monthly => translate('monthly');
  String get perTerm => translate('per_term');
  String get billingCycle => translate('billing_cycle');
}

/// Localization delegate
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar', 'fr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Extension for easy access
extension LocalizationsExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
