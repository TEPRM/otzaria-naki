import 'package:flutter/material.dart';
import 'package:otzaria/search/models/search_configuration.dart';

/// תווית עברית למצב החיפוש שהניב את התוצאה — משמשת את תגית ההתאמה
/// על כרטיסי התוצאות ([SearchResultMatchTag]).
String searchModeLabel(SearchMode mode) {
  switch (mode) {
    case SearchMode.advanced:
      return 'חיפוש מתקדם';
    case SearchMode.exact:
      return 'חיפוש מדוייק';
    case SearchMode.fuzzy:
      return 'חיפוש מקורב';
  }
}

/// תגית סוג-ההתאמה שעל כרטיס תוצאת חיפוש.
///
/// מוצגת לצד תגית המקור ([SearchResultSourceTag]) באותו עיצוב כללי, אך
/// בצבע משני, כדי שאפשר יהיה לראות במבט אחת באיזה מצב חיפוש התוצאה
/// נמצאה, וכמה אופסטים (טווחי-תווים) חולצו מסימון המנוע עבורה.
///
/// * [engineMarked] = `true`: ההדגשה באה מסימון המנוע, ו-[matchCount] הוא
///   מספר טווחי ההתאמה שחולצו ממנו ("אופסטים מהמנוע").
/// * [engineMarked] = `false`: המנוע לא סימן את התוצאה (למשל שורה
///   מאוחדת), וההדגשה נופלת בחזרה להדגשה עצמאית בצד האפליקציה.
class SearchResultMatchTag extends StatelessWidget {
  final String label;
  final String tooltip;
  final int matchCount;
  final bool engineMarked;

  const SearchResultMatchTag({
    super.key,
    required this.label,
    required this.tooltip,
    required this.matchCount,
    required this.engineMarked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: cs.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          // נוסחת התווית: מצב החיפוש + מקור האופסטים. קצר בכוונה כדי שלא
          // ידחוק את שם הספר בשורה הצרה.
          engineMarked ? '$label · $matchCount' : label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
