import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/domain/entities/dashboard.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/domain/repositories/dashboard_repository.dart';

/// Dashboard use case (FEATURE_2610_29) — a thin pass-through, the web
/// `DashboardUseCase`. The grid rules live in `dashboard_layout.dart`.
class DashboardUseCase {
  final DashboardRepository repository;

  DashboardUseCase({required this.repository});

  Future<Either<Failure, DashboardLayout>> getLayout() =>
      repository.getLayout();

  Future<Either<Failure, DashboardLayout>> saveMobileLayout(
          List<DashboardMobileCard> cards) =>
      repository.saveMobileLayout(cards);
}
