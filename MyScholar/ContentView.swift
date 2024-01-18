//
//  ContentView.swift
//  MyScholar
//
//  Created by Daisuke Sakurai on 2024/01/17.
//

import SwiftUI

import WebKit

import SwiftSoup

struct WebView: NSViewRepresentable {
    let urlString: String
    
    @Binding var htmlContent: String

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        
        webView.navigationDelegate = context.coordinator
        
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
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
        nsView.loadHTMLString(htmlString, baseURL: URL(string: "https://scholar.google.co.jp")!)
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
    
    @State var htmlString_left: String = ""
    
    @State private var htmlString_right: String = ""
    
    var body: some View {
        HStack {
            WebView(
                urlString: "https://scholar.google.com/",
                htmlContent: $htmlString_left
            )
            
            VStack {
                Button("=>") {
                    if self.htmlString_right == "" {
                        self.htmlString_right = htmlString_left
                    } else {
                        do {
                            
                            let doc_left: Document = try SwiftSoup.parse(htmlString_left)
                            let divElements_left = try doc_left.select("div.gs_r.gs_or.gs_scl")
                            
                            let doc_right: Document = try SwiftSoup.parse(htmlString_right)
                            
                            for div_left in divElements_left {
                                let right = try doc_right.select("div.gs_r.gs_or.gs_scl")
                                if let right_last = right.last() {
                                    try right_last.after(div_left)
                                }
                            }
                            
                            try self.htmlString_right = doc_right.outerHtml()
                        } catch {
                            print("Error parsing HTML")
                        }
                    }
                }

                Button ("Open") {
                    if let url = showOpenPanel() {
                        do {
                            htmlString_right = try String(contentsOf: url)
                        } catch {
                            print("Failed to open file.")
                        }
                    }
                }

                Button ("Save") {
                    if let url = showSavePanel() {
                        do {
                            try htmlString_right.write(to: url, atomically: true, encoding: .utf8)
                        } catch {
                            print("Failed to save.")
                        }
                    }
                }
            }
            
            WebViewWrapper(
                htmlString: $htmlString_right
            )
            
        }
    }
}

#Preview {
    ContentView()
}
