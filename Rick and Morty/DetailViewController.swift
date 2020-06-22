//
//  DetailViewController.swift
//  Rick and Morty
//
//  Created by Edilbert Loquine on 6/22/20.
//  Copyright © 2020 Edilbert Loquine. All rights reserved.
//

import UIKit
import Apollo

class DetailViewController: UIViewController {
    
    private var character: CharacterDetailQuery.Data.Character? {
        didSet {
          self.configureView()
        }
    }

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    
    @IBOutlet weak var characterImageView: UIImageView!
    @IBOutlet weak var characterNameLabel: UILabel!
    @IBOutlet weak var statusNameLabel: UILabel!
    @IBOutlet weak var speciesNameLabel: UILabel!
    @IBOutlet weak var typeNameLabel: UILabel!
    @IBOutlet weak var locationNameLabel: UILabel!
    @IBOutlet weak var dimensionNameLabel: UILabel!
    @IBOutlet weak var originNameLabel: UILabel!
    
    var characterID: GraphQLID? {
        didSet {
          self.loadCharacterDetails()
        }
    }
    
    private func loadCharacterDetails() {
      guard
        let characterID = self.characterID,
        characterID != self.character?.id else {
          // This is the launch we're already displaying, or the ID is nil.
          return
      }
        
      Network.shared.apollo.fetch(query: CharacterDetailQuery(id: characterID)) { [weak self] result in
        guard let self = self else {
          return
        }
        
        switch result {
        case .failure(let error):
          print("NETWORK ERROR: \(error)")
        case .success(let graphQLResult):
            if let character = graphQLResult.data?.character {
            self.character = character
          }
        
          if let errors = graphQLResult.errors {
            print("GRAPHQL ERRORS: \(errors)")
          }
        }
      }
    }

    func configureView() {
        guard self.characterNameLabel != nil,
            let character = self.character else {
                return
        }
        
        self.characterNameLabel.text = character.name
        self.title = character.name

        let placeholder = UIImage(named: "placeholder")!
            
        if let characterImage = character.image {
          self.characterImageView.sd_setImage(with: URL(string: characterImage)!, placeholderImage: placeholder)
        } else {
          self.characterImageView.image = placeholder
        }

        if let status = character.status {
          self.statusNameLabel.text = "Status: \(status)"
        } else {
          self.statusNameLabel.text = nil
        }
            
        if let speciesName = character.species {
            self.speciesNameLabel.text = "Species: \(speciesName)"
        } else {
            self.speciesNameLabel.text = nil
        }
        
        if let typeName = character.type{
            self.typeNameLabel.text = "Sub-Species: \(typeName == "" ? "N/A" : typeName)"
        } else {
            self.typeNameLabel.text = nil
        }
        
        if let locationName = character.location?.name {
            self.locationNameLabel.text = "\(locationName)"
        } else {
            self.locationNameLabel.text = nil
        }
        
        if let dimensionName = character.location?.dimension {
            self.dimensionNameLabel.text = "\(dimensionName)"
        } else {
            self.dimensionNameLabel.text = nil
        }
        
        if let originName = character.origin?.dimension {
            self.originNameLabel.text = "\(originName == "" ? "N/A" : originName)"
        } else {
            self.originNameLabel.text = nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.characterNameLabel.text = "Loading..."
        self.statusNameLabel.text = nil
        self.speciesNameLabel.text = nil
        self.typeNameLabel.text = nil
        self.locationNameLabel.text = nil
        self.dimensionNameLabel.text = nil
        self.originNameLabel.text = nil
        
        self.configureView()
    }


}

