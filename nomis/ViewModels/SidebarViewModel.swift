import SwiftUI

public class SidebarViewModel: ObservableObject {
    @Published public var showingSidebar = false
    @Published public var showingCreateGroup = false
    
    public static let shared = SidebarViewModel()
    
    private init() {}
} 