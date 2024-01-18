//
//  ContentView.swift
//  MyScholar
//
//  Created by Daisuke Sakurai on 2024/01/17.
//

import SwiftUI

import WebKit

func getCharSet(httpResponse: HTTPURLResponse) -> String? {
    
    if let contentType = httpResponse.allHeaderFields["Content-Type"] as? String {
        // Extract encoding from contentType, e.g., "text/html; charset=UTF-8"
        
        // Get the Charset field
        let regex = try! NSRegularExpression(pattern: "charset=([^;]+)", options: .caseInsensitive)
        
        if let match = regex.firstMatch(in: contentType, options: [], range: NSRange(location: 0, length: contentType.utf16.count)),
           let range = Range(match.range(at: 1), in: contentType) {
               return String(contentType[range])
        }
    }
    
    return nil
}

struct WebView: NSViewRepresentable {
    let urlString: String

    func makeNSView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            nsView.load(request)
        }
    }
}


struct ContentView: View {
    var body: some View {
        WebView(urlString: "https://scholar.google.co.jp/scholar?hl=en&as_sdt=0%2C5&q=test&btnG=")
            .padding()
    }
}

#Preview {
    ContentView()
}
