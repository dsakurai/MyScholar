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
//
//func injectJavaScript(webView: WKWebView, scriptContent: String) {
//    webView.evaluateJavaScript(scriptContent) { result, error in
//        if let error = error {
//            print("Error injecting JavaScript: \(error)")
//        } else {
//            print("JavaScript injected successfully")
//        }
//    }
//}

struct WebView: NSViewRepresentable {
    
    let initial_url: URL
    
    @Binding var htmlContent: String

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        
        var userscript: String = ""
        
        Task { // Load mark.js
            userscript = await fetchJavaScript(from: URL(string: "https://cdnjs.cloudflare.com/ajax/libs/mark.js/8.11.1/mark.min.js")!)!
        }
//        
//        let config = WKWebViewConfiguration()
//        let script = WKUserScript(source: userscript, injectionTime: .atDocumentStart, forMainFrameOnly: true)
//        config.userContentController.addUserScript(script)
//        
//        let userscript2 = """
//        function highlightText() {
//            var searchTerm = document.getElementById("searchInput").value;
//            var markInstance = new Mark(document.body);
//            markInstance.mark(searchTerm, { className: "highlight"});
//        }
//
//        var searchBoxHtml = '<input type="text" id="searchInput" placeholder="Search text"><button onclick="highlightText()">Highlight</button>';
//        document.body.innerHTML = searchBoxHtml + document.body.innerHTML;
//        """
//        
//        config.userContentController.addUserScript(WKUserScript(source: userscript2, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        
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
        
//        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {

            // Open in Safari
//            if (navigationAction.navigationType == WKNavigationType.LinkActivated && !navigationAction.request.URL.host!.lowercaseString.hasPrefix("www.appcoda.com")) {
//                UIApplication.sharedApplication().openURL(navigationAction.request.URL)
//                decisionHandler(WKNavigationActionPolicy.Cancel)
//            } else {
//                decisionHandler(WKNavigationActionPolicy.Allow)
//            }

//        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            
//            // Seems I need to inject this before loading the html...
//            
//            // JavaScript to add a search box and button, and the search functionality
//            let injectScript = """
//            document.head.innerHTML = '<style>.highlight {background-color: yellow;font-weight: bold;}</style><script src="https://cdnjs.cloudflare.com/ajax/libs/mark.js/8.11.1/mark.min.js"></script>' + document.head.innerHTML
//
//            var searchBoxHtml = '<input type="text" id="searchInput" placeholder="Search text"><button onclick="highlightText()">Highlight</button> <script>function highlightText() { var searchTerm = document.getElementById("searchInput").value; var markInstance = new Mark(document.body); markInstance.mark(searchTerm, { className: "highlight"});}</script>';
//            document.body.innerHTML = searchBoxHtml + document.body.innerHTML;
//            """
//
//            webView.evaluateJavaScript(injectScript, completionHandler: nil)
  
            
            
            let injectScript = """
            var searchBoxHtml = '<input type="text" id="searchInput" placeholder="Enter search term"> <button onclick="highlightSearchTerm()">Search</button>';
            document.body.innerHTML = searchBoxHtml + document.body.innerHTML;

            function highlightSearchTerm() {
                var searchTerm = document.getElementById('searchInput').value;

                document.querySelectorAll('.highlight').forEach(function(el) {
                    el.classList.remove('highlight');
                });

                if (searchTerm) {
                    var regex = new RegExp(searchTerm, 'gi');
                    var bodyText = document.body.innerHTML;

                    var newBodyText = bodyText.replace(regex, function(match) {
                        return '<span class="highlight">' + match + '</span>';
                    });
                    document.body.innerHTML = newBodyText;
                }
            }

            var style = document.createElement('style');
            style.innerHTML = '.highlight { background-color: yellow; }';
            document.head.appendChild(style);
            """

            webView.evaluateJavaScript(injectScript, completionHandler: nil)

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

    
    var body: some View {
        HStack {
            WebView(
                initial_url: URL(string: "https://scholar.google.com/")!,
                htmlContent: $htmlString_left
            )
            .frame(width: CGFloat(draggableWidth))
            
            SlideableDivider(dimension: $draggableWidth)

            
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