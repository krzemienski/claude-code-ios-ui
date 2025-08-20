//
//  TerminalOutputParser.swift
//  ClaudeCodeUI
//
//  Created by Claude Code UI on 2025/01/20.
//  
//  Parser for handling terminal output including ANSI codes
//

import UIKit

final class TerminalOutputParser {
    
    // MARK: - Properties
    static let shared = TerminalOutputParser()
    
    // ANSI color codes for foreground (30-37, 90-97)
    private let ansiColors: [Int: UIColor] = [
        30: UIColor.black,
        31: UIColor.systemRed,
        32: UIColor.systemGreen,
        33: UIColor.systemYellow,
        34: UIColor.systemBlue,
        35: UIColor.systemPurple,
        36: UIColor.systemCyan,
        37: UIColor.white,
        90: UIColor.darkGray,
        91: UIColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 1.0), // Light red
        92: UIColor(red: 0.5, green: 1.0, blue: 0.5, alpha: 1.0), // Light green
        93: UIColor(red: 1.0, green: 1.0, blue: 0.5, alpha: 1.0), // Light yellow
        94: UIColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0), // Light blue
        95: UIColor(red: 1.0, green: 0.5, blue: 1.0, alpha: 1.0), // Light magenta
        96: UIColor(red: 0.5, green: 1.0, blue: 1.0, alpha: 1.0), // Light cyan
        97: UIColor.white
    ]
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    
    /// Parse terminal output with ANSI codes and return attributed string
    func parseOutput(_ text: String, defaultColor: UIColor = CyberpunkTheme.primaryText) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        
        // Default attributes
        var currentAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .regular),
            .foregroundColor: defaultColor
        ]
        
        // Pattern to match ANSI escape sequences
        let ansiPattern = "\\x1B\\[([0-9;]+)m|\\x1B\\[([0-9]+)([A-Z])"
        let ansiRegex = try? NSRegularExpression(pattern: ansiPattern, options: [])
        
        var lastIndex = 0
        let nsText = text as NSString
        
        // Find all ANSI codes
        ansiRegex?.enumerateMatches(in: text, options: [], range: NSRange(location: 0, length: nsText.length)) { match, _, _ in
            guard let match = match else { return }
            
            // Append text before this ANSI code
            if match.range.location > lastIndex {
                let range = NSRange(location: lastIndex, length: match.range.location - lastIndex)
                let substring = nsText.substring(with: range)
                attributedString.append(NSAttributedString(string: substring, attributes: currentAttributes))
            }
            
            // Parse ANSI codes
            if match.numberOfRanges > 1 {
                let codeRange = match.range(at: 1)
                if codeRange.location != NSNotFound {
                    let codes = nsText.substring(with: codeRange).split(separator: ";").compactMap { Int($0) }
                    currentAttributes = parseANSICodes(codes, currentAttributes: currentAttributes, defaultColor: defaultColor)
                }
            }
            
            lastIndex = match.range.location + match.range.length
        }
        
        // Append remaining text
        if lastIndex < nsText.length {
            let range = NSRange(location: lastIndex, length: nsText.length - lastIndex)
            let substring = nsText.substring(with: range)
            attributedString.append(NSAttributedString(string: substring, attributes: currentAttributes))
        }
        
        // If no ANSI codes were found, return plain text with default attributes
        if attributedString.length == 0 {
            return NSAttributedString(string: text, attributes: currentAttributes)
        }
        
        return attributedString
    }
    
    /// Parse line-based output for simpler display
    func parseLines(_ text: String) -> [String] {
        return text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    /// Clean ANSI codes from text
    func stripANSICodes(_ text: String) -> String {
        let ansiPattern = "\\x1B\\[[0-9;]*[A-Za-z]"
        let regex = try? NSRegularExpression(pattern: ansiPattern, options: [])
        let range = NSRange(location: 0, length: text.utf16.count)
        return regex?.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "") ?? text
    }
    
    // MARK: - Private Methods
    
    private func parseANSICodes(_ codes: [Int], currentAttributes: [NSAttributedString.Key: Any], defaultColor: UIColor) -> [NSAttributedString.Key: Any] {
        var attributes = currentAttributes
        
        var i = 0
        while i < codes.count {
            let code = codes[i]
            switch code {
            case 0: // Reset all attributes
                attributes[.foregroundColor] = defaultColor
                attributes[.backgroundColor] = UIColor.clear
                attributes[.font] = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
                attributes[.underlineStyle] = 0
                attributes[.strikethroughStyle] = 0
                
            case 1: // Bold
                attributes[.font] = UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)
                
            case 2: // Dim
                if let color = attributes[.foregroundColor] as? UIColor {
                    attributes[.foregroundColor] = color.withAlphaComponent(0.6)
                }
                
            case 4: // Underline
                attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
                
            case 7: // Reverse (swap foreground and background)
                let fg = attributes[.foregroundColor] as? UIColor ?? defaultColor
                let bg = attributes[.backgroundColor] as? UIColor ?? UIColor.clear
                attributes[.foregroundColor] = bg == UIColor.clear ? UIColor.black : bg
                attributes[.backgroundColor] = fg
                
            case 9: // Strikethrough
                attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                
            case 22: // Normal intensity
                attributes[.font] = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
                
            case 24: // No underline
                attributes[.underlineStyle] = 0
                
            case 30...37, 90...97: // Foreground colors
                attributes[.foregroundColor] = ansiColors[code] ?? defaultColor
                
            case 38: // Extended foreground color
                if i + 2 < codes.count && codes[i + 1] == 5 {
                    // 256 color mode
                    let colorIndex = codes[i + 2]
                    attributes[.foregroundColor] = ansi256Color(colorIndex)
                    i += 2
                } else if i + 4 < codes.count && codes[i + 1] == 2 {
                    // RGB color mode
                    let r = CGFloat(codes[i + 2]) / 255.0
                    let g = CGFloat(codes[i + 3]) / 255.0
                    let b = CGFloat(codes[i + 4]) / 255.0
                    attributes[.foregroundColor] = UIColor(red: r, green: g, blue: b, alpha: 1.0)
                    i += 4
                }
                
            case 39: // Default foreground color
                attributes[.foregroundColor] = defaultColor
                
            case 40...47, 100...107: // Background colors
                let bgCode = code >= 100 ? code - 60 : code - 10
                attributes[.backgroundColor] = ansiColors[bgCode] ?? UIColor.clear
                
            case 48: // Extended background color
                if i + 2 < codes.count && codes[i + 1] == 5 {
                    // 256 color mode
                    let colorIndex = codes[i + 2]
                    attributes[.backgroundColor] = ansi256Color(colorIndex)
                    i += 2
                } else if i + 4 < codes.count && codes[i + 1] == 2 {
                    // RGB color mode
                    let r = CGFloat(codes[i + 2]) / 255.0
                    let g = CGFloat(codes[i + 3]) / 255.0
                    let b = CGFloat(codes[i + 4]) / 255.0
                    attributes[.backgroundColor] = UIColor(red: r, green: g, blue: b, alpha: 1.0)
                    i += 4
                }
                
            case 49: // Default background color
                attributes[.backgroundColor] = UIColor.clear
                
            default:
                break
            }
            i += 1
        }
        
        return attributes
    }
    
    private func ansi256Color(_ index: Int) -> UIColor {
        // Standard 16 colors (0-15)
        if index < 16 {
            let standardColors: [UIColor] = [
                UIColor.black,
                UIColor(red: 0.5, green: 0, blue: 0, alpha: 1), // Dark red
                UIColor(red: 0, green: 0.5, blue: 0, alpha: 1), // Dark green
                UIColor(red: 0.5, green: 0.5, blue: 0, alpha: 1), // Dark yellow
                UIColor(red: 0, green: 0, blue: 0.5, alpha: 1), // Dark blue
                UIColor(red: 0.5, green: 0, blue: 0.5, alpha: 1), // Dark magenta
                UIColor(red: 0, green: 0.5, blue: 0.5, alpha: 1), // Dark cyan
                UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1), // Light gray
                UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1), // Dark gray
                UIColor.systemRed,
                UIColor.systemGreen,
                UIColor.systemYellow,
                UIColor.systemBlue,
                UIColor.systemPurple,
                UIColor.systemCyan,
                UIColor.white
            ]
            return index < standardColors.count ? standardColors[index] : CyberpunkTheme.primaryText
        }
        
        // 216 color cube (16-231)
        if index >= 16 && index <= 231 {
            let idx = index - 16
            let r = (idx / 36) * 51
            let g = ((idx % 36) / 6) * 51
            let b = (idx % 6) * 51
            return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: 1.0)
        }
        
        // Grayscale (232-255)
        if index >= 232 && index <= 255 {
            let gray = 8 + (index - 232) * 10
            let value = CGFloat(gray) / 255.0
            return UIColor(white: value, alpha: 1.0)
        }
        
        return CyberpunkTheme.primaryText
    }
}