import SwiftUI
import Combine

struct TMEmptyResponse: Decodable {}

struct TMInstructorDashboardResponse: Decodable {
    let courses: [TMCourseItem]
    let workload: [TMWorkloadItem]
}

struct TMCourseItem: Decodable, Identifiable {
    let id: UUID
    let name: String
    let period: String
    let instructor: String
    let students: [TMStudentItem]
}

struct TMStudentItem: Decodable, Identifiable {
    let id: UUID
    let name: String
    let status: String
    let progress: Int
    let completed: Int
    let total: Int
    let details: [TMModuleDetail]
}

struct TMModuleDetail: Decodable, Identifiable {
    let id: UUID
    let title: String
    let done: Bool
}

struct TMWorkloadItem: Decodable, Identifiable {
    let id: UUID
    let instructor: String
    let count: Int
}

@MainActor
final class TrainingManagerDashboardViewModel: ObservableObject {
    @Published var courses: [TMCourseItem] = []
    @Published var workload: [TMWorkloadItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let req = APIRequest(path: "/api/instructor/dashboard", method: .get)
            let response: TMInstructorDashboardResponse = try await APIClient.shared.send(req)
            self.courses = response.courses
            self.workload = response.workload
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func approve(studentId: UUID) async {
        do {
            let req = APIRequest(path: "/api/instructor/approve/\(studentId.uuidString)", method: .patch)
            _ = try await APIClient.shared.send(req) as TMEmptyResponse
            await load()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func reject(studentId: UUID) async {
        do {
            let req = APIRequest(path: "/api/instructor/reject/\(studentId.uuidString)", method: .patch)
            _ = try await APIClient.shared.send(req) as TMEmptyResponse
            await load()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

struct TrainingManagerDashboardView: View {
    @StateObject private var vm = TrainingManagerDashboardViewModel()

    var body: some View {
        List {
            if let error = vm.errorMessage {
                Section { Text(error).foregroundStyle(.red) }
            }

            if !vm.workload.isEmpty {
                Section(header: Text("Workload")) {
                    ForEach(vm.workload) { item in
                        HStack {
                            Text(item.instructor)
                            Spacer()
                            Text("\(item.count)").foregroundStyle(.secondary)
                        }
                    }
                }
            }

            ForEach(vm.courses) { course in
                Section(header: Text("\(course.name) – \(course.period)\nInstruktor: \(course.instructor)")) {
                    ForEach(course.students) { student in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(student.name).font(.headline)
                                Spacer()
                                Text("\(student.completed)/\(student.total)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            HStack {
                                ProgressView(value: Double(student.progress), total: 100)
                                    .frame(width: 140)
                                Text("\(student.progress)%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Menu {
                                    Button("Genehmigen", systemImage: "checkmark.circle") {
                                        Task { await vm.approve(studentId: student.id) }
                                    }
                                    Button("Ablehnen", systemImage: "xmark.circle") {
                                        Task { await vm.reject(studentId: student.id) }
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                            }
                            if !student.details.isEmpty {
                                ForEach(student.details) { module in
                                    HStack {
                                        Image(systemName: module.done ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(module.done ? .green : .secondary)
                                        Text(module.title).font(.subheadline)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Training Manager")
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }
}

#Preview {
    NavigationStack { TrainingManagerDashboardView() }
}
