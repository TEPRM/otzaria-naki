#!/usr/bin/env bash
# apply-fork-overlay.sh — מחיל את שכבת ה-fork על גבי עץ upstream טרי.
# דטרמיניסטי ואידמפוטנטי — אין מיזוג, אין "קבצים מוגנים", אין קונפליקטים.
set -uo pipefail

ROOT="${1:-.}"
cd "$ROOT" || { echo "::error::cannot cd to $ROOT"; exit 1; }
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
oneline() { tr '\n' '|' | sed 's/|$//'; }
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
    warn "identity anchor NOT found in $file (upstream refactored?)"
  fi
  return 0
}
apply_identity "lib/update/my_update_widget.dart" "_githubOwner = 'Otzaria'" "_githubOwner = 'TEPRM'"
apply_identity "lib/update/my_update_widget.dart" "_githubRepository = 'otzaria'" "_githubRepository = 'otzaria-naki'"
apply_identity "lib/plugins/services/plugin_network_access_resolver.dart" "_officialOwner = 'Otzaria'" "_officialOwner = 'TEPRM'"
apply_identity "lib/plugins/services/plugin_network_access_resolver.dart" "_officialRepository = 'otzaria'" "_officialRepository = 'otzaria-naki'"

# --- 2) הסרת התיאורים (best-effort) ---------------------------------------
PATCH="$HERE/descriptions.patch"
if [ ! -f "$PATCH" ]; then
  warn "descriptions.patch missing — skipping"
else
  if git apply --check "$PATCH" >/tmp/dchk.err 2>&1; then
    git apply "$PATCH" && echo "descriptions: applied (git apply)"
  elif git apply --3way "$PATCH" >/tmp/d3.err 2>&1; then
    echo "descriptions: applied (git apply --3way)"
  elif patch -p1 --forward --fuzz=3 < "$PATCH" >/tmp/dp.err 2>&1; then
    echo "descriptions: applied (patch -p1)"
  else
    warn "descriptions NOT applied. check: $(oneline </tmp/dchk.err) 3way: $(oneline </tmp/d3.err)"
  fi
fi

echo "fork overlay applied."
exit 0
