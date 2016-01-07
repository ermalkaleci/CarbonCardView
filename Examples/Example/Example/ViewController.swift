//
//  ViewController.swift
//  Example
//
//  Created by Ermal Kaleci on 03/01/16.
//  Copyright © 2016 Ermal Kaleci. All rights reserved.
//

import UIKit

class ViewController: UIViewController, CarbonCardViewDataSource {

    @IBOutlet var carbonCardView: CarbonCardView!
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Actions
    @IBAction func reloadButtonTapped() {
        carbonCardView.reloadData()
    }

    // MARK: CarbonPaper data source
    func numberOfItemsInCarbonCardView(carbonCardView: CarbonCardView) -> UInt {
        return 20
    }
    
    func carbonCardView(carbonCardView: CarbonCardView, itemAtIndex index: UInt) -> CarbonCardViewItem {
        let card = NSBundle.mainBundle().loadNibNamed("CardItem", owner: self, options: nil).first as! CardItem
        
        if index % 3 == 0 {
            card.cardLabel.text = "Nikon"
            if let path = NSBundle.mainBundle().pathForResource("nikon", ofType: "png") {
                let image = UIImage(contentsOfFile: path)
                card.cardImageView.image = image
            }
        } else if index % 2 == 0 {
            card.cardLabel.text = "Shoes"
            if let path = NSBundle.mainBundle().pathForResource("shoes", ofType: "png") {
                let image = UIImage(contentsOfFile: path)
                card.cardImageView.image = image
            }
        } else {
            card.cardLabel.text = "Digital Watch"
            if let path = NSBundle.mainBundle().pathForResource("digital_watch", ofType: "png") {
                let image = UIImage(contentsOfFile: path)
                card.cardImageView.image = image
            }
        }
        
        return card
    }
}

