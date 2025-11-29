import 'package:dartz/dartz.dart';
import 'package:bridgecore_flutter_starter/core/error/failures.dart';
import 'package:bridgecore_flutter_starter/features/dashboard/domain/entities/kpi.dart';
import 'package:bridgecore_flutter_starter/features/dashboard/domain/entities/chart_data.dart';

abstract class DashboardRepository {
  Future<Either<Failure, List<KPI>>> getKPIs();

  Future<Either<Failure, ChartData>> getSalesOverview({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<Either<Failure, ChartData>> getOrdersByStatus();
}
