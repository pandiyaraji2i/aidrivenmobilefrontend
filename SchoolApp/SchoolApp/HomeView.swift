import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            HomeTab()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            EventsTab()
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }

            SettingsTab()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }

            ProfileTab()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("School App")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HomeTab: View {
    @State private var circulars: [NetworkManager.Circular] = []
    @State private var events: [NetworkManager.Event] = []
    @State private var isLoading = true
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("What's Happening at School")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if showingAlert {
                        Text(alertMessage)
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        ForEach(circulars) { circular in
                            CircularCard(circular: circular)
                        }

                        Text("Upcoming Events")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                            .padding(.top, 10)

                        ForEach(events.prefix(3)) { event in // Show top 3 events as highlights
                            EventCard(event: event)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Home")
            .onAppear(perform: fetchData)
        }
    }

    private func fetchData() {
        guard let token = UserDefaultsManager.shared.getJWTToken() else {
            alertMessage = "Authentication token not found. Please log in again."
            showingAlert = true
            isLoading = false
            return
        }

        let dispatchGroup = DispatchGroup()

        isLoading = true

        dispatchGroup.enter()
        NetworkManager.shared.fetchCirculars(token: token) { result in
            defer { dispatchGroup.leave() }
            DispatchQueue.main.async {
                switch result {
                case .success(let circulars):
                    self.circulars = circulars
                case .failure(let error):
                    alertMessage = "Failed to fetch circulars: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }

        dispatchGroup.enter()
        NetworkManager.shared.fetchEvents(token: token) { result in
            defer { dispatchGroup.leave() }
            DispatchQueue.main.async {
                switch result {
                case .success(let events):
                    self.events = events
                case .failure(let error):
                    alertMessage = "Failed to fetch events: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            isLoading = false
        }
    }
}

struct CircularCard: View {
    let circular: NetworkManager.Circular

    var body: some View {
        VStack(alignment: .leading) {
            Text(circular.title)
                .font(.headline)
            Text(circular.issuedDate)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(circular.content)
                .font(.body)
                .lineLimit(2)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}

struct EventCard: View {
    let event: NetworkManager.Event

    var body: some View {
        VStack(alignment: .leading) {
            if let imageUrl = event.imageUrl {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 150)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray5))
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 150)
                            .clipped()
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray5))
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            Text(event.title)
                .font(.headline)
                .padding(.top, 5)

            Text(event.date)
                .font(.subheadline)
                .foregroundColor(.gray)

            Text(event.description)
                .font(.body)
                .lineLimit(2)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}

struct EventsTab: View {
    @State private var events: [NetworkManager.Event] = []
    @State private var isLoading = true
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if showingAlert {
                    Text(alertMessage)
                        .foregroundColor(.red)
                        .padding()
                } else if events.isEmpty {
                    ContentUnavailableView {
                        Label("No Events", systemImage: "calendar.badge.minus")
                    } description: {
                        Text("There are no upcoming events at the moment.")
                    }
                } else {
                    List(events) { event in
                        EventCard(event: event)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Events")
            .onAppear(perform: fetchEvents)
        }
    }

    private func fetchEvents() {
        guard let token = UserDefaultsManager.shared.getJWTToken() else {
            alertMessage = "Authentication token not found. Please log in again."
            showingAlert = true
            isLoading = false
            return
        }

        isLoading = true
        NetworkManager.shared.fetchEvents(token: token) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let events):
                    self.events = events
                case .failure(let error):
                    alertMessage = "Failed to fetch events: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

struct SettingsTab: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account")) {
                    // Student Switcher - Placeholder for now
                    Button(action: {
                        // Action to switch student (if multiple students exist)
                        print("Student Switcher tapped")
                    }) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.blue)
                            Text("Switch Student")
                        }
                    }
                    .disabled(true) // Disable until actual logic is implemented

                    Button(action: {
                        appState.logout()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square.fill")
                                .foregroundColor(.red)
                            Text("Logout")
                                .foregroundColor(.red)
                        }
                    }
                }

                Section(header: Text("About")) {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0.0") // Static app version
                    }
                    Link("Privacy Policy", destination: URL(string: "https://www.example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://www.example.com/terms")!)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
        }
    }
}

struct ProfileTab: View {
    @State private var student: NetworkManager.StudentInfo?
    @State private var mobileNumber: String?

    var body: some View {
        NavigationView {
            Group {
                if let student = student {
                    Form {
                        Section(header: Text("Student Information")) {
                            HStack {
                                Text("Name")
                                Spacer()
                                Text(student.name)
                            }
                            HStack {
                                Text("Class & Section")
                                Spacer()
                                Text("\(student.className) - \(student.section)")
                            }
                            HStack {
                                Text("Date of Birth")
                                Spacer()
                                Text(student.dateOfBirth)
                            }
                        }

                        if let mobile = mobileNumber {
                            Section(header: Text("Parent Information")) {
                                HStack {
                                    Text("Mobile Number")
                                    Spacer()
                                    Text(mobile)
                                }
                            }
                        }

                        Section {
                            Button("Edit Profile (Stub)") {
                                print("Edit Profile tapped")
                            }
                            Button("View Past Interactions (Stub)") {
                                print("View Past Interactions tapped")
                            }
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label("No Student Selected", systemImage: "person.crop.circle.badge.questionmark")
                    } description: {
                        Text("Please select a student from the settings or log in.")
                    }
                }
            }
            .navigationTitle("Profile")
            .onAppear(perform: loadProfileData)
        }
    }

    private func loadProfileData() {
        self.student = UserDefaultsManager.shared.getSelectedStudentInfo()
        self.mobileNumber = UserDefaultsManager.shared.getMobileNumber()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppState())
    }
} 