//
//  ARViewModel.swift
//  TicTacToe
//
//  Created by Zaid Neurothrone on 2022-12-27.
//

import ARKit
import RealityKit
import SwiftUI

final class ARViewModel: UIViewController, ObservableObject {
  @Published private var model: ARModel = .init()
  @Published var message: String = "Message"
  
  var playerColor = Color.blue
  
  var gridModelEntityX: ModelEntity?
  var gridModelEntityY: ModelEntity?
  var tileModelEntity: ModelEntity?
  
  func player1ButtonPressed() {
    playerColor = .blue
  }
  
  func player2ButtonPressed() {
    playerColor = .red
  }
  
  func clearButtonPressed() {
    removeAnchors()
  }
  
  var arView: ARView {
    model.arView
  }
  
  func setUp() {
    initARView()
    initModelEntities()
    initGestures()
  }
}

// MARK: - Helper Functions
extension ARViewModel {
  func sendMessage(_ message: String) {
    DispatchQueue.main.async {
      self.message = message
    }
  }
}

// MARK: - AR View Functions
extension ARViewModel: ARSessionDelegate {
  func initARView() {
    arView.session.delegate = self
    arView.automaticallyConfigureSession = false
    
    let arConfiguration = ARWorldTrackingConfiguration()
    arConfiguration.planeDetection = [.horizontal]
    arConfiguration.environmentTexturing = .automatic
    
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
extension ARViewModel {
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
    
    // This creates a new game board and places it in the scene. It also anchors the game board to the surface at the provided position.
    anchorEntity.anchoring = AnchoringComponent(arAnchor)
    arView.scene.addAnchor(anchorEntity)
    arView.session.add(anchor: arAnchor)
  }
}

// MARK: - Gesture Functions
extension ARViewModel {
  func initGestures() {
    let tap = UITapGestureRecognizer(
      target: self,
      action: #selector(handleTap)
    )

    arView.addGestureRecognizer(tap)
  }
  
  @objc func handleTap(recognizer: UITapGestureRecognizer?) {
    guard let touchLocation = recognizer?.location(in: arView) else { return }
    
    if let hitEntity = arView.entity(at: touchLocation),
       let modelEntity = hitEntity as? ModelEntity {
      modelEntity.model?.materials = [
        SimpleMaterial(color: UIColor(self.playerColor), isMetallic: true)
      ]
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
