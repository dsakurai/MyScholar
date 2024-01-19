//
//  ScholarlyApp.swift
//  Scholarly
//
//  Created by Daisuke Sakurai on 2024/01/19.
//

import SwiftUI

@main
struct ScholarlyApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: HTMLDocument()) {
            file in
            ContentView(document: file.$document)
        }
    }
}
