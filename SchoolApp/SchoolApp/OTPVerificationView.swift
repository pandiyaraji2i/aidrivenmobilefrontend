import SwiftUI

struct OTPVerificationView: View {
    @EnvironmentObject var appState: AppState
    @State private var otp: String = ""
    @State private var showStudentSelection = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var studentInfo: [NetworkManager.StudentInfo]?

    let mobileNumber: String

    var isOTPValid: Bool {
        otp.count == 6 && otp.allSatisfy({ $0.isNumber })
    }

    var body: some View {
        VStack {
            Text("Verify OTP")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 20)

            Text("Enter the 6-digit OTP sent to \(mobileNumber)")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.bottom, 40)

            TextField("OTP", text: $otp)
                .keyboardType(.numberPad)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                .onChange(of: otp) { newValue in
                    otp = String(newValue.prefix(6))
                }

            Button("Verify OTP") {
                verifyOTP()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(isOTPValid ? Color.blue : Color.gray)
            .cornerRadius(8)
            .padding(.horizontal)
            .disabled(!isOTPValid)

            // NavigationLink removed as AppState will handle navigation
            // .navigationBarBackButtonHidden(true) is handled by the NavigationView hierarchy
        }
        .sheet(isPresented: $showStudentSelection) {
            if let studentInfo = studentInfo {
                StudentSelectionView(students: studentInfo, onStudentSelected: {
                    appState.loginSuccess() // On student selection, mark as authenticated
                })
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    private func verifyOTP() {
        NetworkManager.shared.verifyOTP(mobileNumber: mobileNumber, otp: otp) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success {
                        if let data = response.data {
                            UserDefaultsManager.shared.saveJWTToken(data.token)
                            UserDefaultsManager.shared.saveMobileNumber(mobileNumber)
                            
                            if !data.students.isEmpty {
                                self.studentInfo = data.students
                                if data.students.count == 1 {
                                    UserDefaultsManager.shared.saveSelectedStudentId(data.students[0].id)
                                    appState.loginSuccess() // Single student, login success
                                } else {
                                    showStudentSelection = true // Multiple students, show selection modal
                                }
                            } else {
                                alertMessage = "No student information found."
                                showingAlert = true
                            }
                        } else {
                            alertMessage = "No data received from server."
                            showingAlert = true
                        }
                    } else {
                        alertMessage = response.message
                        showingAlert = true
                    }
                case .failure(let error):
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

struct OTPVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        OTPVerificationView(mobileNumber: "1234567890")
            .environmentObject(AppState())
    }
} 
