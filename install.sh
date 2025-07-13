#!/bin/bash

# Effective-Goggles Anticheat Installation Script for FiveM

echo "=========================================="
echo "  Effective-Goggles Anticheat Installer"
echo "=========================================="
echo ""

# Check if we're in a FiveM resources directory
if [ ! -f "../../server.cfg" ] && [ ! -f "../server.cfg" ] && [ ! -f "server.cfg" ]; then
    echo "⚠️  Warning: This doesn't appear to be a FiveM server directory."
    echo "   Make sure to place this resource in your resources folder."
    echo ""
fi

# Create logs directory
echo "📁 Creating logs directory..."
mkdir -p logs
chmod 755 logs

# Check file permissions
echo "🔒 Checking file permissions..."
find . -name "*.lua" -exec chmod 644 {} \;

# Display installation summary
echo ""
echo "✅ Installation complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Add 'start effective-goggles' to your server.cfg"
echo "   2. Configure settings in config.lua"
echo "   3. Set up admin permissions in your ACE system"
echo "   4. Optionally configure Discord webhook for notifications"
echo "   5. Restart your FiveM server"
echo ""
echo "🔧 Configuration tips:"
echo "   - Adjust detection thresholds based on your server type"
echo "   - Add admin identifiers to the whitelist"
echo "   - Test with debug mode enabled initially"
echo "   - Monitor logs for false positives and adjust settings"
echo ""
echo "📚 For detailed configuration, see README.md"
echo ""
echo "🚀 Your FiveM server is now protected against noclip cheats!"
echo "=========================================="