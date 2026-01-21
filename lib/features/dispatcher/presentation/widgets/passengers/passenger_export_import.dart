import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/passenger_group_line.dart';

/// Export/Import utilities for passengers
class PassengerExportImport {
  /// Export passengers to Excel file
  static Future<String?> exportToExcel(
    List<PassengerGroupLine> passengers,
  ) async {
    try {
      final excel = Excel.createExcel();
      // Delete default sheet if exists
      if (excel.tables.keys.isNotEmpty) {
        excel.delete(excel.tables.keys.first);
      }
      // Access or create sheet with Arabic name (will create if doesn't exist)
      final sheet = excel['الركاب'];

      // Headers
      final headers = [
        'ID',
        'اسم الراكب',
        'الهاتف',
        'الجوال',
        'هاتف الأب',
        'هاتف الأم',
        'هاتف ولي الأمر',
        'المجموعة',
        'عدد المقاعد',
        'العنوان',
        'ملاحظات',
      ];

      // Write headers
      for (int i = 0; i < headers.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = TextCellValue(
          headers[i],
        );
      }

      // Write data
      for (int i = 0; i < passengers.length; i++) {
        final passenger = passengers[i];
        final int row = i + 1;

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = IntCellValue(
          passenger.passengerId,
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(
          passenger.passengerName,
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = TextCellValue(
          passenger.passengerPhone ?? '',
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
            .value = TextCellValue(
          passenger.passengerMobile ?? '',
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .value = TextCellValue(
          passenger.fatherPhone ?? '',
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
            .value = TextCellValue(
          passenger.motherPhone ?? '',
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
            .value = TextCellValue(
          passenger.guardianPhone ?? '',
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
            .value = TextCellValue(
          passenger.groupName ?? 'غير معين',
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row))
            .value = IntCellValue(
          passenger.seatCount,
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row))
            .value = TextCellValue(
          passenger.pickupStopName ?? passenger.pickupInfoDisplay ?? '',
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row))
            .value = TextCellValue(
          passenger.notes ?? '',
        );
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'passengers_$timestamp.xlsx';
      final filePath = '${directory.path}/$fileName';

      final fileData = excel.save();
      if (fileData != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileData);
        return filePath;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Export passengers to CSV file
  static Future<String?> exportToCSV(
    List<PassengerGroupLine> passengers,
  ) async {
    try {
      final buffer = StringBuffer();

      // Headers
      buffer.writeln(
        'ID,اسم الراكب,الهاتف,الجوال,هاتف الأب,هاتف الأم,هاتف ولي الأمر,المجموعة,عدد المقاعد,العنوان,ملاحظات',
      );

      // Data
      for (final passenger in passengers) {
        buffer.writeln(
          '${passenger.passengerId},'
          '${passenger.passengerName},'
          '${passenger.passengerPhone ?? ''},'
          '${passenger.passengerMobile ?? ''},'
          '${passenger.fatherPhone ?? ''},'
          '${passenger.motherPhone ?? ''},'
          '${passenger.guardianPhone ?? ''},'
          '${passenger.groupName ?? 'غير معين'},'
          '${passenger.seatCount},'
          '${passenger.pickupStopName ?? passenger.pickupInfoDisplay ?? ''},'
          '${passenger.notes ?? ''}',
        );
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'passengers_$timestamp.csv';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(buffer.toString());
      return filePath;
    } catch (e) {
      return null;
    }
  }

  /// Import passengers from Excel/CSV file
  static Future<List<Map<String, dynamic>>?> importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
      );

      if (result == null || result.files.isEmpty) return null;

      final filePath = result.files.single.path;
      if (filePath == null) return null;

      if (filePath.endsWith('.xlsx')) {
        return _importFromExcel(filePath);
      } else if (filePath.endsWith('.csv')) {
        return _importFromCSV(filePath);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> _importFromExcel(
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null) return null;

      final List<Map<String, dynamic>> passengers = [];

      // Skip header row
      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;

        passengers.add({
          'id': row[0]?.value?.toString(),
          'name': row[1]?.value?.toString() ?? '',
          'phone': row[2]?.value?.toString(),
          'mobile': row[3]?.value?.toString(),
          'father_phone': row[4]?.value?.toString(),
          'mother_phone': row[5]?.value?.toString(),
          'guardian_phone': row[6]?.value?.toString(),
          'group_name': row[7]?.value?.toString(),
          'seat_count': row[8]?.value?.toString(),
          'address': row[9]?.value?.toString(),
          'notes': row[10]?.value?.toString(),
        });
      }

      return passengers;
    } catch (e) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> _importFromCSV(
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      final lines = content.split('\n');

      if (lines.isEmpty) return null;

      final List<Map<String, dynamic>> passengers = [];

      // Skip header row
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final values = line.split(',');
        if (values.length < 2) continue;

        passengers.add({
          'id': values[0],
          'name': values[1],
          'phone': values.length > 2 ? values[2] : null,
          'mobile': values.length > 3 ? values[3] : null,
          'father_phone': values.length > 4 ? values[4] : null,
          'mother_phone': values.length > 5 ? values[5] : null,
          'guardian_phone': values.length > 6 ? values[6] : null,
          'group_name': values.length > 7 ? values[7] : null,
          'seat_count': values.length > 8 ? values[8] : null,
          'address': values.length > 9 ? values[9] : null,
          'notes': values.length > 10 ? values[10] : null,
        });
      }

      return passengers;
    } catch (e) {
      return null;
    }
  }

  /// Open exported file
  static Future<void> openFile(String filePath) async {
    try {
      await OpenFile.open(filePath);
    } catch (e) {
      // Handle error
    }
  }
}

/// Export/Import bottom sheet widget
class PassengerExportImportSheet extends StatelessWidget {
  final List<PassengerGroupLine> passengers;
  final Function(List<Map<String, dynamic>>)? onImport;

  const PassengerExportImportSheet({
    super.key,
    required this.passengers,
    this.onImport,
  });

  static Future<void> show(
    BuildContext context, {
    required List<PassengerGroupLine> passengers,
    Function(List<Map<String, dynamic>>)? onImport,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PassengerExportImportSheet(
        passengers: passengers,
        onImport: onImport,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppColors.dispatcherGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.import_export_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'تصدير / استيراد',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.border.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _ActionButton(
                    icon: Icons.file_download_rounded,
                    label: 'تصدير إلى Excel',
                    color: AppColors.success,
                    onTap: () => _exportExcel(context),
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    icon: Icons.file_download_rounded,
                    label: 'تصدير إلى CSV',
                    color: AppColors.primary,
                    onTap: () => _exportCSV(context),
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    icon: Icons.file_upload_rounded,
                    label: 'استيراد من ملف',
                    color: AppColors.dispatcherPrimary,
                    onTap: () => _importFile(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _exportExcel(BuildContext context) async {
    HapticFeedback.lightImpact();
    final filePath = await PassengerExportImport.exportToExcel(passengers);
    if (context.mounted) {
      if (filePath != null) {
        await PassengerExportImport.openFile(filePath);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم التصدير بنجاح',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل التصدير', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _exportCSV(BuildContext context) async {
    HapticFeedback.lightImpact();
    final filePath = await PassengerExportImport.exportToCSV(passengers);
    if (context.mounted) {
      if (filePath != null) {
        await PassengerExportImport.openFile(filePath);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم التصدير بنجاح',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل التصدير', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _importFile(BuildContext context) async {
    HapticFeedback.lightImpact();
    final data = await PassengerExportImport.importFromFile();
    if (context.mounted) {
      if (data != null && data.isNotEmpty) {
        Navigator.pop(context);
        onImport?.call(data);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم استيراد ${data.length} راكب',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'فشل الاستيراد أو الملف فارغ',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: color.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
