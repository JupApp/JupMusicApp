//
//  joinableQueueCell.swift
//  Jup
//
//  Created by Zach Venanzi on 12/24/20.
//

import UIKit

class JoinableQueueCell: UITableViewCell {
    
    @IBOutlet weak var queueNameLabel: UILabel!
    @IBOutlet weak var queuePlatformLabel: UILabel!
    @IBOutlet weak var queueNumParticipants: UILabel!
    var buttonClicked: (() -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func clickJoinQueue(_ sender: Any) {
        buttonClicked?()
    }
    
}
