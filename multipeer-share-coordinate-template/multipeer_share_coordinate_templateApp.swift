//
//  multipeer_share_coordinate_templateApp.swift
//  multipeer-share-coordinate-template
//
//  Created by blueken on 2024/12/20.
//

import SwiftUI

@main
struct multipeer_share_coordinate_templateApp: App {
    
    @State private var appModel = AppModel()
    @StateObject private var peerManager = PeerManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView(peerManager:peerManager)
                .environment(appModel)
        }
        
        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView(peerManager:peerManager)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
