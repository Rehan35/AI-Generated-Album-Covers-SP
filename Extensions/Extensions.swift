//
//  Extensions.swift
//  Album Cover Generator
//
//  Created by Rehan Parwani on 4/17/23.
//

import Foundation
import SpotifyWebAPI

extension Album {

    func loadAlbumImage() {

        var spotifyImage: SpotifyImage

        var image: Image

        if let image = self.images?.largest {
            spotifyImage = image
        }
        else { return }

        // print("loading image for '\(playlist.name)'")

        // Note that a `Set<AnyCancellable>` is NOT being used so that each time
        // a request to load the image is made, the previous cancellable
        // assigned to `loadImageCancellable` is deallocated, which cancels the
        // publisher.
        var loadImageCancellable = spotifyImage.load()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { image in
                    // print("received image for '\(playlist.name)'")
                    image = image
                }
            )
    }
}
