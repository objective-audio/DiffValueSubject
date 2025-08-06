# DiffValueSubject

SwiftのCombineフレームワークを使用して、値の変更を差分として通知するSubjectライブラリです。

## 概要

`DiffValueSubject`は、値の変更を差分（Diff）として通知するSubjectです。値の変更を効率的に検知し、UIの更新を最適化できます。また、配列操作に特化した`DiffArraySubject`も提供しており、配列の追加、削除、移動、更新を個別に検知してUITableViewやSwiftUIのListの更新を効率的に行うことができます。

## 特徴

- **差分通知**: 値の変更を差分として通知し、効率的なUI更新を実現
- **汎用性**: 任意の型の値変更を差分として通知
- **配列特化機能**: 配列操作に特化した`DiffArraySubject`でUITableView/SwiftUIの最適化
- **型安全**: ジェネリクスを使用して型安全性を確保
- **Combine互換**: 標準のCombineフレームワークと完全に互換
- **スレッドセーフ**: 内部でロックを使用してスレッドセーフな実装

## インストール

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/DiffValueSubject.git", from: "1.0.0")
]
```

## 使用方法

### 基本的な使用例（DiffValueSubject）

```swift
import Combine
import DiffValueSubject

// 任意の型のDiffValueSubjectを作成
let diffSubject = DiffValueSubject<String>("初期値")

// 購読を開始
let cancellable = diffSubject
    .sink { update in
        switch update.updateType {
        case .subscription:
            print("初期値: \(update.value)")
        case .change(let diff):
            print("変更: \(diff.oldValue) -> \(diff.newValue)")
        }
    }

// 値を更新
diffSubject.send("新しい値")
diffSubject.send("別の値")
```

### 配列操作の使用例（DiffArraySubject）

```swift
import Combine
import DiffValueSubject

// 配列のDiffArraySubjectを作成
let diffArraySubject = DiffArraySubject<String>([])

// 購読を開始
let cancellable = diffArraySubject
    .sink { update in
        switch update.updateType {
        case .subscription:
            print("初期値: \(update.value)")
        case .change(let diff):
            switch diff {
            case .insert(let index, let element):
                print("追加: \(element) at index \(index)")
            case .remove(let index, let element):
                print("削除: \(element) from index \(index)")
            case .move(let from, let to, let element):
                print("移動: \(element) from \(from) to \(to)")
            case .update(let index, let oldElement, let newElement):
                print("更新: \(oldElement) -> \(newElement) at index \(index)")
            }
        }
    }

// 配列操作
diffArraySubject.insert("Item 1", at: 0)
diffArraySubject.insert("Item 2", at: 1)
diffArraySubject.remove(at: 0)
diffArraySubject.move(from: 0, to: 1)
diffArraySubject.updateElement(at: 0, with: "Updated Item")
```

### UITableViewとの組み合わせ

```swift
class MyTableViewController: UIViewController {
    private var items: [String] = []
    private var cancellables = Set<AnyCancellable>()
    private let diffArraySubject = DiffArraySubject<String>([])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubscription()
    }
    
    private func setupSubscription() {
        diffArraySubject
            .sink { [weak self] update in
                self?.handleUpdate(update)
            }
            .store(in: &cancellables)
    }
    
    private func handleUpdate(_ update: DiffValueUpdate<[String], ArrayDiff<String>>) {
        switch update.updateType {
        case .subscription:
            items = update.value
            tableView.reloadData()
        case .change(let diff):
            items = update.value
            tableView.performBatchUpdates {
                switch diff {
                case .insert(let index, _):
                    tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                case .remove(let index, _):
                    tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                case .move(let from, let to, _):
                    tableView.moveRow(at: IndexPath(row: from, section: 0), to: IndexPath(row: to, section: 0))
                case .update(let index, _, _):
                    tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                }
            }
        }
    }
}
```

### SwiftUIとの組み合わせ

```swift
struct MyView: View {
    @StateObject private var viewModel = DiffArrayViewModel()
    
    var body: some View {
        List {
            ForEach(Array(viewModel.items.enumerated()), id: \.offset) { index, item in
                Text(item)
            }
        }
    }
}

@MainActor
class DiffArrayViewModel: ObservableObject {
    @Published var items: [String] = []
    private var cancellables = Set<AnyCancellable>()
    private let diffArraySubject = DiffArraySubject<String>([])
    
    init() {
        setupSubscription()
    }
    
    private func setupSubscription() {
        diffArraySubject
            .sink { [weak self] update in
                self?.items = update.value
            }
            .store(in: &cancellables)
    }
}
```

## API リファレンス

### DiffValueSubject<T>

#### 初期化

```swift
init(_ initialValue: T)
```

- `initialValue`: 初期値

#### メソッド

```swift
func send(_ value: T)
```
新しい値を送信し、変更を通知します。

```swift
var currentValue: T
```
現在の値を取得します。

### DiffArraySubject<T>

#### 初期化

```swift
init(_ initialValue: [T])
```

- `initialValue`: 初期の配列

#### 配列操作メソッド

```swift
func insert(_ element: T, at index: Int)
```
指定したインデックスに要素を挿入します。

```swift
func remove(at index: Int)
```
指定したインデックスの要素を削除します。

```swift
func move(from: Int, to: Int)
```
要素を移動します。

```swift
func updateElement(at index: Int, with element: T)
```
指定したインデックスの要素を更新します。

### ArrayDiff<T>

配列の変更を表す列挙型です。

```swift
enum ArrayDiff<T> {
    case insert(index: Int, element: T)
    case remove(index: Int, element: T)
    case move(from: Int, to: Int, element: T)
    case update(index: Int, oldElement: T, newElement: T)
}
```

## サンプルアプリケーション

プロジェクトには、DiffValueSubjectの使用方法を示すサンプルアプリケーションが含まれています：

### DiffValueSubjectExamples

`Examples/DiffValueSubjectExamples/` ディレクトリに、SwiftUIとUIKitの両方を使用したサンプルアプリケーションがあります。

- **SwiftUIデモ**: DiffArraySubjectを使用したリスト操作のデモ
- **UIKitデモ**: UITableViewとの組み合わせによる差分更新のデモ

### DiffValueSubjectExample.swiftpm

`Examples/DiffValueSubjectExample.swiftpm/` ディレクトリに、iOSアプリケーションとして実行可能なサンプルがあります。

## テスト

プロジェクトには包括的なテストスイートが含まれています：

```bash
swift test
```

## ライセンス

MIT License 