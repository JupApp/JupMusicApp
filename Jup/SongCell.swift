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
    @IBOutlet weak var LikeButtonCountLabel: UILabel!
    @IBOutlet weak var LikeButton: UIButton!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }


    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
