//
//  ProjectGenerator.swift
//  GodotSnippetEditor
//
//  Created by Miguel de Icaza on 12/31/23.
//

import Foundation

class ProjectGenerator {
    var statementSnippets: [String] = []
    var classSnippets: [(String,String)] = []
    var fullSnippets: [String] = []
    
    init(statementSnippets: [String], classSnippets: [(String,String)], fullSnippets: [String]) {
        self.statementSnippets = statementSnippets
        self.classSnippets = classSnippets
        self.fullSnippets = fullSnippets
    }
    
    enum ProjectErrors: Error {
        case targetExists
    }

    func generate (at path: String) throws {
        let fm = FileManager.default
        
//        if fm.fileExists(atPath: path) {
//            print ("Target already exists, exiting")
//            throw ProjectErrors.targetExists
//        }
        
        try fm.createDirectory(atPath: "\(path)/Sources/Tester", withIntermediateDirectories: true)
        try """
        // swift-tools-version: 5.9
        // The swift-tools-version declares the minimum version of Swift required to build this package.

        import PackageDescription

        let package = Package(name: "SnippetTester",
        platforms: [
            .macOS(.v13)
        ],
        products: [
            // Products define the executables and libraries a package produces, making them visible to other packages.
            .library(
                name: "SnippetTester",
                targets: ["SnippetTester"]),
        ],
        dependencies: [
            .package(url: "https://github.com/migueldeicaza/SwiftGodot", branch: "main"),
        ],
        targets: [
            .target(name: "SnippetTester", dependencies: ["SwiftGodot"])])
        """.write(toFile: "\(path)/Package.swift", atomically: true, encoding: .utf8)
        
        var output = """
// Automatically generated, do not edit
import Foundation
import SwiftGodot

class StatementHolder {

"""
        
        func indent (_ str: String) -> String {
            let lines = str.split(separator: "\n")
            var result = ""
            for x in lines {
                result += "\t\(x)\n"
            }
            return result
        }
        
        // Statements
        var sc = 0
        for snippet in statementSnippets {
            output += "\tfunc host_\(sc) () {\n\(indent (snippet))\n}"
            sc += 1
        }
        output += "}\n\n// Class Snippets\n"
        
        // class snippets
        for (snippetClass, snippet) in classSnippets {
            output += "class Host\(sc): \(snippetClass) {"
            sc += 1
            let fo = "func host () {\(indent (snippet))\n}"
            output += indent (fo)
            output += "}"
        }
        output += "\n\n// Full Snippets\n"
        
        for full in fullSnippets {
            output += full
        }
        
        try output.write(toFile: "\(path)/Sources/File.swift", atomically: true, encoding: .utf8)
        
    }
}
