#!/bin/bash

# Check if features.txt exists
if [ ! -f "features.txt" ]; then
    echo "Error: features.txt file not found"
    exit 1
fi

# Create a directory to store all test folders
mkdir -p feature_tests

# Read each line from features.txt
while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines
    if [ -z "$line" ]; then
        continue
    fi
    
    # Extract the feature name (last part after /)
    feature_folder=$(echo "$line" | awk -F'/' '{print $NF}' | tr -d '\r')
    
    echo "Processing feature: $line"
    echo "Creating folder: $feature_folder"
    
    # Create a folder for this feature
    test_dir="feature_tests/$feature_folder"
    mkdir -p "$test_dir"
    
    # Create devcontainer.json in the folder
    cat > "$test_dir/devcontainer.json" << EOF
{
    "name": "$feature_folder",
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu-24.04",
    "features": {
        "$line": {}
    }
}
EOF
    
    # Run the command
    echo "Running devcontainer build for $feature_folder..."
    
    # Change to the test directory
    cd "$test_dir"
    
    # Run the command and capture output
    if devcontainer build --workspace-folder $(pwd) --config devcontainer.json --log-level debug --log-format json > output.log 2>&1; then
        # Command succeeded
        echo "Build successful for $feature_folder"
        mv output.log ok.txt
    else
        # Command failed
        echo "Build failed for $feature_folder"
        mv output.log error.txt
    fi
    
    # Return to the original directory
    cd - > /dev/null
    
    echo "Completed processing $feature_folder"
    echo "----------------------------------------"
done < "features.txt"

echo "All features processed."