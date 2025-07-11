//
//  SwitchLet.swift
//  SyntaxKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import SwiftSyntax

/// A value binding pattern for use in switch cases.
public struct SwitchLet: PatternConvertible, CodeBlock {
  internal let name: String

  /// Creates a value binding pattern for a switch case.
  /// - Parameter name: The name of the variable to bind.
  public init(_ name: String) {
    self.name = name
  }

  public var patternSyntax: PatternSyntax {
    let identifier = IdentifierPatternSyntax(
      identifier: .identifier(name)
    )
    return PatternSyntax(
      ValueBindingPatternSyntax(
        bindingSpecifier: .keyword(.let, trailingTrivia: .space),
        pattern: identifier
      )
    )
  }

  public var syntax: SyntaxProtocol {
    // For CodeBlock conformance, return the pattern syntax
    patternSyntax
  }
}
