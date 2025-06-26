#!/bin/bash
# generate_manifests.sh
# Usage: ./generate_manifests.sh <binaries_directory>
#
# This script processes all files in the given binaries directory that match the format:
#   nano_agent-<platform>-<version>.sh
# It computes the SHA256 checksum for each file and writes a line in the format:
#   version checksum
# into a manifest file located in the local "manifests/" directory for that platform.
#
# Files that do not match the expected naming format are ignored.

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <binaries_directory>"
    exit 1
fi

BINARIES_DIR="$1"
if [ ! -d "$BINARIES_DIR" ]; then
    echo "Error: $BINARIES_DIR is not a directory."
    exit 1
fi

# Ensure manifests/ directory exists
MANIFEST_DIR="manifests"
mkdir -p "$MANIFEST_DIR"

# Temporary directory for new manifests
TEMP_MANIFEST_DIR=$(mktemp -d)

# Loop over files in the binaries directory.
# Expected format: nano_agent-<platform>-<version>.sh
for file in "$BINARIES_DIR"/nano_agent-*.sh; do
    [ -e "$file" ] || continue
    filename=$(basename "$file")
    # Use a regex to ensure the filename is in the correct format.
    # The regex matches:
    #   nano_agent-                 literal
    #   ([a-zA-Z0-9]+)              platform (one or more alphanumerics)
    #   -                           literal dash
    #   ([0-9]+\.[0-9]+\.[0-9]+)    version in the format digits.digits.digits
    #   \.sh                        literal ".sh"
    if [[ "$filename" =~ ^nano_agent-([a-zA-Z0-9]+)-([0-9]+\.[0-9]+\.[0-9]+)\.sh$ ]]; then
        platform="${BASH_REMATCH[1]}"
        version="${BASH_REMATCH[2]}"
        # Calculate SHA256 checksum
        checksum=$(sha256sum "$file" | awk '{print $1}')
        # Append to the corresponding temporary manifest file (one per platform)
        echo "$version $checksum" >> "$TEMP_MANIFEST_DIR/$platform"
    else
        echo "Skipping file $filename: does not match expected format."
    fi
done

# Combine new manifests with old ones
for new_manifest in "$TEMP_MANIFEST_DIR"/*; do
    platform=$(basename "$new_manifest")
    old_manifest="$MANIFEST_DIR/$platform"
    combined_manifest=$(mktemp)

    # Combine old and new manifests, prioritizing the first occurrence of each version
    if [ -f "$old_manifest" ]; then
        cat "$new_manifest" "$old_manifest" | awk '!seen[$1]++' > "$combined_manifest"
    else
        awk '!seen[$1]++' "$new_manifest" > "$combined_manifest"
    fi

    # Sort the combined manifest in descending version order
    sort -rV "$combined_manifest" -o "$combined_manifest"

    # Replace old manifest with the combined one
    mv "$combined_manifest" "$old_manifest"
done

# Clean up temporary directory
rm -rf "$TEMP_MANIFEST_DIR"

echo "Manifests updated in the '$MANIFEST_DIR' directory."
