//
//  TransformationMatrixPreparationView.swift
//  multipeer-share-coordinate-template
//
//  Created by blueken on 2024/12/18.
//

import SwiftUI


struct TransformationMatrixPreparationView: View {
    @ObservedObject var peerManager = PeerManager()
    @Binding var sharedCoordinateState: SharedCoordinateState
    var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var time: String = ""
    
    var body: some View {
        VStack{
            HStack{
                Text("MyId:\(peerManager.peerID.hash)").font(.title)
                Text(time)
            }
            Divider()
            NavigationStack {
                switch peerManager.transformationMatrixPreparationState {
                case .initial:
                    initialView(peerManager:peerManager)
                case .searching:
                    searchingPeerView(peerManager:peerManager)
                case .selectingHost:
                    selectingPeerHostView(peerManager:peerManager)
                case .selectingClient:
                    selectingPeerClientView(peerManager:peerManager)
                case .rightIndexFingerCoordinatesHost:
                    rightIndexFingerCoordinatesHostView(peerManager:peerManager)
                case .rightIndexFingerCoordinatesClient:
                    rightIndexFingerCoordinatesClientView(peerManager:peerManager)
                case .bothIndexFingerCoordinateHost:
                    bothIndexFingerCoordinateHostView(peerManager:peerManager)
                case .bothIndexFingerCoordinateClient:
                    bothIndexFingerCoordinateClientView(peerManager:peerManager)
                case .prepared:
                    preparedView(peerManager:peerManager, sharedCoordinateState: $sharedCoordinateState)
                }
            }
            Spacer()
            Divider()
            Text("Received Messages:\(peerManager.receivedMessage)")
                .font(.headline)
        }.onAppear {
            peerManager.start()
        }
        .onReceive(timer) { _ in
            self.time = "\(Date())"
        }
    }
}

struct initialView: View {
    @ObservedObject var peerManager = PeerManager()
    
    var body: some View {
        VStack {
            if peerManager.peerID != nil {
                Button(action: {
                    peerManager.firstSendMessage()
                    peerManager.transformationMatrixPreparationState = .searching
                }){
                    Text("初期設定を開始します")
                }
            } else {
                Text("端末のIDが認識できません")
            }
        }
    }
}

struct searchingPeerView: View {
    @ObservedObject var peerManager = PeerManager()
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack {
            Text("1. 近くにいる人を探す").font(.title)
            Divider()
            Button(action:{
                let peers = peerManager.session.connectedPeers
                // 自分のhash値が一番大きいか
                let isHost = peers.allSatisfy { peer in
                    peerManager.peerID.hash > peer.hash
                }
                
                peerManager.decisionHost(isHost: isHost)
                
                if peerManager.isHost == nil {
                    errorMessage = "ホストを決定できませんでした"
                }
                
                peerManager.sendMessageForAll("searched")
                peerManager.transformationMatrixPreparationState = peerManager.isHost ? .selectingHost : .selectingClient
            }){
                Text("探す").font(.title2)
            }
            
            Spacer()
            
            if !errorMessage.isEmpty {
                Text(errorMessage).foregroundColor(.red)
                Button(action: {
                    peerManager.transformationMatrixPreparationState = .initial
                }){
                    Text("設定の最初に戻る")
                }
            }
            
        }
    }
}

struct selectingPeerHostView: View {
    @ObservedObject var peerManager = PeerManager()
    @State private var peerIDHash: Int!
    
    var body: some View {
        VStack {
            Text("2. 近くにいる人を選択").font(.title)
            Divider()
            Picker("", selection: $peerIDHash) {
                Text("選ぶ").tag(nil as Int?)
                ForEach(peerManager.session.connectedPeers, id: \.hash) { peerId in
                    Text(String(peerId.hash)).tag(peerId.hash)
                }
            }
            Spacer()
            Button(action: {
                if peerIDHash != nil {
                    print(peerManager.session.connectedPeers.map{ $0.hash })
                    peerManager.addSendMessagePeer(peerIDHash: peerIDHash)
                    let peerIDHashStr = String(peerManager.peerID.hash)
                    peerManager.sendMessage("selectClient:\(peerIDHashStr)")
                }
            }){
                Text("選択した相手を確定")
            }
            
            Button(action: {
                peerManager.transformationMatrixPreparationState = .initial
            }){
                Text("設定の最初に戻る")
            }
        }
        .onChange(of: peerManager.receivedMessage){
            print("selectingPeerHostView")
            if (peerManager.receivedMessage == "receivedSelect") {
                peerManager.transformationMatrixPreparationState =  .rightIndexFingerCoordinatesHost
            }
            
        }
    }
}

struct selectingPeerClientView: View {
    @ObservedObject var peerManager = PeerManager()
    
    var body: some View {
        VStack {
            Text("2. 近くにいる人を選択").font(.title)
            Divider()
            Text("ホストからの選択を待っています")
            
            Spacer()
            
            Button(action: {
                peerManager.transformationMatrixPreparationState = .initial
            }){
                Text("設定の最初に戻る")
            }
        }
        .onChange(of: peerManager.receivedMessage){
            if (peerManager.receivedMessage.hasPrefix("selectClient:")) {
                print(peerManager.receivedMessage)
                let peerIDHash = peerManager.receivedMessage.replacingOccurrences(of: "selectClient:", with: "")
                print(peerIDHash)
                let peerIDHashInt = Int(peerIDHash) ?? 0
                peerManager.addSendMessagePeer(peerIDHash: peerIDHashInt)
                print(peerManager.sendMessagePeerList)
                peerManager.sendMessage("receivedSelect")
                peerManager.transformationMatrixPreparationState = .rightIndexFingerCoordinatesClient
            }
        }
    }
}

struct rightIndexFingerCoordinatesHostView: View {
    @ObservedObject var peerManager = PeerManager()
    @State var isCommunication = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack {
            Text("3. 右手の人差し指の位置を確認").font(.title)
            Divider()
            
            Text("開始ボタンを押しながら右手の人差し指で相手の右手の人差し指に触れてください")
            
            Button(action: {
                peerManager.sendMessage("reqRightIndexFingerCoordinates")
                peerManager.isUpdatePeerManagerRightIndexFingerCoordinates = false
                Thread.sleep(forTimeInterval: 0.1)
            }){
                Text("開始")
            }
            .disabled(isCommunication)
            
            Spacer()
            
            if isCommunication {
                Text("右手の人差し指同士で触れられていましたか？").font(.title2)
                HStack{
                    Button(action: {
                        peerManager.sendMessage("successRightIndexFingerCoordinates")
                    }){
                        Text("はい")
                    }
                    Button(action: {
                        peerManager.sendMessage("reset")
                        peerManager.isUpdatePeerManagerBothIndexFingerCoordinate = true
                        isCommunication = false
                    }){
                        Text("いいえ")
                    }
                }
            }
            
            Text(errorMessage)
            
            Spacer()
        }
        .onChange(of: peerManager.receivedMessage){
            if (peerManager.receivedMessage.hasPrefix("resRightIndexFingerCoordinates")){
                let receivedMessage = peerManager.receivedMessage.replacingOccurrences(of: "resRightIndexFingerCoordinates", with: "")
                let data = receivedMessage.data(using: .utf8)!
                let rightIndexFingerCoordinates = try! JSONDecoder().decode(RightIndexFingerCoordinates.self, from: data)
                peerManager.rightIndexFingerCoordinates = rightIndexFingerCoordinates
                isCommunication = true
            } else if (peerManager.receivedMessage == "receivedSuccessRightIndexFingerCoordinates") {
                peerManager.transformationMatrixPreparationState = .bothIndexFingerCoordinateHost
            } else if (peerManager.receivedMessage.hasPrefix("error:")) {
                errorMessage = peerManager.receivedMessage
            }
        }
    }
}

struct rightIndexFingerCoordinatesClientView: View {
    @ObservedObject var peerManager = PeerManager()
    
    var body: some View {
        VStack {
            Text("3. 右手の人差し指の位置を確認").font(.title)
            Divider()
            
            Text("相手が開始ボタンを押したときに、相手の右手の人差し指と自分右手の人差し指を合わせてください")
            
            Spacer()
        }
        .onChange(of: peerManager.receivedMessage){
            if (peerManager.receivedMessage == "reqRightIndexFingerCoordinates") {
                peerManager.isUpdatePeerManagerRightIndexFingerCoordinates = false
                Thread.sleep(forTimeInterval: 0.1)
                let json = try! JSONEncoder().encode( peerManager.myRightIndexFingerCoordinates)
                let jsonStr = String(data: json, encoding: .utf8) ?? ""
                peerManager.sendMessage("resRightIndexFingerCoordinates\(jsonStr)")
            } else if (peerManager.receivedMessage == "successRightIndexFingerCoordinates") {
                peerManager.sendMessage("receivedSuccessRightIndexFingerCoordinates")
                peerManager.transformationMatrixPreparationState = .bothIndexFingerCoordinateClient
            } else if (peerManager.receivedMessage == "reset"){
                peerManager.isUpdatePeerManagerRightIndexFingerCoordinates = true
            }
        }
    }
}

struct bothIndexFingerCoordinateHostView: View {
    @ObservedObject var peerManager = PeerManager()
    @State var isCommunication = false
    
    var body: some View {
        VStack {
            Text("4. 両手の人差し指の位置を確認").font(.title)
            Divider()
            
            Text("開始ボタンを押しながら両手の人差し指で相手の両手の人差し指に触れてください")
            
            Button(action: {
                peerManager.sendMessage("reqBothIndexFingerCoordinate")
                peerManager.isUpdatePeerManagerBothIndexFingerCoordinate = false
                Thread.sleep(forTimeInterval: 0.1)
            }){
                Text("開始")
            }
            .disabled(isCommunication)
            
            Spacer()
            
            if isCommunication {
                Text("両手の人差し指に触れられていましたか？").font(.title2)
                HStack{
                    Button(action: {
                        peerManager.sendMessage("successBothIndexFingerCoordinate")
                    }){
                        Text("はい")
                    }
                    Button(action: {
                        peerManager.sendMessage("reset")
                        isCommunication = false
                    }){
                        Text("いいえ")
                    }
                }
            }
            
            Spacer()
        }
        .onChange(of: peerManager.receivedMessage){
            if peerManager.receivedMessage.hasPrefix("resBothIndexFingerCoordinate") {
                let receivedMessage = peerManager.receivedMessage.replacingOccurrences(of: "resBothIndexFingerCoordinate", with: "")
                let data = receivedMessage.data(using: .utf8)!
                let bothIndexFingerCoordinate = try! JSONDecoder().decode(BothIndexFingerCoordinate.self, from: data)
                peerManager.bothIndexFingerCoordinate = bothIndexFingerCoordinate
                isCommunication = true
            } else if (peerManager.receivedMessage == "receivedSuccessBothIndexFingerCoordinate") {
                peerManager.transformationMatrixPreparationState = .prepared
            }
        }
    }
}

struct bothIndexFingerCoordinateClientView: View {
    @ObservedObject var peerManager = PeerManager()
    
    var body: some View {
        VStack {
            Text("4. 両手の人差し指の位置を確認").font(.title)
            Divider()
            
            Text("相手が開始ボタンを押しながら両手の人差し指で相手の人差し指に触れてください")
            
            Spacer()
        }
        .onChange(of: peerManager.receivedMessage){
            if (peerManager.receivedMessage == "reqBothIndexFingerCoordinate") {
                peerManager.isUpdatePeerManagerBothIndexFingerCoordinate = false
                Thread.sleep(forTimeInterval: 0.1)
                let json = try! JSONEncoder().encode(peerManager.myBothIndexFingerCoordinate)
                let jsonStr = String(data: json, encoding: .utf8) ?? ""
                peerManager.sendMessage("resBothIndexFingerCoordinate\(jsonStr)")
            } else if (peerManager.receivedMessage == "successBothIndexFingerCoordinate") {
                peerManager.sendMessage("receivedSuccessBothIndexFingerCoordinate")
                peerManager.transformationMatrixPreparationState = .prepared
            } else if (peerManager.receivedMessage == "reset"){
                peerManager.isUpdatePeerManagerBothIndexFingerCoordinate = true
            }
        }
    }
}

struct preparedView: View {
    @ObservedObject var peerManager = PeerManager()
    @Binding var sharedCoordinateState: SharedCoordinateState
    
    var body: some View {
        VStack {
            Text("設定は完了しました！").font(.title)
            
            Text("右手の座標の共有").font(.title)
            Text("相手").font(.title2)
            Text(peerManager.rightIndexFingerCoordinates.rightIndexFingerCoordinates.description)
            
            Text("自分").font(.title2)
            Text(peerManager.myRightIndexFingerCoordinates.rightIndexFingerCoordinates.description)
            
            Text("両手の座標の共有").font(.title)
            Text("相手").font(.title2)
            Text("右手").font(.title3)
            Text(peerManager.bothIndexFingerCoordinate.indexFingerCoordinate.right.description)
            Text("左手").font(.title3)
            Text(peerManager.bothIndexFingerCoordinate.indexFingerCoordinate.left.description)
            
            Text("自分").font(.title2)
            Text("右手").font(.title3)
            Text(peerManager.myBothIndexFingerCoordinate.indexFingerCoordinate.right.description)
            Text("左手").font(.title3)
            Text(peerManager.myBothIndexFingerCoordinate.indexFingerCoordinate.left.description)
            
            Button(action: {
                sharedCoordinateState = .shared
            }){
                Text("設定を完了する")
            }
            .padding()
            
            Button(action: {
                peerManager.transformationMatrixPreparationState = .initial
            }){
                Text("設定をやり直す")
            }
            
            Spacer()
        }
    }
}
