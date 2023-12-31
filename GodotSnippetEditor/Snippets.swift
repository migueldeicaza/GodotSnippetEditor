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
        sources = try fm.contentsOfDirectory(atPath: snippetDir)
        targets = try fm.contentsOfDirectory(atPath: translatedDir)
        
        func split (_ dir: String, _ array: [String]) -> OrderedDictionary<String,[String]> {
            var res = OrderedDictionary<String,[String]> ()
            
            for element in array {
                let r = element.split(separator: "--")
                let key = r.count == 1 ? "" : String (r[0])
                let value = r.count == 1 ? String (r[0]) : String (r[1])
                
                if key == "Node" {
                    print ("aasdf")
                }
                if var existing = res [key] {
                    existing.append (value)
                    res [key] = existing
                } else {
                    res [key] = [(value)]
                }
            }
            return res
        }
        sourceTops = split (snippetDir, sources.sorted())
        targetTops = split (translatedDir, targets.sorted())
    }
    
    func load (container: String, element: String, isOriginal: Bool) -> String {
        let dir = isOriginal ? snippetDir : translatedDir
        return (try? String (contentsOfFile: "\(dir)/\(container)--\(element)")) ?? ""
    }

    func save (container: String, element: String, text: String) -> Bool {
        let dir = translatedDir
        
        do {
            try text.write(toFile: "\(translatedDir)/\(container)--\(element)", atomically: true, encoding: .utf8)
        } catch {
            return false
        }
        return true
    }
}
