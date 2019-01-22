//
//  Date+TimeAgo.swift
//  picture
//
//  Created by Jason Goodney on 1/4/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import Foundation

extension Date {
    
    func testingTimestamp() -> String {
        return dateTimeFormatter(dateFormat: "h:mm:ss")
    }
    
    func testingIsWithinRecentTime() -> Bool {
        let calendar = Calendar.current
        let hourAgo = calendar.date(byAdding: .hour, value: -1, to: Date())!
        
        if hourAgo < self {
            let diff = Calendar.current.dateComponents([.minute], from: self, to: Date()).minute ?? 0
            if diff <= 10 {
                return true
            }
        }
        
        return false
    }
    
    func messageDateTimestamp() -> String {
        if isToday() {
            return time()
        } else if self.isWithinThePastWeek() {
            return dateTimeFormatter(dateFormat: "E h:mm a")
        }  else {
            return dateTimeFormatter(dateFormat: "MMM d")
        }
    }
    
    func time() -> String {
        
        return dateTimeFormatter(dateFormat: "h:mm a")
    }
    
    private func dateTimeFormatter(dateFormat: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        return formatter.string(from: self)
    }
    
    func timeAgoDisplay() -> String {
        
        let calendar = Calendar.current
        let minuteAgo = calendar.date(byAdding: .minute, value: -1, to: Date())!
        let hourAgo = calendar.date(byAdding: .hour, value: -1, to: Date())!
        let dayAgo = calendar.date(byAdding: .day, value: -1, to: Date())!
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        
        if minuteAgo < self {
            let diff = Calendar.current.dateComponents([.second], from: self, to: Date()).second ?? 0
            if diff < 20 {
                return "just now"
            } else {
                return "\(diff)s"
            }
        } else if hourAgo < self {
            let diff = Calendar.current.dateComponents([.minute], from: self, to: Date()).minute ?? 0
            return "\(diff)m"
        } else if dayAgo < self {
            let diff = Calendar.current.dateComponents([.hour], from: self, to: Date()).hour ?? 0
            return "\(diff)h"
        } else if weekAgo < self {
            let diff = Calendar.current.dateComponents([.day], from: self, to: Date()).day ?? 0
            return "\(diff)d"
        }
        let diff = Calendar.current.dateComponents([.weekOfYear], from: self, to: Date()).weekOfYear ?? 0
        return "\(diff)w"
    }
    
    func isWithinThePast24Hours() -> Bool {
        let calendar = Calendar.current
        let dayAgo = calendar.date(byAdding: .day, value: -1, to: Date())!
        
        if dayAgo < self {
            let diff = Calendar.current.dateComponents([.hour], from: self, to: Date()).hour ?? 0
            if diff <= 24 {
                return true
            }
        }
        
        return false
    }
    
    func isWithinThePastWeek() -> Bool {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        
        if weekAgo < self {
            let diff = Calendar.current.dateComponents([.day], from: self, to: Date()).day ?? 0
            if diff <= 7 {
                return true
            }
        }
        
        return false
    }
    
    func isToday() -> Bool {
        return Calendar.current.isDateInToday(self)
    }
}
