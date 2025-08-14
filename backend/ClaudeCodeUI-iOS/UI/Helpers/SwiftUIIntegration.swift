import SwiftUI
import UIKit
import Combine

// MARK: - UIHostingController Extension
extension UIHostingController {
    /// Configure the hosting controller with cyberpunk theme
    func configureCyberpunkTheme() {
        view.backgroundColor = .clear
        
        // Remove safe area if needed
        if #available(iOS 16.4, *) {
            safeAreaRegions = []
        }
    }
    
    /// Embed SwiftUI view in UIViewController
    func embed(in parent: UIViewController, container: UIView? = nil) {
        parent.addChild(self)
        
        let targetView = container ?? parent.view!
        targetView.addSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: targetView.topAnchor),
            view.leadingAnchor.constraint(equalTo: targetView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: targetView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: targetView.bottomAnchor)
        ])
        
        didMove(toParent: parent)
    }
}

// MARK: - SwiftUI View Embedding
struct UIKitViewControllerRepresentable<ViewController: UIViewController>: UIViewControllerRepresentable {
    let viewController: ViewController
    let configuration: ((ViewController) -> Void)?
    
    init(_ viewController: ViewController, configuration: ((ViewController) -> Void)? = nil) {
        self.viewController = viewController
        self.configuration = configuration
    }
    
    func makeUIViewController(context: Context) -> ViewController {
        configuration?(viewController)
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        configuration?(uiViewController)
    }
}

// MARK: - SwiftUI Environment Bridge
class SwiftUIEnvironmentBridge: ObservableObject {
    static let shared = SwiftUIEnvironmentBridge()
    
    @Published var theme: CyberpunkThemeConfig = .default
    @Published var isLoading: Bool = false
    @Published var currentProject: Project?
    @Published var currentSession: Session?
    @Published var networkStatus: NetworkStatus = .connected
    
    enum NetworkStatus {
        case connected, disconnected, connecting
    }
    
    private init() {}
}

// MARK: - Cyberpunk Theme Config
struct CyberpunkThemeConfig {
    let primaryColor: Color = Color(hex: "00D9FF")
    let secondaryColor: Color = Color(hex: "FF006E")
    let backgroundColor: Color = .black
    let surfaceColor: Color = Color.white.opacity(0.05)
    let textColor: Color = .white
    let glowIntensity: Double = 0.5
    let animationSpeed: Double = 1.0
    
    static let `default` = CyberpunkThemeConfig()
}

// MARK: - UIViewController Extension for SwiftUI
extension UIViewController {
    /// Add a SwiftUI view as a child view controller
    func addSwiftUIView<Content: View>(
        _ swiftUIView: Content,
        to container: UIView? = nil,
        configuration: ((UIHostingController<Content>) -> Void)? = nil
    ) -> UIHostingController<Content> {
        let hostingController = UIHostingController(rootView: swiftUIView)
        configuration?(hostingController)
        hostingController.embed(in: self, container: container)
        return hostingController
    }
    
    /// Present a SwiftUI view modally
    func presentSwiftUIView<Content: View>(
        _ swiftUIView: Content,
        animated: Bool = true,
        configuration: ((UIHostingController<Content>) -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) {
        let hostingController = UIHostingController(rootView: swiftUIView)
        configuration?(hostingController)
        hostingController.configureCyberpunkTheme()
        hostingController.modalPresentationStyle = .fullScreen
        present(hostingController, animated: animated, completion: completion)
    }
}

// MARK: - Combine Publishers for Data Flow
extension UIViewController {
    /// Create a publisher for view controller lifecycle events
    func lifecyclePublisher(for event: LifecycleEvent) -> AnyPublisher<Void, Never> {
        NotificationCenter.default
            .publisher(for: event.notificationName)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    enum LifecycleEvent {
        case viewDidLoad, viewWillAppear, viewDidAppear
        case viewWillDisappear, viewDidDisappear
        
        var notificationName: Notification.Name {
            switch self {
            case .viewDidLoad: return .init("viewDidLoad")
            case .viewWillAppear: return .init("viewWillAppear")
            case .viewDidAppear: return .init("viewDidAppear")
            case .viewWillDisappear: return .init("viewWillDisappear")
            case .viewDidDisappear: return .init("viewDidDisappear")
            }
        }
    }
}

// MARK: - Data Binding Helper
class DataBindingHelper<T> {
    @Published private(set) var value: T
    private var cancellables = Set<AnyCancellable>()
    
    init(initialValue: T) {
        self.value = initialValue
    }
    
    /// Bind to a UIKit control
    func bind(to control: UIControl, keyPath: ReferenceWritableKeyPath<UIControl, T>) {
        $value
            .receive(on: DispatchQueue.main)
            .sink { [weak control] newValue in
                control?[keyPath: keyPath] = newValue
            }
            .store(in: &cancellables)
    }
    
    /// Update the value
    func update(_ newValue: T) {
        value = newValue
    }
}

// MARK: - View Modifier for Cyberpunk Theme
struct CyberpunkThemeModifier: ViewModifier {
    @StateObject private var bridge = SwiftUIEnvironmentBridge.shared
    
    func body(content: Content) -> some View {
        content
            .environmentObject(bridge)
            .preferredColorScheme(.dark)
            .accentColor(bridge.theme.primaryColor)
            .background(bridge.theme.backgroundColor)
    }
}

extension View {
    func cyberpunkTheme() -> some View {
        modifier(CyberpunkThemeModifier())
    }
}

// MARK: - Glow Effect Modifier
struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.8), radius: radius / 2)
            .shadow(color: color.opacity(0.6), radius: radius)
            .shadow(color: color.opacity(0.4), radius: radius * 1.5)
    }
}

extension View {
    func glow(color: Color = Color(hex: "00D9FF"), radius: CGFloat = 8) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}

// MARK: - Navigation Helper
struct NavigationLinkButton<Destination: View>: View {
    let title: String
    let destination: Destination
    let action: (() -> Void)?
    
    init(
        title: String,
        destination: Destination,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.destination = destination
        self.action = action
    }
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: "00D9FF").opacity(0.3),
                                Color(hex: "FF006E").opacity(0.3)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            TapGesture().onEnded {
                action?()
            }
        )
    }
}

// MARK: - Animated Transition Helper
struct AnimatedTransition: ViewModifier {
    let animation: Animation
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1 : 0.8)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(animation) {
                    isVisible = true
                }
            }
            .onDisappear {
                isVisible = false
            }
    }
}

extension View {
    func animatedTransition(_ animation: Animation = .spring()) -> some View {
        modifier(AnimatedTransition(animation: animation))
    }
}

// MARK: - UIView to SwiftUI Bridge
struct UIViewRepresentableWrapper<UIViewType: UIView>: UIViewRepresentable {
    let uiView: UIViewType
    let configuration: ((UIViewType) -> Void)?
    
    func makeUIView(context: Context) -> UIViewType {
        configuration?(uiView)
        return uiView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        configuration?(uiView)
    }
}

// MARK: - Coordinator Pattern Helper
class SwiftUICoordinator<HostedView: View>: NSObject {
    let hostingController: UIHostingController<HostedView>
    weak var parentViewController: UIViewController?
    
    init(rootView: HostedView, parent: UIViewController) {
        self.hostingController = UIHostingController(rootView: rootView)
        self.parentViewController = parent
        super.init()
        setupHostingController()
    }
    
    private func setupHostingController() {
        hostingController.configureCyberpunkTheme()
    }
    
    func present(animated: Bool = true) {
        parentViewController?.present(hostingController, animated: animated)
    }
    
    func embed(in container: UIView? = nil) {
        guard let parent = parentViewController else { return }
        hostingController.embed(in: parent, container: container)
    }
    
    func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        hostingController.dismiss(animated: animated, completion: completion)
    }
}