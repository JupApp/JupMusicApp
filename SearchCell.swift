//
//  lTableViewCell.swift
//  Jup
//
//  Created by Zach Venanzi on 12/19/20.
//

import UIKit

class SearchCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBOutlet weak var SCSongTitle: UILabel!
    @IBOutlet weak var SCSongAlbumArt: UIImageView!
    @IBOutlet weak var SCSongArtist: UILabel!
    @IBOutlet weak var addSongButton: UIButton!
    @IBOutlet weak var addSongImage: UIImageView!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
