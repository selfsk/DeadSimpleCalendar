//
//  SwiftUIView.swift
//  
//
//  Created by Sergei Kononov on 11/3/21.
//

import SwiftUI

struct CalendarCellStyle {
    
    static let height: Double = 35
    static let width: Double = 35
    
    static let highlightColor = Color(UIColor.systemCyan)
    static let todayHighlighColor = Color(UIColor.systemBlue)
    static let selectedDayHighlighColor = Color(UIColor.systemBlue)
    
    static let opacityFactor = 0.2
}

// handles presentation and actions for one cell in grid
struct CalendarCellView: View {
    var data: CalendarCellData
    var numberOfEvents: Int
    
    var body: some View {
        ZStack{
            RoundedRectangle(cornerRadius: 5)
                .fill(numberOfEvents > 0 ?
                      CalendarCellStyle.highlightColor.opacity(Double(numberOfEvents) * CalendarCellStyle.opacityFactor)
                      : Color(UIColor.systemBackground))
            
            Text(data.body)
                .fontWeight(data.isDigit() ? .regular : .bold)
                .font(.system(size: 14))
            
        }
        .frame(width: CalendarCellStyle.width, height: CalendarCellStyle.height)
    }
}

struct CalendarMonthSummaryView: View {
    
    var month: String
    var numberOfEvents: Int
    
    var body: some View {
        ZStack{
            RoundedRectangle(cornerRadius: 5)
                .fill(numberOfEvents > 0 ?
                      CalendarCellStyle.highlightColor.opacity(Double(numberOfEvents) * CalendarCellStyle.opacityFactor)
                      : Color(UIColor.systemBackground))
            VStack(alignment: .center){
                Text(month)
                    .lineLimit(1)
                Text("\(numberOfEvents)")
                    .fontWeight(.thin)
                    .lineLimit(1)
                
            }
        }
        .frame(width: 110, height: 50)
    }
}
// calendar configuration, for now stores only range for years
public struct DeadSimpleCalendarConfiguration {
    var yearRange: ClosedRange<Int>

    public init(yearRange: ClosedRange<Int>) {
        self.yearRange = yearRange
    }
}

enum CalendarMode: String, CaseIterable {
    case month, year
}

public struct CalendarView: View {
    
    @StateObject private var ctrl = CalendarViewModel()
    
    var getEventsNumber: (_ date: Date?) -> Int
    var getEventsNumberInMonth: (_ month: Int, _ year: Int) -> Int
    var perform: (_ date: Date) -> ()
    var monthChanged: (_ month: Int) -> ()
    
    var configuration: DeadSimpleCalendarConfiguration
    
    @State private var currentPresentYear: Int = 0
    @State private var currentPresentMonth: String = ""
    
    @State private var dragAmount: CGSize = .zero
    @State private var calendarMode: CalendarMode = .month
    
    public init(getEventsNumber: @escaping (_ date: Date?) -> Int,
                getEventsNumberInMonth: @escaping (_ month: Int, _ year: Int) -> Int,
                perform: @escaping (_ date: Date) -> (),
                monthChanged: @escaping (_ month: Int) -> (),
                configuration: DeadSimpleCalendarConfiguration? = nil) {
        self.getEventsNumber = getEventsNumber
        self.getEventsNumberInMonth = getEventsNumberInMonth
        self.perform = perform
        self.monthChanged = monthChanged
        
        if let providedConfiguration = configuration {
            self.configuration = providedConfiguration
        } else {
            // init default configuration
            let endYear = getYearFromDate(Date())
            let startYear = endYear - 5 // go back 5 years, should be enough for most cases, right? :)
            self.configuration = DeadSimpleCalendarConfiguration(yearRange: startYear...endYear)
        }
            
    }
    
    @ViewBuilder
    func calendarYearViewBuilder() -> some View {
        let columns = [0,1,2].map{ _ in GridItem(spacing: 0)}
        
        LazyVGrid(columns: columns, spacing: 1, content: {
            ForEach(Array(ctrl.months.enumerated()), id: \.element ) { month_idx, month_name in
                CalendarMonthSummaryView(month: month_name,
                                         numberOfEvents: getEventsNumberInMonth(month_idx, currentPresentYear))
                .onTapGesture {
                    withAnimation {
                        ctrl.monthIndex = month_idx
                        calendarMode = .month
                    }
                }
            }
        })
    }
    
    @ViewBuilder
    func calendarBuilder(_ month: Int) -> some View {
        let columns = ctrl.getWeekDays().map {_ in
            GridItem(spacing: 0)
        }
        
        let griditems = ctrl.getGridContent(month)
        
        LazyVGrid(columns: columns, spacing: 1, content: {
            ForEach(0..<griditems.count, id: \.self) { idx in
                let item = griditems[idx]
                let border = ctrl.isCurrentDate(item.date) ? CalendarCellStyle.todayHighlighColor : Color.primary.opacity(0)
                let displayedMonth = ctrl.isDisplayedMonth(item.date)
                
                CalendarCellView(data: item, numberOfEvents: displayedMonth ?  getEventsNumber(item.date) : 0)
                    .onTapGesture {
                        if let selectedDate = item.date {
                            if selectedDate != ctrl.selectedDate {
                                print("Selecting new date \(selectedDate)")
                                perform(selectedDate)
                            }
                            ctrl.selectDate(selectedDate)
                            
                        }
                    }
                    .border(!ctrl.isSelected(item.date) ? border : CalendarCellStyle.selectedDayHighlighColor)
                    .onAppear {
                        if displayedMonth {
                            monthChanged(ctrl.monthIndex)
                        }
                    }
            }
        })
    }
    
    func getOffset(_ idx: Int, _ width: CGFloat) -> CGFloat {
        let offset = CGFloat(ctrl.monthIndex) * width

        return offset - dragAmount.width
        
    }
    
    public var body: some View {
        VStack{
            HStack{
                Button(action: {
                    print("previous month")
                    withAnimation {
                        ctrl.goToMonth(-1)
                    }
                }, label: {
                    Image(systemName: "chevron.left")
                }).disabled(ctrl.monthIndex == 0)
                
                Spacer()
                
                Spacer()
                Button("Today") {
                    //print("go to today")
                    withAnimation{
                        ctrl.goToMonth(by: Date())
                        currentPresentYear = ctrl.getCurrentYear()
                        calendarMode = .month
                    }
                }
                
                Button(action: {
                    //print("next month")
                    withAnimation {
                        ctrl.goToMonth(1)
                    }
                }, label: {
                    Image(systemName: "chevron.right")
                }).disabled(ctrl.monthIndex == ctrl.months.count - 1)
                
            }
            .padding([.top, .horizontal])
            .onAppear(perform: {
                currentPresentYear = ctrl.getCurrentYear()
                currentPresentMonth = ctrl.getMonthName()
            })
            
            HStack{
                Picker(currentPresentMonth, selection: $currentPresentMonth, content: {
                    ForEach(ctrl.months, id: \.self) { m in
                        Text(m)
                            .tag(m)
                    }
                })
                .frame(minWidth: 100)
                .pickerStyle(.menu)
                .onChange(of: currentPresentMonth, perform: { val in
                    //print("new month: \(val)")
                    withAnimation {
                        ctrl.goToMonth(name: val)
                    }
                })
                
                Spacer()
                Button("\(calendarMode.rawValue.capitalized)") {
                    calendarMode = calendarMode == .month ? .year : .month
                }
                
                Spacer()
                Picker(String(currentPresentYear), selection: $currentPresentYear, content: {
                    ForEach(configuration.yearRange, id: \.self) { year in
                        Text(String(year))
                            .tag(year)
                    }
                })
                
                .pickerStyle(.menu)
                .onChange(of: currentPresentYear, perform: { val in
                    //print("selected year: \(val)")
                    withAnimation {
                        ctrl.goToYear(val)
                    }
                })
                
            }
            .padding([.horizontal])
            
            GeometryReader { geo in
                if calendarMode == .month {
                    let itemWidth = geo.size.width
                    HStack(alignment: .top, spacing: 0){
                        let m = ctrl.getMonths()
                        ForEach(m.indices, id: \.self) { month in
                            calendarBuilder(month)
                                .frame(width: itemWidth)
                            
                        }
                    }
                    .offset(x: -(getOffset(ctrl.monthIndex,itemWidth)))
                } else if calendarMode == .year {
                    calendarYearViewBuilder()
                }
                
            }.frame(height: CalendarCellStyle.height * Double(ctrl.getNumberOfRows()) ) // 7 - 6 weeks max + control bar
            
        }
        .onChange(of: ctrl.monthIndex, perform: { idx in
            withAnimation {
                monthChanged(idx)
            }
            
            // update view state for month we're presenting
            currentPresentMonth = ctrl.getCurrentPresentingMonth()
        })
        .gesture(
            DragGesture()
                .onChanged({ v in
                    dragAmount = v.translation
                })
                .onEnded({v in
                    let screenWidth = UIScreen.main.bounds.width
                    let dragWidth = dragAmount.width
                    
                    withAnimation {
                        dragAmount = .zero
                        if abs(dragWidth) > screenWidth/3 && dragWidth < 0 {
                            ctrl.goToMonth(1)
                        } else if dragWidth > screenWidth/3 && dragWidth > 0 {
                            ctrl.goToMonth(-1)
                        }

                    }
                })
        )
    }

}
