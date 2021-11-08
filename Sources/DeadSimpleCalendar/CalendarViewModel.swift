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
    
    @Published var calendarItems: [CalendarCellData] = []
    @Published var selectedDate: Date?
    
    @Published var monthIndex: Int = 0

    let dateFormatter = DateFormatter()
    
    var months: [String] = []

    
    let cal = Calendar.current
    
    init() {
        months = dateFormatter.monthSymbols
        
        let month = getMonthName()
        monthIndex = months.firstIndex(of: month) ?? 0
    }
    
    func goToMonth(by date: Date) {
        let mn = cal.component(.month, from: date)
        
        monthIndex = mn - 1
    }
    
    func getMonths() -> [String] {
        months
    }
    
    func getCurrentMonth() -> String {
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
    
    func getYear() -> String {
        let y = cal.component(.year, from: currentDate)
        
        return String(y)
    }
    
    func getMonthName() -> String {
        let ms = months[cal.component(.month, from: currentDate)-1]
        
        return ms
    }
    
    func goToMonth(_ step: Int) {
        print("Move to month with step=\(step)")
        if step < 0 && monthIndex > 0 {
            monthIndex -= 1
        } else if step > 0 && monthIndex < (months.count - 1) {
            monthIndex += 1
        }
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
        var components = Calendar.current.dateComponents([.year], from: currentDate)
        components.hour = 0
        components.minute = 0
        components.day = 1
        components.month = monthNumber + 1
        
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
        
        return out
    }
    
}
