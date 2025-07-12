//
//  SwiftUIView.swift
//  Syntaxer
//
//  Created by Leo Dion on 7/10/25.
//

import SwiftUI
import SyntaxerCore

class SyntaxAppDelegate : NSObject, NSApplicationDelegate {
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
}

//applicationShouldTerminateAfterLastWindowClosed
@main
struct SyntaxApp : App {
  @NSApplicationDelegateAdaptor var appDelegate: SyntaxAppDelegate
  
  init() {
    DispatchQueue.main.async {
      NSApp.setActivationPolicy(.regular)
      NSApp.activate(ignoringOtherApps: true)
      NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }
  }
  
  var body: some Scene {
    WindowGroup{
      SyntaxerView()
    }
  }
}

struct SyntaxerView: View {
    @State private var leftText: String = """
          Enum("Suit") {
              EnumCase("spades").equals("♠")
              EnumCase("hearts").equals("♡")
              EnumCase("diamonds").equals("♢")
              EnumCase("clubs").equals("♣")
          }
          .inherits("Character")
      """
    @State private var rightText: String = ""
    @State private var bottomText: String = ""
    @State private var leftSplitPosition: CGFloat = 0.5
    @State private var isBusy = false
   
    
    var body: some View {
        VSplitView {
            // Top section with horizontal split view
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
            .frame(minHeight: 200)
            
            // Bottom Text Editor Pane
                
                TextEditor(text: $bottomText)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding()
            .frame(maxHeight: 150)
        }
        .frame(minWidth: 600, minHeight: 400)
        .toolbar {
            Button("Clear Left") {
                leftText = ""
            }
            
            Button("Process SyntaxKit") {
              isBusy = true
              Task {
                let service = CodeGenerationService()
                let rightText : String
                do {
                  rightText = try await service.generateCode(from: leftText)
                } catch {
                  print(error)
                  isBusy = false
                  return
                }
                self.rightText = rightText
                isBusy = false
              }
            }.disabled(isBusy)
            
            Button("Clear Bottom") {
                bottomText = ""
            }
            
            Button("Copy to Bottom") {
                bottomText = leftText
            }
        }
    }
}

#Preview {
    SyntaxerView()
}
