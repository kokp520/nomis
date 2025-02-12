import Foundation

struct BinUser: Codable, Identifiable {
    let id: String
    var name: String
    let email: String
    let createdAt: Date?
    
    init(id: String, name: String, email: String, createdAt: Date? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.createdAt = createdAt
    }
} 