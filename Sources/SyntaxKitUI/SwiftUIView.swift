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
    @State private var leftText: String = ""
    @State private var rightText: String = ""
    @State private var leftSplitPosition: CGFloat = 0.5
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button("Clear Left") {
                    leftText = ""
                }
                .buttonStyle(.borderedProminent)
                
                Button("Clear Right") {
                    rightText = ""
                }
                .buttonStyle(.borderedProminent)
                
                Button("Clear All") {
                    leftText = ""
                    rightText = ""
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                Button("Copy Left to Right") {
                    rightText = leftText
                }
                .buttonStyle(.bordered)
                
                Button("Copy Right to Left") {
                    leftText = rightText
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .border(Color.gray.opacity(0.3), width: 1)
            
            // Horizontal Split View
            HSplitView {
                // Left Text Box
                VStack {
                    Text("Left Panel")
                        .font(.headline)
                        .padding(.top)
                    
                    TextEditor(text: $leftText)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .padding()
                }
                .frame(minWidth: 200, maxWidth: .infinity)
                
                // Right Text Box
                VStack {
                    Text("Right Panel")
                        .font(.headline)
                        .padding(.top)
                    
                    TextEditor(text: $rightText)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .padding()
                }
                .frame(minWidth: 200, maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

#Preview {
    SwiftUIView()
}
