//
//  SongCell.swift
//  Jup
//
//  Created by Zach Venanzi on 12/16/20.
//

import UIKit

class SongCell: UITableViewCell {
    
    @IBOutlet var songCellName:UILabel!
    @IBOutlet var aristCellName:UILabel!
    @IBOutlet weak var songCellAlbum: UIImageView!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
