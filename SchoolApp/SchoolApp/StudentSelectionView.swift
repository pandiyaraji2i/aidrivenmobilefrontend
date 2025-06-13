import SwiftUI

struct StudentSelectionView: View {
    let students: [NetworkManager.StudentInfo]
    var onStudentSelected: (() -> Void)
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(students) { student in
                    Button(action: {
                        UserDefaultsManager.shared.saveSelectedStudentId(student.id)
                        UserDefaultsManager.shared.saveStudentInfo(student)
                        onStudentSelected()
                        dismiss()
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(student.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Text("Class \(student.className)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Text("•")
                                        .foregroundColor(.gray)
                                    
                                    Text("Section \(student.section)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Text("DOB: \(student.dateOfBirth)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Select Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StudentSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        StudentSelectionView(students: [
            NetworkManager.StudentInfo(id: "s001", name: "Aarav Kumar", className: "3", section: "B", dateOfBirth: "2015-08-20"),
            NetworkManager.StudentInfo(id: "s002", name: "Anaya Kumar", className: "1", section: "A", dateOfBirth: "2017-02-15")
        ], onStudentSelected: {})
    }
} 
