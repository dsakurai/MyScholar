//
//  ContentView.swift
//  MyScholar
//
//  Created by Daisuke Sakurai on 2024/01/17.
//

import SwiftUI

import WebKit

import SwiftSoup

import UniformTypeIdentifiers

struct HTMLDocument: FileDocument {
    static var readableContentTypes: [UTType] {[.html]}
    var text: String
    
    init(text: String = "") {
        self.text = text
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let content = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        self.text = content
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = text.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}

struct WebView: NSViewRepresentable {
    let initial_url: URL
    
    @Binding var htmlContent: String

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        
        webView.navigationDelegate = context.coordinator
        
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        
        if nsView.url == nil {
            let request = URLRequest(url: initial_url)
            nsView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
                
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.documentElement.outerHTML.toString()") {
                (html, error) in
                
                if let htmlString = html as? String {
                    // Now htmlString contains the entire HTML content of the page
                    self.parent.htmlContent = htmlString
                } else if let error = error {
                    // Handle the error
                    print("Error getting HTML string: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct WebViewWrapper: NSViewRepresentable {
    @Binding var htmlString: String
    
    func makeNSView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString(htmlString, baseURL: URL(string: "https://scholar.google.com")!)
    }
}

func showSavePanel() -> URL? {
    let panel = NSSavePanel()
    
    panel.canCreateDirectories = true
    panel.allowedContentTypes = [.html]
    panel.allowsOtherFileTypes = false
    panel.title = "Save HTML File"
    panel.message = "Select a location to save your HTML file"
    panel.nameFieldStringValue = "Citing.html"
        
    if panel.runModal() == .OK {
        return panel.url
    } else {
        return nil
    }
}

func showOpenPanel() -> URL? {
    let panel = NSOpenPanel()
    
    panel.canCreateDirectories = false
    panel.allowedContentTypes = [.html]
    panel.allowsOtherFileTypes = false
    panel.title = "Open HTML File"
    panel.message = "Select your HTML file"
        
    if panel.runModal() == .OK {
        return panel.url
    } else {
        return nil
    }
}


struct ContentView: View {
    
    @Binding var document: HTMLDocument
    
    @State var htmlString_left: String = ""
    
    var body: some View {
        HStack {
            WebView(
                initial_url: URL(string: "https://scholar.google.com/")!,
                htmlContent: $htmlString_left
            )
            
            VStack {
                Button("=>") {
                    if self.document.text == "" {
                        self.document.text = htmlString_left
                    } else {
                        do {
                            
                            let doc_left: Document = try SwiftSoup.parse(htmlString_left)
                            let divElements_left = try doc_left.select("div.gs_r.gs_or.gs_scl")
                            
                            let doc_right: Document = try SwiftSoup.parse(document.text)
                            
                            for div_left in divElements_left {
                                let right = try doc_right.select("div.gs_r.gs_or.gs_scl")
                                if let right_last = right.last() {
                                    try right_last.after(div_left)
                                }
                            }
                            
                            try self.document.text = doc_right.outerHtml()
                        } catch {
                            print("Error parsing HTML")
                        }
                    }
                }
            }
            
            WebViewWrapper(
                htmlString: $document.text
            )
            
        }
    }
}

//#Preview {
//    ContentView()
//}
