import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otzaria/search/utils/snippet_builder.dart';

/// בדיקות לשכבת-האופסטים מעל פלט המנוע.
///
/// המנוע אינו מחזיר אופסטים נומריים — הוא מסמן התאמות בתגי `font`/`mark`
/// בתוך ה-HTML. [SnippetBuilder.parseHighlightedHtml] הופך את הסימון
/// הזה לטווחי-תווים `[start, end)` מדויקים, והבדיקות כאן מוודאות שהטווחים
/// אכן נוחתים על המילים שהמנוע סימן, שהטקסט הנקי זהה למה שמרונדר,
/// ושההדגשה מהאופסטים זהה להדגשה הישנה (דרך fromHighlightedHtml).
void main() {
  const defaultStyle = TextStyle(fontSize: 16);
  const highlightStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);

  /// מרעיף את עץ ה-span-ים לרשימת (text, isHighlighted).
  List<(String, bool)> flatten(List<InlineSpan> spans) {
    final result = <(String, bool)>[];
    void visit(List<InlineSpan> children, bool highlighted) {
      for (final span in children) {
        if (span is! TextSpan) continue;
        final isHl = highlighted ||
            (span.style?.fontWeight == FontWeight.bold &&
                span.style != defaultStyle);
        final text = span.toPlainText();
        if (text.isNotEmpty) result.add((text, isHl));
        final kids = span.children;
        if (kids != null) visit(kids, isHl);
      }
    }

    visit(spans, false);
    return result;
  }

  group('parseHighlightedHtml — חליצת אופסטים מסימון המנוע', () {
    test('תג font בודד מניב טווח אחד שמכסה בדיוק את המילה המסומנת', () {
      const html = 'בראשית ברא <font color="red">אלהים</font> את השמים';
      final parsed = SnippetBuilder.parseHighlightedHtml(html);

      expect(parsed.hasEngineMarkup, isTrue);
      expect(parsed.ranges.length, 1);
      expect(
        parsed.plainText.substring(parsed.ranges[0][0], parsed.ranges[0][1]),
        'אלהים',
      );
      expect(
        parsed.plainText,
        'בראשית ברא אלהים את השמים',
      );
    });

    test('מספר התאמות + טקסט מנוקד — כל טווח נוחת על המילה שלו', () {
      // ניקוד וטעמים נשמרים כמו שהם; האופסטים נמדדים על המחרוזת המנוקדת.
      const html = '<font>בְּרֵאשִׁית</font> בָּרָא <font>אֱלֹהִים</font>';
      final parsed = SnippetBuilder.parseHighlightedHtml(html);

      expect(parsed.hasEngineMarkup, isTrue);
      expect(parsed.ranges.length, 2);
      expect(
        parsed.plainText.substring(parsed.ranges[0][0], parsed.ranges[0][1]),
        'בְּרֵאשִׁית',
      );
      expect(
        parsed.plainText.substring(parsed.ranges[1][0], parsed.ranges[1][1]),
        'אֱלֹהִים',
      );
      // הטווחים בסדר עולה וללא חפיפה.
      expect(parsed.ranges[0][1], lessThanOrEqualTo(parsed.ranges[1][0]));
    });

    test('תג mark ותגים מקוננים נספרים כסימון מנוע', () {
      const html = 'לפנים <mark>משורר</mark> וגם <b><font>אחרון</font></b>';
      final parsed = SnippetBuilder.parseHighlightedHtml(html);

      expect(parsed.hasEngineMarkup, isTrue);
      expect(parsed.ranges.length, 2);
      expect(
        parsed.plainText.substring(parsed.ranges[0][0], parsed.ranges[0][1]),
        'משורר',
      );
      expect(
        parsed.plainText.substring(parsed.ranges[1][0], parsed.ranges[1][1]),
        'אחרון',
      );
    });

    test('HTML בלי סימון מנוע — ranges ריק ו-hasEngineMarkup שקר', () {
      const html = 'טקסט רגיל <b>מודגש</b> בלי הדגשת חיפוש';
      final parsed = SnippetBuilder.parseHighlightedHtml(html);

      expect(parsed.hasEngineMarkup, isFalse);
      expect(parsed.ranges, isEmpty);
      expect(parsed.plainText, 'טקסט רגיל מודגש בלי הדגשת חיפוש');
    });

    test('ישויות HTML מפוענחות לפני חישוב האופסטים', () {
      const html = 'ערך &amp; עוד &lt;font&gt;<font>מסומן</font>';
      final parsed = SnippetBuilder.parseHighlightedHtml(html);

      expect(parsed.hasEngineMarkup, isTrue);
      expect(
        parsed.plainText.substring(parsed.ranges[0][0], parsed.ranges[0][1]),
        'מסומן',
      );
      expect(parsed.plainText.contains('&amp;'), isFalse);
    });
  });

  group('עקביות אופסטים ↔ רינדור', () {
    test('spansFromRanges על האופסטים = fromHighlightedHtml ההיסטורי', () {
      const html = 'בראשית <font color="red">ברא</font> <font>אלהים</font> '
          'את <mark>השמים</mark> ואת <font>הארץ</font>';

      final parsed = SnippetBuilder.parseHighlightedHtml(html);
      final fromOffsets = SnippetBuilder.spansFromRanges(
        plainText: parsed.plainText,
        ranges: parsed.ranges,
        defaultStyle: defaultStyle,
        highlightStyle: highlightStyle,
      );
      final legacy = SnippetBuilder.fromHighlightedHtml(
        html: html,
        defaultStyle: defaultStyle,
        highlightStyle: highlightStyle,
      );

      expect(fromOffsets.toPlainText(), legacy.toPlainText());
      // אותם קטעים מסומנים בדיוק, באותו סדר:
      final offsetHighlighted =
          flatten(fromOffsets).where((e) => e.$2).map((e) => e.$1).toList();
      final legacyHighlighted =
          flatten(legacy).where((e) => e.$2).map((e) => e.$1).toList();
      expect(offsetHighlighted, legacyHighlighted);
      expect(offsetHighlighted.join(' '), contains('ברא'));
    });

    test('האופסטים מכסים בדיוק את הקטעים שהרינדור מדגיש', () {
      const html = 'שורה <font>ראשונה</font> ואחריה <font>שנייה</font> סוף';
      final parsed = SnippetBuilder.parseHighlightedHtml(html);
      final spans = SnippetBuilder.spansFromRanges(
        plainText: parsed.plainText,
        ranges: parsed.ranges,
        defaultStyle: defaultStyle,
        highlightStyle: highlightStyle,
      );

      final renderedHighlighted =
          flatten(spans).where((e) => e.$2).map((e) => e.$1).join('|');
      final offsetHighlighted = parsed.ranges
          .map((r) => parsed.plainText.substring(r[0], r[1]))
          .join('|');

      expect(renderedHighlighted, offsetHighlighted);
      expect(renderedHighlighted, 'ראשונה|שנייה');
    });

    test('fromHighlightedHtml עדיין מחזיר טקסט ריק על HTML ריק', () {
      final spans = SnippetBuilder.fromHighlightedHtml(
        html: '',
        defaultStyle: defaultStyle,
        highlightStyle: highlightStyle,
      );
      expect(spans.toPlainText(), '');
    });
  });
}
