import 'package:dartz/dartz.dart';
import 'package:bridgecore_flutter_starter/core/data/repositories/base_repository.dart';
import 'package:bridgecore_flutter_starter/core/error/failures.dart';
import 'package:bridgecore_flutter_starter/core/data/datasources/remote_data_source.dart';
import 'package:bridgecore_flutter_starter/core/cache/cache_manager.dart';
import 'package:bridgecore_flutter_starter/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:bridgecore_flutter_starter/features/dashboard/domain/entities/kpi.dart';
import 'package:bridgecore_flutter_starter/features/dashboard/domain/entities/chart_data.dart';

class DashboardRepositoryImpl extends BaseRepository
    implements DashboardRepository {
  final OdooRemoteDataSource remoteDataSource;
  final CacheManager cacheManager;

  DashboardRepositoryImpl({
    required this.remoteDataSource,
    required this.cacheManager,
  });

  @override
  Future<Either<Failure, List<KPI>>> getKPIs() async {
    return execute(() async {
      // Try cache first
      final cached = await cacheManager.get<List<dynamic>>('dashboard_kpis');
      if (cached != null) {
        return cached
            .map((json) => KPI.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Fetch from server
      final kpis = <KPI>[];

      // Revenue KPI
      final revenue = await _calculateRevenue();
      kpis.add(revenue);

      // Orders KPI
      final orders = await _calculateOrders();
      kpis.add(orders);

      // Customers KPI
      final customers = await _calculateCustomers();
      kpis.add(customers);

      // Pending KPI
      final pending = await _calculatePending();
      kpis.add(pending);

      // Cache KPIs
      await cacheManager.set(
        'dashboard_kpis',
        kpis.map((k) => k.toJson()).toList(),
        diskTTL: const Duration(minutes: 15),
      );

      return kpis;
    });
  }

  Future<KPI> _calculateRevenue() async {
    final invoices = await remoteDataSource.searchRead(
      model: 'account.move',
      domain: [
        ['move_type', '=', 'out_invoice'],
        ['state', '=', 'posted'],
      ],
      fields: ['amount_total'],
      limit: 1000,
    );

    final total = invoices.fold<double>(
        0, (sum, inv) => sum + (inv['amount_total'] ?? 0));

    // Calculate trend (compare with last month)
    final lastMonthInvoices = await remoteDataSource.searchRead(
      model: 'account.move',
      domain: [
        ['move_type', '=', 'out_invoice'],
        ['state', '=', 'posted'],
        ['date', '<', DateTime.now().toIso8601String()],
        [
          'date',
          '>=',
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String()
        ],
      ],
      fields: ['amount_total'],
    );

    final lastMonthTotal = lastMonthInvoices.fold<double>(
      0,
      (sum, inv) => sum + (inv['amount_total'] ?? 0),
    );

    final trend = lastMonthTotal > 0
        ? ((total - lastMonthTotal) / lastMonthTotal * 100)
        : 0.0;

    return KPI(
      title: 'Revenue',
      value: '\$${total.toStringAsFixed(2)}',
      icon: 'attach_money',
      color: 0xFF4CAF50,
      trend: trend,
      trendLabel: '${trend.toStringAsFixed(1)}%',
    );
  }

  Future<KPI> _calculateOrders() async {
    final orders = await remoteDataSource.searchCount(
      model: 'sale.order',
      domain: [
        [
          'state',
          'in',
          ['sale', 'done']
        ]
      ],
    );

    return KPI(
      title: 'Orders',
      value: orders.toString(),
      icon: 'shopping_cart',
      color: 0xFF2196F3,
      trend: 12.5,
      trendLabel: '+12.5%',
    );
  }

  Future<KPI> _calculateCustomers() async {
    final customers = await remoteDataSource.searchCount(
      model: 'res.partner',
      domain: [
        ['customer_rank', '>', 0]
      ],
    );

    return KPI(
      title: 'Customers',
      value: customers.toString(),
      icon: 'people',
      color: 0xFF9C27B0,
      trend: 8.3,
      trendLabel: '+8.3%',
    );
  }

  Future<KPI> _calculatePending() async {
    final pending = await remoteDataSource.searchCount(
      model: 'sale.order',
      domain: [
        ['state', '=', 'draft']
      ],
    );

    return KPI(
      title: 'Pending',
      value: pending.toString(),
      icon: 'pending',
      color: 0xFFFF9800,
      trend: -5.2,
      trendLabel: '-5.2%',
    );
  }

  @override
  Future<Either<Failure, ChartData>> getSalesOverview({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return execute(() async {
      final cacheKey =
          'sales_overview_${startDate.toIso8601String()}_${endDate.toIso8601String()}';

      // Try cache first
      final cached = await cacheManager.get<Map<String, dynamic>>(cacheKey);
      if (cached != null) {
        return ChartData.fromJson(cached);
      }

      // Fetch from server
      final orders = await remoteDataSource.searchRead(
        model: 'sale.order',
        domain: [
          ['date_order', '>=', startDate.toIso8601String()],
          ['date_order', '<=', endDate.toIso8601String()],
          [
            'state',
            'in',
            ['sale', 'done']
          ],
        ],
        fields: ['date_order', 'amount_total'],
      );

      // Group by date
      final dataPoints = <ChartDataPoint>[];
      final groupedData = <DateTime, double>{};

      for (final order in orders) {
        final date = DateTime.parse(order['date_order'] as String);
        final dateOnly = DateTime(date.year, date.month, date.day);
        groupedData[dateOnly] =
            (groupedData[dateOnly] ?? 0) + (order['amount_total'] ?? 0);
      }

      groupedData.forEach((date, value) {
        dataPoints.add(
          ChartDataPoint(
            x: date.millisecondsSinceEpoch.toDouble(),
            y: value,
            label: '${date.day}/${date.month}',
          ),
        );
      });

      dataPoints.sort((a, b) => a.x.compareTo(b.x));

      final chartData = ChartData(
        title: 'Sales Overview',
        dataPoints: dataPoints,
      );

      // Cache chart data
      await cacheManager.set(
        cacheKey,
        chartData.toJson(),
        diskTTL: const Duration(hours: 1),
      );

      return chartData;
    });
  }

  @override
  Future<Either<Failure, ChartData>> getOrdersByStatus() async {
    return execute(() async {
      // Try cache first
      final cached = await cacheManager.get<Map<String, dynamic>>(
        'orders_by_status',
      );
      if (cached != null) {
        return ChartData.fromJson(cached);
      }

      // Fetch from server
      final statuses = ['draft', 'sent', 'sale', 'done', 'cancel'];
      final dataPoints = <ChartDataPoint>[];

      for (final status in statuses) {
        final count = await remoteDataSource.searchCount(
          model: 'sale.order',
          domain: [
            ['state', '=', status]
          ],
        );

        dataPoints.add(
          ChartDataPoint(
            x: statuses.indexOf(status).toDouble(),
            y: count.toDouble(),
            label: status.toUpperCase(),
          ),
        );
      }

      final chartData = ChartData(
        title: 'Orders by Status',
        dataPoints: dataPoints,
      );

      // Cache chart data
      await cacheManager.set(
        'orders_by_status',
        chartData.toJson(),
        diskTTL: const Duration(minutes: 30),
      );

      return chartData;
    });
  }
}
