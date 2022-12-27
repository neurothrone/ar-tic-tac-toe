//
//  ARModel.swift
//  TicTacToe
//
//  Created by Zaid Neurothrone on 2022-12-27.
//

import ARKit
import RealityKit

struct ARModel {
  private(set) var arView: ARView
  
  init() {
    arView = ARView(frame: .zero)
    arView.session.run(ARWorldTrackingConfiguration())
  }
  
//  mutating func updateHeadTilt() {
//    let faceAnchor = arView.scene.anchors.first(where: { $0.name == faceAnchorName })
//    let cameraAnchor = arView.scene.anchors.first(where: { $0.name == cameraAnchorName })
//
//    headTilt = faceAnchor?.orientation(relativeTo: cameraAnchor).axis.z ?? .zero
//  }
}
