//
//  OptionSet.swift
//  Revolt
//
//  Created by Angelo on 26/09/2024.
//

import Foundation

public struct OptionSetIterator<Element: OptionSet>: IteratorProtocol, Sequence where Element.RawValue == Int {
    private let value: Element
    
    public init(element: Element) {
        self.value = element
    }
    
    private lazy var remainingBits = value.rawValue
    private var bitMask = 1
    
    public mutating func next() -> Element? {
        while remainingBits != 0 {
            defer { bitMask = bitMask &* 2 }
            if remainingBits & bitMask != 0 {
                remainingBits = remainingBits & ~bitMask
                return Element(rawValue: bitMask)
            }
        }
        return nil
    }
}

extension OptionSet where Self.RawValue == Int {
    public func makeIterator() -> OptionSetIterator<Self> {
        return OptionSetIterator(element: self)
    }
}
