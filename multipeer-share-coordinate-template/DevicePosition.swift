//
//  DevicePosition.swift
//  multipeer-share-coordinate-template
//
//  Created by blueken on 2024/12/20.
//

import Observation
import ARKit

struct HandsUpdates {
    var left: HandAnchor?
    var right: HandAnchor?
}

@Observable
class DevicePosition {
    
    let arKitSession = ARKitSession()
    
    var handTrackingProvider = HandTrackingProvider()
    var latestHandTracking: HandsUpdates = .init(left: nil, right: nil)
    
    var latestRightIndexFingerCoordinates: simd_float4x4 = .init()
    var latestLeftIndexFingerCoordinates: simd_float4x4 = .init()
    
    func run() async {
        Task {
            try await arKitSession.run([handTrackingProvider])
            for await update in handTrackingProvider.anchorUpdates {
                switch update.event {
                case .updated:
                    let anchor = update.anchor
                    guard anchor.isTracked else { continue }
                    if anchor.chirality == .left {
                        latestHandTracking.left = anchor
                        self.latestLeftIndexFingerCoordinates = anchor.originFromAnchorTransform
                    } else if anchor.chirality == .right {
                        latestHandTracking.right = anchor
                        self.latestRightIndexFingerCoordinates = anchor.originFromAnchorTransform
                    }
                default:
                    break
                }
            }
        }
        
    }
}
