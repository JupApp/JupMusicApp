//
//  joinableQueueCell.swift
//  Jup
//
//  Created by Zach Venanzi on 12/24/20.
//

import UIKit

class JoinableQueueCell: UITableViewCell {
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }
    @IBOutlet weak var queueNameLabel: UILabel!
    @IBOutlet weak var queuePlatformLabel: UILabel!
    @IBOutlet weak var queueNumParticipants: UILabel!
    
    
    var buttonClicked: (() -> ())?

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func clickJoinQueue(_ sender: Any) {
        buttonClicked?()
    }
    
}
