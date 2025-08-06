import Foundation

public enum ArrayDiff<Element> {
    case insert(index: Int, element: Element)
    case remove(index: Int, element: Element)
    case move(from: Int, to: Int, element: Element)
    case update(index: Int, oldElement: Element, newElement: Element)
}

extension ArrayDiff: Sendable where Element: Sendable {}

extension DiffValueSubject where Value: RangeReplaceableCollection, Value.Index == Int {

    public func insert<Element>(_ element: Element, at index: Int)
    where Value == [Element], Diff == ArrayDiff<Element> {
        update { array in
            array.insert(element, at: index)
            return ArrayDiff.insert(index: index, element: element)
        }
    }

    public func remove<Element>(at index: Int)
    where Value == [Element], Diff == ArrayDiff<Element> {
        update { array in
            let element = array.remove(at: index)
            return ArrayDiff.remove(index: index, element: element)
        }
    }

    public func move<Element>(from sourceIndex: Int, to destinationIndex: Int)
    where Value == [Element], Diff == ArrayDiff<Element> {
        update { array in
            let element = array.remove(at: sourceIndex)
            array.insert(element, at: destinationIndex)
            return ArrayDiff.move(from: sourceIndex, to: destinationIndex, element: element)
        }
    }

    public func updateElement<Element>(at index: Int, with newElement: Element)
    where Value == [Element], Diff == ArrayDiff<Element> {
        update { array in
            let oldElement = array[index]
            array[index] = newElement
            return ArrayDiff.update(index: index, oldElement: oldElement, newElement: newElement)
        }
    }
}

// MARK: - Type Aliases

public typealias DiffArraySubject<Element: Sendable> = DiffValueSubject<
    [Element], ArrayDiff<Element>
>
