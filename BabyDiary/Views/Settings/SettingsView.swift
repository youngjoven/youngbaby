import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.modelContext) private var modelContext

    @Query private var profiles: [UserProfile]
    @Query private var feedings: [FeedingRecord]
    @Query private var bowels: [BowelRecord]

    init(userId: String) {
        _profiles = Query(filter: #Predicate<UserProfile> { $0.cognitoUserId == userId })
        _feedings = Query(filter: #Predicate<FeedingRecord> { $0.userId == userId })
        _bowels   = Query(filter: #Predicate<BowelRecord>   { $0.userId == userId })
    }

    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let pink = Color.appPink

    var body: some View {
        NavigationStack {
            List {
                Section("계정") {
                    Button {
                        clearLocalData()
                        authManager.logout()
                    } label: {
                        Label("로그아웃", systemImage: "arrow.right.square")
                            .foregroundColor(.primary)
                    }

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("계정 삭제", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("설정")
        }
        .confirmationDialog(
            "계정을 삭제하시겠어요?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("계정 삭제", role: .destructive) {
                Task { await deleteAccount() }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("수유·배변 기록과 아이 프로필 등 모든 데이터가 영구적으로 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
        }
        .alert("오류", isPresented: $showError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if isDeleting {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(pink)
                        Text("계정 삭제 중...")
                            .font(.subheadline)
                    }
                    .padding(24)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    private func clearLocalData() {
        for profile in profiles { modelContext.delete(profile) }
        for feeding in feedings { modelContext.delete(feeding) }
        for bowel in bowels { modelContext.delete(bowel) }
    }

    private func deleteAccount() async {
        isDeleting = true
        do {
            try await APIService.shared.deleteUserAccount()
            try await CognitoService.deleteUser(accessToken: authManager.accessToken)
            clearLocalData()
            authManager.logout()
        } catch {
            isDeleting = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
