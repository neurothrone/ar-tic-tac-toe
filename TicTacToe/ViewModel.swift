//
//  ViewModel.swift
//  TicTacToe
//
//  Created by Zaid Neurothrone on 2022-12-27.
//

import ARKit
import MultipeerConnectivity
import RealityKit
import SwiftUI

final class ViewModel: NSObject, ObservableObject {
  @Published var message: String = "Message"
  
  // MARK: - Properties
  var arView: ARView!
  
  var playerColor = Color.blue
  
  var gridModelEntityX: ModelEntity?
  var gridModelEntityY: ModelEntity?
  var tileModelEntity: ModelEntity?

  // Holds the instance of MultipeerSession that you’ll create
  var multipeerSession: MultipeerSession?
  // A list of peer IDs (Strings) that will keep track of the connected peers. You’ll maintain this list of IDs manually
  var peerSessionIDs = [MCPeerID: String]()
  // Uses the observation pattern to monitor your own session ID, in case it changes over time
  var sessionIDObservation: NSKeyValueObservation?
  
  func player1ButtonPressed() {
    playerColor = .blue
  }
  
  func player2ButtonPressed() {
    playerColor = .red
  }
  
  func clearButtonPressed() {
    removeAnchors()
  }
}

// MARK: - AR View Functions
extension ViewModel: ARSessionDelegate {
  func setUp() {
    initARView()
    initModelEntities()
    initGestures()
    initMultipeerSession()
  }
  
  func initARView() {
    arView.session.delegate = self
    arView.automaticallyConfigureSession = false
    
    let arConfiguration = ARWorldTrackingConfiguration()
    arConfiguration.planeDetection = [.horizontal]
    arConfiguration.environmentTexturing = .automatic

    // Enabling collaboration will start sharing collaboration data with connected peers. Collaboration data contains information about detected surfaces, device positions and added anchors.
    arConfiguration.isCollaborationEnabled = true
    
    arView.session.run(arConfiguration)
  }
  
  func removeAnchors() {
    guard let frame = arView.session.currentFrame else { return }
    
    for anchor in frame.anchors {
      arView.session.remove(anchor: anchor)
    }
    
    sendMessage("All anchors removed!")
  }
}

// MARK: - Model Entity Functions
extension ViewModel {
  func initModelEntities() {
    // The Tic-Tac-Toe grid consists of two types of grid bars. Here, you define the vertical grid bar with a mesh component generated from a box that measures (X:30cm, Y:1cm, Z:1cm). It assigns a single white plastic material to the bar.
    gridModelEntityX = ModelEntity(
      mesh: .generateBox(size: SIMD3(x: 0.3, y: 0.01, z: 0.01)),
      materials: [SimpleMaterial(color: .white, isMetallic: false)]
    )
    // This defines the horizontal grid bar with a mesh component generated from a box that measures (X:1cm, Y:1cm, Z:30cm). It also assigns a single white plastic material to the bar.
    gridModelEntityY = ModelEntity(
      mesh: .generateBox(size: SIMD3(x: 0.01, y: 0.01, z: 0.3)),
      materials: [SimpleMaterial(color: .white, isMetallic: false)]
    )
    // This defines the tile with a mesh component generated from a box that measures (X:7cm, Y:1cm, Z:7cm). It assigns a single gray metallic material to the tile.
    tileModelEntity = ModelEntity(
      mesh: .generateBox(size: SIMD3(x: 0.07, y: 0.01, z: 0.07)),
      materials: [SimpleMaterial(color: .gray, isMetallic: true)]
    )
    // To interact with elements in the scene, those elements require a collision component. Here, you generate a collision shaped component for the tile model entity by using the mesh component. Now, you’ll be able to hit test against the tiles.
    tileModelEntity!.generateCollisionShapes(recursive: false)
  }
  
  func cloneModelEntity(_ modelEntity: ModelEntity, position: SIMD3<Float>) -> ModelEntity {
    let newModelEntity = modelEntity.clone(recursive: false)
    newModelEntity.position = position
    return newModelEntity
  }
  
  func addGameBoardAnchor(transform: simd_float4x4) {
    // The entire game board is connected to an AnchorEntity that forms the root entity of the game board. Here, you create an AnchorEntity with an ARAnchor using the provided transform value for the anchor’s position.
    let arAnchor = ARAnchor(name: "XOXO Grid", transform: transform)
    let anchorEntity = AnchorEntity(anchor: arAnchor)
    
    // Here, the nifty new cloning function creates two vertical bars and two horizontal bars to form the grid for the Tic-Tac-Toe experience. All the entities become children of the root anchorEntity
    anchorEntity.addChild(cloneModelEntity(gridModelEntityY!, position: SIMD3(x: 0.05, y: 0, z: 0)))
    anchorEntity.addChild(cloneModelEntity(gridModelEntityY!, position: SIMD3(x: -0.05, y: 0, z: 0)))
    anchorEntity.addChild(cloneModelEntity(gridModelEntityX!, position: SIMD3(x: 0.0, y: 0, z: 0.05)))
    anchorEntity.addChild(cloneModelEntity(gridModelEntityX!, position: SIMD3(x: 0.0, y: 0, z: -0.05)))
    
    // This follows the same process as before, making cloned copies of the original tile. It places each clone at a different position to fill the 9×9 grid. Also, note that each tile becomes a child of the root anchorEntity
    anchorEntity.addChild(cloneModelEntity(tileModelEntity!,
      position: SIMD3(x: -0.1, y: 0, z: -0.1)))
    anchorEntity.addChild(cloneModelEntity(tileModelEntity!,
      position: SIMD3(x: 0, y: 0, z: -0.1)))
    anchorEntity.addChild(cloneModelEntity(tileModelEntity!,
      position: SIMD3(x: 0.1, y: 0, z: -0.1)))
    anchorEntity.addChild(cloneModelEntity(tileModelEntity!,
      position: SIMD3(x: -0.1, y: 0, z: 0)))
    anchorEntity.addChild(cloneModelEntity(tileModelEntity!,
      position: SIMD3(x: 0, y: 0, z: 0)))
    anchorEntity.addChild(cloneModelEntity(tileModelEntity!,
      position: SIMD3(x: 0.1, y: 0, z: 0)))
    anchorEntity.addChild(cloneModelEntity(tileModelEntity!,
      position: SIMD3(x: -0.1, y: 0, z: 0.1)))
    anchorEntity.addChild(cloneModelEntity(tileModelEntity!,
      position: SIMD3(x: 0, y: 0, z: 0.1)))
    anchorEntity.addChild(cloneModelEntity(tileModelEntity!,
      position: SIMD3(x: 0.1, y: 0, z: 0.1)))
    
    // Enabling Automatic Ownership: this simply sets ownershipTransferMode to automatically accept ownership requests. Now, when a peer interacts with a tile, they first need to request ownership of that tile before trying to change its color.
    anchorEntity.synchronization?.ownershipTransferMode = .autoAccept
    
    // This creates a new game board and places it in the scene. It also anchors the game board to the surface at the provided position.
    anchorEntity.anchoring = AnchoringComponent(arAnchor)
    arView.scene.addAnchor(anchorEntity)
    arView.session.add(anchor: arAnchor)
  }
}

// MARK: - Gesture Functions
extension ViewModel {
  func initGestures() {
    let tap = UITapGestureRecognizer(
      target: self,
      action: #selector(handleTap)
    )

    self.arView.addGestureRecognizer(tap)
  }
  
  @objc func handleTap(recognizer: UITapGestureRecognizer?) {
    guard let touchLocation = recognizer?.location(in: arView) else { return }
    
//    if let hitEntity = arView.entity(at: touchLocation) {
//      let modelEntity = hitEntity as! ModelEntity
//        modelEntity.model?.materials = [
//          SimpleMaterial(color: self.playerColor,
//          isMetallic: true)]
//      return
//    }
    
    // Previously, you simply modified the tile color. This time around, you first check to see if you’re the owner of the tile. If you are, no worries, you can change the tile color. If not, you first have to request ownership. Once granted, ownership of the tile now belongs to you and you can change the tile color.
    if let hitEntity = self.arView.entity(at: touchLocation) {
      if hitEntity.isOwner {
        let modelEntity = hitEntity as! ModelEntity
        modelEntity.model?.materials = [
          SimpleMaterial(color: UIColor(playerColor), isMetallic: true)
        ]
      } else {
        hitEntity.requestOwnership { result in
          if result == .granted {
            let modelEntity = hitEntity as! ModelEntity
            modelEntity.model?.materials = [
              SimpleMaterial(color: UIColor(self.playerColor), isMetallic: true)
            ]
          }
        }
      }
      return
    }



    let results = arView.raycast(
      from: touchLocation,
      allowing: .estimatedPlane,
      alignment: .horizontal
    )
        
    if let firstResult = results.first {
      self.addGameBoardAnchor(transform: firstResult.worldTransform)
    } else {
      self.message = "[WARNING] No surface detected!"
    }
  }
}


// MARK: - Multipeer Session Functions
extension ViewModel {
  // This creates an instance of MultipeerSession and provides it with event handlers for all possible network session events
  func initMultipeerSession() {
    // This uses the observer pattern to monitor your current session ID. Should it change, this will ensure the other connected peers are informed of your latest session ID.
    sessionIDObservation = observe(\.arView.session.identifier, options: [.new]) { object, change in
      print("Current SessionID: \(change.newValue!)")
      
      guard let multipeerSession = self.multipeerSession else { return }
      
      self.sendARSessionIDTo(peers: multipeerSession.connectedPeers)
    }
    
    multipeerSession = MultipeerSession(
      receivedDataHandler: receivedData,
      peerJoinedHandler: peerJoined,
      peerLeftHandler: peerLeft,
      peerDiscoveredHandler: peerDiscovered
    )
    
    // With the extension function in place, this makes sure that you get a valid multi-peer session service from MultipeerSession
    guard let multipeerConnectivityService =
      multipeerSession!.multipeerConnectivityService else {
        fatalError("[FATAL ERROR] Unable to create Sync Service!")
      }

    // This registers the synchronization service. Now, RealityKit will keep all the Codable objects in sync. This includes entities along with all their components.
    arView.scene.synchronizationService = multipeerConnectivityService
    self.message = "Waiting for peers..."
  }
  
  func receivedData(_ data: Data, from peer: MCPeerID) {
  }
  
  // When the network session discovers a new peer, it triggers peerDiscovered(_:), asking it for permission to allow the new peer to connect.
  func peerDiscovered(_ peer: MCPeerID) -> Bool {
    guard let multipeerSession = multipeerSession else { return false }
    
    sendMessage("Peer discovered!")
    
    // Here, you build in a restriction on the number of active connected peers allowed at once time. The code above simply checks that the total number of connected peers is under the allowed amount. If so, the peer is allowed to connect; otherwise, it’s rejected and the user gets a message that there are too many connections.
    if multipeerSession.connectedPeers.count > 2 {
      sendMessage("[WARNING] Max connections reached!")
      return false
    } else {
      return true
    }
  }
  
  // When the peer is allowed to connect, the network session will trigger peerJoined(_:)
  func peerJoined(_ peer: MCPeerID) {
    // As soon as a peer joins, it’s good time to inform the users to hold their phones close together. It’s also the perfect time to send your own session id to the peer who just joined so that they can also keep track of you in their list of peers.
    sendMessage("Hold phones together...")
    sendARSessionIDTo(peers: [peer])
  }
  
  // When a peer leaves, you need to update peerSessionIDs
  func peerLeft(_ peer: MCPeerID) {
    // This removes the peer from peerSessionIDs, maintaining the list at all times.
    sendMessage("Peer left!")
    peerSessionIDs.removeValue(forKey: peer)
  }
  
  // When a peer connects or when your session ID changes, you need to inform the connected peers of your current peer ID
  private func sendARSessionIDTo(peers: [MCPeerID]) {
    guard let multipeerSession = multipeerSession else { return }
    
    let idString = arView.session.identifier.uuidString
    let command = "SessionID:" + idString
    
    if let commandData = command.data(using: .utf8) {
      multipeerSession.sendToPeers(
        commandData,
        reliably: true,
        peers: peers
      )
    }
  }
  
  // Here, you use session(_:didAdd) — which is part of the ARSessionDelegate protocol — to check if a newly-added anchor is an ARParticipationAnchor. If it is, a peer has just successfully connected and an active collaborative experience is in progress. Excellent!
  func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
    for anchor in anchors {
      if let participantAnchor = anchor as? ARParticipantAnchor {
        self.message = "Peer connected!"
        let anchorEntity = AnchorEntity(anchor: participantAnchor)
        arView.scene.addAnchor(anchorEntity)
      }
    }
  }
}

// MARK: - Helper Functions
extension ViewModel {
  func sendMessage(_ message: String) {
    DispatchQueue.main.async {
      self.message = message
    }
  }
}



