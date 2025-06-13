import XCTest
@testable import SchoolApp

final class LoginTests: XCTestCase {
    var networkManager: NetworkManager!
    var userDefaultsManager: UserDefaultsManager!
    
    override func setUp() {
        super.setUp()
        networkManager = NetworkManager.shared
        userDefaultsManager = UserDefaultsManager.shared
        // Clear any existing data
        userDefaultsManager.clearUserData()
    }
    
    override func tearDown() {
        networkManager = nil
        userDefaultsManager = nil
        super.tearDown()
    }
    
    func testRequestOTP() async throws {
        // Given
        let mobileNumber = "9597707175"
        
        // When
        let expectation = expectation(description: "OTP Request")
        var response: NetworkManager.OTPRequestResponse?
        var error: Error?
        
        networkManager.requestOTP(mobileNumber: mobileNumber) { result in
            switch result {
            case .success(let resp):
                response = resp
            case .failure(let err):
                error = err
            }
            expectation.fulfill()
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 25.0)
        
        if let error = error {
            XCTFail("OTP request failed with error: \(error.localizedDescription)")
        }
        
        XCTAssertNotNil(response)
        XCTAssertTrue(response?.success ?? false)
        XCTAssertNotNil(response?.message)
    }
    
    func testVerifyOTP() async throws {
        // Given
        let mobileNumber = "9597707175"
        let otp = "123456" // This should be a valid OTP from your test environment
        
        // When
        let expectation = expectation(description: "OTP Verification")
        var response: NetworkManager.OTPVerificationResponse?
        var error: Error?
        
        networkManager.verifyOTP(mobileNumber: mobileNumber, otp: otp) { result in
            switch result {
            case .success(let resp):
                response = resp
            case .failure(let err):
                error = err
            }
            expectation.fulfill()
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        
        if let error = error {
            XCTFail("OTP verification failed with error: \(error.localizedDescription)")
        }
        
        XCTAssertNotNil(response)
        XCTAssertTrue(response?.success ?? false)
        XCTAssertNotNil(response?.message)
        
        if let data = response?.data {
            XCTAssertNotNil(data.token)
            XCTAssertFalse(data.students.isEmpty)
            
            // Verify student data structure
            let student = data.students[0]
            XCTAssertNotNil(student.id)
            XCTAssertNotNil(student.name)
            XCTAssertNotNil(student.className)
            XCTAssertNotNil(student.section)
            XCTAssertNotNil(student.dateOfBirth)
        } else {
            XCTFail("No data received in response")
        }
    }
    
    func testInvalidMobileNumber() async throws {
        // Given
        let invalidMobileNumber = "123" // Too short
        
        // When
        let expectation = expectation(description: "Invalid Mobile Number")
        var response: NetworkManager.OTPRequestResponse?
        var error: Error?
        
        networkManager.requestOTP(mobileNumber: invalidMobileNumber) { result in
            switch result {
            case .success(let resp):
                response = resp
            case .failure(let err):
                error = err
            }
            expectation.fulfill()
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 15.0)
        
        XCTAssertNotNil(response)
        XCTAssertFalse(response?.success ?? true)
        XCTAssertNotNil(response?.message)
    }
    
    func testInvalidOTP() async throws {
        // Given
        let mobileNumber = "9597707175"
        let invalidOTP = "12345" // Too short
        
        // When
        let expectation = expectation(description: "Invalid OTP")
        var response: NetworkManager.OTPVerificationResponse?
        var error: Error?
        
        networkManager.verifyOTP(mobileNumber: mobileNumber, otp: invalidOTP) { result in
            switch result {
            case .success(let resp):
                response = resp
            case .failure(let err):
                error = err
            }
            expectation.fulfill()
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        
        XCTAssertNotNil(response)
        XCTAssertFalse(response?.success ?? true)
        XCTAssertNotNil(response?.message)
    }
    
    func testTokenStorage() async throws {
        // Given
        let mobileNumber = "9597707175"
        let otp = "123456" // This should be a valid OTP from your test environment
        
        // When
        let expectation = expectation(description: "Token Storage")
        var response: NetworkManager.OTPVerificationResponse?
        var error: Error?
        
        networkManager.verifyOTP(mobileNumber: mobileNumber, otp: otp) { result in
            switch result {
            case .success(let resp):
                response = resp
            case .failure(let err):
                error = err
            }
            expectation.fulfill()
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        
        if let error = error {
            XCTFail("OTP verification failed with error: \(error.localizedDescription)")
        }
        
        if let data = response?.data {
            // Store token
            userDefaultsManager.saveJWTToken(data.token)
            
            // Verify token was stored
            let storedToken = userDefaultsManager.getJWTToken()
            XCTAssertNotNil(storedToken)
            XCTAssertEqual(storedToken, data.token)
            
            // Clear token
            userDefaultsManager.clearUserData()
            
            // Verify token was cleared
            let clearedToken = userDefaultsManager.getJWTToken()
            XCTAssertNil(clearedToken)
        } else {
            XCTFail("No data received in response")
        }
    }
} 
