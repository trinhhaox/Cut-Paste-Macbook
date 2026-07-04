import Foundation

// A single completed move, used to support Undo.
struct MovedItem {
    let from: String
    let to: String
}

enum FileMoveError: LocalizedError {
    case fileNotFound(String)
    case destinationNotWritable(String)
    case moveError(String, String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return L.t("error.not_found", path)
        case .destinationNotWritable(let path):
            return L.t("error.not_writable", path)
        case .moveError(let file, let error):
            return L.t("error.move_failed", file, error)
        }
    }
}

class FileMover {
    private let fileManager = FileManager.default

    func moveFiles(_ sources: [String], to destination: String) -> Result<[MovedItem], FileMoveError> {
        // Verify destination is writable
        guard fileManager.isWritableFile(atPath: destination) else {
            return .failure(.destinationNotWritable(destination))
        }

        var moved: [MovedItem] = []

        for source in sources {
            // Check source exists
            guard fileManager.fileExists(atPath: source) else {
                NSLog("CutPaste: File không tồn tại, bỏ qua: \(source)")
                continue
            }

            let fileName = (source as NSString).lastPathComponent
            var destPath = (destination as NSString).appendingPathComponent(fileName)

            // Don't move to same location
            let sourceDir = (source as NSString).deletingLastPathComponent
            let normalizedDest = destination.hasSuffix("/") ? String(destination.dropLast()) : destination
            if sourceDir == normalizedDest {
                NSLog("CutPaste: File đã ở thư mục đích, bỏ qua: \(fileName)")
                continue
            }

            // Handle name conflict
            destPath = resolveConflict(destPath)

            do {
                try fileManager.moveItem(atPath: source, toPath: destPath)
                moved.append(MovedItem(from: source, to: destPath))
                NSLog("CutPaste: Đã di chuyển \(fileName) → \(destination)")
            } catch {
                return .failure(.moveError(fileName, error.localizedDescription))
            }
        }

        return .success(moved)
    }

    // Reverse a previous move: send each file back to its original path.
    func undoMoves(_ items: [MovedItem]) -> Result<Int, FileMoveError> {
        var restored = 0

        for item in items.reversed() {
            guard fileManager.fileExists(atPath: item.to) else {
                NSLog("CutPaste: Không tìm thấy file để hoàn tác, bỏ qua: \(item.to)")
                continue
            }

            // Original parent folder must still exist.
            let parent = (item.from as NSString).deletingLastPathComponent
            guard fileManager.fileExists(atPath: parent) else {
                NSLog("CutPaste: Thư mục gốc không còn, bỏ qua hoàn tác: \(item.from)")
                continue
            }

            // If the original path is taken again, avoid overwriting.
            let dest = fileManager.fileExists(atPath: item.from) ? resolveConflict(item.from) : item.from

            do {
                try fileManager.moveItem(atPath: item.to, toPath: dest)
                restored += 1
            } catch {
                let name = (item.to as NSString).lastPathComponent
                return .failure(.moveError(name, error.localizedDescription))
            }
        }

        return .success(restored)
    }

    private func resolveConflict(_ path: String) -> String {
        guard fileManager.fileExists(atPath: path) else { return path }

        let nsPath = path as NSString
        let directory = nsPath.deletingLastPathComponent
        let ext = nsPath.pathExtension
        let nameWithoutExt = (nsPath.lastPathComponent as NSString).deletingPathExtension

        var counter = 1
        var newPath: String

        repeat {
            let newName: String
            if ext.isEmpty {
                newName = "\(nameWithoutExt) (\(counter))"
            } else {
                newName = "\(nameWithoutExt) (\(counter)).\(ext)"
            }
            newPath = (directory as NSString).appendingPathComponent(newName)
            counter += 1
        } while fileManager.fileExists(atPath: newPath)

        return newPath
    }
}
