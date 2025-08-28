//
//  CyberpunkTheme.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2024-08-05.
//

import UIKit

struct CyberpunkTheme {
    // MARK: - Primary Colors (from design system)
    static let background = UIColor(hex: "#0A0A0F")! // Near black
    static let surface = UIColor(hex: "#1A1A2E")! // Dark blue-gray
    static let surfacePrimary = UIColor(hex: "#1A1A2E")! // Primary surface color
    static let surfaceSecondary = UIColor(hex: "#252540")! // Secondary surface color
    static let primaryCyan = UIColor(hex: "#00D9FF")! // Bright cyan (main brand color)
    static let accentPink = UIColor(hex: "#FF006E")! // Hot pink accent
    static let gradientBlue = UIColor(hex: "#0066FF")! // Gradient start
    static let gradientPurple = UIColor(hex: "#9933FF")! // Gradient end
    
    // MARK: - Text Colors
    static let textPrimary = UIColor(hex: "#FFFFFF")! // Pure white for headers
    static let textSecondary = UIColor(hex: "#E0E0E0")! // Light gray for body
    static let textTertiary = UIColor(hex: "#A0A0A0")! // Medium gray for captions
    static let textCyan = UIColor(hex: "#00D9FF")! // Cyan for interactive text
    
    // MARK: - Semantic Colors
    static let warning = UIColor(hex: "#FFB800")! // Amber/yellow for warnings
    static let success = UIColor(hex: "#00FF88")! // Green for success
    static let error = UIColor(hex: "#FF3366")! // Red for errors
    static let info = UIColor(hex: "#00B8FF")! // Blue for info
    
    // MARK: - Additional UI Colors
    static let primaryText = textPrimary // Alias for consistency
    static let secondaryText = textSecondary // Alias for consistency
    static let tertiaryText = textTertiary // Alias for consistency
    static let border = UIColor(hex: "#2A2A40")! // Border color
    static let primaryColor = primaryCyan // Alias for primary brand color
    static let secondaryColor = accentPink // Alias for secondary brand color
    
    // MARK: - Icon Colors
    static let iconCyan = UIColor(hex: "#00D9FF")! // Primary icon color
    static let iconPink = UIColor(hex: "#FF006E")! // Accent icon color
    
    // MARK: - Effects
    static let glowColor = UIColor(hex: "#00D9FF")!.withAlphaComponent(0.6)
    static let gridLineColor = UIColor(hex: "#1A1A2E")!.withAlphaComponent(0.5)
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