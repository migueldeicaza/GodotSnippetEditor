//
//  Snippets.swift
//  GodotSnippetEditor
//
//  Created by Miguel de Icaza on 12/31/23.
//

import Foundation
import Collections

class Snippets {
    let snippetDir: String
    let translatedDir: String
    let sources: [String]
    var targets: [String]
    var sourceTops = OrderedDictionary<String,[String]> ()
    var targetTops = OrderedDictionary<String,[String]> ()
    
    init? (snippetDir: String, translatedDir: String) throws {
        self.snippetDir = snippetDir
        self.translatedDir = translatedDir
        
        let fm = FileManager.default
        sources = try fm.subpathsOfDirectory(atPath: snippetDir)
        targets = try fm.subpathsOfDirectory(atPath: translatedDir)
        
        func split (_ dir: String, _ array: [String]) -> OrderedDictionary<String,[String]> {
            var res = OrderedDictionary<String,[String]> ()
            
            for element in array {
                let r = element.split(separator: "/")
                let key = r.count == 1 ? "" : String (r[0])
                
                if var existing = res [key] {
                    existing.append (element)
                    res [key] = existing
                } else {
                    res [key] = [(element)]
                }
            }
            return res
        }
        sourceTops = split (snippetDir, sources.sorted())
        targetTops = split (translatedDir, targets.sorted())
    }
    
    func load (path: String, isOriginal: Bool) -> String {
        let dir = isOriginal ? snippetDir : translatedDir
        return (try? String (contentsOfFile: "\(dir)/\(path)")) ?? ""
    }

    func save (path: String, text: String) -> Bool {
        do {
            let dir = NSString (string: path).deletingLastPathComponent
            let fulldir = "\(translatedDir)/\(dir)"
            try FileManager.default.createDirectory(atPath: fulldir, withIntermediateDirectories: true)
            try text.write(toFile: "\(translatedDir)/\(path)", atomically: true, encoding: .utf8)
        } catch {
            return false
        }
        return true
    }
}
