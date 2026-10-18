#!/bin/bash

# Set target file here (leave empty or comment for all files)
# file="2025/09.md"

# Determine file list
if [[ -z "$file" || ! -f "$file" ]]; then
    # Process only monthly log files under YYYY/MM.md, excluding archive
    files=$(find . -type f -path "./[0-9][0-9][0-9][0-9]/[0-9][0-9].md" ! -path "./archive/*" | sort)
else
    # Process only the given file
    files="$file"
fi

for file in $files; do
    echo "Processing $file ..."

    # Extract table rows (skip header/separator rows)
    rows=$(grep '|' "$file" | tail -n +3 | grep -v '^|[- ]\+|')

    total=0
    unset categories daily
    declare -A categories
    declare -A daily

    while IFS='|' read -r _ date amount category payment expense_with_comment _; do
        amount=$(echo "$amount" | xargs)
        category=$(echo "$category" | xargs)
        date=$(echo "$date" | xargs)
        # Truncate any decimal amounts to integer rupees for arithmetic
        amount=${amount%%.*}

        # Remove leading zeros to prevent octal evaluation in bash
        amount=$(echo "$amount" | sed -E 's/^0+([0-9])/\1/')

        # Ensure amount is a valid integer
        if [[ ! "$amount" =~ ^[0-9]+$ ]]; then
            continue
        fi

        total=$((total + amount))
        categories["$category"]=$((categories["$category"] + amount))
        daily["$date"]=$((daily["$date"] + amount))
    done <<< "$rows"

    # Remove old report if exists
    tmpfile=$(mktemp)
    awk '/^## Report/ {exit} {print}' "$file" > "$tmpfile"

    # Write new report
    {
        echo "## Report"
        echo ""
        echo "**Total expenses:** $total"
        echo ""
        echo "### Category-wise totals"
        for cat in $(printf "%s\n" "${!categories[@]}" | sort); do
            echo "- $cat: ${categories[$cat]}"
        done
        echo ""
        echo "### Daily totals"
        for day in $(printf "%s\n" "${!daily[@]}" | sort); do
            echo "- $day: ${daily[$day]}"
        done
    } >> "$tmpfile"

    mv "$tmpfile" "$file"
    echo "→ Report updated in $file"
done
