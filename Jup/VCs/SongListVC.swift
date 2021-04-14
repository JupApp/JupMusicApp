//
//  SongListVC.swift
//  Jup
//
//  Created by Nick Venanzi on 4/12/21.
//

class SongListVC<T: SongItem>: UITableViewController where T: Hashable {
        
    lazy var datasource =
            UITableViewDiffableDataSource<String, T>(tableView: tableView) { tv, ip, s in
        var cell =
            tv.dequeueReusableCell(withIdentifier: "SearchSongCell", for: ip) as! SearchCell
                // temporarily set album artwork to default image
                cell.SCSongAlbumArt.image = UIImage(named: "DefaultArtwork")
                s.retrieveArtwork(completionHandler: { (artwork) in
                    cell.SCSongAlbumArt.image = artwork
                })
                cell.SCSongArtist.text = s.artistName
                cell.SCSongTitle.text = s.songTitle
        return cell
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Handle TableView set up
        self.tableView.delegate = self
        self.tableView.dataSource = datasource
        self.tableView.register(UINib(nibName: "SearchCell", bundle: nil), forCellReuseIdentifier: "SearchSongCell")
        self.tableView.rowHeight = UITableView.automaticDimension;

        var snap = NSDiffableDataSourceSnapshot<String, T>()
        snap.appendSections(["Songs"])
        datasource.apply(snap, animatingDifferences: false)
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
