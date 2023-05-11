import 'package:collection/collection.dart';
import 'package:gpx/src/model/trk_rte.dart';
import 'package:quiver/core.dart';

import 'link.dart';
import 'wpt.dart';

/// Rte represents route - an ordered list of waypoints representing a series of
/// turn points leading to a destination.
class Rte implements TrkRte{
  /// GPS name of route.
  @override
  String? name;

  /// GPS comment for route.
  @override
  String? cmt;

  /// Text description of route for user. Not sent to GPS.
  @override
  String? desc;

  /// Source of data. Included to give user some idea of reliability and
  /// accuracy of data.
  @override
  String? src;

  /// Links to external information about the route.
  @override
  List<Link> links;

  /// GPS route number.
  @override
  int? number;

  /// Type (classification) of route.
  @override
  String? type;

  /// You can add extend GPX by adding your own elements from another schema
  /// here.
  @override
  Map<String, String> extensions;

  /// A list of route points.
  List<Wpt> rtepts;

  /// Construct a new [Rte] object.
  Rte(
      {this.name,
      this.cmt,
      this.desc,
      this.src,
      List<Link>? links,
      this.number,
      this.type,
      Map<String, String>? extensions,
      List<Wpt>? rtepts})
      : links = links ?? [],
        extensions = extensions ?? <String, String>{},
        rtepts = rtepts ?? [];

  @override
  // ignore: type_annotate_public_apis
  bool operator ==(other) {
    if (other is Rte) {
      return other.name == name &&
          other.cmt == cmt &&
          other.desc == desc &&
          other.src == src &&
          const ListEquality().equals(other.links, links) &&
          other.number == number &&
          other.type == type &&
          const MapEquality().equals(other.extensions, extensions) &&
          const ListEquality().equals(other.rtepts, rtepts);
    }

    return false;
  }

  @override
  String toString() => "Rte[${[name, type, extensions, rtepts].join(",")}]";

  @override
  int get hashCode => hashObjects([
        name,
        cmt,
        desc,
        src,
        ...links,
        number,
        type,
        ...extensions.keys,
        ...extensions.values,
        ...rtepts
      ]);
}
