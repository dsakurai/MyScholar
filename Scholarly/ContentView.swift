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

func fetchJavaScript(from url: URL) async -> String? {
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        return String(data: data, encoding: .utf8)
    } catch {
        print("Error fetching JavaScript: \(error)")
        return nil
    }
}

let mark_js_url: URL = URL(string: "https://cdnjs.cloudflare.com/ajax/libs/mark.js/8.11.1/mark.min.js")!;

func highlight_text_javascript(text: String) -> String {
    return """
             var markInstance = new Mark(document.body);
             markInstance.unmark();
             markInstance.mark("\(text)", { className: "highlight"});
    """

}

struct WebView: NSViewRepresentable {
    
    let initial_url: URL
    
    @Binding var htmlContent: String
    @Binding var searchText: String

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
        
        nsView.evaluateJavaScript(
            highlight_text_javascript(text: searchText)
        ) {
            
            (html, error) in
            
            if let htmlString = html as? String {
                    // Now htmlString contains the entire HTML content of the page
                    //                self.parent.htmlContent = htmlString
            } else if let error = error {
                // Handle the error
                print("Error getting HTML string: \(error.localizedDescription)")
            }
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
            
            Task {
                let markjs = await fetchJavaScript(from: mark_js_url)  // Download mark.js file
                
                if let markjs = markjs {
                    await webView.evaluateJavaScript(markjs, completionHandler: nil)
                }
            }
            

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
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                if url.host != "scholar.google.com" {
                    NSWorkspace.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
            }

            decisionHandler(.allow)
        }
    }
}

class Reload {
    var flag = true
}

struct WebViewWrapper: NSViewRepresentable {
    @Binding var htmlString: String
    @Binding var searchText: String
    @Binding var reload: Reload
    
    func makeNSView(context: Context) -> WKWebView {
        
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        
        webView.configuration.userContentController.add(context.coordinator as WKScriptMessageHandler, name: "selection_handler")

        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {

        // If there's no HTML, yet, we need to load it.
        // This check is done by trying to evaluate this JavaScript.
        
        if reload.flag {
            nsView.loadHTMLString(htmlString, baseURL: URL(string: "https://scholar.google.com")!)
            reload.flag = false
        } else {
            
            nsView.evaluateJavaScript(
                highlight_text_javascript(text: searchText)
            ) {
                
                (_, error) in
                
                if let error = error {
                    // Handle the error
                    print("Error getting HTML string: \(error.localizedDescription)")
                }
            }
        }
            
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebViewWrapper
        
        init(_ parent: WebViewWrapper) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                if url.host != "scholar.google.com" {
                    NSWorkspace.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
            }

            decisionHandler(.allow)
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "selection_handler" {
                parent.htmlString = message.body as! String
            }
        }

    }

}

public struct SlideableDivider: View {
    @Binding var dimension: Double
    @State private var dimensionStart: Double?

    public init(dimension: Binding<Double>) {
        self._dimension = dimension
    }
    
    public var body: some View {
        Rectangle().background(Color.gray).frame(width: 10)
            .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.9))
            .onHover { inside in
                if inside {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(drag)
    }
    
    var drag: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: CoordinateSpace.global)
            .onChanged { val in
                if dimensionStart == nil {
                    dimensionStart = dimension
                }
                let delta = val.location.x - val.startLocation.x
                dimension = dimensionStart! + Double(delta)
            }
            .onEnded { val in
                dimensionStart = nil
            }
    }
}

struct ContentView: View {
    
    @Binding var document: HTMLDocument
    
    @State var htmlString_left: String = ""
    @State var draggableWidth: Double = 1000.0 // Should be 50%, like 0.5

    @State private var searchTextLeft = ""
    @State private var searchTextRight = ""
    @State private var reloadRight = Reload()
    
    var body: some View {
        HStack {
            VStack {
                WebView(
                    initial_url: URL(string: "https://scholar.google.com/")!,
                    htmlContent: $htmlString_left,
                    searchText: $searchTextLeft
                )
                .frame(width: CGFloat(draggableWidth))
                
                TextField ("Search", text: $searchTextLeft)
            }
            
            SlideableDivider(dimension: $draggableWidth)

            
            VStack {
                Button("=>") {
                    if self.document.text == "" {
                        // Copy the left HTML to the right
                        self.document.text = htmlString_left
                        
                        do { // Add search box
                            let doc_right: Document = try SwiftSoup.parse(document.text)
                            
                            // Maybe we can remove text inside JavaScript?
                            
                            if let head = doc_right.head(), let body = doc_right.body() {
                                try head.append("<script src=\"\(mark_js_url)\"></script>")
                                
                                // TODO should be a WebKit user script instead
                                try head.append("<style> .selected { background-color: yellow;} </style>")
                                
                                try body.append("""
                                    <script>
                                        document.addEventListener('DOMContentLoaded', (event) => {
                                            const elements = document.querySelectorAll('.gs_r.gs_or.gs_scl');

                                            elements.forEach(element => {
                                                element.addEventListener('click', function() {
                                                    this.classList.toggle('selected');
                                
                                                    // window.webkit.messageHandlers.selection_handler.postMessage('Clicked!');
                                                });
                                            });
                                        });
                                    </script>
                                """)
                                
                                try body.prepend("""
                                <button id="removeButton">Remove Selected Elements</button>
                                """)
                                try body.append("""
                                <script>
                                document.getElementById('removeButton').addEventListener('click', function() {
                                    const selectedElements = document.querySelectorAll('.selected');
                                    selectedElements.forEach(function(element) {
                                        element.remove();
                                    });
                                
                                    const html_string = document.documentElement.outerHTML.toString()
                                    window.webkit.messageHandlers.selection_handler.postMessage(html_string);
                                });
                                </script>
                                """)

                                
                                try self.document.text = doc_right.outerHtml()
                            }
                        } catch {
                            print("Failed to insert search box in the web view on the right hand side")
                        }

                    } else {
                        do {
                            // Add search box
                            
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
                    reloadRight.flag = true
                }
            }
            
            VStack {
                WebViewWrapper(
                    htmlString: $document.text,
                    searchText: $searchTextRight,
                    reload: $reloadRight
                )
                HStack {
                    TextField ("Search", text: $searchTextRight)
                        .border(Color.gray, width: 1)
                }
            }
            
        }
    }
}

//#Preview {
//    ContentView()
//}
