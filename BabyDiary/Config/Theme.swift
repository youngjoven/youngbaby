import SwiftUI

extension Color {
    static let appPink = Color(red: 0.85, green: 0.25, blue: 0.45)
    static let appGreen = Color(red: 0.1, green: 0.6, blue: 0.45)
    static let appPurple = Color(red: 0.5, green: 0.2, blue: 0.8)
}

// MARK: - 공통 네비게이션 바 스타일

struct PastelNavigationStyle: ViewModifier {
    let emoji: String
    let title: String
    let titleColor: Color

    func body(content: Content) -> some View {
        content
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("PastelBackground"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Text(emoji).font(.subheadline)
                        Text(title)
                            .font(.headline.bold())
                            .foregroundColor(titleColor)
                    }
                }
            }
    }
}

extension View {
    func pastelNavigation(emoji: String, title: String, color: Color) -> some View {
        modifier(PastelNavigationStyle(emoji: emoji, title: title, titleColor: color))
    }
}
