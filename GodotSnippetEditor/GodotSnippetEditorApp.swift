//
//  GodotSnippetEditorApp.swift
//  GodotSnippetEditor
//
//  Created by Miguel de Icaza on 12/31/23.
//

import SwiftUI
import AppKit

@main
struct GodotSnippetEditorApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView(snippets: try! Snippets(snippetDir: "/tmp/codeblocks", translatedDir: "/Users/miguel/cvs/snippets-translated")!)
        }
    }
}
