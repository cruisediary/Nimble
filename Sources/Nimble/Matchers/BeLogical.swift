import Foundation

internal func matcherWithFailureMessage<T>(_ matcher: NonNilMatcherFunc<T>, postprocessor: @escaping (FailureMessage) -> Void) -> NonNilMatcherFunc<T> {
    return NonNilMatcherFunc { actualExpression, failureMessage in
        defer { postprocessor(failureMessage) }
        return try matcher.matcher(actualExpression, failureMessage)
    }
}

// MARK: beTrue() / beFalse()

/// A Nimble matcher that succeeds when the actual value is exactly true.
/// This matcher will not match against nils.
public func beTrue() -> NonNilMatcherFunc<Bool> {
    return matcherWithFailureMessage(equal(true)) { failureMessage in
        failureMessage.postfixMessage = "be true"
    }
}

/// A Nimble matcher that succeeds when the actual value is exactly false.
/// This matcher will not match against nils.
public func beFalse() -> NonNilMatcherFunc<Bool> {
    return matcherWithFailureMessage(equal(false)) { failureMessage in
        failureMessage.postfixMessage = "be false"
    }
}

// MARK: beTruthy() / beFalsy()

/// A Nimble matcher that succeeds when the actual value is not logically false.
public func beTruthy<T: ExpressibleByBooleanLiteral & Equatable>() -> MatcherFunc<T> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "be truthy"
        let actualValue = try actualExpression.evaluate()
        if let actualValue = actualValue {
            // FIXME: This is a workaround to SR-2290.
            // See:
            // - https://bugs.swift.org/browse/SR-2290
            // - https://github.com/norio-nomura/Nimble/pull/5#issuecomment-237835873
            if let number = actualValue as? NSNumber {
                return number.boolValue == true
            }

            return actualValue == (true as T)
        }
        return actualValue != nil
    }
}

/// A Nimble matcher that succeeds when the actual value is logically false.
/// This matcher will match against nils.
public func beFalsy<T: ExpressibleByBooleanLiteral & Equatable>() -> MatcherFunc<T> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "be falsy"
        let actualValue = try actualExpression.evaluate()
        if let actualValue = actualValue {
            // FIXME: This is a workaround to SR-2290.
            // See:
            // - https://bugs.swift.org/browse/SR-2290
            // - https://github.com/norio-nomura/Nimble/pull/5#issuecomment-237835873
            if let number = actualValue as? NSNumber {
                return number.boolValue == false
            }

            return actualValue == (false as T)
        }
        return actualValue == nil
    }
}

#if _runtime(_ObjC)
extension NMBObjCMatcher {
    public class func beTruthyMatcher() -> NMBObjCMatcher {
        return NMBObjCMatcher { actualExpression, failureMessage in
            let expr = actualExpression.cast { ($0 as? NSNumber)?.boolValue ?? false as Bool? }
            return try! beTruthy().matches(expr, failureMessage: failureMessage)
        }
    }

    public class func beFalsyMatcher() -> NMBObjCMatcher {
        return NMBObjCMatcher { actualExpression, failureMessage in
            let expr = actualExpression.cast { ($0 as? NSNumber)?.boolValue ?? false as Bool? }
            return try! beFalsy().matches(expr, failureMessage: failureMessage)
        }
    }

    public class func beTrueMatcher() -> NMBObjCMatcher {
        return NMBObjCMatcher { actualExpression, failureMessage in
            let expr = actualExpression.cast { ($0 as? NSNumber)?.boolValue ?? false as Bool? }
            return try! beTrue().matches(expr, failureMessage: failureMessage)
        }
    }

    public class func beFalseMatcher() -> NMBObjCMatcher {
        return NMBObjCMatcher(canMatchNil: false) { actualExpression, failureMessage in
            let expr = actualExpression.cast { ($0 as? NSNumber)?.boolValue ?? false as Bool? }
            return try! beFalse().matches(expr, failureMessage: failureMessage)
        }
    }
}
#endif
