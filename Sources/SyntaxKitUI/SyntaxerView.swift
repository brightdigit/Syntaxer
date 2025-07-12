//
//  SwiftUIView.swift
//  Syntaxer
//
//  Created by Leo Dion on 7/10/25.
//

import SwiftUI
import SyntaxerCore
import os.log

class SyntaxAppDelegate : NSObject, NSApplicationDelegate {
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
}

// Custom logger that captures messages for UI display
@MainActor
class UILogger: ObservableObject {
    @Published var logMessages: [LogMessage] = []
    private let maxMessages = 100
    
    struct LogMessage: Identifiable, Sendable {
        let id = UUID()
        let timestamp: Date
        let level: OSLogType
        let message: String
        
        var displayText: String {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss.SSS"
            let timeString = timeFormatter.string(from: timestamp)
            let levelString = levelString(for: level)
            return "[\(timeString)] \(levelString): \(message)"
        }
        
        private func levelString(for level: OSLogType) -> String {
            switch level {
            case .debug: return "DEBUG"
            case .info: return "INFO"
            case .error: return "ERROR"
            case .fault: return "FAULT"
            default: return "DEFAULT"
            }
        }
    }
  @MainActor
    func log(_ message: String, level: OSLogType = .default) {
  
            let logMessage = LogMessage(timestamp: Date(), level: level, message: message)
          
            self.logMessages.append(logMessage)
            
            // Keep only the last maxMessages
            if self.logMessages.count > self.maxMessages {
                self.logMessages.removeFirst(self.logMessages.count - self.maxMessages)
            }
        
    }
    
  @MainActor
    func clear() {
            self.logMessages.removeAll()
        
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
    @StateObject private var uiLogger = UILogger()
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
            
            // Bottom Log Display Pane
            VStack {
                HStack {
                    Text("Log Output")
                        .font(.headline)
                        .padding(.top)
                    
                    Spacer()
                    
                    Button("Clear Logs") {
                        uiLogger.clear()
                    }
                    .buttonStyle(.bordered)
                    .padding(.top)
                }
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(uiLogger.logMessages) { logMessage in
                            Text(logMessage.displayText)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(colorForLogLevel(logMessage.level))
                                .textSelection(.enabled)
                                .padding(.horizontal, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding()
            }
            .frame(maxHeight: 200)
        }
        .frame(minWidth: 600, minHeight: 400)
        .toolbar {
            Button("Clear Left") {
                leftText = ""
            }
            
            Button("Process SyntaxKit") {
              isBusy = true
              uiLogger.log("Starting SyntaxKit code generation", level: .info)
              
              Task {
                let service = CodeGenerationService()
                let rightText : String
                do {
                  uiLogger.log("Generating code from DSL input", level: .debug)
                  rightText = try await service.generateCode(from: leftText)
                  uiLogger.log("Code generation completed successfully", level: .info)
                } catch {
                  uiLogger.log("Code generation failed: \(error.localizedDescription)", level: .error)
                  print(error)
                  isBusy = false
                  return
                }
                self.rightText = rightText
                isBusy = false
              }
            }.disabled(isBusy)
            
            Button("Clear Logs") {
                uiLogger.clear()
            }
            
            Button("Copy to Right") {
                rightText = leftText
            }
        }
    }
    
    private func colorForLogLevel(_ level: OSLogType) -> Color {
        switch level {
        case .debug: return .secondary
        case .info: return .primary
        case .error: return .red
        case .fault: return .purple
        default: return .primary
        }
    }
}

#Preview {
    SyntaxerView()
}
