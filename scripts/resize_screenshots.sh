#!/bin/bash

INPUT_DIR="screenshots_raw"
OUTPUT_DIR="screenshots_ready"

mkdir -p "$OUTPUT_DIR"

for img in "$INPUT_DIR"/*.png; do
  filename=$(basename "$img")
  
  convert "$img" \
    -resize 1242x2688 \
    -background black \
    -gravity center \
    -extent 1242x2688 \
    "$OUTPUT_DIR/$filename"
done

echo "✅ Ferdig! Ligger i $OUTPUT_DIR"
