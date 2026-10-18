#!/bin/bash
base_dir="$(dirname "$0")"
index_file="$base_dir/index.md"
touch "$index_file"

for file in "$base_dir"/*.md; do
    [[ "$file" == "$index_file" ]] && continue
    filename=$(basename "$file")
    title=$(grep -m 1 '^title:' "$file" | sed 's/title: //')
    [ -z "$title" ] && title="$filename"
    grep -q "\[$title\]($filename)" "$index_file" || echo "- [$title]($filename)" >> "$index_file"
done
echo "Index updated."