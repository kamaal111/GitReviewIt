DERIVED_ROOT="${DERIVED_ROOT:-$HOME/Library/Developer/Xcode/DerivedData}"
BIN_PATH=""

if [[ -n "$SPARKLE_BIN_PATH" && -d "$SPARKLE_BIN_PATH" ]]
then
    BIN_PATH="$SPARKLE_BIN_PATH"
else
    BIN_PATH=$(find "$DERIVED_ROOT" -maxdepth 8 -type d \
        \( -path "*/SourcePackages/artifacts/*/bin" -o -path "*/SourcePackages/artifacts/*/*/bin" \) \
        -print -quit 2>/dev/null)
fi

if [[ -z "$BIN_PATH" || ! -d "$BIN_PATH" ]]
then
    echo "❌ Sparkle tools directory not found under artifacts at: $DERIVED_ROOT" >&2
    echo "💡 Set SPARKLE_BIN_PATH to the artifacts bin or open the project to fetch packages." >&2
    exit 1
fi

echo "$BIN_PATH"
