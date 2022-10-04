//
//  ViewController.swift
//  AR Furniture
//
//  Created by Ali Eldeeb on 10/3/22.
//

import UIKit
import ARKit
import RealityKit
import Combine
class ViewController: UIViewController {
    
    //MARK: - Properties
    let itemsArray: [String] = ["cup", "vase", "boxing", "table"]
    var selectedItem: String?
    var cancelable: AnyCancellable?
    @IBOutlet weak var itemsCollectionView: UICollectionView!
    @IBOutlet weak var arView: ARView!
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configSetup()
        self.itemsCollectionView.dataSource = self
        self.itemsCollectionView.delegate = self
        arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }
    
    //MARK: - Helpers
    
    func configSetup(){
        let configuration = ARWorldTrackingConfiguration()
        arView.automaticallyConfigureSession = false
        configuration.environmentTexturing = .automatic
        configuration.planeDetection = .horizontal
        arView.session.run(configuration)
    }
    
    //MARK: - Selectors
    @objc func handleTap(sender: UITapGestureRecognizer){
        let tapLocation = sender.location(in: arView)
        let result = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
        
        if let firstResult = result.first{
            let worldPosition = simd_make_float3(firstResult.worldTransform.columns.3)
            if let chosenItem = selectedItem{
                cancelable = ModelEntity.loadAsync(named: chosenItem).sink(receiveCompletion: { completion in
                    if case let .failure(error) = completion{
                        print("Unable to load mode \(error)")
                    }
                }, receiveValue: { entity in
                    //place the object at the world position
                    self.placeObject(entity, at: worldPosition)
                })
            }
            
            
        }
    }
    
    func placeObject(_ node: Entity, at location: SIMD3<Float>){
        let anchor = AnchorEntity(world: location)
        anchor.addChild(node)
        arView.scene.addAnchor(anchor)
    }

}

//MARK: - UICollectionViewDataSource

extension ViewController: UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "item", for: indexPath) as! ItemCell
        cell.itemCellLabel.text = self.itemsArray[indexPath.row]
        cell.backgroundColor = .orange
    
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemsArray.count
    }
    
}

//MARK: - UICollectionViewDelegate

extension ViewController: UICollectionViewDelegate{
    //by inheritting from this delegate class we can access the func didselect item
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        self.selectedItem = itemsArray[indexPath.row]
        cell?.backgroundColor = UIColor.green
       
    }
    //if we click on one cell and click on another, the first cell you clicked on is deselected. The func gets triggered for that deselected cell.
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.orange
    }
}

