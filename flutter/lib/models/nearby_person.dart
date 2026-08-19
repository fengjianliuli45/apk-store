import 'package:latlong2/latlong.dart';

class NearbyPerson {
  const NearbyPerson({
    required this.name,
    required this.initials,
    required this.activity,
    required this.offset,
  });

  final String name;
  final String initials;
  final String activity;

  /// Degrees offset from the map center — mock positions, not real uploads.
  final LatLng offset;
}
