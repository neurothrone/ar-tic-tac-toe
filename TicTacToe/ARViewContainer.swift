//
//  ARViewContainer.swift
//  TicTacToe
//
//  Created by Zaid Neurothrone on 2022-12-27.
//

import RealityKit
import SwiftUI

struct ARViewContainer: UIViewRepresentable {
  func makeUIView(context: Context) -> ARView {
    let arView = ARView(frame: .zero)
    
    return arView
  }
  
  func updateUIView(_ uiView: ARView, context: Context) {}
}
