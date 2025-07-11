//
//  SwiftUIView.swift
//  Syntaxer
//
//  Created by Leo Dion on 7/10/25.
//

import SwiftUI

@main
struct SyntaxApp : App {
  init() {
    DispatchQueue.main.async {
      NSApp.setActivationPolicy(.regular)
      NSApp.activate(ignoringOtherApps: true)
      NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }
  }
  
  var body: some Scene {
    WindowGroup{
      SwiftUIView()
    }
  }
  
  
}


struct SwiftUIView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    SwiftUIView()
}
