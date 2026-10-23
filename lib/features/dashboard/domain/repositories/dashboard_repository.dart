import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/domain/entities/dashboard.dart';

/// Dashboard of the logged-in member (FEATURE_2610_29 / D6 · D11).
abstract class DashboardRepository {
  Future<Either<Failure, DashboardLayout>> getLayout();

  Future<Either<Failure, DashboardLayout>> saveMobileLayout(
      List<DashboardMobileCard> cards);
}
