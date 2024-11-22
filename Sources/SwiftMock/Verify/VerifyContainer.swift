//
//  MethodCallContainer.swift
//
//
//  Created by Alexandr Zalutskiy on 12/10/2023.
//

import Foundation

public class VerifyContainer: CallContainer {
	var calls: [Any] = []
	var functions: [String] = []
	var isVerified: [Bool] = []
    private let queue = DispatchQueue(label: "VerifyContainerQueue")

	public init() { }
	
	public func append<T>(mock: AnyObject, call: MethodCall<T>, function: String) {
        queue.sync { [weak self] in
            self?.calls.append(call)
            self?.functions.append(function)
            self?.isVerified.append(false)

            InOrderContainer.append(mock: mock, call: call, function: function)
        }
	}
	
	public func verify<T>(
		mock: AnyObject,
		matcher match: ArgumentMatcher<T>,
		times: (Int) -> Bool,
		type: String,
		function: String,
		file: StaticString,
		line: UInt
	) {
		var callCount = 0
		var indexes: [Array.Index] = []
		for index in calls.startIndex..<calls.endIndex {
			guard !isVerified[index] else {
				continue
			}
			guard functions[index] == function else {
				continue
			}
			guard let call = calls[index] as? MethodCall<T> else {
				continue
			}
			guard match(call.arguments) else {
				continue
			}
			indexes.append(index)
			callCount += 1
		}
		guard times(callCount) else {
			testFailureReport("\(type).\(function): incorrect calls count: \(callCount)", file, line)
			return
		}
		for index in indexes {
			isVerified[index] = true
		}
	}
}
