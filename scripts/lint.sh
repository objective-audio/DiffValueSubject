#!/bin/bash

# DiffValueSubject project code linting (validation) script
# Uses swift-format to check Swift code quality

set -e  # Exit on error

echo "🔍 Starting Swift code linting..."

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
    echo "Running lint with default settings"
fi

lint_errors=0

# Lint Sources directory
if [ -d "Sources" ]; then
    echo "📁 Linting Sources/ directory..."
    if swift-format lint --recursive Sources/; then
        echo "✅ Sources/ linting successful"
    else
        echo "❌ Lint errors found in Sources/"
        lint_errors=$((lint_errors + 1))
    fi
else
    echo "⚠️  Sources/ directory not found"
fi

# Lint Tests directory
if [ -d "Tests" ]; then
    echo "📁 Linting Tests/ directory..."
    if swift-format lint --recursive Tests/; then
        echo "✅ Tests/ linting successful"
    else
        echo "❌ Lint errors found in Tests/"
        lint_errors=$((lint_errors + 1))
    fi
else
    echo "⚠️  Tests/ directory not found"
fi

echo ""

# Display results
if [ $lint_errors -eq 0 ]; then
    echo "🎉 All files are properly formatted!"
    exit 0
else
    echo "❌ Lint errors found in $lint_errors directory(ies)"
    echo ""
    echo "💡 To fix, run:"
    echo "  ./format.sh"
    echo "  or"
    echo "  swift-format format --in-place --recursive Sources/ Tests/"
    exit 1
fi
