abstract class PackageListEvent {}

class FetchPackages extends PackageListEvent {}

class SearchPackages extends PackageListEvent {
  final String query;

  SearchPackages({required this.query});
}
