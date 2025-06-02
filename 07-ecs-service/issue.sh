#!/bin/bash

# Define the directory prefix to prepend to file names in the output
prefix_path="modules/07-ecs-service"

# Define the output file
output_file="issue.md"

# Clear the output file if it already exists
> "$output_file"

# Loop through .tf files in the current directory
for file in *.tf; do
  if [ -f "$file" ]; then
    # Write the file name with prefix to the output file
    echo "**${prefix_path}/${file}**" >> "$output_file"
    
    # Write the code block with cat contents to the output file
    echo '```tf' >> "$output_file"
    cat "$file" >> "$output_file"
    echo '```' >> "$output_file"
    
    # Add a newline to separate the sections
    echo >> "$output_file"
  fi
done

# Append content from all .tfvars files with the same formatting
for tfvars_file in *.tfvars; do
  if [ -f "$tfvars_file" ]; then
    # Write the file name with prefix to the output file
    echo "**${prefix_path}/${tfvars_file}**" >> "$output_file"
    
    # Write the code block with cat contents to the output file
    echo '```tf' >> "$output_file"
    cat "$tfvars_file" >> "$output_file"
    echo '```' >> "$output_file"
    
    # Add a newline to separate the sections
    echo >> "$output_file"
  fi
done

echo "Done! Check $output_file for the results."
