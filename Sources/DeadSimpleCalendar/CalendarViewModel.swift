//
//  File.swift
//  
//
//  Created by Sergei Kononov on 11/3/21.
//

import Foundation

// Cell Data container
// holds body and date (optional, we might have empty cells too)
struct CalendarCellData {
    var body: String
    var date: Date?
    
    func isDigit() -> Bool {
        if let _ = Int(body) {
            return true
        }
        
        return false
    }
    
}

class CalendarViewModel: ObservableObject {
    
    var currentDate: Date = Date()
    
    var numberOfRow: [Int:Int] = [:]
    
    // container year number (2022, 2017, 1983, etc.) we are displaying
    @Published var yearNumber: Int?
    
    // will store date we tap on calendar
    @Published var selectedDate: Date?
    
    // store current month index (0 - Jan, 11 - Dec) we're displaying
    @Published var monthIndex: Int = 0

    let dateFormatter = DateFormatter()
    
    var months: [String] = []
    
    let cal = Calendar.current
    
    init() {
        months = dateFormatter.monthSymbols
        
        // init year number to our current date - "Today"
        yearNumber = getCurrentYear()
        
        let month = getMonthName()
        monthIndex = months.firstIndex(of: month) ?? 0
    }
    
    // update monthIndex according to provided Date
    func goToMonth(by date: Date) {
        let mn = cal.component(.month, from: date)
        
        monthIndex = mn - 1
    }
    
    func getMonths() -> [String] {
        months
    }
        
    func getCurrentPresentingMonth() -> String {
        return months[monthIndex]
    }
    
    func getWeekDays() -> [String] {
        cal.weekdaySymbols
    }
    
    func getMonthName(by idx: Int) -> String {
        cal.monthSymbols[idx]
    }
    
    func selectDate(_ date: Date) {
        if isSelected(Optional(date)) {
            selectedDate = nil
            return
        }
        
        selectedDate = date
    }
    
    func isDisplayedMonth(_ date: Date?) -> Bool {
        guard date != nil else { return false }
        
        let comps: Set<Calendar.Component> = [.month]
        
        let targetDate = cal.dateComponents(comps, from: date!)
        
        return
            targetDate.month == monthIndex + 1
    }
    
    // returns true if date is a "Today", compares month, year and day
    func isCurrentDate(_ date: Date?) -> Bool {
        guard date != nil else { return false }
        
        let components: Set<Calendar.Component> = [.month, .year, .day]
        
        let targetDate = cal.dateComponents(components, from: date!)
        let current = cal.dateComponents(components, from: currentDate)
        
        let rc =  targetDate.month == current.month &&
            targetDate.year == current.year &&
        targetDate.day == current.day
        
        return rc
    }
    
    func isSelected(_ date: Date?) -> Bool {
        guard (selectedDate != nil) else { return false }
        
        return selectedDate! == date
    }
        
    func getCurrentYear() -> Int {
        let y = cal.component(.year, from: currentDate)
        return y
    }
    
    func getYear() -> String {
        return String(getCurrentYear())
    }
    
    func getMonthName() -> String {
        let ms = months[cal.component(.month, from: currentDate)-1]
        
        return ms
    }
    
    func goToMonth(name: String) {
        if let idx = months.firstIndex(of: name) {
            monthIndex = idx
        }
    }
    
    func goToMonth(_ step: Int) {
        print("Move to month with step=\(step)")
        if step < 0 && monthIndex > 0 {
            monthIndex -= abs(step)
        } else if step > 0 && monthIndex < (months.count - 1) {
            monthIndex += step
        }
    }
    
    func goToYear(_ year: Int) {
        yearNumber = year
    }
    func findFirstDayWeekDay(for date: Date) -> String {
        
        let daySymbol = dateFormatter.shortWeekdaySymbols[Calendar.current.component(.weekday, from: date) - 1]
        //print("--> weekday \(daySymbol)")
        
        return daySymbol
    }
    
    func getGridContent(_ monthNumber: Int) -> [CalendarCellData] {
        
        //print("get grid for \(monthNumber)")
        var out: [CalendarCellData] = []
        for item in dateFormatter.shortWeekdaySymbols {
            out.append(CalendarCellData(body: item))
        }

        // find weekday for first day of month
        var components = Calendar.current.dateComponents([], from: currentDate)
        components.hour = 0
        components.minute = 0
        components.day = 1
        components.month = monthNumber + 1
        components.year = yearNumber
        
        let date = Calendar.current.date(from: components)
        
        let daysRange = Calendar.current.range(of: .day, in: .month, for: date!)
        let firstDaySymbol = findFirstDayWeekDay(for: date!)
        //print("week day of 1st - \(firstDaySymbol) \(date!)")
        
        for symbol in dateFormatter.shortWeekdaySymbols {
            if symbol == firstDaySymbol {
                break
            }
            
            out.append(CalendarCellData(body: ""))
        }
        
        for n in daysRange! {
            var temp = cal.dateComponents([.day, .month, .year], from: date!)
            temp.day = n
            let temp_date = cal.date(from: temp)
            
            out.append(CalendarCellData(body: String(n), date: temp_date))
        }
        
        numberOfRow[monthNumber] = out.count
        
        return out
    }
    
    func getNumberOfRows() -> Int {

        if let num = numberOfRow[monthIndex] {
            let rows = num/7
            return rows + 1 // +1 for control above calendar
        }
        
        return 1
    }
    
}
