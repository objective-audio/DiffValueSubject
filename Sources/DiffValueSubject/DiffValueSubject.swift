import Combine
import Foundation
import os

public final class DiffValueSubject<Value: Sendable, Diff: Sendable>: Publisher, @unchecked
    Sendable
{

    public typealias Output = DiffValueUpdate<Value, Diff>
    public typealias Failure = Never

    private let initialValueSubject: CurrentValueSubject<DiffValueUpdate<Value, Diff>, Never>
    private let updateSubject = PassthroughSubject<DiffValueUpdate<Value, Diff>, Never>()
    private let updateLock = OSAllocatedUnfairLock()

    public var currentValue: Value {
        updateLock.lock()
        defer { updateLock.unlock() }
        return initialValueSubject.value.value
    }

    public init(_ initialValue: Value) {
        self.initialValueSubject = CurrentValueSubject(
            DiffValueUpdate<Value, Diff>(value: initialValue, updateType: .subscription)
        )
    }

    public func update(_ updateClosure: @escaping (inout Value) -> Diff) {
        updateLock.lock()
        var currentValue = initialValueSubject.value.value
        let diff = updateClosure(&currentValue)
        let newUpdate = DiffValueUpdate<Value, Diff>(value: currentValue, updateType: .subscription)
        let changeUpdate = DiffValueUpdate<Value, Diff>(
            value: currentValue, updateType: .change(diff))
        initialValueSubject.send(newUpdate)
        updateLock.unlock()
        updateSubject.send(changeUpdate)
    }

    public func receive<S>(subscriber: S)
    where S: Subscriber, Never == S.Failure, DiffValueUpdate<Value, Diff> == S.Input {
        Publishers.Merge(
            initialValueSubject.prefix(1),
            updateSubject
        ).receive(subscriber: subscriber)
    }
}
