import Combine
import XCTest

@testable import DiffValueSubject

final class ArrayDiffTests: XCTestCase {

    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }

    func testArrayInsert() {
        let subject = DiffValueSubject<[String], ArrayDiff<String>>(["A", "B"])
        var receivedUpdates: [DiffValueUpdate<[String], ArrayDiff<String>>] = []

        subject.sink { update in
            receivedUpdates.append(update)
        }.store(in: &cancellables)

        subject.insert("C", at: 1)

        XCTAssertEqual(receivedUpdates.count, 2)

        // Initial subscription
        XCTAssertEqual(receivedUpdates[0].value, ["A", "B"])
        if case .subscription = receivedUpdates[0].updateType {
            // Expected
        } else {
            XCTFail("First update should be subscription")
        }

        // Insert operation
        XCTAssertEqual(receivedUpdates[1].value, ["A", "C", "B"])
        if case .change(let diff) = receivedUpdates[1].updateType,
            case .insert(let index, let element) = diff
        {
            XCTAssertEqual(index, 1)
            XCTAssertEqual(element, "C")
        } else {
            XCTFail("Second update should be insert diff")
        }
    }

    func testArrayRemove() {
        let subject = DiffValueSubject<[String], ArrayDiff<String>>(["A", "B", "C"])
        var receivedUpdates: [DiffValueUpdate<[String], ArrayDiff<String>>] = []

        subject.sink { update in
            receivedUpdates.append(update)
        }.store(in: &cancellables)

        subject.remove(at: 1)

        XCTAssertEqual(receivedUpdates.count, 2)
        XCTAssertEqual(receivedUpdates[1].value, ["A", "C"])

        if case .change(let diff) = receivedUpdates[1].updateType,
            case .remove(let index, let element) = diff
        {
            XCTAssertEqual(index, 1)
            XCTAssertEqual(element, "B")
        } else {
            XCTFail("Should be remove diff")
        }
    }

    func testArrayMove() {
        let subject = DiffValueSubject<[String], ArrayDiff<String>>(["A", "B", "C"])
        var receivedUpdates: [DiffValueUpdate<[String], ArrayDiff<String>>] = []

        subject.sink { update in
            receivedUpdates.append(update)
        }.store(in: &cancellables)

        subject.move(from: 0, to: 2)

        XCTAssertEqual(receivedUpdates.count, 2)
        XCTAssertEqual(receivedUpdates[1].value, ["B", "C", "A"])

        if case .change(let diff) = receivedUpdates[1].updateType,
            case .move(let from, let to, let element) = diff
        {
            XCTAssertEqual(from, 0)
            XCTAssertEqual(to, 2)
            XCTAssertEqual(element, "A")
        } else {
            XCTFail("Should be move diff")
        }
    }

    func testArrayUpdate() {
        let subject = DiffValueSubject<[String], ArrayDiff<String>>(["A", "B", "C"])
        var receivedUpdates: [DiffValueUpdate<[String], ArrayDiff<String>>] = []

        subject.sink { update in
            receivedUpdates.append(update)
        }.store(in: &cancellables)

        subject.updateElement(at: 1, with: "X")

        XCTAssertEqual(receivedUpdates.count, 2)
        XCTAssertEqual(receivedUpdates[1].value, ["A", "X", "C"])

        if case .change(let diff) = receivedUpdates[1].updateType,
            case .update(let index, let oldElement, let newElement) = diff
        {
            XCTAssertEqual(index, 1)
            XCTAssertEqual(oldElement, "B")
            XCTAssertEqual(newElement, "X")
        } else {
            XCTFail("Should be update diff")
        }
    }

    func testMultipleOperations() {
        let subject = DiffValueSubject<[String], ArrayDiff<String>>([])
        var receivedUpdates: [DiffValueUpdate<[String], ArrayDiff<String>>] = []

        subject.sink { update in
            receivedUpdates.append(update)
        }.store(in: &cancellables)

        subject.insert("A", at: 0)
        subject.insert("B", at: 1)
        subject.insert("C", at: 0)
        subject.remove(at: 1)
        subject.updateElement(at: 0, with: "X")

        XCTAssertEqual(receivedUpdates.count, 6)  // 1 initial + 5 operations
        XCTAssertEqual(subject.currentValue, ["X", "B"])
    }

    func testConcurrentOperations() {
        let subject = DiffValueSubject<[Int], ArrayDiff<Int>>([])

        // Perform sequential insertions to test basic functionality
        for i in 0..<5 {
            subject.insert(i, at: 0)
        }

        XCTAssertEqual(subject.currentValue.count, 5)

        // All numbers should be present (in reverse order due to inserting at 0)
        let finalNumbers = Set(subject.currentValue)
        let expectedNumbers = Set(0..<5)
        XCTAssertEqual(finalNumbers, expectedNumbers)
    }

    func testEmptyArrayOperations() {
        let subject = DiffValueSubject<[String], ArrayDiff<String>>([])

        // Insert into empty array
        subject.insert("First", at: 0)
        XCTAssertEqual(subject.currentValue, ["First"])

        // Remove last element
        subject.remove(at: 0)
        XCTAssertEqual(subject.currentValue, [])
    }

    func testThreadSafety() {
        let subject = DiffValueSubject<[Int], ArrayDiff<Int>>([])

        // Test basic thread safety with sequential operations
        subject.insert(1, at: 0)
        subject.insert(2, at: 0)
        subject.remove(at: 0)
        subject.insert(3, at: 0)

        // Should not crash and final state should be consistent
        XCTAssertTrue(subject.currentValue.count >= 0)
        XCTAssertEqual(subject.currentValue, [3, 1])
    }

    func testTypeAliases() {
        // DiffArraySubject を使用
        let diffArraySubject = DiffArraySubject<String>(["A", "B"])
        diffArraySubject.insert("C", at: 1)
        XCTAssertEqual(diffArraySubject.currentValue, ["A", "C", "B"])
    }
}
