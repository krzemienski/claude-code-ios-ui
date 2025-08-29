//
//  CyberpunkTheme.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import UIKit

struct CyberpunkTheme {
    // MARK: - Primary Colors (from design system)
    static let background = UIColor(hex: "#0A0A0F") ?? UIColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1.0) // Near black
    static let surface = UIColor(hex: "#1A1A2E") ?? UIColor(red: 0.10, green: 0.10, blue: 0.18, alpha: 1.0) // Dark blue-gray
    static let surfacePrimary = UIColor(hex: "#1A1A2E") ?? UIColor(red: 0.10, green: 0.10, blue: 0.18, alpha: 1.0) // Primary surface color
    static let surfaceSecondary = UIColor(hex: "#252540") ?? UIColor(red: 0.15, green: 0.15, blue: 0.25, alpha: 1.0) // Secondary surface color
    static let primaryCyan = UIColor(hex: "#00D9FF") ?? UIColor(red: 0.0, green: 0.85, blue: 1.0, alpha: 1.0) // Bright cyan (main brand color)
    static let accentPink = UIColor(hex: "#FF006E") ?? UIColor(red: 1.0, green: 0.0, blue: 0.43, alpha: 1.0) // Hot pink accent
    static let gradientBlue = UIColor(hex: "#0066FF") ?? UIColor(red: 0.0, green: 0.4, blue: 1.0, alpha: 1.0) // Gradient start
    static let gradientPurple = UIColor(hex: "#9933FF") ?? UIColor(red: 0.6, green: 0.2, blue: 1.0, alpha: 1.0) // Gradient end
    
    // MARK: - Text Colors
    static let textPrimary = UIColor(hex: "#FFFFFF") ?? UIColor.white // Pure white for headers
    static let textSecondary = UIColor(hex: "#E0E0E0") ?? UIColor(white: 0.88, alpha: 1.0) // Light gray for body
    static let textTertiary = UIColor(hex: "#A0A0A0") ?? UIColor(white: 0.63, alpha: 1.0) // Medium gray for captions
    static let textCyan = UIColor(hex: "#00D9FF") ?? UIColor(red: 0.0, green: 0.85, blue: 1.0, alpha: 1.0) // Cyan for interactive text
    
    // MARK: - Semantic Colors
    static let warning = UIColor(hex: "#FFB800") ?? UIColor(red: 1.0, green: 0.72, blue: 0.0, alpha: 1.0) // Amber/yellow for warnings
    static let success = UIColor(hex: "#00FF88") ?? UIColor(red: 0.0, green: 1.0, blue: 0.53, alpha: 1.0) // Green for success
    static let error = UIColor(hex: "#FF3366") ?? UIColor(red: 1.0, green: 0.2, blue: 0.4, alpha: 1.0) // Red for errors
    static let info = UIColor(hex: "#00B8FF") ?? UIColor(red: 0.0, green: 0.72, blue: 1.0, alpha: 1.0) // Blue for info
    
    // MARK: - Additional UI Colors
    static let primaryText = textPrimary // Alias for consistency
    static let secondaryText = textSecondary // Alias for consistency
    static let tertiaryText = textTertiary // Alias for consistency
    static let border = UIColor(hex: "#2A2A40") ?? UIColor(red: 0.16, green: 0.16, blue: 0.25, alpha: 1.0) // Border color
    static let primaryColor = primaryCyan // Alias for primary brand color
    static let secondaryColor = accentPink // Alias for secondary brand color
    
    // MARK: - Icon Colors
    static let iconCyan = UIColor(hex: "#00D9FF") ?? UIColor(red: 0.0, green: 0.85, blue: 1.0, alpha: 1.0) // Primary icon color
    static let iconPink = UIColor(hex: "#FF006E") ?? UIColor(red: 1.0, green: 0.0, blue: 0.43, alpha: 1.0) // Accent icon color
    
    // MARK: - Effects
    static let glowColor = (UIColor(hex: "#00D9FF") ?? UIColor(red: 0.0, green: 0.85, blue: 1.0, alpha: 1.0)).withAlphaComponent(0.6)
    static let gridLineColor = (UIColor(hex: "#1A1A2E") ?? UIColor(red: 0.10, green: 0.10, blue: 0.18, alpha: 1.0)).withAlphaComponent(0.5)
    static let borderRadius: CGFloat = 16.0
    static let glowIntensity: CGFloat = 0.8
    static let animationDuration: TimeInterval = 0.3
    
    // MARK: - Typography
    static let titleFont = UIFont.systemFont(ofSize: 28, weight: .bold)
    static let headlineFont = UIFont.systemFont(ofSize: 22, weight: .semibold)
    static let bodyFont = UIFont.systemFont(ofSize: 17, weight: .regular)
    static let captionFont = UIFont.systemFont(ofSize: 14, weight: .regular)
    static let codeFont = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    static let smallFont = UIFont.systemFont(ofSize: 12, weight: .regular)
}

// MARK: - Typography System
struct Typography {
    // Dynamic Type Scale (from design system)
    static let largeTitle = UIFont.systemFont(ofSize: 34, weight: .bold) // "CLAUDE CODE"
    static let title = UIFont.systemFont(ofSize: 28, weight: .semibold) // "Title"
    static let body = UIFont.systemFont(ofSize: 17, weight: .regular) // "Body"
    static let caption = UIFont.systemFont(ofSize: 12, weight: .regular) // "Caption"
    
    // Dynamic Type examples from design
    static let medium = UIFont.systemFont(ofSize: 20, weight: .medium) // "Medium"
    static let small = UIFont.systemFont(ofSize: 14, weight: .regular) // "Small"
    
    // Dynamic Type Support
    static func scaledFont(for style: UIFont.TextStyle) -> UIFont {
        return UIFont.preferredFont(forTextStyle: style)
    }
}

// MARK: - Icon System
struct IconSystem {
    // Icon set from design system
    enum Icons: String {
        // Top row
        case search = "magnifyingglass"
        case back = "chevron.backward"
        case forward = "chevron.forward"
        case play = "play.circle"
        case ellipsis = "ellipsis.circle"
        
        // Middle row
        case location = "location"
        case comment = "bubble.left"
        case playFill = "play.fill"
        case chat = "message"
        case user = "person.circle"
        
        // Bottom row (first set)
        case upload = "arrow.up.circle"
        case message = "bubble.right"
        case circle = "circle"
        case wand = "wand.and.rays"
        case settings = "gearshape"
        
        // Bottom row (second set)
        case home = "house"
        case shield = "shield"
        case lock = "lock"
        case person = "person"
        case flower = "camera.macro"
        
        // Additional icons
        case trash = "trash"
        case cloud = "cloud"
        case folder = "folder"
        case wifi = "wifi"
        case wifiMedium = "wifi.medium"
        case wifiFull = "wifi.circle.fill"
        case volume = "speaker.wave.3"
        case key = "key"
        case lockOpen = "lock.open"
        case plus = "plus"
        case minus = "minus"
        case camera = "camera"
        case faceId = "faceid"
    }
    
    static func icon(_ icon: Icons, size: CGFloat = 24) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: size, weight: .regular)
        return UIImage(systemName: icon.rawValue, withConfiguration: config)
    }
}

// MARK: - UIColor Extension for Hex Colors
extension UIColor {
    convenience init?(hex: String) {
        let r, g, b, a: CGFloat

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                    g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                    b = CGFloat(hexNumber & 0x0000ff) / 255
                    a = 1.0

                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }

        return nil
    }
}