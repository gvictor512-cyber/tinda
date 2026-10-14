/// Minimal geohash encoder — no dependencies.
/// Precision guide: 4 chars ≈ ±20 km, 5 chars ≈ ±2.4 km, 6 chars ≈ ±0.6 km.
class GeoHash {
  GeoHash._();

  static const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Encodes a lat/lng into a geohash of [precision] characters.
  static String encode(double latitude, double longitude, {int precision = 6}) {
    var latRange = [-90.0, 90.0];
    var lonRange = [-180.0, 180.0];

    final buffer = StringBuffer();
    var bit = 0;
    var ch = 0;
    var even = true;

    while (buffer.length < precision) {
      if (even) {
        final mid = (lonRange[0] + lonRange[1]) / 2;
        if (longitude >= mid) {
          ch |= (1 << (4 - bit));
          lonRange[0] = mid;
        } else {
          lonRange[1] = mid;
        }
      } else {
        final mid = (latRange[0] + latRange[1]) / 2;
        if (latitude >= mid) {
          ch |= (1 << (4 - bit));
          latRange[0] = mid;
        } else {
          latRange[1] = mid;
        }
      }
      even = !even;
      if (bit < 4) {
        bit++;
      } else {
        buffer.write(_base32[ch]);
        bit = 0;
        ch = 0;
      }
    }
    return buffer.toString();
  }

  /// Returns the geohash prefix length that covers a square roughly
  /// [radiusKm] wide. Used to bound Firestore queries.
  static int prefixForRadius(double radiusKm) {
    if (radiusKm <= 5) return 5;
    if (radiusKm <= 40) return 4;
    if (radiusKm <= 150) return 3;
    if (radiusKm <= 600) return 2;
    return 1;
  }

  /// Lexicographic upper bound of a geohash prefix (prefix + highest char).
  static String prefixUpperBound(String prefix) {
    return '$prefix~'; // '~' sorts after all base32 chars
  }
}
