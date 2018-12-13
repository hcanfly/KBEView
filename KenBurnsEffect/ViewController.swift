//
//  ViewController.swift
//  KenBurnsEffect
//
//  Copyright © 2018 Gary Hanson.
//  Licensed under the MIT license, see LICENSE file
//

import UIKit

class ViewController: UIViewController {

    var photos = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    private func addKenBurnsView() {
        
        let containerFrame = view.safeAreaLayoutGuide.layoutFrame
        let containerView = UIView(frame: containerFrame)
        containerView.clipsToBounds = true      // keep transforms from drawing outside their bounds if they're not the size of the screen
        self.view.addSubview(containerView)
        
        let kenburnsView = KBEView(frame: containerView.bounds)
        containerView.addSubview(kenburnsView)

        // initialize KenBurnsView
        self.loadPhotos()
        kenburnsView.images = self.photos
        kenburnsView.animationDuration = 11.5
    }

    override func viewDidLayoutSubviews() {
        // iOS 11 - Safe Area isn't calculated until now
        self.addKenBurnsView()
    }
    
    private func loadPhotos() {
        let fm = FileManager.default
        let path = Bundle.main.resourcePath! + "/Photos/"
        let items = try! fm.contentsOfDirectory(atPath: path)
        
        for item in items {
            if item.hasSuffix(".jpg") || item.hasSuffix(".JPG") || item.hasSuffix(".jpeg")  || item.hasSuffix(".png"){
                if let image = UIImage(named: "Photos/" + item) {
                    self.photos.append(image)
                }
            }
        }
    }


}

