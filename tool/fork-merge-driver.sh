#!/usr/bin/env bash
# fork-merge-driver.sh — מיזוג סלקטיבי לקבצים המוגנים של ה-fork.
#
# רקע: ה-fork נוצר כ-snapshot (commit 0f23b62, מסומן ב-tag fork-snapshot-base).
# עבור קובץ מוגן, המיזוג הנכון הוא שלושה-כיווני מול גרסת ה-snapshot:
#   base   = גרסת הקובץ ב-fork-snapshot-base
#   ours   = הגרסה הנוכחית ב-fork (הסרת תיאורים / תיקוני build)
#   theirs = הגרסה החדשה של upstream
# תוצאה: שינויים של upstream באזורים שה-fork לא נגע בהם נכנסים אוטומטית;
# באזורים שה-fork שינה — הגרסה שלנו מנצחת (git merge-file --ours).
#
# הערות חשובות:
# * הבסיס נשלף עם `git cat-file blob` (ולא עם $(git show ...)) — שיטות
#   command substitution מסירות את ה-newline הסופי, וזה שובר את merge-file
#   על תוספות בסוף הקובץ.
# * הקובץ חייב להישאר LF (ראה .gitattributes → tool/*.sh text eol=lf) —
#   אחרת סופי השורות של הסקריפט עצמו שוברים את הפקודות (בעיקר את ה-mv).
#
# ה-driver מוגדר ע"י auto-sync.yml לפני המיזוג (git config merge.<name>.driver),
# וההפנייה אליו נמצאת ב-.gitattributes. דורש את ה-tag fork-snapshot-base.
#
# usage: fork-merge-driver.sh <path-in-repo> <ours-tmp> <base-tmp> <theirs-tmp>
set -u

PATH_IN_REPO="$1"
OURS="$2"
BASE_TMP="$3"
THEIRS="$4"

# נארמליזציה של סופי שורות (LF) — מונעת קונפליקטים מלאכותיים בתערובת CRLF/LF.
normalize() {
  tr -d '\r' < "$1" > "$1.lf" && mv "$1.lf" "$1"
}

cp "$OURS" "$OURS.bak"
normalize "$OURS"
normalize "$BASE_TMP"
normalize "$THEIRS"

if ! git cat-file blob "fork-snapshot-base:$PATH_IN_REPO" > "$OURS.snap" 2>/dev/null; then
  # הקובץ לא היה קיים ב-snapshot (למשל auto-sync.yml) — שומרים את גרסת ה-fork.
  echo "fork-merge-driver: no snapshot base for $PATH_IN_REPO — keeping fork version" >&2
  rm -f "$OURS.bak"
  exit 0
fi
normalize "$OURS.snap"

git merge-file --ours "$OURS" "$OURS.snap" "$THEIRS"
RC=$?
if [ "$RC" -gt 1 ]; then
  # שגיאת מיזוג אמיתית — נשארים עם גרסת ה-fork ומודיעים.
  echo "fork-merge-driver: merge-file error for $PATH_IN_REPO (rc=$RC) — keeping fork version" >&2
  cp "$OURS.bak" "$OURS"
fi
rm -f "$OURS.bak" "$OURS.snap"
exit 0
