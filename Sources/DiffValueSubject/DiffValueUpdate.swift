import Foundation

public struct DiffValueUpdate<Value: Sendable, Diff: Sendable>: Sendable {
    public let value: Value
    public let updateType: UpdateType

    public enum UpdateType: Sendable {
        case subscription
        case change(Diff)
    }

    public init(value: Value, updateType: UpdateType) {
        self.value = value
        self.updateType = updateType
    }
}
