#!/usr/bin/env bash
# apply-fork-overlay.sh — מחיל את שכבת ה-fork על גבי עץ upstream טרי.
#
# מודל הסנכרון: מאפסים את dev ל-upstream/dev (לוקחים את המקורי במלואו),
# ואז מריצים את הסקריפט הזה. הסקריפט דטרמיניסטי ואידמפוטנטי — אין מיזוג,
# אין "קבצים מוגנים", ואין קונפליקטים.
#
# שני חלקים:
#   1) זהות ה-fork (חובה) — מעדכן התוכנה ומקור ה-allowlist מצביעים ל-fork.
#   2) הסרת התיאורים (best-effort) — patch; אם לא חל, מדווחים וממשיכים.
#
# אין `set -e`: צעד אופציונלי לא מפיל את ה-job. כל בעיה מדווחת כ-::warning::.
set -uo pipefail

ROOT="${1:-.}"
cd "$ROOT" || { echo "::error::cannot cd to $ROOT"; exit 1; }
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

warn() { echo "::warning title=fork-overlay::$*"; echo "WARN: $*"; }

# --- 1) זהות ה-fork ---------------------------------------------------------
apply_identity() {
  local file="$1" from="$2" to="$3"
  if [ ! -f "$file" ]; then warn "missing $file — skipping identity"; return 0; fi
  if grep -qF "$from" "$file"; then
    local fe te
    fe=$(printf '%s' "$from" | sed -e 's/[\/&]/\&/g')
    te=$(printf '%s' "$to" | sed -e 's/[\/&]/\&/g')
    sed -i "s/$fe/$te/g" "$file"
    echo "identity: $file  ->  $to"
  else
    warn "identity anchor not found in $file (upstream may have refactored)"
  fi
  return 0
}

apply_identity "lib/update/my_update_widget.dart" \
  "_githubOwner = 'Otzaria'" "_githubOwner = 'TEPRM'"
apply_identity "lib/update/my_update_widget.dart" \
  "_githubRepository = 'otzaria'" "_githubRepository = 'otzaria-naki'"
apply_identity "lib/plugins/services/plugin_network_access_resolver.dart" \
  "_officialOwner = 'Otzaria'" "_officialOwner = 'TEPRM'"
apply_identity "lib/plugins/services/plugin_network_access_resolver.dart" \
  "_officialRepository = 'otzaria'" "_officialRepository = 'otzaria-naki'"

# --- 2) הסרת התיאורים (best-effort) ---------------------------------------
PATCH="$HERE/descriptions.patch"
if [ ! -f "$PATCH" ]; then
  warn "descriptions.patch missing — skipping description removal"
else
  if git apply --3way "$PATCH" 2>/dev/null; then
    echo "descriptions: applied (git apply --3way)"
  elif patch -p1 --forward --fuzz=3 < "$PATCH" >/dev/null 2>&1; then
    echo "descriptions: applied (patch -p1 --fuzz=3)"
  else
    warn "descriptions patch did not apply — upstream refactored; descriptions may remain until the patch is refreshed"
  fi
fi

echo "fork overlay applied."
exit 0
