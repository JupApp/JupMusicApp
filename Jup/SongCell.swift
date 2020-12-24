//
//  SongCell.swift
//  Jup
//
//  Created by Zach Venanzi on 12/16/20.
//

import UIKit

class SongCell: UITableViewCell {
    
    @IBOutlet var songCellLabel:UILabel!
    @IBOutlet var aristCellLabel:UILabel!
    @IBOutlet weak var songCellAlbumImage: UIImageView!
    @IBOutlet weak var likeButtonCountLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        likeButtonCountLabel.adjustsFontSizeToFitWidth = true
        // Initialization code
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
