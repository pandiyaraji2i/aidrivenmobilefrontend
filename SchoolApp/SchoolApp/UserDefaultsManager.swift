import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private init() {}

    private let defaults = UserDefaults.standard

    enum Keys {
        static let jwtToken = "jwtToken"
        static let selectedStudentId = "selectedStudentId"
        static let mobileNumber = "mobileNumber"
    }

    func saveJWTToken(_ token: String) {
        defaults.set(token, forKey: Keys.jwtToken)
    }

    func getJWTToken() -> String? {
        defaults.string(forKey: Keys.jwtToken)
    }

    func saveSelectedStudentId(_ studentId: String) {
        defaults.set(studentId, forKey: Keys.selectedStudentId)
    }

    func saveStudentInfo(_ studentInfo: NetworkManager.StudentInfo) {
        if let encoded = try? JSONEncoder().encode(studentInfo) {
            defaults.set(encoded, forKey: "selectedStudentInfo")
        }
    }

    func getSelectedStudentInfo() -> NetworkManager.StudentInfo? {
        if let savedStudentInfo = defaults.data(forKey: "selectedStudentInfo") {
            if let decodedStudentInfo = try? JSONDecoder().decode(NetworkManager.StudentInfo.self, from: savedStudentInfo) {
                return decodedStudentInfo
            }
        }
        return nil
    }

    func getSelectedStudentId() -> String? {
        defaults.string(forKey: Keys.selectedStudentId)
    }

    func saveMobileNumber(_ number: String) {
        defaults.set(number, forKey: Keys.mobileNumber)
    }

    func getMobileNumber() -> String? {
        defaults.string(forKey: Keys.mobileNumber)
    }

    func clearUserData() {
        defaults.removeObject(forKey: Keys.jwtToken)
        defaults.removeObject(forKey: Keys.selectedStudentId)
        defaults.removeObject(forKey: Keys.mobileNumber)
    }
} 