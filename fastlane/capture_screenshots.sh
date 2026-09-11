#!/bin/bash
# App Store 用スクリーンショットを撮る。
#
#   ./fastlane/capture_screenshots.sh
#
# iPhone 14 Plus のシミュレータを使うのは、撮れる 1284x2778 が App Store の
# 6.5/6.7 インチ枠がそのまま受け付けるサイズだから。
# 撮影後は fastlane/screenshots/{ja,en-US}/ に入る。
#
# 画面遷移は MyHandMemoUITests/ScreenshotUITests.swift が行う。撮った画像は
# XCTAttachment として結果バンドルに入るので、ここで取り出して並べ直す。
# 見本のメモは DEBUG ビルドの -seedSampleData で入る（SampleData.swift）。
set -euo pipefail

DEVICE_NAME="ShotDevice-14Plus"
DEVICE_TYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-14-Plus"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/fastlane/screenshots"
WORK="$(mktemp -d)"

RUNTIME=$(xcrun simctl list runtimes --json | python3 -c \
  "import json,sys;print([r['identifier'] for r in json.load(sys.stdin)['runtimes'] if r['isAvailable'] and 'iOS' in r['name']][-1])")

UDID=$(xcrun simctl list devices --json | python3 -c "
import json,sys
for devs in json.load(sys.stdin)['devices'].values():
    for d in devs:
        if d['name'] == '$DEVICE_NAME':
            print(d['udid']); raise SystemExit
")
if [ -z "${UDID:-}" ]; then
  UDID=$(xcrun simctl create "$DEVICE_NAME" "$DEVICE_TYPE" "$RUNTIME")
fi
echo "device: $DEVICE_NAME ($UDID)"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null

# 時刻と電波を揃える
xcrun simctl status_bar "$UDID" override \
  --time "9:41" --batteryState charged --batteryLevel 100 \
  --cellularBars 4 --wifiBars 3 --dataNetwork wifi

rm -rf "$OUT"; mkdir -p "$OUT/ja" "$OUT/en-US"

capture() { # 1=SHOT_LANG 2=出力ディレクトリ名
  local lang="$1" dir="$2"
  echo "--- $lang ---"
  rm -rf "$WORK/$lang.xcresult"
  TEST_RUNNER_SHOT_LANG="$lang" xcodebuild test \
    -project "$ROOT/MyHandMemo.xcodeproj" \
    -scheme MyHandMemo \
    -destination "id=$UDID" \
    -only-testing:MyHandMemoUITests/ScreenshotUITests \
    -resultBundlePath "$WORK/$lang.xcresult" >"$WORK/$lang.log" 2>&1 \
    || { echo "撮影に失敗した。ログ: $WORK/$lang.log"; tail -30 "$WORK/$lang.log"; exit 1; }

  rm -rf "$WORK/$lang-att"
  xcrun xcresulttool export attachments \
    --path "$WORK/$lang.xcresult" --output-path "$WORK/$lang-att" >/dev/null

  python3 - "$WORK/$lang-att" "$OUT/$dir" "$lang" <<'PY'
import json, pathlib, re, shutil, sys
src, dst, lang = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]), sys.argv[3]
manifest = json.loads((src / "manifest.json").read_text())
n = 0
for test in manifest:
    for a in test.get("attachments", []):
        name = a.get("suggestedHumanReadableName") or a.get("exportedFileName", "")
        if not name.startswith(f"{lang}_"):
            continue
        stem = name[len(lang) + 1:].removesuffix(".png")
        stem = re.sub(r"_\d+_[0-9A-F-]{36}$", "", stem)
        out = dst / (stem + ".png")
        shutil.copyfile(src / a["exportedFileName"], out)
        print(f"  {out.parent.name}/{out.name}")
        n += 1
if n == 0:
    raise SystemExit("スクリーンショットが1枚も取り出せなかった")
PY
}

capture ja ja
capture en en-US

echo
echo "サイズ確認:"
for f in "$OUT"/*/*.png; do
  printf "  %-34s " "${f#$OUT/}"
  sips -g pixelWidth -g pixelHeight "$f" | awk '/pixel/{printf "%s ", $2} END{print ""}'
done
