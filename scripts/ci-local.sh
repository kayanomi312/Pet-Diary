#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
project=PawprintDays.xcodeproj
scheme=PawprintDays
simulator_id=${CI_SIMULATOR_ID:-F839F388-C746-4C4E-9A82-AEB40A1ECC70}

if ! command -v xcodegen >/dev/null; then
    echo "XcodeGen is required. Install it with 'brew install xcodegen'." >&2
    exit 1
fi

# XcodeGen also writes Info.plist files. Keep generation out of the working tree.
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
cp -R project.yml PawprintDays PawprintDaysWidgets PawprintDaysTests "$scratch"
git archive HEAD "$project" | tar -xf - -C "$scratch"
mv "$scratch/$project" "$scratch/committed.xcodeproj"
(cd "$scratch" && xcodegen generate)

# SwiftPM manages Package.resolved independently of XcodeGen.
if ! diff -ru -x Package.resolved "$scratch/committed.xcodeproj" "$scratch/$project"; then
    echo "Xcode project drift detected. Run 'xcodegen generate' and commit the project changes." >&2
    exit 1
fi
git diff --exit-code HEAD -- "$project"

xcode=(xcodebuild -project "$project" -scheme "$scheme")
if [[ $simulator_id == auto ]]; then
    # Take the newest eligible iOS runtime with a concrete iPhone destination.
    destinations=$("${xcode[@]}" -showdestinations)
    simulator_id=$(awk -F ', *' '
        /Destinations incompatible/ { exit }
        /platform:iOS Simulator,/ && /name:iPhone/ {
            id = ""; os = ""
            for (i = 1; i <= NF; i++) {
                if ($i ~ /^id:/) id = substr($i, 4)
                if ($i ~ /^OS:/) os = substr($i, 4)
            }
            if (id != "" && os != "") print os, id
        }
    ' <<<"$destinations" | LC_ALL=C sort -Vr | awk 'NR == 1 { print $2 }')
    if [[ -z $simulator_id ]]; then
        echo "No available iPhone simulator for $scheme under the selected Xcode." >&2
        echo "$destinations" >&2
        exit 1
    fi
fi

mkdir -p build/ci
result_dir=$(mktemp -d "$PWD/build/ci/run.XXXXXX")
echo "Simulator: $simulator_id"
echo "Test results: $result_dir/PawprintDays.xcresult"
"${xcode[@]}" \
    -destination "platform=iOS Simulator,id=$simulator_id" \
    -derivedDataPath "$PWD/DerivedData/CI" \
    -resultBundlePath "$result_dir/PawprintDays.xcresult" \
    -parallel-testing-enabled NO \
    -only-testing:PawprintDaysTests \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO \
    test
