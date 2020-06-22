//
//  Network.swift
//  Rick and Morty
//
//  Created by Edilbert Loquine on 6/22/20.
//  Copyright © 2020 Edilbert Loquine. All rights reserved.
//

import Foundation
import Apollo

class Network {
  static let shared = Network()
    
  private(set) lazy var apollo = ApolloClient(url: URL(string: "https://rickandmortyapi.com/graphql/")!)
}
