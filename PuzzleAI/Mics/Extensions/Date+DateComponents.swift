//
//  Date.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import Foundation

extension Date {
    func dateDifference(to endDate: Date? = nil) -> DateComponents {
        let calendar = Calendar.current
        let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        let dateComponents = calendar.dateComponents(components, from: self, to: endDate ?? .init())
        return dateComponents
    }
    
    var dateComponents:DateComponents? {
        let results = Calendar.current.dateComponents([.calendar, .year, .month, .day, .hour, .minute, .second], from: self)
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .current
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return results
    }
}
