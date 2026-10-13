//
//  TasbihCounterApp.swift
//  TasbihCounter
//
//  Created by Mohamed Negm on 10/8/26.
//

import SwiftUI
import CoreText

@main
struct TasbihCounterApp: App {
    init() {
        // Register the bundled Arabic font so Font.custom("NotoNaskhArabic-Bold") finds it
        if let url = Bundle.main.url(forResource: "NotoNaskhArabic-Bold", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
