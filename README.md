# DeadSimpleCalendar

Package provides a CalendarView which can be used to display simple calendar in your App.

You'd have to pass `getEventsNumber` and `perform` functions which will be used to:
  * `getEventsNumbers(Date?)` - will be called for each date cell for currently displaying month
  * `perform(Date)` - will be called on tap of date cell
  

# Usage


```swift
import DeadSimpleCalendar

let mockEvents = makeMockData()
    
struct ContentView: View {
    
    
    @State private var showSheet = false
    @State private var selectedDate: Date = Date()
    
    var body: some View {
        VStack{
            CalendarView(
                getEventsNumber: { date in
                    guard date != nil else { return 0 }

                    if let item = mockEvents[date!] {
                        return item
                    }
                    
                    return 0
                },
                perform: { d in
                    // we can call showSheet.toggle() here, but there is no guarantee that selectedDate will be updated by the time sheet displayed...
                    // apparently
                    selectedDate = d
                }
            )
            .onChange(of: selectedDate, perform: { d in
                showSheet.toggle()
            })
            Spacer()
            
        }
        .sheet(isPresented: $showSheet) {
            Text("\(selectedDate)")
        }
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

```

