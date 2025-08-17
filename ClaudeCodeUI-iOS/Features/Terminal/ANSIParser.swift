//
//  ANSIParser.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-16.
//

import UIKit

/// Parser for ANSI escape codes to NSAttributedString
public class ANSIParser {
    
    // MARK: - ANSI Color Codes
    
    /// Standard 16 ANSI colors
    private static let standardColors: [Int: UIColor] = [
        30: UIColor(hex: "#000000")!,  // Black
        31: UIColor(hex: "#CD3131")!,  // Red
        32: UIColor(hex: "#0DBC79")!,  // Green
        33: UIColor(hex: "#E5E510")!,  // Yellow
        34: UIColor(hex: "#2472C8")!,  // Blue
        35: UIColor(hex: "#BC3FBC")!,  // Magenta
        36: UIColor(hex: "#11A8CD")!,  // Cyan
        37: UIColor(hex: "#E5E5E5")!,  // White
        
        // Bright colors (90-97)
        90: UIColor(hex: "#666666")!,  // Bright Black
        91: UIColor(hex: "#F14C4C")!,  // Bright Red
        92: UIColor(hex: "#23D18B")!,  // Bright Green
        93: UIColor(hex: "#F5F543")!,  // Bright Yellow
        94: UIColor(hex: "#3B8EEA")!,  // Bright Blue
        95: UIColor(hex: "#D670D6")!,  // Bright Magenta
        96: UIColor(hex: "#29B8DB")!,  // Bright Cyan
        97: UIColor(hex: "#FFFFFF")!   // Bright White
    ]
    
    /// Background color codes (add 10 to foreground codes)
    private static func backgroundColorCode(_ code: Int) -> Int {
        return code + 10
    }
    
    // MARK: - Text Attributes
    
    private struct TextAttributes {
        var foregroundColor: UIColor = CyberpunkTheme.primaryText
        var backgroundColor: UIColor = .clear
        var isBold: Bool = false
        var isItalic: Bool = false
        var isUnderlined: Bool = false
        var isStrikethrough: Bool = false
        var isDim: Bool = false
        var isReversed: Bool = false
        var isHidden: Bool = false
        
        mutating func reset() {
            foregroundColor = CyberpunkTheme.primaryText
            backgroundColor = .clear
            isBold = false
            isItalic = false
            isUnderlined = false
            isStrikethrough = false
            isDim = false
            isReversed = false
            isHidden = false
        }
        
        func toNSAttributes(font: UIFont) -> [NSAttributedString.Key: Any] {
            var attributes: [NSAttributedString.Key: Any] = [:]
            
            // Colors
            var fgColor = foregroundColor
            var bgColor = backgroundColor
            
            if isReversed {
                swap(&fgColor, &bgColor)
            }
            
            if isDim {
                fgColor = fgColor.withAlphaComponent(0.6)
            }
            
            if isHidden {
                fgColor = .clear
            }
            
            attributes[.foregroundColor] = fgColor
            if bgColor != .clear {
                attributes[.backgroundColor] = bgColor
            }
            
            // Font styles
            var fontTraits: UIFontDescriptor.SymbolicTraits = []
            if isBold {
                fontTraits.insert(.traitBold)
            }
            if isItalic {
                fontTraits.insert(.traitItalic)
            }
            
            if !fontTraits.isEmpty {
                if let descriptor = font.fontDescriptor.withSymbolicTraits(fontTraits) {
                    attributes[.font] = UIFont(descriptor: descriptor, size: font.pointSize)
                } else {
                    attributes[.font] = font
                }
            } else {
                attributes[.font] = font
            }
            
            // Text decorations
            if isUnderlined {
                attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
            }
            
            if isStrikethrough {
                attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            }
            
            return attributes
        }
    }
    
    // MARK: - Public Interface
    
    /// Parses ANSI escape codes and returns an attributed string
    public static func parse(_ text: String, font: UIFont = .monospacedSystemFont(ofSize: 13, weight: .regular)) -> NSAttributedString {
        let result = NSMutableAttributedString()
        var currentAttributes = TextAttributes()
        
        // Regular expression to match ANSI escape sequences
        let pattern = #"\x1B\[([0-9;]+)?m"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        
        var lastEndIndex = text.startIndex
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            // Add text before the escape sequence
            if let range = Range(match.range, in: text) {
                let beforeText = String(text[lastEndIndex..<range.lowerBound])
                if !beforeText.isEmpty {
                    let attributedText = NSAttributedString(
                        string: beforeText,
                        attributes: currentAttributes.toNSAttributes(font: font)
                    )
                    result.append(attributedText)
                }
                
                // Process the escape codes
                if match.numberOfRanges > 1 {
                    let codesRange = match.range(at: 1)
                    if codesRange.location != NSNotFound,
                       let swiftRange = Range(codesRange, in: text) {
                        let codesString = String(text[swiftRange])
                        let codes = codesString.split(separator: ";").compactMap { Int($0) }
                        processANSICodes(codes, attributes: &currentAttributes)
                    }
                }
                
                lastEndIndex = range.upperBound
            }
        }
        
        // Add remaining text
        let remainingText = String(text[lastEndIndex...])
        if !remainingText.isEmpty {
            let attributedText = NSAttributedString(
                string: remainingText,
                attributes: currentAttributes.toNSAttributes(font: font)
            )
            result.append(attributedText)
        }
        
        return result
    }
    
    // MARK: - Private Methods
    
    private static func processANSICodes(_ codes: [Int], attributes: inout TextAttributes) {
        var i = 0
        while i < codes.count {
            let code = codes[i]
            
            switch code {
            case 0:
                // Reset all attributes
                attributes.reset()
                
            case 1:
                // Bold
                attributes.isBold = true
                
            case 2:
                // Dim
                attributes.isDim = true
                
            case 3:
                // Italic
                attributes.isItalic = true
                
            case 4:
                // Underline
                attributes.isUnderlined = true
                
            case 5, 6:
                // Blink (not supported, but don't break parsing)
                break
                
            case 7:
                // Reverse
                attributes.isReversed = true
                
            case 8:
                // Hidden
                attributes.isHidden = true
                
            case 9:
                // Strikethrough
                attributes.isStrikethrough = true
                
            case 21:
                // Reset bold
                attributes.isBold = false
                
            case 22:
                // Reset dim
                attributes.isDim = false
                
            case 23:
                // Reset italic
                attributes.isItalic = false
                
            case 24:
                // Reset underline
                attributes.isUnderlined = false
                
            case 27:
                // Reset reverse
                attributes.isReversed = false
                
            case 28:
                // Reset hidden
                attributes.isHidden = false
                
            case 29:
                // Reset strikethrough
                attributes.isStrikethrough = false
                
            case 30...37, 90...97:
                // Foreground colors
                if let color = standardColors[code] {
                    attributes.foregroundColor = color
                }
                
            case 38:
                // Extended foreground color
                if i + 2 < codes.count && codes[i + 1] == 5 {
                    // 256 color mode
                    let colorIndex = codes[i + 2]
                    attributes.foregroundColor = color256(colorIndex)
                    i += 2
                } else if i + 4 < codes.count && codes[i + 1] == 2 {
                    // RGB color mode
                    let r = codes[i + 2]
                    let g = codes[i + 3]
                    let b = codes[i + 4]
                    attributes.foregroundColor = UIColor(
                        red: CGFloat(r) / 255.0,
                        green: CGFloat(g) / 255.0,
                        blue: CGFloat(b) / 255.0,
                        alpha: 1.0
                    )
                    i += 4
                }
                
            case 39:
                // Default foreground color
                attributes.foregroundColor = CyberpunkTheme.primaryText
                
            case 40...47, 100...107:
                // Background colors
                let fgCode = (code >= 100) ? code - 60 : code - 10
                if let color = standardColors[fgCode] {
                    attributes.backgroundColor = color
                }
                
            case 48:
                // Extended background color
                if i + 2 < codes.count && codes[i + 1] == 5 {
                    // 256 color mode
                    let colorIndex = codes[i + 2]
                    attributes.backgroundColor = color256(colorIndex)
                    i += 2
                } else if i + 4 < codes.count && codes[i + 1] == 2 {
                    // RGB color mode
                    let r = codes[i + 2]
                    let g = codes[i + 3]
                    let b = codes[i + 4]
                    attributes.backgroundColor = UIColor(
                        red: CGFloat(r) / 255.0,
                        green: CGFloat(g) / 255.0,
                        blue: CGFloat(b) / 255.0,
                        alpha: 1.0
                    )
                    i += 4
                }
                
            case 49:
                // Default background color
                attributes.backgroundColor = .clear
                
            default:
                // Unknown code, ignore
                break
            }
            
            i += 1
        }
    }
    
    /// Get color from 256 color palette
    private static func color256(_ index: Int) -> UIColor {
        switch index {
        case 0...15:
            // Standard 16 colors
            let mapping = [30, 31, 32, 33, 34, 35, 36, 37, 90, 91, 92, 93, 94, 95, 96, 97]
            if index < mapping.count, let color = standardColors[mapping[index]] {
                return color
            }
            
        case 16...231:
            // 6x6x6 RGB cube
            let adjustedIndex = index - 16
            let r = (adjustedIndex / 36) % 6
            let g = (adjustedIndex / 6) % 6
            let b = adjustedIndex % 6
            
            let rValue = r == 0 ? 0 : 55 + r * 40
            let gValue = g == 0 ? 0 : 55 + g * 40
            let bValue = b == 0 ? 0 : 55 + b * 40
            
            return UIColor(
                red: CGFloat(rValue) / 255.0,
                green: CGFloat(gValue) / 255.0,
                blue: CGFloat(bValue) / 255.0,
                alpha: 1.0
            )
            
        case 232...255:
            // Grayscale
            let gray = 8 + (index - 232) * 10
            return UIColor(
                red: CGFloat(gray) / 255.0,
                green: CGFloat(gray) / 255.0,
                blue: CGFloat(gray) / 255.0,
                alpha: 1.0
            )
            
        default:
            break
        }
        
        return CyberpunkTheme.primaryText
    }
    
    // MARK: - Utility Methods
    
    /// Strips ANSI escape codes from text
    public static func stripANSICodes(from text: String) -> String {
        let pattern = #"\x1B\[[0-9;]*m"#
        return text.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
    }
    
    /// Tests if text contains ANSI escape codes
    public static func containsANSICodes(_ text: String) -> Bool {
        let pattern = #"\x1B\[[0-9;]*m"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: (text as NSString).length)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }
}

// MARK: - Terminal Text View Extension

extension UITextView {
    /// Appends ANSI formatted text to the text view
    func appendANSIText(_ text: String, font: UIFont = .monospacedSystemFont(ofSize: 13, weight: .regular)) {
        let attributedText = ANSIParser.parse(text, font: font)
        
        if let currentAttributedText = self.attributedText {
            let mutableText = NSMutableAttributedString(attributedString: currentAttributedText)
            mutableText.append(attributedText)
            self.attributedText = mutableText
        } else {
            self.attributedText = attributedText
        }
        
        // Auto-scroll to bottom
        if self.text.count > 0 {
            let bottom = NSMakeRange(self.text.count - 1, 1)
            self.scrollRangeToVisible(bottom)
        }
    }
}