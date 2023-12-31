//
//  ContentView.swift
//  GodotSnippetEditor
//
//  Created by Miguel de Icaza on 12/31/23.
//

import SwiftUI
import STTextViewUI
import NeonPlugin

var statementSnippets: [String] = [
    "let d = DisplayServer.xgetName () "
]

var classSnippets: [(String,String)] = [
    ("Node", "print (owner)")
]

var fullSnippets: [String] = [
    "@Godot class Demo: Node { }"
]

struct RunView: View {
    @State var status: String = "Not Run"
    @State var stderr: String?
    @State var stdout: String?
    
    func run () {
        let generatedPath = "/tmp/output"
        let r = ProjectGenerator(statementSnippets: statementSnippets,
                                 classSnippets: classSnippets,
                                 fullSnippets: fullSnippets)
        do {
            try r.generate(at: generatedPath)
        } catch (let err) {
            status = err.localizedDescription
            return
        }
        status = "Building..."
        Task {
            let fm = FileManager.default
            let stdoutPath = "\(generatedPath)/stdout"
            let stderrPath = "\(generatedPath)/stderr"
            try? fm.removeItem(atPath: stdoutPath)
            try? fm.removeItem(atPath: stderrPath)
            
            let process = Process ()
            process.arguments = ["build"]
            process.currentDirectoryURL = URL (filePath: generatedPath)
            process.executableURL = URL (filePath: "/usr/bin/swift")
            fm.createFile(atPath: stdoutPath, contents: nil)
            fm.createFile(atPath: stderrPath, contents: nil)
            process.standardError = FileHandle (forWritingAtPath: stderrPath)
            process.standardOutput = FileHandle (forWritingAtPath: stdoutPath)
            process.terminationHandler = { process in
                DispatchQueue.main.async {
                    switch process.terminationReason {
                    case .exit:
                        status = "Process terminated with \(process.terminationStatus)"
                        if process.terminationStatus != 0 {
                            stderr = (try? String(contentsOfFile: stderrPath)) ?? "Could not read \(stderrPath)"
                            stdout = (try? String(contentsOfFile: stdoutPath)) ?? "Could not read \(stdoutPath)"
                        }
                    case .uncaughtSignal:
                        status = "Uncaught signal"
                    default:
                        status = "Unknown reason for termination"
                    }
                }
            }
            do {
                try process.run ()
            } catch (let err) {
                status = "Failure to launch: \(err.localizedDescription)"
            }
        }
    }
    
    var body: some View {
        VStack {
            Text ("Status: \(status)")
            Button (action: { run () }) {
                Text ("Run")
            }
            ScrollView {
                VStack {
                    if let stderr {
                        Text (stderr)
                            .font (.system(.body, design: .monospaced, weight: .regular))
                            .multilineTextAlignment(.leading)
                    }
                    if let stdout {
                        Text (stdout)
                            .font (.system(.body, design: .monospaced, weight: .regular))
                            .multilineTextAlignment(.leading)
                    }
                }
            }
        }
        .padding()
    }
}

struct Target: Hashable {
    let container: String
    let value: String
}

struct ContentView: View {
    let snippets: Snippets
    @State var sel: Target?
    @State var edited: AttributedString = ""
    @State private var selection: NSRange?
    @State var status = "OK"
    @FocusState var textFocus: Bool
    
    var body: some View {
        NavigationSplitView {
            List (snippets.sourceTops.elements, id: \.key, selection: $sel) { key, values in
                DisclosureGroup(key == "" ? "Global" : key) {
                    ForEach (values, id: \.self) { v in
                        NavigationLink(v, value: Target (container: key, value: v))
                    }
                }
            }
        } content: {
            if let sel {
                VStack {
                    ScrollView {
                        HStack {
                            Text (snippets.load(container: sel.container, element: sel.value, isOriginal: true))
                                .font(.system(.body, design: .monospaced, weight: .regular))
                                .textSelection(.enabled)
                            Spacer ()
                        }
                        Spacer ()
                    }
                    Text ("Status: \(status)")
                }
            } else {
                Text ("Choose a node")
            }
        } detail: {
            GeometryReader { geo in
                STTextViewUI.TextView(
                    text: $edited,
                    selection: $selection,
                    options: [.wrapLines, .highlightSelectedLine],
                    plugins: [NeonPlugin(theme: .default, language: .swift)]
                )
                .textViewFont(.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular))
                .focused($textFocus)
                .frame (width: geo.size.width, height: geo.size.height)
            }
        }
        .onChange(of: sel) { oldValue, newSel in
            if let oldValue {
                if !snippets.save (container: oldValue.container, element: oldValue.value, text: String (edited.characters)) {
                    status = "Could not save the file for \(oldValue.container)/\(oldValue.value)"
                }
            }
            if let newSel {
                edited = AttributedString (snippets.load(container: newSel.container, element: newSel.value, isOriginal: false))
                selection = nil
                textFocus = true
            }
        }
    }
}
#Preview {
    ContentView(snippets: (try? Snippets(snippetDir: "/tmp/codeblocks", translatedDir: "/Users/miguel/cvs/snippets-translated"))!)
}

