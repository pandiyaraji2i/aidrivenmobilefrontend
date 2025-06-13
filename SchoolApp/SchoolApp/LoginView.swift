import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var mobileNumber: String = ""
    @State private var otp: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isOTPRequested = false
    @State private var isMobileEditable = true
    @State private var showStudentSelection = false
    @State private var studentInfo: [NetworkManager.StudentInfo]?

    var isMobileNumberValid: Bool {
        mobileNumber.count == 10 && mobileNumber.allSatisfy({ $0.isNumber })
    }

    var isOTPValid: Bool {
        otp.count == 6 && otp.allSatisfy({ $0.isNumber })
    }

    var body: some View {
        VStack {
            Image(systemName: "book.closed.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
                .padding(.bottom, 20)

            Text("Welcome to School App")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 40)

            HStack {
                TextField("Mobile Number", text: $mobileNumber)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .disabled(!isMobileEditable)
                    .onChange(of: mobileNumber) { oldValue, newValue in
                        mobileNumber = String(newValue.prefix(10))
                    }
                
                if !isMobileEditable {
                    Button(action: {
                        isMobileEditable = true
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                    .padding(.trailing)
                }
            }
            .padding(.horizontal)

            if isOTPRequested {
                Text("Enter the 6-digit OTP sent to \(mobileNumber)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)

                SecureField("Enter OTP", text: $otp)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .onChange(of: otp) { oldValue, newValue in
                        otp = String(newValue.prefix(6))
                    }
            }

            Button(isOTPRequested ? "Verify OTP" : "Send OTP") {
                if isOTPRequested {
                    verifyOTP()
                } else {
                    requestOTP()
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(isOTPRequested ? (isOTPValid ? Color.blue : Color.gray) : (isMobileNumberValid ? Color.blue : Color.gray))
            .cornerRadius(8)
            .padding(.horizontal)
            .disabled(isOTPRequested ? !isOTPValid : !isMobileNumberValid)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showStudentSelection) {
            if let studentInfo = studentInfo {
                StudentSelectionView(students: studentInfo, onStudentSelected: {
                    appState.loginSuccess()
                })
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    private func requestOTP() {
        NetworkManager.shared.requestOTP(mobileNumber: mobileNumber) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success {
                        isOTPRequested = true
                        isMobileEditable = false
                    } else {
                        alertMessage = response.message ?? "Failed to send OTP. Please try again."
                        showingAlert = true
                    }
                case .failure(let error):
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
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
                                    appState.loginSuccess()
                                } else {
                                    showStudentSelection = true
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

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AppState())
    }
} 
