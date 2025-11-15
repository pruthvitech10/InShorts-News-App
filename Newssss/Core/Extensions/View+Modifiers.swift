//
//  View+Modifiers.swift
//  ShortsNewsClone
//
//  Created on 29 October 2025.
//

import SwiftUI

// MARK: - Card Styles

extension View {
    /// Applies a standard card style with shadow and corner radius
    func cardStyle() -> some View {
        self
            .background(Color(.systemBackground))
            .cornerRadius(Constants.UI.cardCornerRadius)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /// Applies an elevated card style with more prominent shadow
    func elevatedCardStyle() -> some View {
        self
            .background(Color(.systemBackground))
            .cornerRadius(Constants.UI.cardCornerRadius)
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
    
    /// Applies a subtle card style with minimal shadow
    func subtleCardStyle() -> some View {
        self
            .background(Color(.systemBackground))
            .cornerRadius(Constants.UI.cardCornerRadius)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
    
    /// Applies a bordered card style without shadow
    func borderedCardStyle(color: Color = .gray.opacity(0.2)) -> some View {
        self
            .background(Color(.systemBackground))
            .cornerRadius(Constants.UI.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.UI.cardCornerRadius)
                    .stroke(color, lineWidth: 1)
            )
    }
}

// MARK: - Conditional Modifiers

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

// MARK: - Loading States

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

// MARK: - Error Handling

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

// MARK: - Navigation

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

// MARK: - Keyboard

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

// MARK: - Animations

extension View {
    /// Applies a spring animation
    func springAnimation() -> some View {
        self.animation(.spring(response: 0.3, dampingFraction: 0.7), value: UUID())
    }
    
    /// Applies the app's standard animation
    func standardAnimation<V: Equatable>(_ value: V) -> some View {
        self.animation(.easeInOut(duration: Constants.UI.animationDuration), value: value)
    }
}

// MARK: - Empty State

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

// MARK: - Redacted (Placeholder)

extension View {
    /// Shows redacted placeholder while loading
    func placeholder(_ isLoading: Bool) -> some View {
        self
            .redacted(reason: isLoading ? .placeholder : [])
            .shimmer(isLoading)
    }
}

// MARK: - Haptic Feedback

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

// MARK: - Corner Radius

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

// MARK: - Share

extension View {
    /// Presents a share sheet
    func share(items: [Any]) -> some View {
        self.sheet(isPresented: .constant(true)) {
            ShareSheet(items: items)
        }
    }
}

// MARK: - News-Specific Modifiers

extension View {
    /// Applies news card styling
    func newsCardStyle(isFeatured: Bool = false) -> some View {
        self
            .if(isFeatured) { view in
                view.elevatedCardStyle()
            } else: { view in
                view.cardStyle()
            }
            .padding(.horizontal, Constants.UI.defaultPadding)
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

// MARK: - Supporting Types
// ShimmerModifier, ShareSheet, and HapticFeedback are defined in their respective files
