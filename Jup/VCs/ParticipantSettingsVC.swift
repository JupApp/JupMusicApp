//
//  ParticipantSettingsVC.swift
//  Jup
//
//  Created by Zach Venanzi on 11/27/20.
//

import UIKit

class ParticipantSettingsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
        
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var joinableQueuesTable: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cellNib = UINib(nibName: "joinableQueueCell", bundle: nil)
        joinableQueuesTable.register(cellNib, forCellReuseIdentifier: "joinableQueueCell")
        joinableQueuesTable.register(joinableQueueCell.self, forCellReuseIdentifier: "joinableQueueCell")
        
        joinableQueuesTable.delegate = self
        joinableQueuesTable.dataSource = self
        joinableQueuesTable.backgroundColor = UIColor.clear
        self.joinableQueuesTable.layer.cornerRadius = 10
        joinableQueuesTable.separatorStyle = .none


    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(
            withIdentifier: "joinableQueueCell", for: indexPath) as? joinableQueueCell
    if cell == nil {
        cell = joinableQueueCell(style:.default, reuseIdentifier: "joinableQueueCell")
    }
    return cell!
    }
}

