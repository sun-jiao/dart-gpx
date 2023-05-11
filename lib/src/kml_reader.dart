import 'package:gpx/src/model/gpx_object.dart';
import 'package:xml/xml_events.dart';

import 'model/copyright.dart';
import 'model/email.dart';
import 'model/gpx.dart';
import 'model/gpx_tag.dart';
import 'model/kml_tag.dart';
import 'model/link.dart';
import 'model/metadata.dart';
import 'model/person.dart';
import 'model/rte.dart';
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
    String? desc;
    Person? author;

    while (iterator.moveNext()) {
      final val = iterator.current;

      if (val is XmlStartElementEvent) {
        switch (val.name) {
          case KmlTagV22.document:
            break;
          case KmlTagV22.kml:
            break;
          case KmlTagV22.name:
            kmlName = _readString(iterator, val.name);
            break;
          case KmlTagV22.desc:
            desc = _readString(iterator, val.name);
            break;
          case KmlTagV22.author:
            author = _readPerson(iterator);
            break;
          case KmlTagV22.extendedData:
            gpx.metadata = _parseMetadata(iterator);
            break;
          case KmlTagV22.placemark:
            final item = _readPlacemark(iterator, val.name);
            if (item is Wpt) {
              gpx.wpts.add(item);
            } else if (item is Rte) {
              gpx.rtes.add(item);
            }
            break;
          default:
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

    if (author != null){
      gpx.metadata ??= Metadata();
      gpx.metadata!.desc = desc;
    }

    return gpx;
  }

  Metadata _parseMetadata(Iterator<XmlEvent> iterator) {
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
                  metadata.keywords = _readData(iterator, _readString);
                  break;
                case KmlTagV22.time:
                  metadata.time = _readData(iterator, _readDateTime);
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
  
  Object _readPlacemark(Iterator<XmlEvent> iterator, String tagName) {
    var item = GpxObject();
    final elm = iterator.current;
    DateTime? time;
    Wpt? ext;

    if ((elm is XmlStartElementEvent) && !elm.isSelfClosing) {
      while (iterator.moveNext()) {
        final val = iterator.current;

        if (val is XmlStartElementEvent) {
          switch (val.name) {
            case KmlTagV22.name:
              item.name = _readString(iterator, val.name);
              break;
            case KmlTagV22.desc:
              item.desc = _readString(iterator, val.name);
              break;
            case KmlTagV22.link:
              item.links.add(_readLink(iterator));
              break;
            case KmlTagV22.extendedData:
              ext = _readExtended(iterator);
              break;
            case KmlTagV22.timestamp:
              time = _readData(iterator, _readDateTime,
                  tagName: KmlTagV22.when);
              break;
            case KmlTagV22.point:
              final coor = _readCoordinate(iterator);
              item = item as Wpt;
              item.lon = coor.lon;
              item.lat = coor.lat;
              item.ele = coor.ele;
              break;
            case KmlTagV22.track:
            case KmlTagV22.ring:

              break;
            default:
              break;
          }
        }

        if (val is XmlEndElementEvent && val.name == tagName) {
          break;
        }
      }
    }

    if (item is Wpt && ext != null){
      item.magvar = ext.magvar;
      item.sat = ext.sat;
      item.src = ext.src;
      item.hdop = ext.hdop;
      item.vdop = ext.vdop;
      item.pdop = ext.pdop;
      item.geoidheight = ext.geoidheight;
      item.ageofdgpsdata = ext.ageofdgpsdata;
      item.dgpsid = ext.dgpsid;
      item.cmt = ext.cmt;
      item.type = ext.type;
    }

    return item;
  }
  
  double? _readDouble(Iterator<XmlEvent> iterator, String tagName) {
    final doubleString = _readString(iterator, tagName);
    return doubleString != null ? double.parse(doubleString) : null;
  }

  int? _readInt(Iterator<XmlEvent> iterator, String tagName) {
    final intString = _readString(iterator, tagName);
    return intString != null ? int.parse(intString) : null;
  }

  DateTime? _readDateTime(Iterator<XmlEvent> iterator, String tagName) {
    final dateTimeString = _readString(iterator, tagName);
    return dateTimeString != null ? DateTime.parse(dateTimeString) : null;
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
        string += val.text;
      }

      if (val is XmlCDATAEvent) {
        string += val.text;
      }

      if (val is XmlEndElementEvent && val.name == tagName) {
        break;
      }
    }

    return string.trim();
  }

  T? _readData<T>(Iterator<XmlEvent> iterator,
      T? Function(Iterator<XmlEvent> iterator, String tagName) function,
      {String? tagName}) {
    tagName ??= KmlTagV22.value;

    final elm = iterator.current;

    if (elm is XmlStartElementEvent) {
      if (!elm.isSelfClosing) {
        while (iterator.moveNext()) {
          final val = iterator.current;

          if (val is XmlStartElementEvent) {
            if (val.name == tagName){
              return function(iterator, tagName);
            }

            if (elm.isSelfClosing && val.name == KmlTagV22.data) {
              break;
            }
          }
        }
      }
    }
    return null;
  }

  Wpt _readExtended(Iterator<XmlEvent> iterator) {
    final wpt = Wpt();
    final elm = iterator.current;

    if ((elm is XmlStartElementEvent) && !elm.isSelfClosing) {
      while (iterator.moveNext()) {
        final val = iterator.current;

        if (val is XmlStartElementEvent && val.name == KmlTagV22.data) {
          for (final attribute in val.attributes){
            if (attribute.name == KmlTagV22.name){
              switch (attribute.value) {
                case GpxTagV11.magVar:
                  wpt.magvar = _readData(iterator, _readDouble);
                  break;

                case GpxTagV11.sat:
                  wpt.sat = _readData(iterator, _readInt);
                  break;
                case GpxTagV11.src:
                  wpt.src = _readData(iterator, _readString);
                  break;
                  
                case GpxTagV11.hDOP:
                  wpt.hdop = _readData(iterator, _readDouble);
                  break;
                case GpxTagV11.vDOP:
                  wpt.vdop = _readData(iterator, _readDouble);
                  break;
                case GpxTagV11.pDOP:
                  wpt.pdop = _readData(iterator, _readDouble);
                  break;

                case GpxTagV11.geoidHeight:
                  wpt.geoidheight = _readData(iterator, _readDouble);
                  break;
                case GpxTagV11.ageOfData:
                  wpt.ageofdgpsdata = _readData(iterator, _readDouble);
                  break;
                case GpxTagV11.dGPSId:
                  wpt.dgpsid = _readData(iterator, _readInt);
                  break;
                  
                case GpxTagV11.comment:
                  wpt.cmt = _readData(iterator, _readString);
                  break;
                case GpxTagV11.type:
                  wpt.type = _readData(iterator, _readString);
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

    return wpt;
  }
  
  Wpt _readCoordinate(Iterator<XmlEvent> iterator){
    final wpt = Wpt();
    final elm = iterator.current;

    if ((elm is XmlStartElementEvent) && !elm.isSelfClosing) {
      while (iterator.moveNext()) {
        final val = iterator.current;

        if (val is XmlStartElementEvent) {
          switch (val.name) {
            case KmlTagV22.altitudeMode:
              break;
            case KmlTagV22.coordinates:
              final coordinate = _readString(iterator, KmlTagV22.coordinates);
              final list = coordinate?.split(',');
              if (list != null && list.length >= 3){
                wpt.lon = double.parse(list[0]);
                wpt.lat = double.parse(list[1]);
                wpt.ele = double.parse(list[2]);
              }
              break;
          }
        }

        if (val is XmlEndElementEvent && val.name == KmlTagV22.point) {
          break;
        }
      }
    }

    return wpt;
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
              person.email = _readEmail(iterator);
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
                final copyrightSplit = copyrightText.split(', ');

                if (copyrightSplit.length != 2){
                  throw const FormatException(
                      'Supplied copyright text is not right.');
                } else {
                  copyright.author = copyrightSplit[0];
                  copyright.year = int.parse(copyrightSplit[1]);
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

  Email _readEmail(Iterator<XmlEvent> iterator) {
    final email = Email();
    final elm = iterator.current;

    if (elm is XmlStartElementEvent) {
      if (elm.name == KmlTagV22.email){
        final emailText = _readString(iterator, KmlTagV22.email);
        if (emailText != null){
          final emailSplit = emailText.split('@');

          if (emailSplit.length != 2){
            throw const FormatException(
                'Supplied email address is not in the right format.');
          } else {
            email.id = emailSplit[0];
            email.domain = emailSplit[1];
          }
        }
      }
    }

    return email;
  }
}

