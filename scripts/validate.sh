#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track validation status
VALIDATION_FAILED=0

echo "🔍 Starting validation..."
echo ""

# Determine which validator to use
VALIDATOR=""
if command -v ajv &> /dev/null; then
    VALIDATOR="ajv"
    echo "Using ajv-cli for validation"
elif command -v bunx &> /dev/null; then
    VALIDATOR="bunx"
    echo "Using bunx with ajv-cli for validation"
elif command -v npx &> /dev/null; then
    VALIDATOR="npx"
    echo "Using npx with ajv-cli for validation"
else
    echo -e "${RED}❌ ERROR: No JSON schema validator found.${NC}"
    echo ""
    echo "Please install Bun (https://bun.sh) or Node.js, or install ajv-cli globally:"
    echo "  npm install -g ajv-cli ajv-formats"
    echo ""
    exit 1
fi
echo ""

# Function to validate JSON against schema
validate_json_schema() {
    local json_file="$1"
    local schema_ref
    
    echo -e "${YELLOW}📄 Validating: ${json_file}${NC}"
    
    # Extract $schema reference from JSON file
    schema_ref=$(jq -r '."$schema" // empty' "$json_file")
    
    if [ -z "$schema_ref" ]; then
        echo -e "${RED}❌ ERROR: No \$schema reference found in ${json_file}${NC}"
        VALIDATION_FAILED=1
        return 1
    fi
    
    # Convert URL to local file path
    # Example: https://open.divekit.app/schemas/agencies/agencies.schema.v1.0.0.json
    # -> schemas/agencies/agencies.schema.v1.0.0.json
    local schema_file=$(echo "$schema_ref" | sed 's|https://open.divekit.app/||')
    
    if [ ! -f "$schema_file" ]; then
        echo -e "${RED}❌ ERROR: Schema file not found: ${schema_file}${NC}"
        VALIDATION_FAILED=1
        return 1
    fi
    
    echo "   Schema: $schema_file"
    
    # Create a temporary file for output
    local temp_output=$(mktemp)
    
    # Validate using ajv (either directly or via bunx/npx)
    local validation_status=0
    if [ "$VALIDATOR" = "ajv" ]; then
        ajv validate -s "$schema_file" -d "$json_file" --strict=false --all-errors > "$temp_output" 2>&1 || validation_status=$?
    elif [ "$VALIDATOR" = "bunx" ]; then
        bunx --bun ajv-cli validate -s "$schema_file" -d "$json_file" --strict=false --spec=draft2020 > "$temp_output" 2>&1 || validation_status=$?
    else
        npx --yes ajv-cli validate -s "$schema_file" -d "$json_file" --strict=false --spec=draft2020 > "$temp_output" 2>&1 || validation_status=$?
    fi
    
    if [ $validation_status -eq 0 ]; then
        echo -e "${GREEN}✅ Schema validation passed${NC}"
    else
        echo -e "${RED}❌ Schema validation failed${NC}"
        # Filter out noise from bun/npx output
        grep -v "^unknown format" "$temp_output" | \
        grep -v "^Resolving" | \
        grep -v "^Resolved," | \
        grep -v "^Saved lockfile" | \
        grep -v "^Installed" || true
        VALIDATION_FAILED=1
    fi
    
    rm -f "$temp_output"
    echo ""
}

# Function to check for duplicate IDs in a JSON dataset
check_duplicate_ids() {
    local json_file="$1"
    
    echo -e "${YELLOW}🔎 Checking for duplicate IDs in: ${json_file}${NC}"
    
    # Determine the array key based on filename
    local array_key=""
    if [[ "$json_file" == *"agencies.json"* ]]; then
        array_key="agencies"
    elif [[ "$json_file" == *"certifications"* ]]; then
        array_key="certifications"
    elif [[ "$json_file" == *"cylinders"* ]]; then
        array_key="cylinders"
    else
        # Try to find any array that contains objects with 'id' fields
        array_key=$(jq -r 'to_entries | map(select(.value | type == "array" and (.[0]? | has("id")))) | .[0].key // empty' "$json_file" 2>/dev/null || echo "")
    fi
    
    if [ -z "$array_key" ]; then
        echo -e "${BLUE}ℹ️  Could not determine array key for duplicate ID check, skipping${NC}"
        echo ""
        return 0
    fi
    
    # Extract all IDs and check for duplicates
    local duplicates
    duplicates=$(jq -r ".${array_key}[]? | .id? // empty" "$json_file" 2>/dev/null | sort | uniq -d || echo "")
    
    if [ -n "$duplicates" ] && [ "$duplicates" != "" ]; then
        echo -e "${RED}❌ ERROR: Duplicate IDs found:${NC}"
        echo "$duplicates" | while read -r dup_id; do
            if [ -n "$dup_id" ]; then
                echo -e "${RED}   - ${dup_id}${NC}"
            fi
        done
        VALIDATION_FAILED=1
    else
        echo -e "${GREEN}✅ No duplicate IDs found${NC}"
    fi
    
    echo ""
}

# Function to check for unique agency names and abbreviations
check_unique_agency_names_and_abbrs() {
    local json_file="$1"
    
    # Only check agencies files
    if [[ "$json_file" != *"agencies"*.json ]]; then
        return 0
    fi
    
    echo -e "${YELLOW}🔎 Checking for unique agency names and abbreviations in: ${json_file}${NC}"
    
    local has_duplicates=0
    
    # Check for duplicate names
    local duplicate_names
    duplicate_names=$(jq -r '.agencies[]? | .name? // empty' "$json_file" 2>/dev/null | sort | uniq -d || echo "")
    
    if [ -n "$duplicate_names" ] && [ "$duplicate_names" != "" ]; then
        echo -e "${RED}❌ ERROR: Duplicate agency names found:${NC}"
        echo "$duplicate_names" | while read -r dup_name; do
            if [ -n "$dup_name" ]; then
                echo -e "${RED}   - ${dup_name}${NC}"
                # Show which agencies have this name
                local agencies_with_name
                agencies_with_name=$(jq -r ".agencies[]? | select(.name == \"$dup_name\") | .id" "$json_file" 2>/dev/null || echo "")
                echo "$agencies_with_name" | while read -r agency_id; do
                    if [ -n "$agency_id" ]; then
                        echo -e "${RED}     Used by: ${agency_id}${NC}"
                    fi
                done
            fi
        done
        has_duplicates=1
        VALIDATION_FAILED=1
    fi
    
    # Check for duplicate abbreviations
    local duplicate_abbrs
    duplicate_abbrs=$(jq -r '.agencies[]? | .abbr? // empty' "$json_file" 2>/dev/null | sort | uniq -d || echo "")
    
    if [ -n "$duplicate_abbrs" ] && [ "$duplicate_abbrs" != "" ]; then
        echo -e "${RED}❌ ERROR: Duplicate agency abbreviations found:${NC}"
        echo "$duplicate_abbrs" | while read -r dup_abbr; do
            if [ -n "$dup_abbr" ]; then
                echo -e "${RED}   - ${dup_abbr}${NC}"
                # Show which agencies have this abbreviation
                local agencies_with_abbr
                agencies_with_abbr=$(jq -r ".agencies[]? | select(.abbr == \"$dup_abbr\") | .id" "$json_file" 2>/dev/null || echo "")
                echo "$agencies_with_abbr" | while read -r agency_id; do
                    if [ -n "$agency_id" ]; then
                        echo -e "${RED}     Used by: ${agency_id}${NC}"
                    fi
                done
            fi
        done
        has_duplicates=1
        VALIDATION_FAILED=1
    fi
    
    if [ $has_duplicates -eq 0 ]; then
        echo -e "${GREEN}✅ All agency names and abbreviations are unique${NC}"
    fi
    
    echo ""
}

# Function to check for unique certification names and abbreviations per agency
check_unique_cert_names_and_abbrs_per_agency() {
    local json_file="$1"
    
    # Only check certifications files
    if [[ "$json_file" != *"certifications"*.json ]]; then
        return 0
    fi
    
    echo -e "${YELLOW}🔎 Checking for unique certification names and abbreviations per agency in: ${json_file}${NC}"
    
    local has_duplicates=0
    
    # Check for duplicate names per agency
    # Create a temporary file to store agency-name pairs
    local temp_name_pairs=$(mktemp)
    
    # Extract agency-name pairs
    jq -r '.certifications[]? | "\(.agency // "unknown")|\(.name // "")"' "$json_file" 2>/dev/null > "$temp_name_pairs"
    
    # Find duplicate agency-name pairs
    local duplicate_name_pairs
    duplicate_name_pairs=$(sort "$temp_name_pairs" | uniq -d)
    
    if [ -n "$duplicate_name_pairs" ] && [ "$duplicate_name_pairs" != "" ]; then
        echo -e "${RED}❌ ERROR: Duplicate certification names found within the same agency:${NC}"
        echo "$duplicate_name_pairs" | while IFS='|' read -r agency name; do
            if [ -n "$agency" ] && [ -n "$name" ]; then
                echo -e "${RED}   - Agency: ${agency}, Certification name: ${name}${NC}"
                # Show which certification IDs have this duplicate
                local cert_ids
                cert_ids=$(jq -r ".certifications[]? | select(.agency == \"$agency\" and .name == \"$name\") | .id" "$json_file" 2>/dev/null || echo "")
                echo "$cert_ids" | while read -r cert_id; do
                    if [ -n "$cert_id" ]; then
                        echo -e "${RED}     Certificate ID: ${cert_id}${NC}"
                    fi
                done
            fi
        done
        has_duplicates=1
        VALIDATION_FAILED=1
    fi
    
    rm -f "$temp_name_pairs"
    
    # Check for duplicate abbreviations per agency
    # Create a temporary file to store agency-abbr pairs
    local temp_abbr_pairs=$(mktemp)
    
    # Extract agency-abbr pairs (excluding null/empty abbreviations)
    jq -r '.certifications[]? | select(.abbr != null and .abbr != "") | "\(.agency // "unknown")|\(.abbr)"' "$json_file" 2>/dev/null > "$temp_abbr_pairs"
    
    # Find duplicate agency-abbr pairs
    local duplicate_abbr_pairs
    duplicate_abbr_pairs=$(sort "$temp_abbr_pairs" | uniq -d)
    
    if [ -n "$duplicate_abbr_pairs" ] && [ "$duplicate_abbr_pairs" != "" ]; then
        echo -e "${RED}❌ ERROR: Duplicate certification abbreviations found within the same agency:${NC}"
        echo "$duplicate_abbr_pairs" | while IFS='|' read -r agency abbr; do
            if [ -n "$agency" ] && [ -n "$abbr" ]; then
                echo -e "${RED}   - Agency: ${agency}, Certification abbreviation: ${abbr}${NC}"
                # Show which certification IDs have this duplicate
                local cert_ids
                cert_ids=$(jq -r ".certifications[]? | select(.agency == \"$agency\" and .abbr == \"$abbr\") | .id" "$json_file" 2>/dev/null || echo "")
                echo "$cert_ids" | while read -r cert_id; do
                    if [ -n "$cert_id" ]; then
                        echo -e "${RED}     Certificate ID: ${cert_id}${NC}"
                    fi
                done
            fi
        done
        has_duplicates=1
        VALIDATION_FAILED=1
    fi
    
    rm -f "$temp_abbr_pairs"
    
    if [ $has_duplicates -eq 0 ]; then
        echo -e "${GREEN}✅ All certification names and abbreviations are unique within each agency${NC}"
    fi
    
    echo ""
}

# Function to check for unique cylinder common names
check_unique_cylinder_common_names() {
    local json_file="$1"
    
    # Only check cylinders files
    if [[ "$json_file" != *"cylinders"*.json ]]; then
        return 0
    fi
    
    echo -e "${YELLOW}🔎 Checking for unique cylinder common names in: ${json_file}${NC}"
    
    local has_duplicates=0
    
    # Check for duplicate common names
    local duplicate_names
    duplicate_names=$(jq -r '.cylinders[]? | .commonName? // empty' "$json_file" 2>/dev/null | sort | uniq -d || echo "")
    
    if [ -n "$duplicate_names" ] && [ "$duplicate_names" != "" ]; then
        echo -e "${RED}❌ ERROR: Duplicate cylinder common names found:${NC}"
        echo "$duplicate_names" | while read -r dup_name; do
            if [ -n "$dup_name" ]; then
                echo -e "${RED}   - ${dup_name}${NC}"
                # Show which cylinders have this name
                local cylinders_with_name
                cylinders_with_name=$(jq -r ".cylinders[]? | select(.commonName == \"$dup_name\") | .id" "$json_file" 2>/dev/null || echo "")
                echo "$cylinders_with_name" | while read -r cylinder_id; do
                    if [ -n "$cylinder_id" ]; then
                        echo -e "${RED}     Used by: ${cylinder_id}${NC}"
                    fi
                done
            fi
        done
        has_duplicates=1
        VALIDATION_FAILED=1
    fi
    
    if [ $has_duplicates -eq 0 ]; then
        echo -e "${GREEN}✅ All cylinder common names are unique${NC}"
    fi
    
    echo ""
}

# Function to validate schema files themselves
validate_schema_file() {
    local schema_file="$1"
    
    echo -e "${YELLOW}📋 Validating schema file: ${schema_file}${NC}"
    
    # Check if file is valid JSON first
    if ! jq empty "$schema_file" 2>/dev/null; then
        echo -e "${RED}❌ ERROR: Invalid JSON in schema file${NC}"
        VALIDATION_FAILED=1
        return 1
    fi
    
    # Extract the $schema reference to determine which meta-schema to validate against
    local meta_schema
    meta_schema=$(jq -r '."$schema" // empty' "$schema_file" 2>/dev/null || echo "")
    
    if [ -z "$meta_schema" ]; then
        echo -e "${BLUE}ℹ️  No \$schema reference found, assuming draft-07${NC}"
        meta_schema="http://json-schema.org/draft-07/schema#"
    fi
    
    echo "   Meta-schema: $meta_schema"
    
    # Create a temporary file for output
    local temp_output=$(mktemp)
    
    # Validate the schema file against the meta-schema
    local validation_status=0
    if [ "$VALIDATOR" = "ajv" ]; then
        ajv compile -s "$schema_file" --strict=false > "$temp_output" 2>&1 || validation_status=$?
    elif [ "$VALIDATOR" = "bunx" ]; then
        bunx --bun ajv-cli compile -s "$schema_file" --strict=false --spec=draft2020 > "$temp_output" 2>&1 || validation_status=$?
    else
        npx --yes ajv-cli compile -s "$schema_file" --strict=false --spec=draft2020 > "$temp_output" 2>&1 || validation_status=$?
    fi
    
    if [ $validation_status -eq 0 ]; then
        echo -e "${GREEN}✅ Schema is valid${NC}"
    else
        echo -e "${RED}❌ Schema validation failed${NC}"
        grep -v "^unknown format" "$temp_output" | \
        grep -v "^Resolving" | \
        grep -v "^Resolved," | \
        grep -v "^Saved lockfile" | \
        grep -v "^Installed" || true
        VALIDATION_FAILED=1
    fi
    
    rm -f "$temp_output"
    echo ""
}

# Function to check if agency logos exist
check_agency_logos() {
    local json_file="$1"
    
    # Only check agencies.json
    if [[ "$json_file" != *"agencies.json"* ]]; then
        return 0
    fi
    
    echo -e "${YELLOW}🖼️  Checking agency logos in: ${json_file}${NC}"
    
    # Check if assets/agency-logos directory exists
    if [ ! -d "assets/agency-logos" ]; then
        echo -e "${RED}❌ ERROR: assets/agency-logos directory not found${NC}"
        VALIDATION_FAILED=1
        echo ""
        return 1
    fi
    
    # Extract all agency IDs
    local agency_ids
    agency_ids=$(jq -r '.agencies[]? | .id? // empty' "$json_file" 2>/dev/null || echo "")
    
    if [ -z "$agency_ids" ]; then
        echo -e "${BLUE}ℹ️  No agencies found in file${NC}"
        echo ""
        return 0
    fi
    
    local missing_logos=()
    local found_count=0
    local total_count=0
    
    # Check each agency for a corresponding logo file
    while IFS= read -r agency_id; do
        if [ -z "$agency_id" ]; then
            continue
        fi
        
        total_count=$((total_count + 1))
        
        # Check for both .svg and .png extensions
        local logo_svg="assets/agency-logos/${agency_id}.svg"
        local logo_png="assets/agency-logos/${agency_id}.png"
        
        if [ -f "$logo_svg" ] || [ -f "$logo_png" ]; then
            found_count=$((found_count + 1))
            if [ -f "$logo_svg" ]; then
                echo -e "${GREEN}   ✓ ${agency_id}.svg${NC}"
            else
                echo -e "${GREEN}   ✓ ${agency_id}.png${NC}"
            fi
        else
            missing_logos+=("$agency_id")
        fi
    done <<< "$agency_ids"
    
    echo ""
    
    # Report results
    if [ ${#missing_logos[@]} -gt 0 ]; then
        echo -e "${RED}❌ ERROR: Missing agency logos (${#missing_logos[@]} out of $total_count agencies)${NC}"
        echo -e "${RED}   Each agency must have a corresponding logo file in assets/agency-logos/${NC}"
        echo -e "${RED}   Logo files must be named with the agency ID and be either .svg or .png${NC}"
        echo ""
        echo -e "${RED}   Missing logos for:${NC}"
        for missing_id in "${missing_logos[@]}"; do
            echo -e "${RED}   - ${missing_id} (expected: ${missing_id}.svg or ${missing_id}.png)${NC}"
        done
        VALIDATION_FAILED=1
    else
        echo -e "${GREEN}✅ All ${total_count} agencies have logo files${NC}"
    fi
    
    echo ""
}

# Function to check if dive signal illustrations exist
check_signal_images() {
    local json_file="$1"

    # Only check dive-signals.json
    if [[ "$json_file" != "datasets/dive-signals.json" ]]; then
        return 0
    fi

    echo -e "${YELLOW}🖼️  Checking signal illustrations in: ${json_file}${NC}"

    # Check if assets/dive-signals directory exists
    if [ ! -d "assets/dive-signals" ]; then
        echo -e "${RED}❌ ERROR: assets/dive-signals directory not found${NC}"
        VALIDATION_FAILED=1
        echo ""
        return 1
    fi

    # Extract all image paths
    local image_paths
    image_paths=$(jq -r '.signals[]? | .image? // empty' "$json_file" 2>/dev/null || echo "")

    if [ -z "$image_paths" ]; then
        echo -e "${BLUE}ℹ️  No signals found in file${NC}"
        echo ""
        return 0
    fi

    local missing_images=()
    local found_count=0
    local total_count=0

    # Check each referenced illustration exists
    while IFS= read -r image_path; do
        if [ -z "$image_path" ]; then
            continue
        fi

        total_count=$((total_count + 1))

        if [ -f "$image_path" ]; then
            found_count=$((found_count + 1))
        else
            missing_images+=("$image_path")
        fi
    done <<< "$image_paths"

    # Report results
    if [ ${#missing_images[@]} -gt 0 ]; then
        echo -e "${RED}❌ ERROR: Missing signal illustrations (${#missing_images[@]} out of $total_count signals)${NC}"
        echo -e "${RED}   Every signal entry must reference an existing SVG in assets/dive-signals/${NC}"
        echo ""
        echo -e "${RED}   Missing files:${NC}"
        for missing_path in "${missing_images[@]}"; do
            echo -e "${RED}   - ${missing_path}${NC}"
        done
        VALIDATION_FAILED=1
    else
        echo -e "${GREEN}✅ All ${total_count} signals have illustration files${NC}"
    fi

    # Warn about orphaned SVGs not referenced by any signal entry
    local orphaned
    orphaned=$(comm -23 \
        <(find assets/dive-signals -name "*.svg" -type f 2>/dev/null | sort) \
        <(echo "$image_paths" | sort -u))

    if [ -n "$orphaned" ]; then
        echo -e "${YELLOW}⚠️  WARNING: SVG files not referenced by any dataset entry:${NC}"
        echo "$orphaned" | while read -r orphan; do
            if [ -n "$orphan" ]; then
                echo -e "${YELLOW}   - ${orphan}${NC}"
            fi
        done
    fi

    echo ""
}

# References and search sources share one id space, and references.json keeps
# one block per topic (the first topic in the schema's order), ids A to Z inside.
check_references_and_sources() {
    local refs="datasets/references.json"
    local srcs="datasets/search-sources.json"
    [ -f "$refs" ] || return 0

    echo -e "${YELLOW}🔎 Checking ids across ${refs} and ${srcs}${NC}"
    local duplicates
    duplicates=$( { jq -r '.references[]?.id' "$refs"; [ -f "$srcs" ] && jq -r '.sources[]?.id' "$srcs"; } | sort | uniq -d)
    if [ -n "$duplicates" ]; then
        echo -e "${RED}❌ ERROR: Ids used more than once across references and search sources:${NC}"
        echo "$duplicates" | sed 's/^/   - /'
        VALIDATION_FAILED=1
    else
        echo -e "${GREEN}✅ Ids are unique across references and search sources${NC}"
    fi

    echo -e "${YELLOW}🔎 Checking the order of ${refs}${NC}"
    local schema_file
    schema_file=$(jq -r '."$schema"' "$refs" | sed 's|https://open.divekit.app/||')
    local misplaced
    misplaced=$(jq -r --slurpfile s "$schema_file" '
        ($s[0].properties.references.items.properties.topics.items.enum) as $order
        | [.references[] | (.topics[0] // "") as $t | {id, rank: ($order | index($t))}]
        | . as $r
        | [range(1; length) | select([$r[. - 1].rank, $r[. - 1].id] > [$r[.].rank, $r[.].id]) | $r[.].id]
        | .[]' "$refs")
    if [ -n "$misplaced" ]; then
        echo -e "${RED}❌ ERROR: references.json is out of order (by first topic, then id). Out of place:${NC}"
        echo "$misplaced" | sed 's/^/   - /'
        VALIDATION_FAILED=1
    else
        echo -e "${GREEN}✅ References are in topic blocks, ids A to Z inside${NC}"
    fi
    echo ""
}

# Checklist, section and step ids are unique together, and every id and field in
# datasets/i18n/<locale>/<base> exists in the base dataset. A base id with no
# translation is allowed (it falls back to English) and only counted.
check_checklists_and_translations() {
    local cl="datasets/checklists.json"
    if [ -f "$cl" ]; then
        echo -e "${YELLOW}🔎 Checking checklist, section and step ids in ${cl}${NC}"
        local duplicates
        duplicates=$(jq -r '.checklists[] | .id, (.sections[] | .id, .steps[].id)' "$cl" | sort | uniq -d)
        if [ -n "$duplicates" ]; then
            echo -e "${RED}❌ ERROR: Ids used more than once:${NC}"
            echo "$duplicates" | sed 's/^/   - /'
            VALIDATION_FAILED=1
        else
            echo -e "${GREEN}✅ Checklist, section and step ids are unique${NC}"
        fi
        echo ""
    fi

    local file base orphans missing
    for file in datasets/i18n/*/*.json; do
        [ -f "$file" ] || continue
        base="datasets/$(jq -r '.meta.base' "$file")"
        echo -e "${YELLOW}🔎 Checking ${file} against ${base}${NC}"
        if [ ! -f "$base" ]; then
            echo -e "${RED}❌ ERROR: base dataset ${base} not found${NC}"
            VALIDATION_FAILED=1
            continue
        fi
        # Every record with an id in the base, as {id: [its text fields]}.
        orphans=$(jq -r --slurpfile b "$base" '
            ([$b[0] | .. | objects | select(has("id")) | {key: .id, value: (to_entries | map(select(.value | type == "string")) | map(.key))}] | from_entries) as $ids
            | .strings | to_entries[] | .key as $id
            | if $ids[$id] == null then "\($id) is not an id in the base"
              else (.value | keys[] | select(. as $f | $ids[$id] | index($f) | not) | "\($id).\(.) is not a field of that record") end' "$file")
        missing=$(jq -r --slurpfile b "$base" '
            [$b[0] | .. | objects | select(has("id")) | .id] - (.strings | keys) | length' "$file")
        if [ -n "$orphans" ]; then
            echo -e "${RED}❌ ERROR: Translations that map to nothing:${NC}"
            echo "$orphans" | sed 's/^/   - /'
            VALIDATION_FAILED=1
        else
            echo -e "${GREEN}✅ Every translated id and field exists in the base${NC}"
        fi
        [ "$missing" -gt 0 ] && echo -e "${BLUE}ℹ️  ${missing} base ids have no translation (English shows)${NC}"
        echo ""
    done
}

# The footer's "Last updated" fallback date in each page matches the newest
# meta.generated_at across the datasets (index.html refreshes it at load).
check_last_updated() {
    echo -e "${YELLOW}🔎 Checking the footer's Last updated date${NC}"
    local newest
    newest=$(jq -r '.meta.generated_at // empty' datasets/*.json | sort | tail -1 | cut -c1-10)
    local page baked stale=0
    for page in index.html 404.html view.html; do
        [ -f "$page" ] || continue
        baked=$(grep -o 'data-updated datetime="[0-9-]*"' "$page" | grep -o '[0-9]\{4\}-[0-9-]*')
        if [ "$baked" != "$newest" ]; then
            echo -e "${RED}❌ ERROR: ${page} says Last updated ${baked:-(missing)}; the newest dataset is ${newest}. Update its <time data-updated> date and text.${NC}"
            stale=1
        fi
    done
    if [ $stale -eq 0 ]; then
        echo -e "${GREEN}✅ Last updated reads ${newest} on every page${NC}"
    else
        VALIDATION_FAILED=1
    fi
    echo ""
}

# Main validation logic
main() {
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}❌ ERROR: jq is required but not installed.${NC}"
        echo "Please install jq: https://jqlang.github.io/jq/download/"
        exit 1
    fi
    
    # ===== STEP 1: Validate Schema Files =====
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}Step 1: Validating Schema Files${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo ""
    
    if [ -d "schemas" ]; then
        local schema_files
        schema_files=$(find schemas -name "*.json" -type f 2>/dev/null || echo "")
        
        if [ -n "$schema_files" ]; then
            echo "Found schema files:"
            echo "$schema_files" | while read -r file; do
                if [ -n "$file" ]; then
                    echo "  - $file"
                fi
            done
            echo ""
            
            # Validate each schema file
            while IFS= read -r schema_file; do
                if [ -n "$schema_file" ] && [ -f "$schema_file" ]; then
                    validate_schema_file "$schema_file"
                fi
            done <<< "$schema_files"
        else
            echo -e "${YELLOW}⚠️  No schema files found in schemas directory${NC}"
            echo ""
        fi
    else
        echo -e "${YELLOW}⚠️  schemas directory not found${NC}"
        echo ""
    fi
    
    # ===== STEP 2: Validate Dataset Files =====
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}Step 2: Validating Dataset Files${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo ""
    
    # Check if datasets directory exists
    if [ ! -d "datasets" ]; then
        echo -e "${RED}❌ ERROR: datasets directory not found${NC}"
        echo "Please run this script from the project root directory."
        exit 1
    fi
    
    # Get all JSON files in datasets
    local json_files
    json_files=$(find datasets -name "*.json" -type f 2>/dev/null || echo "")
    
    if [ -z "$json_files" ]; then
        echo -e "${YELLOW}⚠️  No JSON files found in datasets directory${NC}"
    else
        echo "Found dataset files:"
        echo "$json_files" | while read -r file; do
            if [ -n "$file" ]; then
                echo "  - $file"
            fi
        done
        echo ""
        
        # Validate each JSON file
        while IFS= read -r json_file; do
            if [ -n "$json_file" ] && [ -f "$json_file" ]; then
                validate_json_schema "$json_file"
                check_duplicate_ids "$json_file"
                check_unique_agency_names_and_abbrs "$json_file"
                check_unique_cert_names_and_abbrs_per_agency "$json_file"
                check_unique_cylinder_common_names "$json_file"
                check_agency_logos "$json_file"
                check_signal_images "$json_file"
            fi
        done <<< "$json_files"
    fi
    
    check_references_and_sources
    check_checklists_and_translations
    check_last_updated

    # Final result
    echo "=========================================="
    if [ $VALIDATION_FAILED -eq 0 ]; then
        echo -e "${GREEN}✅ All validations passed!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Validation failed. Please fix the errors above.${NC}"
        exit 1
    fi
}

# Run main function
main
