import Foundation
class UserSettings {
    
    static let shared = UserSettings()
    
    private let defaults = UserDefaults.standard
    
    var isAutomaticDetect: Bool {
        get {
            return defaults.object(forKey: "isAutomaticDetect") as? Bool ?? true
        }
        set {
            defaults.set(newValue, forKey: "isAutomaticDetect")
        }
    }
    
    
}
