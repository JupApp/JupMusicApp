//
//  joinableQueueCell.swift
//  Jup
//
//  Created by Zach Venanzi on 12/24/20.
//

import UIKit

class joinableQueueCell: UITableViewCell {
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }
    @IBOutlet var queueNameLabel: UILabel!
    @IBOutlet var joinQueueButton: UIButton!
    
    var buttonClicked: (() -> ())?

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func clickJoinQueue(_ sender: Any) {
        buttonClicked?()
    }
    
}
