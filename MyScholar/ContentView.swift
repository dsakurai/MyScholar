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

struct ContentView: View {
    
    @State var htmlString: String = ""
    
    var body: some View {
        HStack {
            WebView(
                urlString: "https://scholar.google.co.jp/scholar?hl=en&as_sdt=0%2C5&q=test&btnG=",
                htmlContent: $htmlString
            )
            .padding()
            
            Button("Test") {
                print("hello")
                print(htmlString)
            }
        }
    }
}

#Preview {
    ContentView()
}
