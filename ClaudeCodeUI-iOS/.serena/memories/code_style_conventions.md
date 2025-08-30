# Code Style and Conventions

## Swift Style Guide
- **Naming**: 
  - Classes/Structs: PascalCase (e.g., `ChatMessageCell`)
  - Methods/Properties: camelCase (e.g., `setupUI()`)
  - Constants: camelCase or UPPER_SNAKE_CASE for global
  - Protocols: PascalCase with descriptive names

## Architecture Patterns
- **MVVM**: ViewModels for business logic separation
- **Delegate Pattern**: For component communication
- **Coordinator Pattern**: Navigation management
- **Repository Pattern**: Data access abstraction

## File Organization
- Group by feature, not by type
- Separate concerns: Views, ViewModels, Models, Services
- Use MARK comments for section organization:
  ```swift
  // MARK: - Properties
  // MARK: - Lifecycle
  // MARK: - Setup
  // MARK: - Actions
  ```

## UIKit/SwiftUI Guidelines
- Prefer UIKit for complex screens requiring fine control
- Use SwiftUI for simple, declarative components
- Bridge with UIHostingController when needed
- Maintain consistent theming across both frameworks

## Best Practices
- **Accessibility**: Support VoiceOver, Dynamic Type
- **Localization**: Use NSLocalizedString for all user-facing text
- **Error Handling**: Comprehensive error cases with user feedback
- **Memory Management**: Weak references for delegates, careful with closures
- **Testing**: Minimum 80% code coverage target

## Documentation
- Document public APIs with /// comments
- Include usage examples for complex components
- Maintain README files for feature modules