import Foundation

struct BackingTrack: Identifiable, Equatable, Hashable {
    let title: String
    let resourceName: String
    let fileExtension: String

    var id: String {
        "\(resourceName).\(fileExtension)"
    }

    func resourceURL(in bundle: Bundle = .main) -> URL? {
        if let url = bundle.url(forResource: resourceName, withExtension: fileExtension) {
            return url
        }
        #if DEBUG
        // Development fallback: load from the source directory when not bundled
        let sourceDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let devURL = sourceDirectory.appendingPathComponent("\(resourceName).\(fileExtension)")
        if FileManager.default.fileExists(atPath: devURL.path) {
            return devURL
        }
        #endif
        return nil
    }

    static func discoverBundledTracks(in bundle: Bundle = .main) -> [BackingTrack] {
        let midiExtensions = ["mid", "midi"]
        var urls = midiExtensions.flatMap { bundle.urls(forResourcesWithExtension: $0, subdirectory: nil) ?? [] }
        #if DEBUG
        if urls.isEmpty {
            // Development fallback: read from source directory if not bundled
            let sourceDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            if let contents = try? FileManager.default.contentsOfDirectory(at: sourceDirectory, includingPropertiesForKeys: nil) {
                let devURLs = contents.filter { midiExtensions.contains($0.pathExtension.lowercased()) }
                urls.append(contentsOf: devURLs)
            }
        }
        #endif
        let tracks = urls.map { url in
            BackingTrack(
                title: url.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " ").uppercased(),
                resourceName: url.deletingPathExtension().lastPathComponent,
                fileExtension: url.pathExtension
            )
        }
        return Array(Set(tracks)).sorted { $0.title < $1.title }
    }
}
