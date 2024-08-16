//
//  CustomMailSearch.swift
//  amsearch
//
//  Created by amolonus on 11/08/2024.
//

import SwiftUI



struct Email: Identifiable, Hashable {
    let id: UUID = UUID()
    let from: String
    let message: String
}

extension Email {
    static let fetchedEmails: [Email] = [
        Email(from: "alice@example.com", message: "Hello Bob, how are you?"),
        Email(from: "bob@example.com", message: "Hi Alice, I'm doing well. How about you?"),
        Email(from: "carol@example.com", message: "Reminder: Team meeting at 3 PM."),
        Email(from: "dan@example.com", message: "Can we reschedule our appointment?"),
        Email(from: "eve@example.com", message: "Here's the report you asked for."),
        Email(from: "frank@example.com", message: "Check out this cool new feature!"),
        Email(from: "grace@example.com", message: "Don't forget to submit your timesheet."),
        Email(from: "heidi@example.com", message: "Happy Birthday!"),
        Email(from: "ivan@example.com", message: "Can you review the attached document?"),
        Email(from: "judy@example.com", message: "Let's catch up soon.")
    ]
}

extension Email {
    static let searchResults: [Email] = [
        Email(from: "john.doe@amazon.com", message: "Amazon quarterly update."),
        Email(from: "jane.smith@apple.com", message: "Apple new product launch."),
        Email(from: "mark.jones@google.com", message: "Google security alert."),
        Email(from: "susan.taylor@amazon.com", message: "Amazon Prime Day specials."),
        Email(from: "michael.johnson@apple.com", message: "Apple software update."),
        Email(from: "laura.wilson@google.com", message: "Google workspace new features.")
    ]
}

enum InboxViewState: CaseIterable {
    case emails
    case search
}

enum EmailsListState: CaseIterable {
    case data
    case loading
    case empty
    case error
}

extension EmailsListState {
    var displayName: String {
        switch self {
        case .data:
            "EmailsListState - Emails"
        case .loading:
            "EmailsListState - Loading"
        case .empty:
            "EmailsListState - Empty"
        case .error:
            "EmailsListState - Error"
        }
    }
}

enum SearchViewState: CaseIterable {
    case results
    case searching
    case empty
    case error
}

extension SearchViewState {
    var displayName: String {
        switch self {
        case .results:
            "SearchViewState - Data"
        case .searching:
            "SearchViewState - Searching"
        case .empty:
            "SearchViewState - Empty"
        case .error:
            "SearchViewState - Error"
        }
    }
}

protocol InboxViewModel: ObservableObject {
    var emails: [Email] { get }
    var searchResults: [Email] { get }
    var searchQueries: [String] { get }
    var searchText: String { get set }
    
    var inboxViewState: InboxViewState { get }
    var emailsListState: EmailsListState { get }
    var searchState: SearchViewState { get }
    
    func fetchNews() async
    func performSearch() async
    func observeSearchMode(newValue: Bool)
}

final class UIInboxViewModel: InboxViewModel {
    @Published var searchText: String = ""
    @Published private(set) var emailsListState: EmailsListState = .data
    @Published private(set) var inboxViewState: InboxViewState = .emails
    @Published private(set) var searchState: SearchViewState = .empty
    
    @Published var emails: [Email] = []
    @Published var searchResults: [Email] = []
    @Published var searchQueries: [String] = []
    
    @MainActor
    func fetchNews() async {
        //Setting viewState to loading
        emailsListState = .loading
        
        //Simulating fetching operation
        try! await Task.sleep(for: .seconds(3))
        
        //Returning fetched emails
        emails = Email.fetchedEmails
        
        //Setting viewState
        emailsListState = !emails.isEmpty ? .data : .empty
    }
    
    @MainActor
    func performSearch() async {
        do {
            self.searchState = .searching
            //Simulating fetching operation
            try await Task.sleep(for: .seconds(3))
            
            //Appending search results
            self.searchQueries.append(searchText)
            
            //Returning search results
            self.searchResults = Email.searchResults
            
            //Changing searchView state depending on searchResults
            self.searchState = !searchResults.isEmpty ? .results : .empty
        } catch let error {
            self.searchState = .error
        }
    }
    
    
    //Used to react work in pair with .onChange and to react on change of environment value .isSearching
    func observeSearchMode(newValue: Bool) {
        if newValue {
            inboxViewState = .search
        } else {
            inboxViewState = .emails
            searchState = .empty
        }
    }
}

final class TestInboxViewModel: InboxViewModel {
    @Published var searchText: String = ""
    @Published private(set) var emailsListState: EmailsListState
    @Published private(set) var inboxViewState: InboxViewState
    @Published private(set) var searchState: SearchViewState
    
    @Published var emails: [Email] = []
    @Published var searchResults: [Email] = []
    @Published var searchQueries: [String] = []
    
    init(emailsListState: EmailsListState = .data,
         inboxViewState: InboxViewState = .emails,
         searchState: SearchViewState = .empty) {
        self.emailsListState = emailsListState
        self.inboxViewState = inboxViewState
        self.searchState = searchState
        
        switch emailsListState {
        case .data:
            self.emails = Email.fetchedEmails
        case .empty, .loading, .error:
            self.emails = []
        }
        
        switch searchState {
        case .results:
            self.searchResults = Email.searchResults
        case .empty, .searching, .error:
            self.searchResults = []
        }
    }
    
    
    @MainActor
    func fetchNews() async {}
    
    @MainActor
    func performSearch() async {}
    
    func observeSearchMode(newValue: Bool) {
        if newValue {
            inboxViewState = .search
        } else {
            inboxViewState = .emails
            searchState = .empty
        }
    }
}

struct RootView<ViewModel: InboxViewModel>: View {
    @StateObject var viewModel: ViewModel
    
    var body: some View {
        NavigationStack {
            InboxView(viewModel: viewModel)
                .navigationTitle("All Inboxes")
                .searchable(text: $viewModel.searchText)
                .task {
                    await viewModel.fetchNews()
                }
                .refreshable {
                    await viewModel.fetchNews()
                }
                .onSubmit(of: .search) {
                    Task {
                        await viewModel.performSearch()
                    }
                }
        }
    }
}


struct InboxView<ViewModel: InboxViewModel>: View {
    @Environment(\.isSearching) private var isSearching
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        Group {
            switch viewModel.inboxViewState {
            case .emails:
                EmailsListView(viewModel: viewModel)
            case .search:
                SearchView(viewModel: viewModel)
            }
        }
        .onChange(of: isSearching) { oldValue, newValue in
            viewModel.observeSearchMode(newValue: newValue)
        }
        .animation(.bouncy, value: viewModel.emailsListState)
        .animation(.linear, value: viewModel.searchState)
        .toolbar {
            inboxViewToolbar
        }
        .toolbar(viewModel.inboxViewState == .search ? .hidden : .visible, for: .bottomBar)
    }
}

extension InboxView {
    @ToolbarContentBuilder
    var inboxViewToolbar: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            Button { } label: {
                Image(systemName:"line.3.horizontal.decrease.circle")
            }
        }
        ToolbarItem(placement: .bottomBar) {
            Spacer()
        }
        Group {
            switch viewModel.emailsListState {
            case .data:
                ToolbarItem(placement: .bottomBar) {
                    VStack {
                        Text("Updated Just Now")
                            .font(.caption)
                        Text("11 Unread")
                            .font(.system(size: 12, weight: .ultraLight, design: .default))
                    }
                }
            case .loading:
                ToolbarItem(placement: .bottomBar) {
                    VStack {
                        Text("Checking for Mail...")
                            .font(.caption)
                    }
                }
            case .empty:
                ToolbarItem(placement: .bottomBar) {
                    EmptyView()
                }
            case .error:
                ToolbarItem(placement: .bottomBar) {
                    EmptyView()
                }
            }
        }
        ToolbarItem(placement: .bottomBar) {
            Spacer()
        }
        ToolbarItem(placement: .bottomBar) {
            Button { } label: {
                Image(systemName:"square.and.pencil")
            }
        }
    }
}

struct EmailsListView<ViewModel: InboxViewModel>: View {
    @ObservedObject var viewModel: ViewModel
    var body: some View {
        Group {
            switch viewModel.emailsListState {
            case .data:
                emailsList
            case .loading:
                LoaderView()
                    .redacted(reason: .placeholder)
            case .empty:
                ContentUnavailableView("No emails available.", systemImage: "magnifyingglass")
            case .error:
                errorStateView
            }
        }
    }
    
    private var emailsList: some View {
        List {
            ForEach(viewModel.emails) { email in
                Text(email.message)
                
            }
        }
    }
    
    private var errorStateView: some View {
        VStack {
            Label("Error fetching.", systemImage: "arrow.counterclockwise")
            Button {
                Task {
                    await viewModel.fetchNews()
                }
            } label: {
                Text("Retry")
            }
        }
    }
}

struct SearchView<ViewModel: InboxViewModel>: View {
    @ObservedObject var viewModel: ViewModel
    var body: some View {
        Group {
            switch viewModel.searchState {
            case .results:
                searchResultsView
            case .searching:
                LoaderView()
                    .redacted(reason: .placeholder)
            case .empty:
                searchQueriesHistoryView
            case .error:
                Text("Search failed.")
            }
        }
    }
    private var searchResultsView: some View {
        List {
            ForEach(viewModel.searchResults) { searchResult in
                Text(searchResult.message)
            }
        }
    }
    
    private var searchQueriesHistoryView: some View {
        List {
            ForEach(viewModel.searchQueries, id:\.self) { searchQuery in
                Label("\(searchQuery)", systemImage: "clock")
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 5)
            }
        }
        .listStyle(.plain)
    }
}


struct LoaderView: View {
    var body: some View {
        List {
            ForEach(Email.fetchedEmails) { email in
                Text(email.message)
            }
        }
    }
}

#Preview {
    let viewModel: UIInboxViewModel = .init()
    return RootView(viewModel: viewModel)
}


// Preview for EmailsListView
struct EmailsListView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(EmailsListState.allCases, id: \.self) { state in
            EmailsListView(viewModel: TestInboxViewModel(emailsListState: state))
                .previewDisplayName(state.displayName)
        }
    }
}

// Preview for SearchView
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(SearchViewState.allCases, id: \.self) { state in
            SearchView(viewModel: TestInboxViewModel(searchState: state))
                .previewDisplayName(state.displayName)
        }
    }
}
