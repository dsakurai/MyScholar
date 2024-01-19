//
//  MyScholarApp.swift
//  MyScholar
//
//  Created by Daisuke Sakurai on 2024/01/17.
//

import SwiftUI

@main
struct MyScholarApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: HTMLDocument()) {
            file in
            ContentView(document: file.$document)
        }
    }
}
