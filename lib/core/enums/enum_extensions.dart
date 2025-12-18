import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../features/groups/domain/entities/passenger_group.dart';
import 'trip_state.dart';
import 'trip_type.dart';
import 'trip_line_status.dart';

/// Extension methods for enums to support localization
extension TripStateL10n on TripState {
  /// Get localized label using AppLocalizations
  String getLocalizedLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case TripState.draft:
        return l10n.draft;
      case TripState.planned:
        return l10n.planned;
      case TripState.ongoing:
        return l10n.ongoing;
      case TripState.done:
        return l10n.completed;
      case TripState.cancelled:
        return l10n.cancelled;
    }
  }
}

extension TripTypeL10n on TripType {
  /// Get localized label using AppLocalizations
  String getLocalizedLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case TripType.pickup:
        return l10n.pickup;
      case TripType.dropoff:
        return l10n.dropoff;
    }
  }
}

extension TripLineStatusL10n on TripLineStatus {
  /// Get localized label using AppLocalizations
  String getLocalizedLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case TripLineStatus.pending:
        return l10n.pending;
      case TripLineStatus.notStarted:
        return l10n.notBoarded;
      case TripLineStatus.absent:
        return l10n.absent;
      case TripLineStatus.boarded:
        return l10n.boarded;
      case TripLineStatus.dropped:
        return l10n.dropped;
    }
  }
}

extension GroupTripTypeL10n on GroupTripType {
  /// Get localized label using AppLocalizations
  String getLocalizedLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case GroupTripType.pickup:
        return l10n.pickup;
      case GroupTripType.dropoff:
        return l10n.dropoff;
      case GroupTripType.both:
        return l10n.bothPickupDropoff;
    }
  }
}

extension BillingCycleL10n on BillingCycle {
  /// Get localized label using AppLocalizations
  String getLocalizedLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case BillingCycle.perTrip:
        return l10n.perTrip;
      case BillingCycle.monthly:
        return l10n.monthly;
      case BillingCycle.perTerm:
        return l10n.perTerm;
    }
  }
}

extension WeekdayL10n on Weekday {
  /// Get localized label using AppLocalizations
  String getLocalizedLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case Weekday.monday:
        return l10n.monday;
      case Weekday.tuesday:
        return l10n.tuesday;
      case Weekday.wednesday:
        return l10n.wednesday;
      case Weekday.thursday:
        return l10n.thursday;
      case Weekday.friday:
        return l10n.friday;
      case Weekday.saturday:
        return l10n.saturday;
      case Weekday.sunday:
        return l10n.sunday;
    }
  }
}
