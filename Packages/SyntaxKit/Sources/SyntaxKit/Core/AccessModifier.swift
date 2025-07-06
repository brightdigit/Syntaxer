//
//  AccessModifier.swift
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

/// Represents Swift access modifiers.
public enum AccessModifier: CaseIterable, Sendable, Equatable {
  case `public`
  case `private`
  case `internal`
  case `fileprivate`
  case `open`

  /// Returns the corresponding SwiftSyntax Keyword for this access modifier.
  public var keyword: Keyword {
    switch self {
    case .public:
      return .public
    case .private:
      return .private
    case .internal:
      return .internal
    case .fileprivate:
      return .fileprivate
    case .open:
      return .open
    }
  }
}

extension Keyword {
  /// Creates a Keyword from an AccessModifier.
  /// - Parameter accessModifier: The access modifier to convert.
  public init(_ accessModifier: AccessModifier) {
    self = accessModifier.keyword
  }
}
