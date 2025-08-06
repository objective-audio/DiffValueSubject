import SwiftUI
import UIKit
import Combine
import DiffValueSubject

struct UIKitDemoView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> TableViewController {
        return TableViewController()
    }

    func updateUIViewController(_ uiViewController: TableViewController, context: Context) {
        // No updates needed
    }
}

class TableViewController: UIViewController {

    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        table.dataSource = self
        table.delegate = self
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    private lazy var buttonStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add Item", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(addItem), for: .touchUpInside)
        return button
    }()

    private lazy var removeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Remove Last", for: .normal)
        button.backgroundColor = .systemOrange
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(removeLastItem), for: .touchUpInside)
        return button
    }()

    private lazy var clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Clear All", for: .normal)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(clearAll), for: .touchUpInside)
        return button
    }()

    private lazy var historyLabel: UILabel = {
        let label = UILabel()
        label.text = "Change History:"
        label.font = .boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var historyTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.font = .systemFont(ofSize: 12)
        textView.backgroundColor = UIColor.systemGray6
        textView.layer.cornerRadius = 8
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    // MARK: - Properties
    private var items: [String] = []
    private var changeHistory: [String] = []
    private var cancellables = Set<AnyCancellable>()
    private let diffArraySubject = DiffArraySubject<String>([])

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSubscription()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "UITableView Demo"

        // Add subviews
        view.addSubview(buttonStackView)
        view.addSubview(historyLabel)
        view.addSubview(historyTextView)
        view.addSubview(tableView)

        // Configure button stack
        buttonStackView.addArrangedSubview(addButton)
        buttonStackView.addArrangedSubview(removeButton)
        buttonStackView.addArrangedSubview(clearButton)

        // Setup constraints
        NSLayoutConstraint.activate([
            // Button stack
            buttonStackView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            buttonStackView.heightAnchor.constraint(equalToConstant: 44),

            // History label
            historyLabel.topAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: 16),
            historyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            historyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // History text view
            historyTextView.topAnchor.constraint(equalTo: historyLabel.bottomAnchor, constant: 8),
            historyTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            historyTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            historyTextView.heightAnchor.constraint(equalToConstant: 100),

            // Table view
            tableView.topAnchor.constraint(equalTo: historyTextView.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func setupSubscription() {
        diffArraySubject
            .sink { [weak self] update in
                self?.handleUpdate(update)
            }
            .store(in: &cancellables)
    }

    // MARK: - Update Handling
    private func handleUpdate(_ update: DiffValueUpdate<[String], ArrayDiff<String>>) {
        switch update.updateType {
        case .subscription:
            items = update.value
            tableView.reloadData()
            addToHistory("📱 Initial subscription: \(update.value.count) items")

        case .change(let diff):
            items = update.value
            handleDiff(diff)
        }
    }

    private func handleDiff(_ diff: ArrayDiff<String>) {
        tableView.performBatchUpdates {
            switch diff {
            case .insert(let index, let element):
                tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                addToHistory("➕ Inserted '\(element)' at index \(index)")

            case .remove(let index, let element):
                tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                addToHistory("➖ Removed '\(element)' from index \(index)")

            case .move(let from, let to, let element):
                tableView.moveRow(
                    at: IndexPath(row: from, section: 0), to: IndexPath(row: to, section: 0))
                addToHistory("🔄 Moved '\(element)' from index \(from) to \(to)")

            case .update(let index, let oldElement, let newElement):
                tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                addToHistory("✏️ Updated '\(oldElement)' to '\(newElement)' at index \(index)")
            }
        }
    }

    private func addToHistory(_ message: String) {
        changeHistory.append(message)

        // Keep only last 10 items
        if changeHistory.count > 10 {
            changeHistory.removeFirst()
        }

        // Update text view
        historyTextView.text = changeHistory.joined(separator: "\n")

        // Scroll to bottom
        let bottom = NSMakeRange(historyTextView.text.count - 1, 1)
        historyTextView.scrollRangeToVisible(bottom)
    }

    // MARK: - Actions
    @objc private func addItem() {
        let newItem = "Item \(diffArraySubject.currentValue.count + 1)"
        diffArraySubject.insert(newItem, at: diffArraySubject.currentValue.count)
    }

    @objc private func removeLastItem() {
        guard !diffArraySubject.currentValue.isEmpty else { return }
        diffArraySubject.remove(at: diffArraySubject.currentValue.count - 1)
    }

    @objc private func clearAll() {
        while !diffArraySubject.currentValue.isEmpty {
            diffArraySubject.remove(at: 0)
        }
    }
}

// MARK: - UITableViewDataSource
extension TableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "\(indexPath.row + 1). \(items[indexPath.row])"
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

// MARK: - UITableViewDelegate
extension TableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Update the selected item
        let currentItem = items[indexPath.row]
        let updatedItem = "\(currentItem) ✓"
        diffArraySubject.updateElement(at: indexPath.row, with: updatedItem)
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(
        _ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath,
        to destinationIndexPath: IndexPath
    ) {
        diffArraySubject.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
    }

    func tableView(
        _ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if editingStyle == .delete {
            diffArraySubject.remove(at: indexPath.row)
        }
    }
}
