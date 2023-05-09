import 'package:xml/xml.dart';

import 'model/gpx.dart';
import 'model/gpx_tag.dart';
import 'model/kml_tag.dart';
import 'model/link.dart';
import 'model/metadata.dart';
import 'model/rte.dart';
import 'model/trk.dart';
import 'model/wpt.dart';

/// KML 2.2 AltitudeMode values
enum AltitudeMode {
  absolute,
  clampToGround,
  relativeToGround,
}

/// Convert Gpx into KML
class KmlWriter {
  final AltitudeMode altitudeMode;

  KmlWriter({this.altitudeMode = AltitudeMode.absolute});

  String get _altitudeModeString {
    final strVal = altitudeMode.toString();
    return strVal.substring(strVal.indexOf('.') + 1);
  }

  /// Convert Gpx into KML as String
  String asString(Gpx gpx, {bool pretty = false}) =>
      _build(gpx).toXmlString(pretty: pretty);

  /// Convert Gpx into KML as XmlNode
  XmlNode asXml(Gpx gpx) => _build(gpx);

  XmlNode _build(Gpx gpx) {
    final builder = XmlBuilder();

    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(KmlTagV22.kml, nest: () {
      builder.attribute('xmlns', 'http://www.opengis.net/kml/2.2');

      builder.element(KmlTagV22.document, nest: () {
        if (gpx.metadata != null) {
          _writeMetadata(builder, gpx.metadata!);
        }

        for (final wpt in gpx.wpts) {
          _writePoint(builder, KmlTagV22.placemark, wpt);
        }

        for (final rte in gpx.rtes) {
          _writeRoute(builder, rte);
        }

        for (final trk in gpx.trks) {
          _writeTrack(builder, trk);
        }
      });
    });

    return builder.buildDocument();
  }

  void _writeMetadata(XmlBuilder builder, Metadata metadata) {
    _writeElement(builder, KmlTagV22.name, metadata.name);
    _writeElement(builder, KmlTagV22.desc, metadata.desc);

    if (metadata.author != null) {
      builder.element(KmlTagV22.author, nest: () {
        _writeElement(builder, KmlTagV22.authorName, metadata.author?.name);
        if (metadata.author?.email?.id != null &&
            metadata.author?.email?.domain != null) {
          final email =
              '${metadata.author!.email!.id}@${metadata.author!.email!.domain}';
          _writeElement(builder, KmlTagV22.email, email);
        }

        _writeElement(builder, KmlTagV22.uri, metadata.author?.link?.href);
      });
    }

    builder.element(KmlTagV22.extendedData, nest: () {
      _writeExtendedElement(builder, GpxTagV11.keywords, metadata.keywords);

      if (metadata.time != null) {
        _writeExtendedElement(
            builder, GpxTagV11.time, metadata.time?.toIso8601String());
      }

      if (metadata.copyright != null) {
        _writeExtendedElement(builder, GpxTagV11.copyright,
            '${metadata.copyright!.author}, ${metadata.copyright!.year}');
      }
    });
  }

  void _writeRoute(XmlBuilder builder, Rte rte) {
    builder.element(KmlTagV22.placemark, nest: () {
      _writeElement(builder, GpxTagV11.name, rte.name);
      _writeElement(builder, GpxTagV11.desc, rte.desc);
      _writeAtomLinks(builder, rte.links);

      builder.element(KmlTagV22.extendedData, nest: () {
        _writeExtendedElement(builder, GpxTagV11.comment, rte.cmt);
        _writeExtendedElement(builder, GpxTagV11.type, rte.type);

        _writeExtendedElement(builder, GpxTagV11.src, rte.src);
        _writeExtendedElement(builder, GpxTagV11.number, rte.number);
      });

      builder.element(KmlTagV22.track, nest: () {
        _writeElement(builder, KmlTagV22.extrude, 1);
        _writeElement(builder, KmlTagV22.tessellate, 1);
        _writeElement(builder, KmlTagV22.altitudeMode, _altitudeModeString);

        _writeElement(
            builder,
            KmlTagV22.coordinates,
            rte.rtepts
                .map((wpt) => [wpt.lon, wpt.lat, wpt.ele ?? 0].join(','))
                .join('\n'));
      });
    });
  }

  void _writeTrack(XmlBuilder builder, Trk trk) {
    builder.element(KmlTagV22.placemark, nest: () {
      _writeElement(builder, KmlTagV22.name, trk.name);
      _writeElement(builder, KmlTagV22.desc, trk.desc);
      _writeAtomLinks(builder, trk.links);

      builder.element(KmlTagV22.extendedData, nest: () {
        _writeExtendedElement(builder, GpxTagV11.comment, trk.cmt);
        _writeExtendedElement(builder, GpxTagV11.type, trk.type);

        _writeExtendedElement(builder, GpxTagV11.src, trk.src);
        _writeExtendedElement(builder, GpxTagV11.number, trk.number);
      });

      builder.element(KmlTagV22.track, nest: () {
        _writeElement(builder, KmlTagV22.extrude, 1);
        _writeElement(builder, KmlTagV22.tessellate, 1);
        _writeElement(builder, KmlTagV22.altitudeMode, _altitudeModeString);

        _writeElement(
            builder,
            KmlTagV22.coordinates,
            trk.trksegs
                .expand((trkseg) => trkseg.trkpts)
                .map((wpt) => [wpt.lon, wpt.lat, wpt.ele ?? 0].join(','))
                .join('\n'));
      });
    });
  }

  void _writePoint(XmlBuilder builder, String tagName, Wpt wpt) {
    builder.element(tagName, nest: () {
      _writeElement(builder, KmlTagV22.name, wpt.name);
      _writeElement(builder, KmlTagV22.desc, wpt.desc);

      _writeElementWithTime(builder, wpt.time);

      _writeAtomLinks(builder, wpt.links);

      builder.element(KmlTagV22.extendedData, nest: () {
        _writeExtendedElement(builder, GpxTagV11.magVar, wpt.magvar);

        _writeExtendedElement(builder, GpxTagV11.sat, wpt.sat);
        _writeExtendedElement(builder, GpxTagV11.src, wpt.src);

        _writeExtendedElement(builder, GpxTagV11.hDOP, wpt.hdop);
        _writeExtendedElement(builder, GpxTagV11.vDOP, wpt.vdop);
        _writeExtendedElement(builder, GpxTagV11.pDOP, wpt.pdop);

        _writeExtendedElement(builder, GpxTagV11.geoidHeight, wpt.geoidheight);
        _writeExtendedElement(builder, GpxTagV11.ageOfData, wpt.ageofdgpsdata);
        _writeExtendedElement(builder, GpxTagV11.dGPSId, wpt.dgpsid);

        _writeExtendedElement(builder, GpxTagV11.comment, wpt.cmt);
        _writeExtendedElement(builder, GpxTagV11.type, wpt.type);
      });

      builder.element(KmlTagV22.point, nest: () {
        if (wpt.ele != null) {
          _writeElement(builder, KmlTagV22.altitudeMode, _altitudeModeString);
        }

        _writeElement(builder, KmlTagV22.coordinates,
            [wpt.lon, wpt.lat, wpt.ele ?? 0].join(','));
      });
    });
  }

  void _writeElement(XmlBuilder builder, String tagName, Object? value) {
    if (value != null) {
      builder.element(tagName, nest: value);
    }
  }

  void _writeAtomLinks(XmlBuilder builder, List<Link> value) {
    for (final link in value) {
      builder.element(KmlTagV22.link, nest: link.href);
    }
  }

  void _writeExtendedElement(XmlBuilder builder, String tagName, value) {
    if (value != null) {
      builder.element(KmlTagV22.data, nest: () {
        builder.attribute(KmlTagV22.name, tagName);
        builder.element(KmlTagV22.value, nest: value);
      });
    }
  }

  void _writeElementWithTime(XmlBuilder builder, DateTime? value) {
    if (value != null) {
      builder.element(KmlTagV22.timestamp, nest: () {
        builder.element(KmlTagV22.when, nest: value.toUtc().toIso8601String());
      });
    }
  }
}
