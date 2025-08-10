import Combine
import Testing

@testable import DiffValueSubject

@Suite struct DiffValueSubjectTests {
    
    @Test("Basic functionality test")
    func testDiffValueSubjectBasicFunctionality() throws {
        let subject = DiffValueSubject<Int, Int>(42)

        var receivedValues: [DiffValueUpdate<Int, Int>] = []
        let cancellable = subject.sink { update in
            receivedValues.append(update)
        }

        // 初期値を受信（.subscription）
        #expect(receivedValues.count == 1)
        #expect(receivedValues[0].value == 42)
        if case .subscription = receivedValues[0].updateType {
            // OK
        } else {
            throw TestError("Expected .subscription")
        }

        // 値を更新
        subject.update { value in
            let oldValue = value
            value += 10
            return value - oldValue  // diff = 10
        }

        // 更新値を受信（.change(diff)）
        #expect(receivedValues.count == 2)
        #expect(receivedValues[1].value == 52)
        if case .change(let diff) = receivedValues[1].updateType {
            #expect(diff == 10)
        } else {
            throw TestError("Expected .change(10)")
        }

        cancellable.cancel()
    }

    @Test("Multiple subscribers test")
    func testMultipleSubscribers() throws {
        let subject = DiffValueSubject<String, String>("初期値")

        var subscriber1Values: [DiffValueUpdate<String, String>] = []
        var subscriber2Values: [DiffValueUpdate<String, String>] = []

        let cancellable1 = subject.sink { update in
            subscriber1Values.append(update)
        }

        // 最初のサブスクライバーが初期値を受信
        #expect(subscriber1Values.count == 1)
        #expect(subscriber1Values[0].value == "初期値")

        // 値を更新
        subject.update { value in
            value = "更新値"
            return "diff1"
        }

        // 最初のサブスクライバーが更新を受信
        #expect(subscriber1Values.count == 2)
        #expect(subscriber1Values[1].value == "更新値")

        // 2番目のサブスクライバーを追加
        let cancellable2 = subject.sink { update in
            subscriber2Values.append(update)
        }

        // 2番目のサブスクライバーが現在の値を受信（.subscription）
        #expect(subscriber2Values.count == 1)
        #expect(subscriber2Values[0].value == "更新値")
        if case .subscription = subscriber2Values[0].updateType {
            // OK
        } else {
            throw TestError("Expected .subscription")
        }

        // さらに更新
        subject.update { value in
            value = "最終値"
            return "diff2"
        }

        // 両方のサブスクライバーが更新を受信
        #expect(subscriber1Values.count == 3)
        #expect(subscriber1Values[2].value == "最終値")

        #expect(subscriber2Values.count == 2)
        #expect(subscriber2Values[1].value == "最終値")

        cancellable1.cancel()
        cancellable2.cancel()
    }

    @Test("Concurrent and recursive updates test")
    func testConcurrentAndRecursiveUpdates() throws {
        let subject = DiffValueSubject<Int, String>(0)
        var receivedValues: [DiffValueUpdate<Int, String>] = []
        var recursiveCallCount = 0

        let cancellable = subject.sink { update in
            receivedValues.append(update)

            // 再帰的にupdateを呼び出してみる（少数回のみ）
            if case .change = update.updateType, recursiveCallCount < 2 {
                recursiveCallCount += 1
                subject.update { value in
                    value += 100
                    return "recursive-\(recursiveCallCount)"
                }
            }
        }

        // 最初のupdate呼び出し
        subject.update { value in
            value = 42
            return "initial"
        }

        // OSAllocatedUnfairLock + lock()により、すべての更新が順次実行される
        #expect(receivedValues.count >= 2, "少なくとも初期値 + 最初の更新")

        // 最初の値は初期値（購読時の.subscription）
        #expect(receivedValues[0].value == 0)
        if case .subscription = receivedValues[0].updateType {
            // OK
        } else {
            throw TestError("First should be .subscription type")
        }

        // 2番目の値は更新値（.change）
        #expect(receivedValues[1].value == 42)
        if case .change(let diff) = receivedValues[1].updateType {
            #expect(diff == "initial")
        } else {
            throw TestError("Second should be .change type")
        }

        // 現在値が更新されていることを確認（再帰更新により値が変化）
        #expect(subject.currentValue >= 42)

        cancellable.cancel()
    }

    @Test("Concurrent updates test")
    func testConcurrentUpdates() async throws {
        let subject = DiffValueSubject<Int, String>(0)
        var receivedValues: [DiffValueUpdate<Int, String>] = []

        let cancellable = subject.sink { update in
            receivedValues.append(update)
        }

        // 複数のスレッドから同時にupdateを実行
        // lock()により全ての更新が順次実行される
        await withTaskGroup(of: Void.self) { group in
            for iteration in 0..<10 {
                group.addTask {
                    subject.update { value in
                        value += 1
                        return "update-\(iteration)"
                    }
                }
            }
        }

        // 少し待ってから結果を確認
        try await Task.sleep(for: .milliseconds(100))

        // 検証: 初期値 + 10回の更新 = 11個の値
        // lock()により全ての更新が確実に実行される
        #expect(receivedValues.count == 11, "初期値 + 10回の並行更新")

        // 最初の値は初期値であることを確認
        #expect(receivedValues[0].value == 0)
        if case .subscription = receivedValues[0].updateType {
            // OK
        } else {
            throw TestError("First should be .subscription type")
        }

        // 最終値が10であることを確認（全ての更新が適用された）
        #expect(subject.currentValue == 10)

        // 10回の変更が記録されていることを確認
        let changeUpdates = receivedValues.filter {
            if case .change = $0.updateType { return true }
            return false
        }
        #expect(changeUpdates.count == 10, "10回の変更が記録されている")

        cancellable.cancel()
    }

    @Test("Current value access during update test")
    func testCurrentValueAccessDuringUpdate() throws {
        let subject = DiffValueSubject<Int, String>(0)
        var receivedValues: [DiffValueUpdate<Int, String>] = []
        var currentValueDuringUpdate: Int?

        let cancellable = subject.sink { update in
            receivedValues.append(update)

            // subscriberからcurrentValueにアクセス（デッドロックテスト）
            if case .change = update.updateType {
                currentValueDuringUpdate = subject.currentValue
            }
        }

        // updateを実行
        subject.update { value in
            value = 42
            return "test"
        }

        // 検証
        #expect(receivedValues.count == 2, "初期値 + 更新値")
        #expect(currentValueDuringUpdate == 42, "subscriberからcurrentValueに安全にアクセス可能")
        #expect(subject.currentValue == 42, "最終的な現在値")

        cancellable.cancel()
    }
}


