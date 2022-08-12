#!/usr/bin/env swift

import Foundation
import ImageIO

func getImageExif(_ url: URL) -> [String: Any]? {
    if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
       let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil),
       let dict = imageProperties as? [String: Any],
       let exif = dict[kCGImagePropertyExifDictionary as String]  as? [String: Any] {
        return exif
    }
    return nil
}

func formatDateTime(dateTime: String) -> String {
    return dateTime.replacingOccurrences(of: ":", with: "").replacingOccurrences(of: " ", with: "-")
}

func getAllImages() -> [String] {
    let currentPath = FileManager.default.currentDirectoryPath
    var filePaths = [String]()

    do {
       let allImagePaths = try FileManager.default.contentsOfDirectory(atPath: currentPath)
                                    .map { "\(currentPath)/\($0)" }
                                    .filter { path in

                                        var isDir: ObjCBool = false

                                        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && !isDir.boolValue else {
                                            return false
                                        }

                                        guard allowsExt.contains((path as NSString).pathExtension.lowercased()) else {
                                            return false
                                        }

                                        return true
                                    }
        filePaths.append(contentsOf: allImagePaths)
    } catch {
        print("\(red)\(error.localizedDescription)\(white)")
    }

    return filePaths
}

let allowsExt = ["jpg", "jpeg", "png", "heic"]
var success = 0, fail = 0
let red = "\u{001B}[0;31m"
let white =  "\u{001B}[0;37m"

_ = getAllImages()
    .map { path in
        let imageURL = URL(fileURLWithPath: path)
        let ext = imageURL.pathExtension
        let dirURL = imageURL.deletingLastPathComponent()

        if let exif = getImageExif(imageURL),
           let dateTime = exif["DateTimeOriginal"] as? String {
            let dateURL = dirURL.appendingPathComponent(formatDateTime(dateTime: dateTime)).appendingPathExtension(ext)
            if let _ = try? FileManager.default.moveItem(at: imageURL, to: dateURL) {
                success += 1
                print("🍻 ------ | \(imageURL.lastPathComponent) → \(dateURL.lastPathComponent)")
            }
        } else {
            fail += 1
            print("\(red)❎ ------ | \(imageURL.lastPathComponent) × No date information was found \(white)")
        }
    }

print("""

---------------------------------------------------------------
🍺 🥜  The renaming is complete, \(red)\(success)\(white) succeed, \(red)\(fail)\(white) fail !! 🍟 🍻
---------------------------------------------------------------

""")
