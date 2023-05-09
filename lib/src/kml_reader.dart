import 'package:gpx/src/model/kml_tag.dart';
import 'package:xml/xml_events.dart';

import 'model/copyright.dart';
import 'model/email.dart';
import 'model/gpx.dart';
import 'model/gpx_tag.dart';
import 'model/link.dart';
import 'model/metadata.dart';
import 'model/person.dart';
import 'model/wpt.dart';

/// Read Gpx from string
class KmlReader {
//  // @TODO
//  Gpx fromStream(Stream<int> stream) {
//
//  }

  /// Parse xml string and create Gpx object
  Gpx fromString(String xml) {
    final iterator = parseEvents(xml).iterator;

    // ignore: avoid_as
    final gpx = Gpx();
    String? kmlName;
    Person? author;

    while (iterator.moveNext()) {
      final val = iterator.current;

      if (val is XmlStartElementEvent) {
        switch (val.name) {
          case KmlTagV22.kml:
            break;
          case KmlTagV22.name:
            kmlName = _readString(iterator, val.name);
            break;
          case KmlTagV22.author:
            author = _readPerson(iterator);
            break;
          case KmlTagV22.extendedData:
            gpx.metadata = _parseExtendedData(iterator);
            break;
          case KmlTagV22.placemark:
            gpx.wpts.add(_readPlacemark(iterator, val.name));
            break;
        }
      }
    }

    if (kmlName != null) {
      gpx.metadata ??= Metadata();
      gpx.metadata!.name = kmlName;
    }

    if (author != null){
      gpx.metadata ??= Metadata();
      gpx.metadata!.author = author;
    }

    return gpx;
  }

  Metadata _parseExtendedData(Iterator<XmlEvent> iterator) {
    final metadata = Metadata();
    final elm = iterator.current;

    if ((elm is XmlStartElementEvent) && !elm.isSelfClosing) {
      while (iterator.moveNext()) {
        final val = iterator.current;

        if (val is XmlStartElementEvent && val.name == KmlTagV22.data) {
          for (final attribute in val.attributes){
            if (attribute.name == KmlTagV22.name){
              switch (attribute.value) {
                case KmlTagV22.copyright:
                  metadata.copyright = _readCopyright(iterator);
                  break;
                case KmlTagV22.keywords:
                  metadata.keywords = _readString(iterator, val.name);
                  break;
                case KmlTagV22.time:
                  metadata.time = _readExtendedDataDateTime(iterator);
                  break;
              }
            }
          }
        }

        if (val is XmlEndElementEvent && val.name == KmlTagV22.extendedData) {
          break;
        }
      }
    }

    return metadata;
  }
  
  Wpt _readPlacemark(Iterator<XmlEvent> iterator, String tagName) {
    final wpt = Wpt();
    final elm = iterator.current;

    if (elm is XmlStartElementEvent) {
      wpt.lat = double.parse(elm.attributes
          .firstWhere((attr) => attr.name == GpxTagV11.latitude)
          .value);
      wpt.lon = double.parse(elm.attributes
          .firstWhere((attr) => attr.name == GpxTagV11.longitude)
          .value);
    }

    if ((elm is XmlStartElementEvent) && !elm.isSelfClosing) {
      while (iterator.moveNext()) {
        final val = iterator.current;

        if (val is XmlStartElementEvent) {
          switch (val.name) {
            case GpxTagV11.sym:
              wpt.sym = _readString(iterator, val.name);
              break;

            case GpxTagV11.fix:
              final fixAsString = _readString(iterator, val.name);
              wpt.fix = FixType.values.firstWhere(
                      (e) =>
                  e.toString().replaceFirst('.fix_', '.') ==
                      'FixType.$fixAsString',
                  orElse: () => FixType.unknown);

              if (wpt.fix == FixType.unknown) {
                wpt.fix = null;
              }
              break;

            case GpxTagV11.dGPSId:
              wpt.dgpsid = _readInt(iterator, val.name);
              break;

            case GpxTagV11.name:
              wpt.name = _readString(iterator, val.name);
              break;
            case GpxTagV11.desc:
              wpt.desc = _readString(iterator, val.name);
              break;
            case GpxTagV11.comment:
              wpt.cmt = _readString(iterator, val.name);
              break;
            case GpxTagV11.src:
              wpt.src = _readString(iterator, val.name);
              break;
            case GpxTagV11.link:
              wpt.links.add(_readLink(iterator));
              break;
            case GpxTagV11.hDOP:
              wpt.hdop = _readDouble(iterator, val.name);
              break;
            case GpxTagV11.vDOP:
              wpt.vdop = _readDouble(iterator, val.name);
              break;
            case GpxTagV11.pDOP:
              wpt.pdop = _readDouble(iterator, val.name);
              break;
            case GpxTagV11.ageOfData:
              wpt.ageofdgpsdata = _readDouble(iterator, val.name);
              break;

            case GpxTagV11.magVar:
              wpt.magvar = _readDouble(iterator, val.name);
              break;
            case GpxTagV11.geoidHeight:
              wpt.geoidheight = _readDouble(iterator, val.name);
              break;

            case GpxTagV11.sat:
              wpt.sat = _readInt(iterator, val.name);
              break;

            case GpxTagV11.elevation:
              wpt.ele = _readDouble(iterator, val.name);
              break;
            case GpxTagV11.time:
              wpt.time = _readDateTime(iterator, val.name);
              break;
            case GpxTagV11.type:
              wpt.type = _readString(iterator, val.name);
              break;
            case GpxTagV11.extensions:
              wpt.extensions = _readExtensions(iterator);
              break;
          }
        }

        if (val is XmlEndElementEvent && val.name == tagName) {
          break;
        }
      }
    }

    return wpt;
  }

  DateTime? _readDateTime(Iterator<XmlEvent> iterator, String tagName) {
    final dateTimeString = _readString(iterator, tagName);
    return dateTimeString != null ? DateTime.parse(dateTimeString) : null;
  }

  double? _readDouble(Iterator<XmlEvent> iterator, String tagName) {
    final doubleString = _readString(iterator, tagName);
    return doubleString != null ? double.parse(doubleString) : null;
  }

  int? _readInt(Iterator<XmlEvent> iterator, String tagName) {
    final intString = _readString(iterator, tagName);
    return intString != null ? int.parse(intString) : null;
  }

  DateTime? _readExtendedDataDateTime(Iterator<XmlEvent> iterator) {
    final elm = iterator.current;

    if (elm is XmlStartElementEvent) {
      if (!elm.isSelfClosing) {
        while (iterator.moveNext()) {
          final val = iterator.current;

          if (val is XmlStartElementEvent) {
            if (val.name == KmlTagV22.value){

              final dateTimeString = _readString(iterator, val.name);
              return dateTimeString != null ? DateTime.parse(dateTimeString.trim()) : null;
            }
          }

          if (val is XmlEndElementEvent && val.name == KmlTagV22.data) {
            break;
          }
        }
      }
    }
    return null;
  }

  String? _readString(Iterator<XmlEvent> iterator, String tagName) {
    final elm = iterator.current;
    if (!(elm is XmlStartElementEvent &&
        elm.name == tagName &&
        !elm.isSelfClosing)) {
      return null;
    }

    var string = '';
    while (iterator.moveNext()) {
      final val = iterator.current;

      if (val is XmlTextEvent) {
        string += val.value;
      }

      if (val is XmlCDATAEvent) {
        string += val.value;
      }

      if (val is XmlEndElementEvent && val.name == tagName) {
        break;
      }
    }

    return string.trim();
  }

  Map<String, String> _readExtensions(Iterator<XmlEvent> iterator) {
    final exts = <String, String>{};
    final elm = iterator.current;

    /*if (elm is XmlStartElementEvent) {
      link.href = elm.attributes
          .firstWhere((attr) => attr.name == GpxTagV11.href)
          .value;
    }*/

    if ((elm is XmlStartElementEvent) && !elm.isSelfClosing) {
      while (iterator.moveNext()) {
        final val = iterator.current;

        if (val is XmlStartElementEvent) {
          exts[val.name] = _readString(iterator, val.name) ?? '';
        }

        if (val is XmlEndElementEvent && val.name == GpxTagV11.extensions) {
          break;
        }
      }
    }

    return exts;
  }

  Link _readLink(Iterator<XmlEvent> iterator) {
    final link = Link();
    final elm = iterator.current;

    if (elm is XmlStartElementEvent) {
      link.href = elm.attributes
          .firstWhere((attr) => attr.name == GpxTagV11.href)
          .value;
    }

    if ((elm is XmlStartElementEvent) && !elm.isSelfClosing) {
      while (iterator.moveNext()) {
        final val = iterator.current;

        if (val is XmlStartElementEvent) {
          switch (val.name) {
            case GpxTagV11.text:
              link.text = _readString(iterator, val.name);
              break;
            case GpxTagV11.type:
              link.type = _readString(iterator, val.name);
              break;
          }
        }

        if (val is XmlEndElementEvent && val.name == GpxTagV11.link) {
          break;
        }
      }
    }

    return link;
  }

  Person _readPerson(Iterator<XmlEvent> iterator) {
    final person = Person();
    final elm = iterator.current;

    if ((elm is XmlStartElementEvent) && !elm.isSelfClosing) {
      while (iterator.moveNext()) {
        final val = iterator.current;

        if (val is XmlStartElementEvent) {
          switch (val.name) {
            case KmlTagV22.authorName:
              person.name = _readString(iterator, val.name);
              break;
            case KmlTagV22.email:
              person.email = _getEmail(_readString(iterator, val.name));
              break;
            case KmlTagV22.uri:
              person.link = Link(href: _readString(iterator, val.name) ?? '');
              break;
          }
        }

        if (val is XmlEndElementEvent && val.name == KmlTagV22.author) {
          break;
        }
      }
    }

    return person;
  }

  Copyright _readCopyright(Iterator<XmlEvent> iterator) {
    final copyright = Copyright();
    final elm = iterator.current;

    if (elm is XmlStartElementEvent) {
      if (!elm.isSelfClosing) {
        while (iterator.moveNext()) {
          final val = iterator.current;

          if (val is XmlStartElementEvent) {
            if (val.name == KmlTagV22.value){
              final copyrightText = _readString(iterator, val.name);
              if (copyrightText != null){
                final copyrightTexts = copyrightText.split(', ');

                if (copyrightTexts.length != 2){
                  throw const FormatException('Supplied copyright text is wrong.');
                } else {
                  copyright.author = copyrightTexts[0];
                  copyright.year = int.parse(copyrightTexts[1]);
                }
              }
            }
          }

          if (val is XmlEndElementEvent && val.name == KmlTagV22.data) {
            break;
          }
        }
      }
    }

    return copyright;
  }

  Email _getEmail(String? emailString) {
    final email = Email();

    if (emailString == null){
      return email;
    }

    final emailStrings = emailString.split('@');

    if (emailStrings.length != 2){
      throw const FormatException('Supplied email address is wrong.');
    } else {
      email.id = emailStrings[0];
      email.domain = emailStrings[1];
    }

    return email;
  }
}
