#!/bin/bash

# Terminal Color Test Script for iOS Terminal WebSocket
# Tests ANSI color rendering in the iOS terminal

echo "=================================="
echo "Terminal WebSocket Color Test"
echo "=================================="
echo ""

# Basic 16 Colors Test
echo "Standard 16 Colors:"
echo -e "\033[30mBlack (30)\033[0m"
echo -e "\033[31mRed (31)\033[0m"
echo -e "\033[32mGreen (32)\033[0m"
echo -e "\033[33mYellow (33)\033[0m"
echo -e "\033[34mBlue (34)\033[0m"
echo -e "\033[35mMagenta (35)\033[0m"
echo -e "\033[36mCyan (36)\033[0m"
echo -e "\033[37mWhite (37)\033[0m"
echo ""

echo "Bright Colors:"
echo -e "\033[90mBright Black (90)\033[0m"
echo -e "\033[91mBright Red (91)\033[0m"
echo -e "\033[92mBright Green (92)\033[0m"
echo -e "\033[93mBright Yellow (93)\033[0m"
echo -e "\033[94mBright Blue (94)\033[0m"
echo -e "\033[95mBright Magenta (95)\033[0m"
echo -e "\033[96mBright Cyan (96)\033[0m"
echo -e "\033[97mBright White (97)\033[0m"
echo ""

# Text Attributes Test
echo "Text Attributes:"
echo -e "\033[1mBold Text\033[0m"
echo -e "\033[2mDim Text\033[0m"
echo -e "\033[3mItalic Text\033[0m"
echo -e "\033[4mUnderlined Text\033[0m"
echo -e "\033[7mReversed Text\033[0m"
echo -e "\033[9mStrikethrough Text\033[0m"
echo ""

# Combined Attributes
echo "Combined Attributes:"
echo -e "\033[1;31mBold Red\033[0m"
echo -e "\033[4;34mUnderlined Blue\033[0m"
echo -e "\033[1;4;32mBold Underlined Green\033[0m"
echo -e "\033[31;46mRed on Cyan Background\033[0m"
echo ""

# Background Colors
echo "Background Colors:"
echo -e "\033[40m Black Background \033[0m"
echo -e "\033[41m Red Background \033[0m"
echo -e "\033[42m Green Background \033[0m"
echo -e "\033[43m Yellow Background \033[0m"
echo -e "\033[44m Blue Background \033[0m"
echo -e "\033[45m Magenta Background \033[0m"
echo -e "\033[46m Cyan Background \033[0m"
echo -e "\033[47m White Background \033[0m"
echo ""

# 256 Color Test (sample)
echo "256 Color Mode (Sample):"
echo -e "\033[38;5;208mOrange (208)\033[0m"
echo -e "\033[38;5;226mYellow (226)\033[0m"
echo -e "\033[38;5;46mGreen (46)\033[0m"
echo -e "\033[38;5;21mBlue (21)\033[0m"
echo -e "\033[38;5;201mPink (201)\033[0m"
echo ""

# RGB Color Test
echo "RGB Color Mode:"
echo -e "\033[38;2;255;0;128mRGB Pink (255,0,128)\033[0m"
echo -e "\033[38;2;0;255;255mRGB Cyan (0,255,255)\033[0m"
echo -e "\033[38;2;255;165;0mRGB Orange (255,165,0)\033[0m"
echo ""

# Cyberpunk Theme Colors
echo "Cyberpunk Theme Colors:"
echo -e "\033[38;2;0;217;255mPrimary Cyan (#00D9FF)\033[0m"
echo -e "\033[38;2;255;0;110mAccent Pink (#FF006E)\033[0m"
echo -e "\033[38;2;255;215;0mWarning Yellow (#FFD700)\033[0m"
echo -e "\033[38;2;50;205;50mSuccess Green (#32CD32)\033[0m"
echo ""

echo "=================================="
echo "Test Complete!"
echo "==================================