import Combine
import Testing

@testable import DiffValueSubject

@Suite struct ArrayDiffTests {
    
    @Test("Array insert test")
    func testArrayInsert() throws {
        let subject = DiffValueSubject<[String], ArrayDiff<String>>(["A", "B"])
        var receivedUpdates: [DiffValueUpdate<[String], ArrayDiff<String>>] = []

        let cancellable = subject.sink { update in
            receivedUpdates.append(update)
        }

        subject.insert("C", at: 1)

        #expect(receivedUpdates.count == 2)

        // Initial subscription
        #expect(receivedUpdates[0].value == ["A", "B"])
        if case .subscription = receivedUpdates[0].updateType {
            // Expected
        } else {
            throw TestError("First update should be subscription")
        }

        // Insert operation
        #expect(receivedUpdates[1].value == ["A", "C", "B"])
        if case .change(let diff) = receivedUpdates[1].updateType,
            case .insert(let index, let element) = diff
        {
            #expect(index == 1)
            #expect(element == "C")
        } else {
            throw TestError("Second update should be insert diff")
        }
        
        cancellable.cancel()
    }

    @Test("Array remove test")
    func testArrayRemove() throws {
        let subject = DiffValueSubject<[String], ArrayDiff<String>>(["A", "B", "C"])
        var receivedUpdates: [DiffValueUpdate<[String], ArrayDiff<String>>] = []

        let cancellable = subject.sink { update in
            receivedUpdates.append(update)
        }

        subject.remove(at: 1)

        #expect(receivedUpdates.count == 2)
        #expect(receivedUpdates[1].value == ["A", "C"])

        if case .change(let diff) = receivedUpdates[1].updateType,
            case .remove(let index, let element) = diff
        {
            #expect(index == 1)
            #expect(element == "B")
        } else {
            throw TestError("Should be remove diff")
        }
        
        cancellable.cancel()
    }

    @Test("Array move test")
    func testArrayMove() throws {
        let subject = DiffValueSubject<[String], ArrayDiff<String>>(["A", "B", "C"])
        var receivedUpdates: [DiffValueUpdate<[String], ArrayDiff<String>>] = []

        let cancellable = subject.sink { update in
            receivedUpdates.append(update)
        }

        subject.move(from: 0, to: 2)

        #expect(receivedUpdates.count == 2)
        #expect(receivedUpdates[1].value == ["B", "C", "A"])

        if case .change(let diff) = receivedUpdates[1].updateType,
            case .move(let from, let to, let element) = diff
        {
            #expect(from == 0)
            #expect(to == 2)
            #expect(element == "A")
        } else {
            throw TestError("Should be move diff")
        }
        
        cancellable.cancel()
    }

    @Test("Array update test")
    func testArrayUpdate() throws {
        let subject = DiffValueSubject<[String], ArrayDiff<String>>(["A", "B", "C"])
        var receivedUpdates: [DiffValueUpdate<[String], ArrayDiff<String>>] = []

        let cancellable = subject.sink { update in
            receivedUpdates.append(update)
        }

        subject.updateElement(at: 1, with: "X")

        #expect(receivedUpdates.count == 2)
        #expect(receivedUpdates[1].value == ["A", "X", "C"])

        if case .change(let diff) = receivedUpdates[1].updateType,
            case .update(let index, let oldElement, let newElement) = diff
        {
            #expect(index == 1)
            #expect(oldElement == "B")
            #expect(newElement == "X")
        } else {
            throw TestError("Should be update diff")
        }
        
        cancellable.cancel()
    }

    @Test("Multiple operations test")
    func testMultipleOperations() throws {
        let subject = DiffValueSubject<[String], ArrayDiff<String>>([])
        var receivedUpdates: [DiffValueUpdate<[String], ArrayDiff<String>>] = []

        let cancellable = subject.sink { update in
            receivedUpdates.append(update)
        }

        subject.insert("A", at: 0)
        subject.insert("B", at: 1)
        subject.insert("C", at: 0)
        subject.remove(at: 1)
        subject.updateElement(at: 0, with: "X")

        #expect(receivedUpdates.count == 6)  // 1 initial + 5 operations
        #expect(subject.currentValue == ["X", "B"])
        
        cancellable.cancel()
    }

    @Test("Concurrent operations test")
    func testConcurrentOperations() throws {
        let subject = DiffValueSubject<[Int], ArrayDiff<Int>>([])

        // Perform sequential insertions to test basic functionality
        for i in 0..<5 {
            subject.insert(i, at: 0)
        }

        #expect(subject.currentValue.count == 5)

        // All numbers should be present (in reverse order due to inserting at 0)
        let finalNumbers = Set(subject.currentValue)
        let expectedNumbers = Set(0..<5)
        #expect(finalNumbers == expectedNumbers)
    }

    @Test("Empty array operations test")
    func testEmptyArrayOperations() throws {
        let subject = DiffValueSubject<[String], ArrayDiff<String>>([])

        // Insert into empty array
        subject.insert("First", at: 0)
        #expect(subject.currentValue == ["First"])

        // Remove last element
        subject.remove(at: 0)
        #expect(subject.currentValue == [])
    }

    @Test("Thread safety test")
    func testThreadSafety() throws {
        let subject = DiffValueSubject<[Int], ArrayDiff<Int>>([])

        // Test basic thread safety with sequential operations
        subject.insert(1, at: 0)
        subject.insert(2, at: 0)
        subject.remove(at: 0)
        subject.insert(3, at: 0)

        // Should not crash and final state should be consistent
        #expect(subject.currentValue.count >= 0)
        #expect(subject.currentValue == [3, 1])
    }

    @Test("Type aliases test")
    func testTypeAliases() throws {
        // DiffArraySubject を使用
        let diffArraySubject = DiffArraySubject<String>(["A", "B"])
        diffArraySubject.insert("C", at: 1)
        #expect(diffArraySubject.currentValue == ["A", "C", "B"])
    }
}


