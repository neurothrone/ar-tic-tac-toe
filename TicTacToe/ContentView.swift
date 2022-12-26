//
//  ContentView.swift
//  TicTacToe
//
//  Created by Zaid Neurothrone on 2022-12-27.
//

import SwiftUI

struct ContentView: View {
  @StateObject private var viewModel: ViewModel = .init()
  
  var body: some View {
    ZStack(alignment: .top) {
      ARViewContainer()
        .edgesIgnoringSafeArea(.all)
      
      VStack {
        Button {
          
        } label: {
          Text("Message")
        }

        Spacer()
        
        HStack {
          Button("Player 1", action: viewModel.player1ButtonPressed)
          Button("Clear", action: viewModel.clearButtonPressed)
          Button("Player 2", action: viewModel.player2ButtonPressed)
        }
      }
    }
    .onAppear(perform: viewModel.setUp)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
