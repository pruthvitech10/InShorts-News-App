//
//  View+Modifiers.swift
//  ShortsNewsClone
//
//  Created on 29 October 2025.
//

import SwiftUI

// Card styling

extension View {
    /// Applies a standard card style with shadow and corner radius
    func cardStyle() -> some View {
        AdaptiveCardStyle(content: self, shadowOpacity: 0.1, radius: 5)
    }
    
    /// Applies an elevated card style with more prominent shadow
    func elevatedCardStyle() -> some View {
        AdaptiveCardStyle(content: self, shadowOpacity: 0.15, radius: 10, yOffset: 5)
    }
    
    /// Applies a subtle card style with minimal shadow
    func subtleCardStyle() -> some View {
        AdaptiveCardStyle(content: self, shadowOpacity: 0.05, radius: 3, yOffset: 1)
    }
    
    /// Applies a bordered card style without shadow
    func borderedCardStyle(color: Color = .gray.opacity(0.2)) -> some View {
        AdaptiveBorderedCardStyle(content: self, borderColor: color)
    }
}

private struct AdaptiveCardStyle<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let content: Content
    let shadowOpacity: Double
    let radius: CGFloat
    var yOffset: CGFloat = 2
    
    var body: some View {
        content
            .background(Color.theme.cardBackground.value(for: colorScheme))
            .cornerRadius(AppConstants.cardCornerRadius)
            .shadow(
                color: (colorScheme == .dark ? Color.white : Color.black).opacity(shadowOpacity),
                radius: radius,
                x: 0,
                y: yOffset
            )
    }
}

private struct AdaptiveBorderedCardStyle<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let content: Content
    let borderColor: Color
    
    var body: some View {
        content
            .background(Color.theme.cardBackground.value(for: colorScheme))
            .cornerRadius(AppConstants.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius)
                    .stroke(Color.theme.border.value(for: colorScheme), lineWidth: 1)
            )
    }
}

// Conditional view modifiers

extension View {
    /// Conditionally applies a transform
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Conditionally applies one of two transforms
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        then trueTransform: (Self) -> TrueContent,
        else falseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            trueTransform(self)
        } else {
            falseTransform(self)
        }
    }
    
    /// Applies transform if optional value is not nil
    @ViewBuilder
    func ifLet<T, Transform: View>(_ value: T?, transform: (Self, T) -> Transform) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

// Loading overlays

extension View {
    /// Shows a loading overlay
    func loading(_ isLoading: Bool) -> some View {
        self.overlay(
            Group {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    }
                }
            }
        )
    }
    
    /// Shows a shimmer loading effect
    func shimmer(_ isLoading: Bool) -> some View {
        self.modifier(ShimmerModifier(isAnimating: isLoading))
    }
}

// Error alerts

extension View {
    /// Shows an error alert
    func errorAlert(error: Binding<Error?>) -> some View {
        self.alert("Error", isPresented: .constant(error.wrappedValue != nil)) {
            Button("OK") {
                error.wrappedValue = nil
            }
        } message: {
            if let error = error.wrappedValue {
                Text(error.localizedDescription)
            }
        }
    }
    
    /// Shows a custom error view overlay
    func errorOverlay<ErrorContent: View>(
        error: Error?,
        @ViewBuilder content: (Error) -> ErrorContent
    ) -> some View {
        self.overlay(
            Group {
                if let error = error {
                    content(error)
                }
            }
        )
    }
}

// Navigation helpers

extension View {
    /// Hides the navigation bar
    func hideNavigationBar() -> some View {
        self
            .navigationBarHidden(true)
            .navigationBarTitleDisplayMode(.inline)
    }
    
    /// Sets up a custom navigation title with display mode
    func customNavigationTitle(_ title: String, displayMode: NavigationBarItem.TitleDisplayMode = .large) -> some View {
        self
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(displayMode)
    }
}

// Keyboard handling

extension View {
    /// Dismisses keyboard on tap
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }
    
    /// Adds toolbar with done button to dismiss keyboard
    func keyboardToolbar(onDone: @escaping () -> Void = {}) -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                    onDone()
                }
            }
        }
    }
}

// Animation helpers

extension View {
    /// Applies a spring animation
    func springAnimation() -> some View {
        self.animation(.spring(response: 0.3, dampingFraction: 0.7), value: UUID())
    }
    
    /// Applies the app's standard animation
    func standardAnimation<V: Equatable>(_ value: V) -> some View {
        self.animation(.easeInOut(duration: AppConstants.animationDuration), value: value)
    }
}

// Empty state views

extension View {
    /// Shows content or empty state
    func emptyState<EmptyContent: View>(
        isEmpty: Bool,
        @ViewBuilder emptyContent: () -> EmptyContent
    ) -> some View {
        ZStack {
            self.opacity(isEmpty ? 0 : 1)
            
            if isEmpty {
                emptyContent()
            }
        }
    }
}

// Placeholder/skeleton views

extension View {
    /// Shows redacted placeholder while loading
    func placeholder(_ isLoading: Bool) -> some View {
        self
            .redacted(reason: isLoading ? .placeholder : [])
            .shimmer(isLoading)
    }
}

// Haptic feedback

extension View {
    /// Adds haptic feedback on tap
    func hapticFeedback(
        _ style: UIImpactFeedbackGenerator.FeedbackStyle = .light,
        onTap action: @escaping () -> Void
    ) -> some View {
        self.onTapGesture {
            HapticFeedback.impact(style: style)
            action()
        }
    }
}

// Corner radius helpers

extension View {
    /// Applies corner radius to specific corners
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

// Supporting shape for rounded corners
private struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Share sheet

extension View {
    /// Presents a share sheet
    func share(items: [Any]) -> some View {
        self.sheet(isPresented: .constant(true)) {
            ShareSheet(items: items)
        }
    }
}

// News card styling

extension View {
    /// Applies news card styling
    func newsCardStyle(isFeatured: Bool = false) -> some View {
        self
            .if(isFeatured) { view in
                view.elevatedCardStyle()
            } else: { view in
                view.cardStyle()
            }
            .padding(.horizontal, AppConstants.defaultPadding)
    }
    
    /// Adds a "fresh" indicator badge
    func freshIndicator(isFresh: Bool) -> some View {
        self.overlay(
            Group {
                if isFresh {
                    VStack {
                        HStack {
                            Spacer()
                            Text("Fresh")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .cornerRadius(8)
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            },
            alignment: .topTrailing
        )
    }
}

// Supporting types
// ShimmerModifier, ShareSheet, and HapticFeedback are defined in their respective files
