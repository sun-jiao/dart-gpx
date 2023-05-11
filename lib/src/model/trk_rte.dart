import 'link.dart';

abstract class TrkRte{
  /// GPS name of track.
  String? name;

  /// GPS comment for track.
  String? cmt;

  /// User description of track.
  String? desc;

  /// Source of data. Included to give user some idea of reliability and
  /// accuracy of data.
  String? src;

  /// Links to external information about the track.
  late List<Link> links;

  /// GPS track number.
  int? number;

  /// Type (classification) of track.
  String? type;

  /// You can add extend GPX by adding your own elements from another schema
  /// here.
  late Map<String, String> extensions;

  // Element tag.
  late String tag;
}