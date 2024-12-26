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
                        // 腕と人差し指の指先の座標の取得
                        guard let originTransform = latestHandTracking.left?.originFromAnchorTransform else { return }
                        guard let handSkeletonAnchorTransform = latestHandTracking.left?.handSkeleton?.joint(.indexFingerTip).anchorFromJointTransform else { return }
                        // 人差し指の指先の座標を計算
                        latestLeftIndexFingerCoordinates = originTransform * handSkeletonAnchorTransform
                    } else if anchor.chirality == .right {
                        latestHandTracking.right = anchor
                        // 腕と人差し指の指先の座標の取得
                        guard let originTransform = latestHandTracking.right?.originFromAnchorTransform else { return }
                        guard let handSkeletonAnchorTransform = latestHandTracking.right?.handSkeleton?.joint(.indexFingerTip).anchorFromJointTransform else { return }
                        // 人差し指の指先の座標を計算
                        latestLeftIndexFingerCoordinates = originTransform * handSkeletonAnchorTransform
                    }
                default:
                    break
                }
            }
        }
    }        
}
