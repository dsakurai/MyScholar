//
//  ScholaryApp.swift
//  Scholary
//
//  Created by Daisuke Sakurai on 2024/01/19.
//

import SwiftUI

@main
struct ScholaryApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: HTMLDocument()) {
            file in
            ContentView(document: file.$document)
        }
    }
}
