//
//  PlaylistItem.swift
//  Jup
//
//  Created by Nick Venanzi on 5/7/21.
//

class PlaylistItem: Hashable {
    var name: String
    var id: String
    var url: String
    var image: UIImage?
    
    init(_ name: String, _ id: String, _ url: String) {
        self.name = name
        self.id = id
        self.url = url
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func ==(lhs: PlaylistItem, rhs: PlaylistItem) -> Bool {
               return lhs.id == rhs.id
    }
    
    func retrieveArtwork(_ completionHandler: @escaping (_ image: UIImage) -> ()) {
        guard let _ = image else {
            completionHandler(image!)
            return
        }
        guard let url: URL = URL(string: url) else {
            completionHandler(UIImage())
            return
        }
        let request = URLRequest(url: url)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data else { completionHandler(UIImage()); return }
            DispatchQueue.main.async {
                self.image = UIImage(data: data)
                completionHandler(self.image ?? UIImage())
            }
        }
        task.resume()
    }
}

