import Foundation
import CoreData

// MARK: - Email Processing Facade

class EmailProcessingFacade {
    private let emailViewModel: EmailViewModel
    private let validationService: EmailValidationService
    private let processingQueue: OperationQueue
    private let logger: EmailProcessingLogger
    
    init(emailViewModel: EmailViewModel, 
         validationService: EmailValidationService = EmailValidationService(),
         logger: EmailProcessingLogger = EmailProcessingLogger()) {
        self.emailViewModel = emailViewModel
        self.validationService = validationService
        self.logger = logger
        
        self.processingQueue = OperationQueue()
        self.processingQueue.maxConcurrentOperationCount = 1
        self.processingQueue.qualityOfService = .userInitiated
    }
    
    func processEmails(_ emailList: NSArray, 
                      isGmailManualSync: Bool = false, 
                      isManualSync: Bool = false,
                      completion: @escaping (EmailProcessingResult) -> Void) {
        
        logger.log(.info, "Starting email processing for \(emailList.count) emails")
        
        // Validation
        let validationResult = validationService.validateEmailList(emailList)
        guard validationResult.isValid else {
            logger.log(.error, "Validation failed: \(validationResult.errors)")
            completion(.failure(validationResult.errors))
            return
        }
        
        // Processing
        processingQueue.addOperation {
            let processingResult = self.processValidEmails(emailList, 
                                                         isGmailManualSync: isGmailManualSync, 
                                                         isManualSync: isManualSync)
            
            // Post-processing
            self.handlePostProcessing(processingResult)
            
            DispatchQueue.main.async {
                completion(processingResult)
            }
        }
    }
    
    private func processValidEmails(_ emailList: NSArray, 
                                  isGmailManualSync: Bool, 
                                  isManualSync: Bool) -> EmailProcessingResult {
        
        // Break down into smaller chunks for better performance
        let chunks = emailList.chunked(into: 100)
        var results: [EmailProcessingResult] = []
        var totalProcessed = 0
        var totalSkipped = 0
        var allErrors: [EmailProcessingError] = []
        
        logger.log(.info, "Processing \(chunks.count) chunks")
        
        for (index, chunk) in chunks.enumerated() {
            do {
                emailViewModel.saveEmailToLocalStorage(emailList: chunk, 
                                                     isGmailManualSync: isGmailManualSync, 
                                                     isManualSync: isManualSync)
                totalProcessed += chunk.count
                logger.log(.debug, "Processed chunk \(index + 1)/\(chunks.count)")
            } catch {
                let processingError = EmailProcessingError.chunkProcessingFailed(chunkIndex: index, error: error)
                allErrors.append(processingError)
                totalSkipped += chunk.count
                logger.log(.error, "Chunk \(index + 1) failed: \(error)")
            }
        }
        
        if allErrors.isEmpty {
            return .success(processedCount: totalProcessed, 
                          skippedCount: totalSkipped, 
                          errors: [])
        } else {
            return .partialSuccess(processedCount: totalProcessed, 
                                 skippedCount: totalSkipped, 
                                 errors: allErrors)
        }
    }
    
    private func handlePostProcessing(_ result: EmailProcessingResult) {
        switch result {
        case .success(let processed, let skipped, _):
            logger.log(.info, "Processing completed: \(processed) processed, \(skipped) skipped")
        case .partialSuccess(let processed, let skipped, let errors):
            logger.log(.warning, "Processing completed with errors: \(processed) processed, \(skipped) skipped, \(errors.count) errors")
        case .failure(let errors):
            logger.log(.error, "Processing failed: \(errors.count) errors")
        }
    }
}

// MARK: - Email Validation Service

class EmailValidationService {
    private let dateFormatter: DateFormatter
    
    init() {
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
    }
    
    func validateEmailList(_ emailList: NSArray) -> ValidationResult {
        var errors: [EmailProcessingError] = []
        
        for (index, emailInfo) in emailList.enumerated() {
            if let emailDict = emailInfo as? NSDictionary {
                let emailErrors = validateEmailInfo(emailDict, at: index)
                errors.append(contentsOf: emailErrors)
            } else {
                errors.append(.invalidFormat(at: index))
            }
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    private func validateEmailInfo(_ emailInfo: NSDictionary, at index: Int) -> [EmailProcessingError] {
        var errors: [EmailProcessingError] = []
        
        // Required fields validation
        if emailInfo["id"] == nil {
            errors.append(.missingRequiredField("id", at: index))
        }
        
        if emailInfo["from_address"] == nil && emailInfo["from"] == nil {
            errors.append(.missingRequiredField("from_address/from", at: index))
        }
        
        // Date validation
        if let dateString = emailInfo["date"] as? String {
            if !isValidDate(dateString) {
                errors.append(.invalidDate(dateString, at: index))
            }
        }
        
        // Email validation
        if let fromAddress = emailInfo["from_address"] as? NSDictionary,
           let email = fromAddress["email"] as? String {
            if !isValidEmail(email) {
                errors.append(.invalidEmail(email, at: index))
            }
        }
        
        return errors
    }
    
    private func isValidDate(_ dateString: String) -> Bool {
        return dateFormatter.date(from: dateString) != nil
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Email Processing Result

enum EmailProcessingResult {
    case success(processedCount: Int, skippedCount: Int, errors: [EmailProcessingError])
    case partialSuccess(processedCount: Int, skippedCount: Int, errors: [EmailProcessingError])
    case failure([EmailProcessingError])
    
    var isSuccessful: Bool {
        switch self {
        case .success, .partialSuccess:
            return true
        case .failure:
            return false
        }
    }
    
    var processedCount: Int {
        switch self {
        case .success(let count, _, _), .partialSuccess(let count, _, _):
            return count
        case .failure:
            return 0
        }
    }
    
    var errorCount: Int {
        switch self {
        case .success(_, _, let errors), .partialSuccess(_, _, let errors), .failure(let errors):
            return errors.count
        }
    }
}

// MARK: - Email Processing Error

enum EmailProcessingError: Error, LocalizedError {
    case invalidFormat(at: Int)
    case missingRequiredField(String, at: Int)
    case invalidDate(String, at: Int)
    case invalidEmail(String, at: Int)
    case chunkProcessingFailed(chunkIndex: Int, error: Error)
    case contextSaveFailed(Error)
    case duplicateMessageId(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat(let index):
            return "Invalid email format at index \(index)"
        case .missingRequiredField(let field, let index):
            return "Missing required field '\(field)' at index \(index)"
        case .invalidDate(let date, let index):
            return "Invalid date format '\(date)' at index \(index)"
        case .invalidEmail(let email, let index):
            return "Invalid email address '\(email)' at index \(index)"
        case .chunkProcessingFailed(let chunkIndex, let error):
            return "Chunk \(chunkIndex) processing failed: \(error.localizedDescription)"
        case .contextSaveFailed(let error):
            return "Context save failed: \(error.localizedDescription)"
        case .duplicateMessageId(let messageId):
            return "Duplicate message ID: \(messageId)"
        }
    }
}

// MARK: - Validation Result

struct ValidationResult {
    let isValid: Bool
    let errors: [EmailProcessingError]
}

// MARK: - Email Processing Logger

class EmailProcessingLogger {
    enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }
    
    func log(_ level: LogLevel, _ message: String) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] [\(level.rawValue)] EmailProcessing: \(message)"
        
        #if DEBUG
        print(logMessage)
        #endif
        
        // In production, you might want to send this to a logging service
        // or save to a file
    }
}

// MARK: - Extensions

extension NSArray {
    func chunked(into size: Int) -> [[Any]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}

// MARK: - Usage Example

/*
// Example usage in your EmailViewModel or ViewController:

let facade = EmailProcessingFacade(emailViewModel: emailViewModel)

facade.processEmails(emailList, isGmailManualSync: false, isManualSync: true) { result in
    switch result {
    case .success(let processed, let skipped, _):
        print("Successfully processed \(processed) emails, skipped \(skipped)")
        
    case .partialSuccess(let processed, let skipped, let errors):
        print("Partially successful: \(processed) processed, \(skipped) skipped")
        print("Errors: \(errors)")
        
    case .failure(let errors):
        print("Processing failed with errors: \(errors)")
    }
}
*/
