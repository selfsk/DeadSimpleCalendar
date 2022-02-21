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
    
    static let highlightColor = Color.blue
    
}

// handles presentation and actions for one cell in grid
struct CalendarCellView: View {
    var data: CalendarCellData
    var numberOfEvents: Int
    
    var body: some View {
        ZStack(alignment: .bottom){
            Text(data.body)
                .fontWeight(data.isDigit() ? .regular : .bold)
                .font(.system(size: 14))
            
        }
        .frame(width: CalendarCellStyle.width, height: CalendarCellStyle.height)
        .background(CalendarCellStyle.highlightColor.opacity(Double(numberOfEvents) * 0.05))
    }
}

// calendar configuration, for now stores only range for years
public struct DeadSimpleCalendarConfiguration {
    var yearRange: ClosedRange<Int>

    public init(yearRange: ClosedRange<Int>) {
        self.yearRange = yearRange
    }
}

public struct CalendarView: View {
    
    @StateObject private var ctrl = CalendarViewModel()
    
    var getEventsNumber: (_ date: Date?) -> Int
    var perform: (_ date: Date) -> ()
    var monthChanged: (_ month: Int) -> ()
    
    var configuration: DeadSimpleCalendarConfiguration
    /*
     okay, this strange numbers requires some clarification:
     
     Apparently in iOS14 can not figure out layout for Text() showing this state values, if they are different "length". Using dummy values, just to make layout happy.
     Values will be updated with .onAppear() handler
    */
    @State private var currentPresentYear: Int = 9999
    @State private var currentPresentMonth: String = "MonthName"
    
    @State private var dragAmount: CGSize = .zero
    
    public init(getEventsNumber: @escaping (_ date: Date?) -> Int, perform: @escaping (_ date: Date) -> (), monthChanged: @escaping (_ month: Int) -> (), configuration: DeadSimpleCalendarConfiguration? = nil) {
        self.getEventsNumber = getEventsNumber
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
    func calendarBuilder(_ month: Int) -> some View {
        let columns = ctrl.getWeekDays().map {_ in
            GridItem(spacing: 0)
        }
        
        let griditems = ctrl.getGridContent(month)
        
        LazyVGrid(columns: columns, spacing: 0, content: {
            ForEach(0..<griditems.count, id: \.self) { idx in
                let item = griditems[idx]
                let border = ctrl.isCurrentDate(item.date) ? Color.black : Color.primary.opacity(0)
                let displayedMonth = ctrl.isDisplayedMonth(item.date)
                
                CalendarCellView(data: item, numberOfEvents: displayedMonth ?  getEventsNumber(item.date) : 0)
                    .onTapGesture {
                        if let selectedDate = item.date {
                            if selectedDate != ctrl.selectedDate {
                                print("Selecting new date \(selectedDate)")
                                perform(selectedDate)
                            }
                            //print("Selected date \(selectedDate)")
                            ctrl.selectDate(selectedDate)
                            
                        }
                    }
                    .background(ctrl.isSelected(item.date) ? Color.gray.opacity(0.1) : Color.primary.opacity(0))
                    .border(border)
                    .onAppear {
                        if displayedMonth {
                            monthChanged(ctrl.monthIndex)
                        }
                    }
                    //.overlay(Rectangle().stroke(Color.black))
                    
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
            
                Picker(currentPresentMonth, selection: $currentPresentMonth, content: {
                    ForEach(ctrl.months, id: \.self) { m in
                        Text(m)
                    }
                })
                    .pickerStyle(.menu)
                    .onChange(of: currentPresentMonth, perform: { val in
                    //print("new month: \(val)")
                    withAnimation {
                        ctrl.goToMonth(name: val)
                    }
                })
                
                Picker(String(currentPresentYear), selection: $currentPresentYear, content: {
                    ForEach(configuration.yearRange, id: \.self) { year in
                        Text(String(year))
                            .tag(year)
                    }
                }).pickerStyle(.menu)
                    .onChange(of: currentPresentYear, perform: { val in
                        //print("selected year: \(val)")
                        withAnimation {
                            ctrl.goToYear(val)
                        }
                    })
                
                Spacer()
                Button("Today") {
                    //print("go to today")
                    withAnimation{
                        ctrl.goToMonth(by: Date())
                        currentPresentYear = ctrl.getCurrentYear()
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
            
            GeometryReader { geo in
                let itemWidth = geo.size.width
                HStack(alignment: .top, spacing: 0){
                    let m = ctrl.getMonths()
                    ForEach(m.indices, id: \.self) { month in
                        calendarBuilder(month)
                            .frame(width: itemWidth)
                        
                    }
                }
                .offset(x: -(getOffset(ctrl.monthIndex,itemWidth)))
                
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
