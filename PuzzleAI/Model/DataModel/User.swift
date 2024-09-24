//
//  User.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import Foundation

struct User:Codable, Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.aiPaid == rhs.aiPaid && lhs.balance == rhs.balance
    }
    
    fileprivate static var defaultBalanceValue:Float {
        350
    }
    
    private var balance:Coint = .init(value: User.defaultBalanceValue)
    var hints:Int = 3
    var aiPaid:Bool = false
    
    init(balance: Coint? = nil, hints: Int? = nil, aiPaid: Bool? = nil) {
        if let balance {
            self.balance = balance
        }
        if let hints {
            self.hints = hints
        }
        if let aiPaid {
            self.aiPaid = aiPaid
        }
    }
    
    var getBalance:Coint {
        return .init(type: .default, value: balance.value + (Float(DB.dbHolder?.errorTokenValue ?? "") ?? 0))
    }
    
    mutating func setBalanceFromKeychain() {
        let keychain = Float(KeychainService.getToken(forKey: .balance) ?? "") ?? User.defaultBalanceValue
        balance = .init(value: keychain)
    }
    
    mutating func refillBlance(_ value:Float, override:Bool = false, canCheckError:Bool = true) -> Bool {
        setBalanceFromKeychain()
        var value = value
        if value <= 0 && !canCheckError {
            value *= -1
        }
        let error = !canCheckError ? false : (value <= 0 && balance.value < (value * -1))
        if !error {
            balance.value += value
            KeychainService.saveToken("\(balance.value)", forKey: .balance)
            print("balance updated ", value)
            return true
        } else {
            print("cannot refill")
            return false
        }
    }
}
