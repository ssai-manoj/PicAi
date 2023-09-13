//
//  Filters.swift
//  picaifinal
//
//  Created by AppleMini on 20/06/23.
//

import UIKit

extension ViewController {
    
    func loadFilterData() {
        if let url = Bundle.main.url(forResource: "Filters", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let jsonData = try decoder.decode(Filters.self, from: data)
                globalScenesArray = jsonData.scenes
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    
    func setAllFilters(){
        let allFilters: [Filter] = globalScenesArray.flatMap { $0.leftFilters + $0.rightFilters }
        leftFilters = allFilters
    }
    
    func setFiltersForScene(sceneLabel: String) {
        // Find the scene in globalScenesArray that matches the scene label
        if let scene = globalScenesArray.first(where: { $0.label == sceneLabel }) {
            // Set the left and right filters for this scene
            leftFilters = scene.leftFilters
            rightFilters = scene.rightFilters
            
            // Just for testing, print the first filter name for left and right
        } else {
            print("Scene \(sceneLabel) not found")
        }
    }

}
