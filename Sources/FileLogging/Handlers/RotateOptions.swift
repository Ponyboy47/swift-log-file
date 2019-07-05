public struct RotateOptions: SetAlgebra, Hashable, Comparable {
    public struct DateRotateOption: RawRepresentable, ExpressibleByIntegerLiteral {
        public let rawValue: UInt64

        public static let hourly = DateRotateOption(rawValue: 1)
        public static let daily = DateRotateOption(rawValue: 24)
        public static let weekly = DateRotateOption(rawValue: 24 * 7)
        public static let monthly = DateRotateOption(rawValue: 24 * 30)
        public static let yearly = DateRotateOption(rawValue: 24 * 365)

        public static func hours(_ hrs: UInt64) -> DateRotateOption {
            return DateRotateOption(rawValue: hrs)
        }

        public init(rawValue: UInt64) {
            self.rawValue = rawValue
        }

        public init(integerLiteral value: UInt64) {
            self.init(rawValue: value)
        }
    }

    public enum MaxRotateOption {
        case overall
        case perDatePeriod
    }

    public typealias Element = RotateOptions

    public let value: UInt64
    public let type: RotateOptionType

    private(set) var storage = Set<RotateOptions>()

    public enum RotateOptionType: UInt, Hashable {
        case none = 0
        case date = 1
        case size = 2
        case maxOverall = 4
        case maxPerDatePeriod = 8
    }

    public static func date(_ when: DateRotateOption) -> RotateOptions {
        return .init(.date, when.rawValue)
    }

    public static func size(_ bytes: UInt64) -> RotateOptions {
        return .init(.size, bytes)
    }

    public static func max(_ count: UInt64, _ predicate: MaxRotateOption) -> RotateOptions {
        switch predicate {
        case .overall: return .init(.maxOverall, count)
        case .perDatePeriod: return .init(.maxPerDatePeriod, count)
        }
    }

    private init(_ type: RotateOptionType, _ value: UInt64) {
        self.type = type
        self.value = value

        storage.insert(self)
    }

    public init(rawValue: UInt64) {
        self.init(.none, rawValue)
    }

    public init() {
        self.init(.none, 0)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(value)
    }

    public func contains(_ element: Element) -> Bool {
        return storage.contains(element)
    }

    public mutating func insert(_ element: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        return storage.insert(element)
    }

    public mutating func remove(_ element: Element) -> Element? {
        return storage.remove(element)
    }

    public mutating func update(with newMember: Element) -> Element? {
        return storage.update(with: newMember)
    }

    public func union(_ other: RotateOptions) -> RotateOptions {
        var unioned = RotateOptions()
        unioned.storage = storage.union(other.storage)
        return unioned
    }

    public mutating func formUnion(_ other: RotateOptions) {
        storage.formUnion(other.storage)
    }

    public func intersection(_ other: RotateOptions) -> RotateOptions {
        var intersecting = RotateOptions()
        intersecting.storage = storage.intersection(other.storage)
        return intersecting
    }

    public mutating func formIntersection(_ other: RotateOptions) {
        storage.formIntersection(other.storage)
    }

    public func symmetricDifference(_ other: RotateOptions) -> RotateOptions {
        var symDif = RotateOptions()
        symDif.storage = storage.symmetricDifference(other.storage)
        return symDif
    }

    public mutating func formSymmetricDifference(_ other: RotateOptions) {
        storage.formSymmetricDifference(other.storage)
    }

    public static func < (lhs: RotateOptions, rhs: RotateOptions) -> Bool {
        return lhs.type.rawValue < rhs.type.rawValue
    }
}
