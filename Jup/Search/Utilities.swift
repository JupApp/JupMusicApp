//
//  Utilities.swift
//  Jup
//
//  Created by Nick Venanzi on 5/7/21.
//

class Utilities {
    
    /*
     Converts song item into a hierarchy of possible searches to query
     */
    static func searchQueryFromSong(_ songItem: SongItem) -> String {
        let artists: String = songItem.artistName
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "& ", with: "")
            .replacingOccurrences(of: "and ", with: "")
        let title: String = songItem.songTitle
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "- ", with: "")
            .replacingOccurrences(of: "(feat. ", with: "")
            .replacingOccurrences(of: "(with ", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: "& ", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " x ", with: " ")

        print("Song Title: \n\(title)")
        print("Artists:\n\(artists)")
        return title + " " + artists
    }
    
    /*
     Attempts to find result that matches query words exactly, otherwise returns first result
     */
    static func matchQuery<T: SongItem>(_ songItemToMatch: SongItem, _ resultSongItems: [T]) -> T {
        let matchGoal: [String] = searchQueryFromSong(songItemToMatch).split(separator: " ").map { (substring) -> String in
            String(substring)
        }
        
        let matchGoalSet: Set<String> = Set(matchGoal)
        
        for possibleMatch in resultSongItems {
            let itemsInPossibleMatch: [String] = searchQueryFromSong(possibleMatch).split(separator: " ").map { String($0) }
            if matchGoalSet.isSubset(of: itemsInPossibleMatch) && matchGoalSet.isSuperset(of: itemsInPossibleMatch) {
                return possibleMatch
            }
        }
        return resultSongItems[0]
    }
    
    /*
     Function constructs a collage of 2x2 images from the first four songs of a playlist in the case
     that a playlist does not have album artwork of its own. If songItems.count < 4, the first image artwork
     is chosen as the playlist artwork. If songItems.count == 0, UIImage() is returned.
     */
    static func constructAlbumCollage(_ songItems: [SongItem], _ completionHandler: @escaping (UIImage?) -> ()) {
        guard !songItems.isEmpty else {
            completionHandler(nil)
            return
        }
        guard songItems.count >= 4 else {
            songItems[0].retrieveArtwork { image in
                completionHandler(image)
            }
            return
        }
        
        // have at least 4 images to make the collage
        // now we must fetch each of the 4 images before we can draw with them
        
        var images: [UIImage] = []
        for song in songItems {
            song.retrieveArtwork { image in
                images.append(image)
                
                // if last image is drawn, run completionHandler
                if images.count == 4 {
                    drawCollage(images) { collage in
                        completionHandler(collage)
                    }
                }
            }
        }
    }
    
    private static func drawCollage(_ images: [UIImage], _ completionHandler: @escaping (UIImage) -> ()) {
        let imageLength: Int = 400
        let l = imageLength / 2
        
        let collageSize = CGSize(width: imageLength, height: imageLength)
        let areasToDraw: [CGRect] = [
            CGRect(x: 0, y: 0, width: l, height: l),
            CGRect(x: l, y: 0, width: l, height: l),
            CGRect(x: 0, y: l, width: l, height: l),
            CGRect(x: l, y: l, width: l, height: l)
        ]
        
        UIGraphicsBeginImageContext(collageSize)
        for i in 0..<4 {
            images[i].draw(in: areasToDraw[i])
        }
        let collage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        completionHandler(collage)
    }
}
