//
//  joinableQueueCell.swift
//  Jup
//
//  Created by Zach Venanzi on 12/24/20.
//

import UIKit

class JoinableQueueCell: UITableViewCell {
    
    var joinButton: UIButton = UIButton()
    @IBOutlet weak var queueNameLabel: UILabel!
    @IBOutlet weak var queuePlatformLabel: UILabel!
    @IBOutlet weak var queueNumParticipants: UILabel!
    var buttonClicked: (() -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        joinButton.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        joinButton.addTarget(self, action: #selector(clickJoinQueue), for: .touchUpInside)
        joinButton.layer.cornerRadius = joinButton.frame.height/4
        self.addSubview(joinButton)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @objc func clickJoinQueue() {
        buttonClicked?()
    }
    
}
