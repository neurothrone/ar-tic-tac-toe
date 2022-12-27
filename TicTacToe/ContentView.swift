//
//  ContentView.swift
//  TicTacToe
//
//  Created by Zaid Neurothrone on 2022-12-27.
//

import RealityKit
import SwiftUI

struct ContentView: View {
  @StateObject private var arViewModel: ARViewModel = .init()
  
  var body: some View {
    ZStack(alignment: .top) {
      ARViewContainer(arViewModel: arViewModel)
        .edgesIgnoringSafeArea(.all)

      
      VStack {
        Text(arViewModel.message)

        Spacer()
        
        HStack {
          Button("Player 1", action: arViewModel.player1ButtonPressed)
          Button("Clear", action: arViewModel.clearButtonPressed)
          Button("Player 2", action: arViewModel.player2ButtonPressed)
        }
      }
    }
  }
}

struct ARViewContainer: UIViewRepresentable {
  var arViewModel: ARViewModel
  
  func makeUIView(context: Context) -> ARView {
    arViewModel.setUp()
    return arViewModel.arView
  }
  
  func updateUIView(_ uiView: ARView, context: Context) {}
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
