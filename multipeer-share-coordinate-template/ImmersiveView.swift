//
//  ImmersiveView.swift
//  multipeer-share-coordinate-template
//
//  Created by blueken on 2024/12/20.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    @ObservedObject var peerManager : PeerManager
    
    let devicePosition = DevicePosition()
    
    @State var latestRightIndexFingerCoordinates: simd_float4x4 = .init()
    @State var latestLeftIndexFingerCoordinates: simd_float4x4 = .init()
    
    var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                content.add(immersiveContentEntity)
                
                // Put skybox here.  See example in World project available at
                // https://developer.apple.com/
            }
        }
        .onChange(of: devicePosition.latestRightIndexFingerCoordinates) {
            if (!peerManager.isUpdatePeerManagerRightIndexFingerCoordinates){
                return
            }
            self.latestRightIndexFingerCoordinates = devicePosition.latestRightIndexFingerCoordinates
            peerManager.myRightIndexFingerCoordinates = RightIndexFingerCoordinates(unixTime: Int(Date().timeIntervalSince1970), rightIndexFingerCoordinates: convertToNestedArray(matrix: latestRightIndexFingerCoordinates))
            peerManager.myBothIndexFingerCoordinate = BothIndexFingerCoordinate(unixTime: Int(Date().timeIntervalSince1970), indexFingerCoordinate: IndexFingerCoordinate(left: convertToNestedArray(matrix: latestLeftIndexFingerCoordinates), right: convertToNestedArray(matrix: latestRightIndexFingerCoordinates)))
            
        }
        .onChange(of: devicePosition.latestLeftIndexFingerCoordinates) {
            if (!peerManager.isUpdatePeerManagerBothIndexFingerCoordinate){
                return
            }
            self.latestLeftIndexFingerCoordinates = devicePosition.latestLeftIndexFingerCoordinates
            
            peerManager.myBothIndexFingerCoordinate = BothIndexFingerCoordinate(unixTime: Int(Date().timeIntervalSince1970), indexFingerCoordinate: IndexFingerCoordinate(left: convertToNestedArray(matrix: latestLeftIndexFingerCoordinates), right: convertToNestedArray(matrix: latestRightIndexFingerCoordinates)))
        }
        .onReceive(timer) { _ in
            if devicePosition.handTrackingProvider.state != .running {
                Task {
                    await devicePosition.run()
                }
            }
            print(convertToNestedArray(matrix: devicePosition.latestLeftIndexFingerCoordinates))
            print(convertToNestedArray(matrix: latestRightIndexFingerCoordinates))
        }
    }
    
    private func convertToNestedArray(matrix: simd_float4x4) -> [[Float]] {
        return [
            [matrix.columns.0.x, matrix.columns.0.y, matrix.columns.0.z, matrix.columns.0.w],
            [matrix.columns.1.x, matrix.columns.1.y, matrix.columns.1.z, matrix.columns.1.w],
            [matrix.columns.2.x, matrix.columns.2.y, matrix.columns.2.z, matrix.columns.2.w],
            [matrix.columns.3.x, matrix.columns.3.y, matrix.columns.3.z, matrix.columns.3.w]
        ]
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView(peerManager: PeerManager())
}
