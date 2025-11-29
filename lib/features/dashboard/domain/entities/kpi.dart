import 'package:equatable/equatable.dart';

class KPI extends Equatable {
  final String title;
  final String value;
  final String icon;
  final int color;
  final double trend;
  final String trendLabel;

  const KPI({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    required this.trendLabel,
  });

  bool get isPositiveTrend => trend >= 0;

  Map<String, dynamic> toJson() => {
        'title': title,
        'value': value,
        'icon': icon,
        'color': color,
        'trend': trend,
        'trend_label': trendLabel,
      };

  factory KPI.fromJson(Map<String, dynamic> json) => KPI(
        title: json['title'] as String,
        value: json['value'] as String,
        icon: json['icon'] as String,
        color: json['color'] as int,
        trend: (json['trend'] as num).toDouble(),
        trendLabel: json['trend_label'] as String,
      );

  @override
  List<Object?> get props => [title, value, icon, color, trend, trendLabel];
}
