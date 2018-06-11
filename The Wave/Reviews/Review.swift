//
//  Review.swift
//  ThePost
//
//  Created by Andrew Robinson on 1/13/17.
//  Copyright © 2017 XYello, Inc. All rights reserved.
//

import UIKit

class Review: NSObject {
    
    var reviewerId: String!
    var comment: String!
    var timePostedString: String!
    var rating: Int!
    
    var date: Date! {
        get {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yy HH:mm:ss"
            formatter.timeZone = TimeZone(identifier: "America/New_York")
            return formatter.date(from: timePostedString)
        }
    }
    var relativeDate: String! {
        get {
            let now = Date()
            
            let components = Calendar.current.dateComponents([.year, .month, .weekOfYear, .day, .hour, .minute, .second], from: date, to: now)
            
            if let years = components.year, years > 0 {
                return "\(years) year\(years == 1 ? "" : "s") ago"
            }
            
            if let months = components.month, months > 0 {
                return "\(months) month\(months == 1 ? "" : "s") ago"
            }
            
            if let weeks = components.weekOfYear, weeks > 0 {
                return "\(weeks) week\(weeks == 1 ? "" : "s") ago"
            }
            if let days = components.day, days > 0 {
                guard days > 1 else { return "yesterday" }
                
                return "\(days) day\(days == 1 ? "" : "s") ago"
            }
            
            if let hours = components.hour, hours > 0 {
                return "\(hours) hour\(hours == 1 ? "" : "s") ago"
            }
            
            if let minutes = components.minute, minutes > 0 {
                return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
            }
            
            if let seconds = components.second, seconds > 30 {
                return "\(seconds) second\(seconds == 1 ? "" : "s") ago"
            }
            
            return "just now"
        }
    }

}
