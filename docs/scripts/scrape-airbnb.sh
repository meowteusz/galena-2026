#!/usr/bin/env bash
# Re-scrape the Airbnb listing for fresh OG metadata + cover image.
# Usage: ./scripts/scrape-airbnb.sh [airbnb-url]
set -euo pipefail

URL="${1:-https://www.airbnb.com/l/AYrg5G9y}"
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
OUT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp)"

echo "→ resolving $URL"
RESOLVED="$(curl -sIL -A "$UA" "$URL" | awk -F': ' 'tolower($1)=="location"{print $2}' | tr -d '\r' | tail -1)"
RESOLVED="${RESOLVED:-$URL}"
echo "  resolved: $RESOLVED"

curl -sL -A "$UA" "$RESOLVED" -o "$TMP"

extract() {
  grep -oE "\"og:$1\"[^>]*content=\"[^\"]*\"" "$TMP" | head -1 | sed -E "s/.*content=\"([^\"]*)\".*/\1/"
}

TITLE="$(extract title)"
DESC="$(extract description)"
IMG="$(extract image | sed 's/&amp;/\&/g')"

echo "  title: $TITLE"
echo "  desc:  $DESC"
echo "  image: $IMG"

if [ -n "$IMG" ]; then
  HIRES="$(echo "$IMG" | sed -E 's/im_w=[0-9]+/im_w=1200/; s/quality=[0-9]+/quality=80/')"
  curl -sL "$HIRES" -o "$OUT_DIR/images/airbnb-cover.jpg"
  echo "  saved: images/airbnb-cover.jpg"
fi

cat > "$OUT_DIR/airbnb-meta.json" <<EOF
{
  "url": "$URL",
  "resolved_url": "$RESOLVED",
  "title": "$TITLE",
  "description": "$DESC",
  "image": "$IMG",
  "scraped_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
echo "→ wrote airbnb-meta.json"
rm -f "$TMP"
