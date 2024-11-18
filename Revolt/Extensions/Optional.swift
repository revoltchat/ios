//
//  Optional.swift
//  Revolt
//
//  Created by Angelo on 18/11/2024.
//

extension Optional {
    enum Error: Swift.Error {
        case unexpectedNil
    }
    
    func unwrapped() throws -> Wrapped {
        if let self { return self }
        else { throw Error.unexpectedNil }
    }
}
