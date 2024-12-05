//
//  InOrderContainer.swift
//
//
//  Created by Alexandr Zalutskiy on 13/10/2023.
//

import Foundation

class InOrderContainer: CallContainer {
	private static var mocks: [AnyObject] = []
	private static var calls: [Any] = []
	private static var functions: [String] = []
	private static let queue = DispatchQueue(label: "InOrderContainerQueue")
	
	var startIndex = 0
	
	init() { }

	deinit { queue = nil }
	
	static func append<T>(mock: AnyObject, call: MethodCall<T>, function: String) {
	        queue.sync {
		        Self.mocks.append(mock)
		        Self.calls.append(call)
		        Self.functions.append(function)
	        }
	}
	
	static func clear() {
		mocks = []
		calls = []
		functions = []
	}
	
	func verify<T>(
		mock: AnyObject,
		matcher match: ArgumentMatcher<T>,
		times: (Int) -> Bool,
		type: String,
		function: String,
		file: StaticString,
		line: UInt
	) {
		var callCount = 0
		
		let mocks = InOrderContainer.mocks
		let calls = InOrderContainer.calls
		let functions = InOrderContainer.functions
		
		guard startIndex < calls.count else {
			testFailureReport("\(type).\(function): incorrect calls count: \(callCount)", file, line)
			return
		}
		
		var lastCheckedIndex = startIndex

		for index in startIndex..<calls.endIndex {
			guard mock === mocks[index] else {
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
			
			callCount += 1
			lastCheckedIndex = index
		}
		guard times(callCount) else {
			testFailureReport("\(type).\(function): incorrect calls count: \(callCount)", file, line)
			return
		}
		
		startIndex = lastCheckedIndex + 1
	}
}

