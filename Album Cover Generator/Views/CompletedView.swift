//
//  CompletedView.swift
//  Album Cover Generator
//
//  Created by Rehan Parwani on 5/17/23.
//

import SwiftUI
import SpotifyWebAPI
import Combine
import CoreML
import Accelerate
import CoreGraphics
import StableDiffusion

struct CompletedView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var spotify: Spotify
    
    let collection: Any
    
    let data = ""

    @State var generatedImage: Image
    let collectionName : String
    let isPlaylist : Bool
    
    @State var cancellables: [AnyCancellable] = []
    
    @State var items : [Any] = []
    
    @State var displayShareSheet = false
    
    @Binding var displayCompletedView : Bool
    
    @State private var renderedImage: Image?
    
    @State private var uploadToSpotifyAlert = "Playlist Image Uploaded"
    @State private var displayUploadAlert = false
    @State private var uploadingText = "Upload to Spotify"
    
    var body: some View {
        VStack {
            generatedImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(50)
                .shadow(radius: 20)
                .padding()
                .onAppear {
                    let renderer = ImageRenderer(content: generatedImage)
                    renderer.scale = 3
                    if let image = renderer.cgImage {
                        renderedImage = Image(decorative: image, scale: 1.0)
                    }
                }
            Text(collectionName)
                .font(.largeTitle)
                .bold()
            
            Button(action: {
                
            }) {
                HStack {
                    Text("Show Diffusion Steps")
                    Image(systemName: "photo.on.rectangle.angled")
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(colorScheme == .dark ? .black : .white)
                .padding(10)
                .bold()
            }
            .background(Color.primary)
            .cornerRadius(10)
            .padding(5)
            
            if (isPlaylist) {
                Button(action: {
                    uploadingText = "Uploading..."
                    if let playlist = collection as? Playlist<PlaylistItemsReference> {
                        let renderer = ImageRenderer(content: generatedImage)
                        renderer.scale = 3
                        if let image = renderer.uiImage {
                            if let imageData = image.jpeg(.lowest) {
                                print(imageData.base64EncodedString())
                                uploadPlaylistImage(playlist: playlist, param: imageData.base64EncodedString())
                            }
                        }
                    }
                }) {
                    HStack {
                        Text(uploadingText)
                        Image(systemName: "music.note")
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .padding(10)
                    .bold()
                }
                .background(Color.primary)
                .cornerRadius(10)
                .padding(5)
            }
            
            Button(action: {
                displayCompletedView = false
            }) {
                Text("Done")
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                    .padding(10)
                    .bold()
            }
            .background(Color.primary)
            .cornerRadius(10)
            .padding(5)
        }
        .navigationTitle(!isPlaylist ? Text("Album Cover") : Text("Playlist Cover"))
        .toolbar {
            if let renderedImage {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink("Share", item: renderedImage, subject: Text("Share Generated Image"),  message: Text(""), preview: SharePreview(Text(collectionName), image: renderedImage))
                }
            }
        }
        .alert(self.uploadToSpotifyAlert, isPresented: $displayUploadAlert) {
            Button("OK", role: .cancel) { }
        }
        
    }
    
    func uploadPlaylistImage(playlist: Playlist<PlaylistItemsReference>, param: String) {
        let index = playlist.uri.index(playlist.uri.lastIndex(of: ":")!, offsetBy: 1)
        print(playlist.uri)
        print(playlist.uri[index...])
        guard let url = URL(string: "https://api.spotify.com/v1/playlists/\(playlist.uri[index...])/images/") else { return }
        print(1)
        
        let paramData = param.data(using: .utf8)
        
        let apiKey = spotify.api.authorizationManager.accessToken ?? ""
        print("API KEY \(apiKey)")
        
        var request = URLRequest(url: url)
        print(2)
        
        request.httpMethod = "PUT"
        request.httpBody = paramData
        print(3)
        
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        print(4)
        
        let response = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print(error)
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                return
            }
            print(response.statusCode)
            if response.statusCode >= 200 && response.statusCode < 300 {
                uploadToSpotifyAlert = "Uploaded to Spotify Successfully"
            } else {
                uploadToSpotifyAlert = "Failed to Upload. Try Again!"
            }
            displayUploadAlert = true
            uploadingText = "Upload to Spotify"

        }
        response.resume()

    }
    
}

extension UIImage {
    enum JPEGQuality: CGFloat {
        case lowest  = 0
        case low     = 0.25
        case medium  = 0.5
        case high    = 0.75
        case highest = 1
    }
    
    /// Returns the data for the specified image in JPEG format.
    /// If the image object’s underlying image data has been purged, calling this function forces that data to be reloaded into memory.
    /// - returns: A data object containing the JPEG data, or nil if there was a problem generating the data. This function may return nil if the image has no data or if the underlying CGImageRef contains data in an unsupported bitmap format.
    func jpeg(_ jpegQuality: JPEGQuality) -> Data? {
        return jpegData(compressionQuality: jpegQuality.rawValue)
    }
}

extension SpotifyAuthorizationManager where Self: SpotifyScopeAuthorizationManager {}
