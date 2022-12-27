//
//  ARView+Extensions.swift
//  TicTacToe
//
//  Created by Zaid Neurothrone on 2022-12-27.
//

import ARKit
import RealityKit

extension ARView {
  func addCoachingOverlay() {
    let coachingOverlay = ARCoachingOverlayView()
    
    coachingOverlay.goal = .horizontalPlane
    coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    coachingOverlay.session = self.session
    
    self.addSubview(coachingOverlay)
  }
}
