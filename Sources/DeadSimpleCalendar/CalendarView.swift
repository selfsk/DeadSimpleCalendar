//
//  SwiftUIView.swift
//  
//
//  Created by Sergei Kononov on 11/3/21.
//

import SwiftUI

// handles presentation and actions for one cell in grid
struct CalendarCellView: View {
    var data: CalendarCellData
    var numberOfEvents: Int
    
    var body: some View {
        ZStack(alignment: .bottom){
            Text(data.body)
                .fontWeight(data.isDigit() ? .regular : .bold)
            
        }
        .frame(width: 40, height: 40)
        .background(Color.blue.opacity(Double(numberOfEvents) * 0.05))
    }
}

public struct CalendarView: View {
    
    @StateObject private var ctrl = CalendarViewModel()
    
    var getEventsNumber: (_ date: Date?) -> Int
    var perform: (_ date: Date) -> ()
    
    @State private var dragAmount: CGSize = .zero
    
    public init(getEventsNumber: @escaping (_ date: Date?) -> Int, perform: @escaping (_ date: Date) -> ()) {
        self.getEventsNumber = getEventsNumber
        self.perform = perform
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
                
                CalendarCellView(data: item, numberOfEvents: ctrl.isDisplayedMonth(item.date) ?  getEventsNumber(item.date) : 0)
                    .onTapGesture {
                        if let selectedDate = item.date {
                            if selectedDate != ctrl.selectedDate {
                                print("Selecting new date \(selectedDate)")
                                perform(selectedDate)
                            }
                            //print("Selected date \(selectedDate)")
                            ctrl.selectDate(selectedDate)
                            
                            //TODO: implement perform callback
                        }
                    }
                    .background(ctrl.isSelected(item.date) ? Color.gray.opacity(0.1) : Color.primary.opacity(0))
                    .border(border)
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
                GeometryReader { geo in
                    let itemWidth = geo.size.width
                    HStack{
                        Button("Prev") {
                            print("previous month")
                            withAnimation {
                                ctrl.goToMonth(-1)
                            }
                        }
                        Spacer()
                        Button("Today") {
                            print("go to today")
                            withAnimation{
                                ctrl.goToMonth(by: Date())
                            }
                        }
                        Button("Next") {
                            print("next month")
                            withAnimation {
                                ctrl.goToMonth(1)
                            }
                        }
                    }
                    HStack(alignment: .top, spacing: 0){
                            let m = ctrl.getMonths()
                            ForEach(m.indices, id: \.self) { month in
                                VStack{
                                    Text("\(ctrl.getMonthName(by: month)) \(ctrl.getYear())")
                                    calendarBuilder(month)
                                        
                                }
                                .padding()
                                .frame(width: itemWidth)
                                
                            }
                    }
                    .offset(x: -(getOffset(ctrl.monthIndex,itemWidth)))
                }
            }
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
