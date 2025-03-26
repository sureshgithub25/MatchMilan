//
//  MatchMilanApp.swift
//  MatchMilan
//
//  Created by Suresh Kumar on 26/03/25.
//

import SwiftUI

@main
struct MatchMilanApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
