//
//  Reward.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import Foundation

struct Reward:Codable {
    var received:Bool = false
    var type:RewardType
    /// - Returns
    /// example: value in range 0..<<RewardType.maxCount>
    /// period - numberOfUninterruptedLogins
    var period:Int
    static func rewardAmount(_ period:Int) -> Float {
        return CointView.priceStartAmount + Float(CointView.priceMultiplyAmount * (period - 1))
    }
}

enum RewardType:CaseIterable, Codable {
    case dailyReward
    var maxCount:Int {
        return switch self {
        case .dailyReward: 7
        }
    }
}

extension [Reward] {
    func canGrand(numberOfLogins:Int, type:RewardType) -> Bool {
        let array = Array(self.sorted(by: {
            $0.period > $1.period
        }))
        let lastReward = array.last?.period ?? 0
        if lastReward == 0 && numberOfLogins == 0 {
            return true
        }
        if numberOfLogins > type.maxCount {
            return false
        } else {
            if numberOfLogins >= lastReward {
                if array.contains(where: {
                    $0.period == numberOfLogins
                }) {
                    return false
                } else {
                    return true
                }
            } else {
                return false
            }
        }
    }
    
    var containsUnreceivedRewards: Bool {
        contains(where: {!$0.received && $0.type == .dailyReward})
    }
}
