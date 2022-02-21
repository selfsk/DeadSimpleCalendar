//
//  File.swift
//  
//
//  Created by Sergei Kononov on 11/3/21.
//

import Foundation

/* Helper function which generates a mock data that can be used for experiments
 *
 * Creates dictionary with date as key and random number of events for provided year.
 */
public func makeMockData(numberOfDates: Int = 50, year: Int = 2021) -> [Date:Int] {
    
    var out: [Date:Int] = [:]
    
    for _ in 0..<numberOfDates {
        let year = year
        let month = Int.random(in: 1..<12)
        let day = Int.random(in: 1..<25) // don't want to deal with Feburary and 30/31 days...
        
        let c = DateComponents(year: year, month: month, day: day)
        let d = Calendar.current.date(from: c)
        
        // random number of events
        out[d!] = Int.random(in: 0..<5)
    }
    
    return out
}

//static version for getCurrentYear, always uses today as date
public func getYearFromDate(_ date: Date) -> Int {
    let y = Calendar.current.component(.year, from: date)
    return y
}
