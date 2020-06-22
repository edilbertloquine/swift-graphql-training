//
//  MasterViewController.swift
//  Rick and Morty
//
//  Created by Edilbert Loquine on 6/22/20.
//  Copyright © 2020 Edilbert Loquine. All rights reserved.
//

import UIKit
import SDWebImage
import Apollo

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    
    var characters = [CharacterListQuery.Data.Character.Result]()
    
    private var lastConnection: CharacterListQuery.Data.Character.Info?
    private var activeRequest: Cancellable?
    
    enum ListSection: Int, CaseIterable {
        case characters
        case loading
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadMoreCharactersIfTheyExist()
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      guard let selectedIndexPath = self.tableView.indexPathForSelectedRow else {
        // Nothing is selected, nothing to do
        return
      }
        
      guard let listSection = ListSection(rawValue: selectedIndexPath.section) else {
        assertionFailure("Invalid section")
        return
      }
        
      switch listSection {
      case .characters:
        guard
          let destination = segue.destination as? UINavigationController,
          let detail = destination.topViewController as? DetailViewController else {
            assertionFailure("Wrong kind of destination")
            return
        }
        
        let character = self.characters[selectedIndexPath.row]
        detail.characterID = character.id
        self.detailViewController = detail
      case .loading:
        print("loading")
      }
    }


    override func numberOfSections(in tableView: UITableView) -> Int {
        return ListSection.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      guard let listSection = ListSection(rawValue: section) else {
        assertionFailure("Invalid section")
        return 0
      }
            
      switch listSection {
      case .characters:
        return self.characters.count
      case .loading:
        // failed attempt to do pagination :(
//        if self.lastConnection!.next! > 1 {
//            return 0
//        } else {
//            return 1
//        }
        return 0
      }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        cell.imageView?.image = nil
        cell.textLabel?.text = nil
        cell.detailTextLabel?.text = nil

      guard let listSection = ListSection(rawValue: indexPath.section) else {
        assertionFailure("Invalid section")
        return cell
      }
        
      switch listSection {
      case .characters:
        let character = self.characters[indexPath.row]
        cell.textLabel?.text = character.name
        cell.detailTextLabel?.text = character.species
        
        let placeholder = UIImage(named: "placeholder")!
        
        if let characterImage = character.image {
          cell.imageView?.sd_setImage(with: URL(string: characterImage)!, placeholderImage: placeholder)
        } else {
          cell.imageView?.image = placeholder
        }
      case .loading:
        if self.activeRequest == nil {
          cell.textLabel?.text = "Tap to load more"
        } else {
          cell.textLabel?.text = "Loading..."
        }
      }
        
      return cell
    }
    
    private func showErrorAlert(title: String, message: String) {
      let alert = UIAlertController(title: title,
                                    message: message,
                                    preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default))
      self.present(alert, animated: true)
    }
    
    private func loadMoreCharacters(from page: Int?) {
      Network.shared.apollo
        .fetch(query: CharacterListQuery(page: page)) { [weak self] result in
        
          guard let self = self else {
            return
          }

            self.activeRequest = nil
          defer {
            self.tableView.reloadData()
          }
                
          switch result {
          case .success(let graphQLResult):
            if let characterConnection = graphQLResult.data?.characters {
                self.characters.append(contentsOf: characterConnection.results!.compactMap { $0 })
            }
                    
            if let errors = graphQLResult.errors {
              let message = errors
                    .map { $0.localizedDescription }
                    .joined(separator: "\n")
              self.showErrorAlert(title: "GraphQL Error(s)",
                                  message: message)
            }
          case .failure(let error):
            self.showErrorAlert(title: "Network Error",
                                message: error.localizedDescription)
          }
      }
    }

    private func loadMoreCharactersIfTheyExist() {
      guard let connection = self.lastConnection else {
        // We don't have stored launch details, load from scratch
        self.loadMoreCharacters(from: nil)
        return
      }
        
        guard connection.next! > 1 else {
        // No more launches to fetch
        return
      }
        
        self.loadMoreCharacters(from: connection.next)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
      guard let selectedIndexPath = self.tableView.indexPathForSelectedRow else {
        return false
      }
              
      guard let listSection = ListSection(rawValue: selectedIndexPath.section) else {
        assertionFailure("Invalid section")
        return false
      }
            
    switch listSection {
      case .characters:
        return true
      case .loading:
        self.tableView.deselectRow(at: selectedIndexPath, animated: true)

        if self.activeRequest == nil {
          self.loadMoreCharactersIfTheyExist()
        } // else, let the active request finish loading

        self.tableView.reloadRows(at: [selectedIndexPath], with: .automatic)
        
        // In either case, don't perform the segue
        return false
      }
    }

}

