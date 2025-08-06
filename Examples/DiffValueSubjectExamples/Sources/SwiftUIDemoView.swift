import Combine
import DiffValueSubject
import SwiftUI

struct SwiftUIDemoView: View {
    @StateObject private var viewModel = DiffArrayViewModel()

    var body: some View {
        VStack {
            // 操作ボタン
            HStack {
                Button("Add Item") {
                    viewModel.addItem()
                }
                .buttonStyle(.borderedProminent)

                Button("Remove Last") {
                    viewModel.removeLastItem()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.items.isEmpty)

                Button("Clear All") {
                    viewModel.clearAll()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.items.isEmpty)
            }
            .padding()

            // 変更履歴
            if !viewModel.changeHistory.isEmpty {
                VStack(alignment: .leading) {
                    Text("Change History:")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(viewModel.changeHistory.indices, id: \.self) { index in
                                let change = viewModel.changeHistory[index]
                                Text(change)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .frame(maxHeight: 100)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }

            // アイテムリスト
            List {
                ForEach(Array(viewModel.items.enumerated()), id: \.offset) { index, item in
                    HStack {
                        Text("\(index + 1). \(item)")
                            .font(.body)

                        Spacer()

                        Button("Remove") {
                            viewModel.removeItem(at: index)
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                    .padding(.vertical, 2)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}

@MainActor
class DiffArrayViewModel: ObservableObject {
    @Published var items: [String] = []
    @Published var changeHistory: [String] = []

    private var cancellables = Set<AnyCancellable>()
    private let diffArraySubject = DiffArraySubject<String>([])

    init() {
        setupSubscription()
    }

    private func setupSubscription() {
        diffArraySubject
            .sink { [weak self] update in
                self?.items = update.value

                switch update.updateType {
                case .subscription:
                    self?.changeHistory.append(
                        "📱 Initial subscription: \(update.value.count) items")
                case .change(let diff):
                    self?.handleDiff(diff)
                }
            }
            .store(in: &cancellables)
    }

    private func handleDiff(_ diff: ArrayDiff<String>) {
        switch diff {
        case .insert(let index, let element):
            changeHistory.append("➕ Inserted '\(element)' at index \(index)")
        case .remove(let index, let element):
            changeHistory.append("➖ Removed '\(element)' from index \(index)")
        case .move(let from, let to, let element):
            changeHistory.append("🔄 Moved '\(element)' from index \(from) to \(to)")
        case .update(let index, let oldElement, let newElement):
            changeHistory.append("✏️ Updated '\(oldElement)' to '\(newElement)' at index \(index)")
        }

        // 履歴を最新の10件に制限
        if changeHistory.count > 10 {
            changeHistory.removeFirst()
        }
    }

    func addItem() {
        let newItem = "Item \(items.count + 1)"
        diffArraySubject.insert(newItem, at: items.count)
    }

    func removeLastItem() {
        guard !items.isEmpty else { return }
        diffArraySubject.remove(at: items.count - 1)
    }

    func removeItem(at index: Int) {
        guard index >= 0 && index < items.count else { return }
        diffArraySubject.remove(at: index)
    }

    func clearAll() {
        while !items.isEmpty {
            diffArraySubject.remove(at: 0)
        }
    }
}
