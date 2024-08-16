//
//  amsearchApp.swift
//  amsearch
//
//  Created by amolonus on 01/08/2024.
//

import SwiftUI

@main
struct amsearchApp: App {
    var body: some Scene {
        WindowGroup {
            rootView
        }
    }
    
    @ViewBuilder
    private var rootView: some View {
        let viewModel: UIInboxViewModel = .init()
        RootView(viewModel: viewModel)
    }
}
