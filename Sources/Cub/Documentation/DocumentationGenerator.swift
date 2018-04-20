//
//  DocumentationGenerator.swift
//  Cub
//
//  Created by Louis D'hauwe on 19/04/2018.
//  Copyright © 2018 Silver Fox. All rights reserved.
//

import Foundation

public class DocumentationGenerator {
	
	public init() {
		
	}
	
	public func items(runner: Runner) -> [DocumentationItem] {
		
		var items = [DocumentationItem]()
		
		let stdLib = StdLib()
		if let stbLibSource = try? stdLib.stdLibCode() {
			
			if let sourceItems = try? self.items(for: stbLibSource) {
				items.append(contentsOf: sourceItems)
			}
			
		}
		
		return items
	}
	
	func items(for source: String) throws -> [DocumentationItem] {
		
		var items = [DocumentationItem]()

		let tokens = Lexer(input: source).tokenize()

		let parser = Parser(tokens: tokens)
		let ast = try parser.parse()
		
		for node in ast {
			
			if let functionNode = node as? FunctionNode {
				
				let functionItem = parsedDocumentation(for: functionNode)
				
				items.append(functionItem)
			}
			
		}
		
		return items
	}
	
	private func parsedDocumentation(for functionNode: FunctionNode) -> DocumentationItem {
		
		let args = functionNode.prototype.argumentNames.joined(separator: ", ")
		var definition = "func \(functionNode.prototype.name)(\(args))"
		
		if functionNode.prototype.returns {
			definition += " returns"
		}
		
		let functionDocumentation: FunctionDocumentation?
		
		let rawDocumentation = functionNode.documentation
		
		if let rawDocumentation = rawDocumentation {
			
			let rawDocLines = rawDocumentation.split(separator: "\n").map({ String($0) })
			
			let cleanedUpRawDocLines: [String] = rawDocLines.map({
				var cleanedUp = $0
				if cleanedUp.hasPrefix("///") {
					cleanedUp.removeFirst(3)
				}
				
				cleanedUp = cleanedUp.trimmingCharacters(in: .whitespaces)
				
				return cleanedUp
			})
			
			var description: String? = nil
			var endDescriptionParsing = false
			
			var argumentDescriptions = [String: String?]()
			var returnDescription: String? = nil
			
			var legalDocFields = [String: String]()
			
			for argumentName in functionNode.prototype.argumentNames {
				
				legalDocFields["- Parameter \(argumentName):"] = argumentName
				
			}
			
			if functionNode.prototype.returns {
				legalDocFields["- Returns:"] = "returns"
			}
			
			for line in cleanedUpRawDocLines {
				
				if line.starts(with: "-") {
					
					endDescriptionParsing = true
					
					for (legalDocField, name) in legalDocFields {
						
						if line.starts(with: legalDocField) {
							
							let value = String(line.dropFirst(legalDocField.count))
							
							let cleanedUpValue = value.trimmingCharacters(in: .whitespaces)
							
							if name == "returns" {
								returnDescription = cleanedUpValue
							} else {
								argumentDescriptions[name] = cleanedUpValue
							}
							
						}
						
					}
					
				} else if !endDescriptionParsing {
					
					if description == nil {
						description = line
					} else {
						
						description?.append("\n")
						description?.append(line)

					}
					
				}
				
			}
			
			functionDocumentation = FunctionDocumentation(description: description, argumentDescriptions: argumentDescriptions, returnDescription: returnDescription)
			
		} else {
			
			functionDocumentation = nil
			
		}
		
		let functionItem = DocumentationItem(definition: definition, rawDocumentation: rawDocumentation, type: .function, functionDocumentation: functionDocumentation)
		
		return functionItem
	}
	
}
