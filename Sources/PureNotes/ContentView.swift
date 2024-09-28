import SwiftUI

struct Note: Hashable, Identifiable, Codable {
    var id: Int
    var title: String
    var text: String
    var snippet: String
    var modifyDate: Double
    
    var modifyDateDate: Date {
        return Date(timeIntervalSince1970: modifyDate + 978307200)
    }
    
    var modifyDateString: String {
        let date = modifyDateDate
        let formatter = DateFormatter()
        formatter.dateFormat = "M/dd/yy"
        return formatter.string(from: date)
    }
}

func groupNotesByDate(_ notes: [Note]) -> [(String, [Note])] {
    let now = Date()
    var groupedNotes: [(String, [Note])] = []

    var last24Hours: [Note] = []
    var last7Days: [Note] = []
    var last30Days: [Note] = []
    
    // Dictionary to store notes by month-year
    var monthlyNotes: [String: [Note]] = [:]
    
    for note in notes {
        let noteDate = note.modifyDateDate // Use the computed property
        
        if now.timeIntervalSince(noteDate) < 24 * 60 * 60 {
            last24Hours.append(note)
        } else if now.timeIntervalSince(noteDate) < 7 * 24 * 60 * 60 {
            last7Days.append(note)
        } else if now.timeIntervalSince(noteDate) < 30 * 24 * 60 * 60 {
            last30Days.append(note)
        } else {
            let calendar = Calendar.current
            let year = calendar.component(.year, from: noteDate)
            let month = calendar.component(.month, from: noteDate)
            
            // Construct the month-year key
            let monthYearKey = "\(month)/\(year)"
            
            // Append the note to the corresponding month-year key in the dictionary
            if monthlyNotes[monthYearKey] != nil {
                monthlyNotes[monthYearKey]?.append(note)
            } else {
                monthlyNotes[monthYearKey] = [note]
            }
        }
    }

    // Append last time-based notes with sorting
    if !last24Hours.isEmpty {
        groupedNotes.append(("Last 24 Hours", last24Hours.sorted(by: { $0.modifyDate > $1.modifyDate })))
    }
    if !last7Days.isEmpty {
        groupedNotes.append(("Last 7 Days", last7Days.sorted(by: { $0.modifyDate > $1.modifyDate })))
    }
    if !last30Days.isEmpty {
        groupedNotes.append(("Last 30 Days", last30Days.sorted(by: { $0.modifyDate > $1.modifyDate })))
    }

    // Append monthly notes from the dictionary, sorting each group by modifyDate
    for (key, notes) in monthlyNotes.reversed() {
        groupedNotes.append((key, notes.sorted(by: { $0.modifyDate > $1.modifyDate })))
    }

    return groupedNotes
}

public struct ContentView: View {
    @State private var notes: [Note] = []
    @State private var error: String? = nil
    @State private var searchText: String = ""
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack {
                if !notes.isEmpty {
                    List {
                        Section {
                            HStack {
                                Image(systemName: "magnifyingglass").padding(.leading, 10)
                                
                                TextField("Search", text: $searchText)
                                    .opacity(0.7)
                                    .textFieldStyle(.plain)
                                    .padding(.leading, -15)
                                
                                Spacer()
                                
                                if !searchText.isEmpty {
                                    Button(action: {
                                        searchText = ""
                                    }) {
                                        Image(systemName: "xmark")
                                            .padding(.trailing)
                                    }
                                }
                            }.padding(.vertical, -5)
                        }
                        
                        let filteredNotes = notes.filter { note in
                            searchText.isEmpty || note.title.contains(searchText) || note.text.contains(searchText)
                        }
                        
                        let groupedNotes = groupNotesByDate(filteredNotes)
                        
                        ForEach(groupedNotes, id: \.0) { group in
                            Section(header: Text(group.0)) {
                                ForEach(group.1.sorted(by: { $0.modifyDate > $1.modifyDate })) { note in
                                    NavigationLink(destination: NoteView(noteIndex: notes.firstIndex(where: { $0.id == note.id })!, notes: $notes)) {
                                        VStack(alignment: .leading) {
                                            Text(note.title).bold().font(.body).lineLimit(1)
                                            Text("\(note.modifyDateString) \(note.snippet)").opacity(0.6).font(.caption).lineLimit(1)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if let error = error {
                        Text(error)
                    } else {
                        ProgressView()
                    }
                }
            }
            .navigationTitle("Notes")
            .onAppear {
                Task.detached {
                    do {
                        let jsonData = try Data(contentsOf: URL(fileURLWithPath: "/sdcard/Documents/PureNotes.json"))
                        let decoder = JSONDecoder()
                        let decodedArray = try decoder.decode([Note].self, from: jsonData)
                        DispatchQueue.main.async {
                            notes = decodedArray
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.error = error.localizedDescription
                        }
                    }
                }
            }
        }
    }
}

struct NoteView: View {
    let noteIndex: Int
    @Binding var notes: [Note]
    
    var note: Note {
        notes[noteIndex]
    }
    
    var body: some View {
        TextEditor(text: .constant(note.text))
            .padding()
            .navigationTitle(note.title)
    }
}

