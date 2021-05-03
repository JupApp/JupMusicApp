//
//  SongCell.swift
//  Jup
//
//  Created by Zach Venanzi on 12/16/20.
//

import UIKit

class SongCell: UITableViewCell {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var artistLabel: UILabel!
    @IBOutlet weak var albumArtwork: UIImageView!
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var contributorLabel: UILabel!
    
    var completionHandler: (() -> ())!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        likeCountLabel.adjustsFontSizeToFitWidth = true
        // Initialization code
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func songLiked(_ sender: Any) {
        completionHandler()
    }
}
