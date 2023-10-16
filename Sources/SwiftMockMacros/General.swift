import SwiftSyntax
import SwiftSyntaxBuilder

extension MockMacro {
	// MARK: - Making Method Wrapper Types
	
	static func makeMethodInvocationType(
		isAsync: Bool = false,
		isThrows: Bool = false,
		arguments: [TypeSyntax] = [],
		returnType: TypeSyntax? = nil
	) -> TypeSyntax {
		makeMethodWrapperType(
			baseName: .identifier("MethodInvocation"),
			isAsync: isAsync,
			isThrows: isThrows,
			arguments: arguments,
			returnType: returnType
		)
	}
	
	static func makeMethodSignatureType(
		isAsync: Bool = false,
		isThrows: Bool = false,
		arguments: [TypeSyntax] = [],
		returnType: TypeSyntax? = nil
	) -> TypeSyntax {
		makeMethodWrapperType(
			baseName: .identifier("MethodSignature"),
			isAsync: isAsync,
			isThrows: isThrows,
			arguments: arguments,
			returnType: returnType
		)
	}
	
	static func makeMethodCallType(
		arguments: [TypeSyntax]
	) -> TypeSyntax {
		TypeSyntax(
			fromProtocol: IdentifierTypeSyntax(
				name: .identifier("MethodCall"),
				genericArgumentClause: GenericArgumentClauseSyntax {
					GenericArgumentSyntax(argument: makeTupleType(from: arguments))
				}
			)
		)
	}
	
	private static func makeMethodWrapperType(
		baseName: TokenSyntax,
		isAsync: Bool,
		isThrows: Bool,
		arguments: [TypeSyntax],
		returnType: TypeSyntax?
	) -> TypeSyntax {
		let type = makeTokenWithPrefix(isAsync: isAsync, isThrows: isThrows, token: baseName)
		return TypeSyntax(
			IdentifierTypeSyntax(
				name: type,
				genericArgumentClause: makeTupleGenericArgumentClause(arguments: arguments, returnType: returnType)
			)
		)
	}
	
	static func makeMethodSignatureExpr(
		isAsync: Bool = false,
		isThrows: Bool = false,
		arguments: [TypeSyntax] = [],
		returnType: TypeSyntax? = nil
	) -> ExprSyntax {
		makeMethodWrappperExpr(
			baseName: "MethodSignature",
			isAsync: isAsync,
			isThrows: isThrows,
			arguments: arguments,
			returnType: returnType
		)
	}
	
	private static func makeMethodWrappperExpr(
		baseName: TokenSyntax,
		isAsync: Bool,
		isThrows: Bool,
		arguments: [TypeSyntax],
		returnType: TypeSyntax?
	) -> ExprSyntax {
		let type = makeTokenWithPrefix(isAsync: isAsync, isThrows: isThrows, token: baseName)
		return ExprSyntax(
			fromProtocol: GenericSpecializationExprSyntax(
				expression: DeclReferenceExprSyntax(baseName: type),
				genericArgumentClause: makeTupleGenericArgumentClause(arguments: arguments, returnType: returnType)
			)
		)
	}
	
	private static func makeTokenWithPrefix(
		isAsync: Bool,
		isThrows: Bool,
		token: TokenSyntax
	) -> TokenSyntax {
		var name = token.text
		if isThrows {
			name = "Throws" + name
		}
		if isAsync {
			name = "Async" + name
		}
		
		return TokenSyntax.identifier(name)
	}
	
	private static func makeTupleGenericArgumentClause<T: Collection>(
		arguments: T,
		returnType: TypeSyntax?
	) -> GenericArgumentClauseSyntax where T.Element == TypeSyntax {
		GenericArgumentClauseSyntax {
			packTypesToGenericArgumentSyntax(types: arguments)
			GenericArgumentSyntax(
				argument: returnType ?? voidType
			)
		}
	}
	
	static func packTypesToGenericArgumentSyntax<T: Collection>(
		types: T
	) -> GenericArgumentSyntax where T.Element == TypeSyntax {
		GenericArgumentSyntax(
			argument: makeTupleType(from: types)
		)
	}
	
	private static func makeTupleType<T: Collection>(
		from types: T
	) -> TypeSyntax where T.Element == TypeSyntax {
		return TypeSyntax(
			fromProtocol: TupleTypeSyntax(
				elements: packParametersToTupleType(types)
			)
		)
	}
	
	private static func packParametersToTupleType<Z: Collection>(
		_ types: Z
	) -> TupleTypeElementListSyntax where Z.Element == TypeSyntax {
		if types.count <= 1 {
			return TupleTypeElementListSyntax {
				for type in types {
					TupleTypeElementSyntax(type: type)
				}
			}
		} else {
			let rest = types.dropFirst()
			return  TupleTypeElementListSyntax {
				TupleTypeElementSyntax(type: types.first!)
				TupleTypeElementSyntax(
					type: TupleTypeSyntax(elements: packParametersToTupleType(rest))
				)
			}
		}
	}
	
	// MARK: - Making Labeled Expressions
	
	static func makeMethodSignatureRegisterLabeledExpr(from containerToken: TokenSyntax) -> LabeledExprSyntax {
		LabeledExprSyntax(
			label: "register",
			expression: ClosureExprSyntax {
				FunctionCallExprSyntax(
					calledExpression: MemberAccessExprSyntax(
						base: MemberAccessExprSyntax(
							base: DeclReferenceExprSyntax(baseName: TokenSyntax.keyword(.`self`)),
							declName: DeclReferenceExprSyntax(baseName: containerToken)
						),
						declName: DeclReferenceExprSyntax(baseName: .identifier("append"))
					),
					leftParen: .leftParenToken(),
					rightParen: .rightParenToken()
				) {
					LabeledExprSyntax(expression: DeclReferenceExprSyntax(baseName: .identifier("$0")))
				}
			}
		)
	}
	
	// MARK: - ArgumentMatcher
	
	static func wrapToEscapingType(type: TypeSyntax) -> TypeSyntax {
		TypeSyntax(
			fromProtocol: AttributedTypeSyntax(
				attributes: AttributeListSyntax {
					escapingAttribute
				},
				baseType: type
			)
		)
	}
	
	static func wrapToArgumentMatcherType(type: TypeSyntax) -> TypeSyntax {
		TypeSyntax(
			fromProtocol: IdentifierTypeSyntax(
				name: "ArgumentMatcher",
				genericArgumentClause: GenericArgumentClauseSyntax {
					GenericArgumentSyntax(argument: type)
				}
			)
		)
	}
	
	static func makeArgumentMatcherZipStmts(tokens: [TokenSyntax]) -> [DeclSyntax] {
		var stmts: [DeclSyntax] = []
		if tokens.isEmpty {
			stmts.append("let argumentMatcher0: ArgumentMatcher<()> = any()")
		} else {
			for (index, token) in tokens.enumerated().reversed() {
				if index == tokens.count - 1 {
					stmts.append("let argumentMatcher\(raw: index) = \(raw: token.text)")
				} else {
					stmts.append("let argumentMatcher\(raw: index) = zip(\(raw: token.text), argumentMatcher\(raw: index + 1))")
				}
			}
		}
		return stmts
	}
}
