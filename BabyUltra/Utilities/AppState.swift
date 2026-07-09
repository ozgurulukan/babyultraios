import SwiftUI

class AppState: ObservableObject {
    static let shared = AppState()
    @Published var selectedTab: BabyUltraTab = .home
    @Published var hideTabBar: Bool = false
}