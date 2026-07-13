abstract class PlatformCodeEvent {}

class FetchCodes extends PlatformCodeEvent {}

class CreateCode extends PlatformCodeEvent {
  final String platform;
  final String code;
  CreateCode({required this.platform, required this.code});
}

class UpdateCode extends PlatformCodeEvent {
  final int codeId;
  final String platform;
  final String code;
  UpdateCode({required this.codeId, required this.platform, required this.code});
}

class DeleteCode extends PlatformCodeEvent {
  final int codeId;
  DeleteCode({required this.codeId});
}
