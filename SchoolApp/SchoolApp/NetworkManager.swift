import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    private let baseURL = "http://127.0.0.1:8000"

    enum APIError: Error, LocalizedError {
        case invalidURL
        case requestFailed(Error)
        case invalidResponse
        case decodingFailed(Error)
        case serverError(statusCode: Int, message: String?)
        case unknownError

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "The URL was invalid."
            case .requestFailed(let error):
                return "Network request failed: \(error.localizedDescription)"
            case .invalidResponse:
                return "Invalid response from the server."
            case .decodingFailed(let error):
                return "Failed to decode the response: \(error.localizedDescription)"
            case .serverError(let statusCode, let message):
                return "Server error (\(statusCode)): \(message ?? "Unknown error")"
            case .unknownError:
                return "An unknown error occurred."
            }
        }
    }

    func request<T: Decodable>(endpoint: String, method: String = "GET", headers: [String: String]? = nil, body: Data? = nil, completion: @escaping (Result<T, APIError>) -> Void) {
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add default headers
        var requestHeaders = headers ?? [:]
        
        // Add Authorization header for non-OTP endpoints
        if !endpoint.contains("/auth/") {
            if let token = UserDefaultsManager.shared.getJWTToken() {
                requestHeaders["Authorization"] = "Bearer \(token)"
            }
        }
        
        request.allHTTPHeaderFields = requestHeaders
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.requestFailed(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }

            // Handle unauthorized response (401)
            if httpResponse.statusCode == 401 {
                // Clear user data and token
                UserDefaultsManager.shared.clearUserData()
                completion(.failure(.serverError(statusCode: 401, message: "Session expired. Please login again.")))
                return
            }

            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }

            do {
                // First try to decode as the expected type
                let decodedObject = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decodedObject))
            } catch {
                // If decoding fails, try to decode as an error response
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    // Create a response of type T with success: false
                    if let response = self.createErrorResponse(from: errorResponse, type: T.self) {
                        completion(.success(response))
                    } else {
                        // If we can't create a proper error response, create a generic one
                        let genericError = ErrorResponse(success: false, message: "Request failed with status code \(httpResponse.statusCode)")
                        if let response = self.createErrorResponse(from: genericError, type: T.self) {
                            completion(.success(response))
                        } else {
                            completion(.failure(.decodingFailed(error)))
                        }
                    }
                } else {
                    // If we can't decode as an error response, create a generic error response
                    let genericError = ErrorResponse(success: false, message: "Request failed with status code \(httpResponse.statusCode)")
                    if let response = self.createErrorResponse(from: genericError, type: T.self) {
                        completion(.success(response))
                    } else {
                        completion(.failure(.decodingFailed(error)))
                    }
                }
            }
        }.resume()
    }

    private func createErrorResponse<T: Decodable>(from errorResponse: ErrorResponse, type: T.Type) -> T? {
        // Create a dictionary with the error response
        var dict: [String: Any] = [
            "success": false,
            "message": errorResponse.message
        ]
        
        // Add additional fields based on the type
        if type == OTPRequestResponse.self {
            // No additional fields needed for OTPRequestResponse
        } else if type == OTPVerificationResponse.self {
            dict["data"] = nil
        } else if type is BaseResponse<[Circular]>.Type {
            dict["data"] = []
        } else if type is BaseResponse<[Event]>.Type {
            dict["data"] = []
        } else if type is BaseResponse<Timetable>.Type {
            dict["data"] = [:]
        } else if type is BaseResponse<AboutSchool>.Type {
            dict["data"] = [:]
        }
        
        // Convert to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict) else {
            return nil
        }
        
        // Try to decode as the expected type
        return try? JSONDecoder().decode(T.self, from: jsonData)
    }

    // MARK: - Auth Endpoints

    func requestOTP(mobileNumber: String, completion: @escaping (Result<OTPRequestResponse, APIError>) -> Void) {
        let parameters: [String: Any] = ["mobileNumber": mobileNumber]
        guard let body = try? JSONSerialization.data(withJSONObject: parameters) else {
            completion(.failure(.unknownError))
            return
        }
        request(endpoint: "/api/auth/request-otp", method: "POST", headers: ["Content-Type": "application/json"], body: body, completion: completion)
    }

    func verifyOTP(mobileNumber: String, otp: String, completion: @escaping (Result<OTPVerificationResponse, APIError>) -> Void) {
        let parameters: [String: Any] = ["mobileNumber": mobileNumber, "otp": otp]
        guard let body = try? JSONSerialization.data(withJSONObject: parameters) else {
            completion(.failure(.unknownError))
            return
        }
        request(endpoint: "/api/auth/verify-otp", method: "POST", headers: ["Content-Type": "application/json"], body: body, completion: completion)
    }

    // MARK: - Data Endpoints

    func fetchCirculars(token: String, completion: @escaping (Result<[Circular], APIError>) -> Void) {
        let headers = ["Authorization": "Bearer \(token)"]
        request(endpoint: "/api/circulars", headers: headers) { (result: Result<BaseResponse<[Circular]>, APIError>) in
            switch result {
            case .success(let response):
                completion(.success(response.data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchEvents(token: String, completion: @escaping (Result<[Event], APIError>) -> Void) {
        let headers = ["Authorization": "Bearer \(token)"]
        request(endpoint: "/api/events", headers: headers) { (result: Result<BaseResponse<[Event]>, APIError>) in
            switch result {
            case .success(let response):
                completion(.success(response.data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchTimetable(studentId: String, token: String, completion: @escaping (Result<Timetable, APIError>) -> Void) {
        let headers = ["Authorization": "Bearer \(token)"]
        request(endpoint: "/api/timetable/\(studentId)", headers: headers) { (result: Result<BaseResponse<Timetable>, APIError>) in
            switch result {
            case .success(let response):
                completion(.success(response.data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchAboutSchool(token: String, completion: @escaping (Result<AboutSchool, APIError>) -> Void) {
        let headers = ["Authorization": "Bearer \(token)"]
        request(endpoint: "/api/about", headers: headers, completion: completion)
    }

    // MARK: - Models

    struct OTPRequestResponse: Decodable {
        let success: Bool
        let message: String?
    }

    struct OTPVerificationResponse: Decodable {
        let success: Bool
        let message: String
        let data: ResponseData?
    }

    struct ResponseData: Decodable {
        let token: String
        let students: [StudentInfo]
    }

    struct StudentInfo: Codable, Identifiable {
        let id: String
        let name: String
        let className: String
        let section: String
        let dateOfBirth: String

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case className = "class"
            case section
            case dateOfBirth = "dob"
        }
    }

    // MARK: - Response Models
    
    struct BaseResponse<T: Decodable>: Decodable {
        let success: Bool
        let message: String
        let data: T
    }

    struct ErrorResponse: Decodable {
        let success: Bool
        let message: String
    }

    struct Event: Decodable, Identifiable {
        let title: String
        let date: String
        let description: String
        let imageUrl: URL?
        
        var id: String { title + date } // Using combination of title and date as unique identifier
    }

    struct Circular: Decodable, Identifiable {
        let title: String
        let issuedDate: String
        let content: String
        
        var id: String { title + issuedDate } // Using combination of title and date as unique identifier
    }

    struct Timetable: Decodable {
        let className: String
        let section: String
        let schedule: [String: [ScheduleEntry]]
        
        enum CodingKeys: String, CodingKey {
            case className = "class"
            case section
            case schedule
        }
    }

    struct ScheduleEntry: Decodable, Identifiable {
        let subject: String
        let time: String
        
        var id: String { subject + time } // Using combination of subject and time as unique identifier
    }

    struct AboutSchool: Decodable {
        let name: String
        let address: String
        let contact: String
        let email: String
        let website: String
        let description: String
    }
} 
