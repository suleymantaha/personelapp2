// ignore_for_file: depend_on_referenced_packages
import 'package:xml/xml.dart';

String _text(String value) => XmlText(value).toXmlString();

/// Native chart series reference worksheet cells, with matching offline caches.
String monthlyChartXml(String sheet, List<String> labels, List<int> values,
    {required bool horizontal, List<int>? planned}) {
  final last = labels.length + 1;
  final escapedSheet = sheet.replaceAll("'", "''");
  final category = _text("'$escapedSheet'!\$A\$2:\$A\$$last");
  String points(Iterable<Object> items) => items.indexed
      .map((p) =>
          '<c:pt idx="${p.$1}"><c:v>${_text(p.$2.toString())}</c:v></c:pt>')
      .join();
  String series(
      int index, String column, List<int> counts, String name, String color) {
    final numbers = _text("'$escapedSheet'!\$$column\$2:\$$column\$$last");
    return '''<c:ser><c:idx val="$index"/><c:order val="$index"/>
<c:tx><c:v>$name</c:v></c:tx>
<c:spPr><a:solidFill><a:srgbClr val="$color"/></a:solidFill></c:spPr>
<c:cat><c:strRef><c:f>$category</c:f><c:strCache>
<c:ptCount val="${labels.length}"/>${points(labels)}</c:strCache></c:strRef></c:cat>
<c:val><c:numRef><c:f>$numbers</c:f><c:numCache><c:formatCode>0</c:formatCode>
<c:ptCount val="${counts.length}"/>${points(counts)}</c:numCache></c:numRef></c:val>
</c:ser>''';
  }

  final seriesXml = horizontal
      ? series(0, 'B', values, 'Görevlendirme', '2470A0')
      : series(0, 'D', values, 'Kayıtlı atama', '2470A0') +
          series(1, 'E', planned!, 'Planlanan atama', 'E59D23');
  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<c:chartSpace xmlns:c="http://schemas.openxmlformats.org/drawingml/2006/chart"
 xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
<c:lang val="tr-TR"/><c:chart><c:autoTitleDeleted val="1"/>
<c:plotArea><c:layout/><c:barChart><c:barDir val="${horizontal ? 'bar' : 'col'}"/>
<c:grouping val="clustered"/><c:varyColors val="0"/>$seriesXml
<c:gapWidth val="80"/><c:axId val="100"/><c:axId val="200"/></c:barChart>
<c:catAx><c:axId val="100"/><c:scaling><c:orientation val="minMax"/></c:scaling>
<c:delete val="0"/><c:axPos val="${horizontal ? 'l' : 'b'}"/>
<c:tickLblPos val="nextTo"/><c:crossAx val="200"/><c:crosses val="autoZero"/>
<c:auto val="1"/><c:lblAlgn val="ctr"/><c:lblOffset val="100"/></c:catAx>
<c:valAx><c:axId val="200"/><c:scaling><c:orientation val="minMax"/>
<c:min val="0"/></c:scaling><c:delete val="0"/><c:axPos val="${horizontal ? 'b' : 'l'}"/>
<c:majorGridlines/><c:numFmt formatCode="0" sourceLinked="0"/>
<c:tickLblPos val="nextTo"/><c:crossAx val="100"/><c:crosses val="autoZero"/>
<c:crossBetween val="between"/></c:valAx></c:plotArea>
<c:legend><c:legendPos val="b"/><c:overlay val="0"/></c:legend>
<c:plotVisOnly val="1"/><c:dispBlanksAs val="zero"/></c:chart></c:chartSpace>''';
}

String monthlyChartDrawing(int index) =>
    '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xdr:wsDr xmlns:xdr="http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing"
 xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
<xdr:oneCellAnchor><xdr:from><xdr:col>6</xdr:col><xdr:colOff>0</xdr:colOff>
<xdr:row>1</xdr:row><xdr:rowOff>0</xdr:rowOff></xdr:from>
<xdr:ext cx="8382000" cy="4572000"/><xdr:graphicFrame macro="">
<xdr:nvGraphicFramePr><xdr:cNvPr id="$index" name="Görevlendirme $index"/>
<xdr:cNvGraphicFramePr/></xdr:nvGraphicFramePr>
<xdr:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/></xdr:xfrm>
<a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/chart">
<c:chart xmlns:c="http://schemas.openxmlformats.org/drawingml/2006/chart"
 xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" r:id="rId1"/>
</a:graphicData></a:graphic></xdr:graphicFrame><xdr:clientData/></xdr:oneCellAnchor></xdr:wsDr>''';
