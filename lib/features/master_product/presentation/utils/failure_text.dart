import 'package:flutter_oklyn_mobile/core/error/failure.dart';

/// Mobile counterpart of the web `extractErrorMessage(e, fallback)`
/// (FEATURE_2609_80).
///
/// Uses the server envelope `message` when present, otherwise [fallback]. A 403
/// already carries the fixed text set by the repository.
/// ❌ Never show `failure.message` directly — an empty string would leak.
String failureText(Failure failure, String fallback) =>
    failure.message.trim().isNotEmpty ? failure.message : fallback;
