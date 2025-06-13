#!/bin/bash

# Define the directory prefix to prepend to file names in the output
prefix_path="modules/07-ecs-service"

# Define the output file
output_file="issue.md"

# Clear the output file if it already exists
> "$output_file"

# Helper function to write a file to the output with proper formatting
write_file_block() {
  local file="$1"
  local lang="$2"
  echo "**${prefix_path}/${file}**" >> "$output_file"
  echo "\`\`\`${lang}" >> "$output_file"
  cat "$file" >> "$output_file"
  echo '```' >> "$output_file"
  echo >> "$output_file"
}

# Process .tf files
for file in *.tf; do
  [ -f "$file" ] && write_file_block "$file" "tf"
done

# Process .tfvars files
for file in *.tfvars; do
  [ -f "$file" ] && write_file_block "$file" "tf"
done

# Process .json files
for file in *.json; do
  [ -f "$file" ] && write_file_block "$file" "json"
done

echo "Done! Check $output_file for the results."
