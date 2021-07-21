//
//  lTableViewCell.swift
//  Jup
//
//  Created by Zach Venanzi on 12/19/20.
//

import UIKit

class SearchCell: UITableViewCell {
    
    var completionHandler: ((SongItem) -> ())?
    var songItem: SongItem?
    
    @IBOutlet weak var SCSongTitle: UILabel!
    @IBOutlet weak var SCSongAlbumArt: UIImageView!
    @IBOutlet weak var SCSongArtist: UILabel!
    @IBOutlet weak var addSongButton: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func songAdded(_ sender: Any) {
        addSongButton.isHidden = true
        // attempt to add song to queue, update tableview
        completionHandler?(songItem!)
        completionHandler = nil
    }
}
    

