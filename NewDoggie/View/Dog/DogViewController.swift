//
//  DogViewController.swift
//  NewDoggie
//
//  Created by Eli Warner on 4/23/19.
//  Copyright © 2019 EGW. All rights reserved.
//

import UIKit
import CoreData

class DogViewController: UIViewController, UICollectionViewDelegateFlowLayout {

    //MARK: Properties
    private var reuseIdentifier = "dogcell"
    var breeds: [String]  = []
    var imagePickerRow: Int?
    var dogImages: [DogAsset] = []
    var loadingData: Bool = false
    let activityView = UIActivityIndicatorView(style: .gray)

    private let itemsPerRow: CGFloat = 2
    private let sectionInsets = UIEdgeInsets(top: 5.0,
                                             left: 10.0,
                                             bottom: 5.0,
                                             right: 10.0)
    
    //MARK: Outlets
    @IBOutlet weak var collectionImageView: UICollectionView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializers()
        load20Images()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        DogAPI.requestBreedList(completionHandler: handleBreedsListResponse(breeds:error:))
        print(breeds)
    }
    
    func initializers(){
        collectionImageView.delegate = self
        collectionImageView.dataSource = self
        activity()
    }
    
    func handleBreedsListResponse(breeds: [String], error: Error?){
        self.breeds = breeds
        
    }
    
    func activity(){
        let fadeView:UIView = UIView()
        
        self.view.addSubview(activityView)
        activityView.hidesWhenStopped = true
        activityView.center = self.view.center
        // start animating activity view
        activityView.startAnimating()
    }
    //MARK - Loading Images
    func load20Images(){
        var i = 0
        
        for _ in i...15 {
            self.loadImage()
            i = i + 1
        }
        loadingData = false
    }

    func loadImage(){
        let dogCount = dogImages.count + 14
        DogAPI.requestRandomImage { (image, error) in
            guard let image = image?.message else {
                print(error)
                return
            }
            
            if let url = URL(string: image) {
                DogAPI.requestImage(url: url, completionHandler: { (response, error) in
                    guard let response = response else {
                        print("Error: \(error)")
                        return
                    }
                    var tempimage = DogAsset(image: response)
                    self.dogImages.append(tempimage)
                    if self.dogImages.count > dogCount {
                        DispatchQueue.main.async {
                            self.activityView.stopAnimating()
                            self.collectionImageView.reloadData()
                        }
                    }
                })
            } else {
                DogAPI.requestRandomImage(completionHandler: { (image, error) in
                    guard let image = image?.message else {
                        print(error)
                        return
                    }
                    let url = URL(string: image)
                    DogAPI.requestImage(url: url!, completionHandler: { (response, error) in
                        guard let response = response else {
                            print("Error: \(error)")
                            return
                        }
                        var tempimage = DogAsset(image: response)
                        self.dogImages.append(tempimage)
                        if self.dogImages.count > dogCount {
                            DispatchQueue.main.async {
                                self.activityView.stopAnimating()
                                self.collectionImageView.reloadData()
                            }
                        }
                    })

                })
            }
            
        }
    }

}

extension DogViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if dogImages.count == 0 {
            self.collectionImageView.setEmptyMessage("Wait while we load some Puppers! :)")
            return dogImages.count
        } else {
            self.collectionImageView.setEmptyMessage("")
            return dogImages.count
        }    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        DogAPI.requestBreedList(completionHandler: handleBreedsListResponse(breeds:error:))
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! DogColView
        cell.activityIndicator.startAnimating()
        let image = dogImages[indexPath.row]
        
        DispatchQueue.main.async {
            cell.activityIndicator.stopAnimating()
            cell.activityIndicator.hidesWhenStopped = true
            cell.imageView.image = image.image
        }
        
        return cell
    }
    

    
    func save(asset: DogAsset) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "DogData", in: managedContext)!
        
        let dogImage = NSManagedObject(entity: entity, insertInto: managedContext)
        
        dogImage.setValue(asset.image.pngData(), forKeyPath: "data")
  
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        //2
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        save(asset: dogImages[indexPath.row])
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let lastimage = dogImages.count - 2
        if !loadingData && indexPath.row == lastimage {
            loadingData = true
            load20Images()
        }
    }

}
