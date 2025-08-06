#!/bin/bash

# DiffValueSubject project code formatting script
# Uses swift-format to format Swift code

set -e  # Exit on error

echo "🔧 Starting Swift code formatting..."

# Check if swift-format is available
if ! command -v swift-format &> /dev/null; then
    echo "❌ Error: swift-format not found"
    echo "Installation:"
    echo "  brew install swift-format"
    echo "  or"
    echo "  swift package --allow-writing-to-directory . --package-path . install swift-format"
    exit 1
fi

# Check for .swift-format configuration file
if [ ! -f ".swift-format" ]; then
    echo "⚠️  Warning: .swift-format configuration file not found"
    echo "Running format with default settings"
fi

# Format Sources directory
if [ -d "Sources" ]; then
    echo "📁 Formatting Sources/ directory..."
    swift-format format --in-place --recursive Sources/
    echo "✅ Sources/ formatting completed"
else
    echo "⚠️  Sources/ directory not found"
fi

# Format Tests directory
if [ -d "Tests" ]; then
    echo "📁 Formatting Tests/ directory..."
    swift-format format --in-place --recursive Tests/
    echo "✅ Tests/ formatting completed"
else
    echo "⚠️  Tests/ directory not found"
fi

# Format sample app directories
if [ -d "DiffValueSubjectExample.swiftpm" ]; then
    echo "📱 Formatting DiffValueSubjectExample.swiftpm/ directory..."
    swift-format format --in-place --recursive DiffValueSubjectExample.swiftpm/
    echo "✅ DiffValueSubjectExample.swiftpm/ formatting completed"
else
    echo "⚠️  DiffValueSubjectExample.swiftpm/ directory not found"
fi

# Format other sample directories
for sample_dir in DiffValueSubjectIOSExample; do
    if [ -d "$sample_dir" ]; then
        echo "📱 Formatting $sample_dir/ directory..."
        swift-format format --in-place --recursive "$sample_dir/"
        echo "✅ $sample_dir/ formatting completed"
    else
        echo "⚠️  $sample_dir/ directory not found"
    fi
done

# Check formatting results
echo ""
echo "📊 Formatting results:"
if command -v git &> /dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
    # For Git repositories, show changed files
    changed_files=$(git diff --name-only --diff-filter=M | grep -E '\.(swift)$' || true)
    if [ -n "$changed_files" ]; then
        echo "📝 Formatted files:"
        echo "$changed_files" | sed 's/^/  - /'
        echo ""
        echo "💡 To check changes: git diff"
        echo "💾 To commit changes: git add . && git commit -m \"Apply code formatting\""
    else
        echo "✨ No changes needed (already formatted)"
    fi
else
    echo "✅ Formatting process completed"
fi

echo ""
echo "🎉 Swift code formatting completed!"
