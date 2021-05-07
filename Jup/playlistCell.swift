//
//  playlistCell.swift
//  Jup
//
//  Created by Zach Venanzi on 5/7/21.
//

import UIKit

class playlistCell: UITableViewCell {

    @IBOutlet weak var playlistImage: UIImageView!
    @IBOutlet weak var playlistLabel: NSLayoutConstraint!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
