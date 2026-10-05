import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:otzaria/library/models/library.dart';
import 'package:otzaria/widgets/dialogs/dialogs_exports.dart';
import 'package:otzaria/widgets/misc/app_selection_area.dart';
import 'package:otzaria_icons/otzaria_icons.dart';

/// מציג את כל פרטי הקטגוריה הזמינים.
Future<void> showCategoryDetailsDialog(
  BuildContext context,
  Category category,
) async {
  await showSingleActionDialog(
    context: context,
    title: 'אודות הקטגוריה',
    confirmText: 'סגור',
    customContent: _CategoryDetailsDialogContent(category: category),
  );
}

class _CategoryDetailsDialogContent extends StatelessWidget {
  const _CategoryDetailsDialogContent({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 450,
      child: AppSelectionArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // אותם אייקונים כמו ב"אודות הספר", כדי ששני הדיאלוגים ייקראו
              // כאותה טבלת פרטים.
              DetailsInfoSection(
                title: 'שם הקטגוריה:',
                icon: FluentIcons.folder_24_regular,
                value: category.title,
              ),
              // תיאורי הקטגוריה (קצר ומורחב) הוסרו ב-fork — מוצג רק שם הקטגוריה.
            ],
          ),
        ),
      ),
    );
  }
}
