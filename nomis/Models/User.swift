import Foundation

public struct User: Identifiable, Codable {
    public let id: String
    public var name: String
    public let email: String
    
    public init(id: String, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
} 