infix operator !!: NilCoalescingPrecedence

/// Unwrap or die operator
func !! <T>(lhs: T?, rhs: @autoclosure () -> String) -> T {
    if let val = lhs { return val }
    fatalError(rhs())
}
