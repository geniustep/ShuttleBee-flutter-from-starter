import 'package:equatable/equatable.dart';

class ChartData extends Equatable {
  final String title;
  final List<ChartDataPoint> dataPoints;

  const ChartData({
    required this.title,
    required this.dataPoints,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'data_points': dataPoints.map((p) => p.toJson()).toList(),
      };

  factory ChartData.fromJson(Map<String, dynamic> json) => ChartData(
        title: json['title'] as String,
        dataPoints: (json['data_points'] as List)
            .map((p) => ChartDataPoint.fromJson(p as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [title, dataPoints];
}

class ChartDataPoint extends Equatable {
  final double x;
  final double y;
  final String label;

  const ChartDataPoint({
    required this.x,
    required this.y,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'label': label,
      };

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) =>
      ChartDataPoint(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        label: json['label'] as String,
      );

  @override
  List<Object?> get props => [x, y, label];
}
