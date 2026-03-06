import Foundation
import SwiftUI

@MainActor
class FileOperationViewModel: ObservableObject {
    @Published var isShowingDialog: Bool = false
    @Published var dialogType: FileDialogType = .none
    @Published var dialogInput: String = ""
    @Published var dialogMessage: String = ""
    @Published var isProcessing: Bool = false
    @Published var progressMessage: String = ""

    enum FileDialogType {
        case none, copy, move, mkdir, delete, rename
    }

    private let fs = FileSystemRegistry.shared

    func promptCopy(items: [FileItem], destination: String) {
        let names = items.map(\.name).joined(separator: ", ")
        dialogMessage = "Copy \(items.count) item(s) to:"
        dialogInput = destination
        dialogType = .copy
        isShowingDialog = true
    }

    func promptMove(items: [FileItem], destination: String) {
        dialogMessage = "Move \(items.count) item(s) to:"
        dialogInput = destination
        dialogType = .move
        isShowingDialog = true
    }

    func promptMkdir(currentPath: String) {
        dialogMessage = "New folder name:"
        dialogInput = ""
        dialogType = .mkdir
        isShowingDialog = true
    }

    func promptDelete(items: [FileItem]) {
        let names = items.map(\.name).joined(separator: ", ")
        dialogMessage = "Delete \(items.count) item(s)?\n\(names)"
        dialogInput = ""
        dialogType = .delete
        isShowingDialog = true
    }

    func promptRename(item: FileItem) {
        dialogMessage = "Rename:"
        dialogInput = item.name
        dialogType = .rename
        isShowingDialog = true
    }

    func executeCopy(sources: [String], destination: String) async throws {
        isProcessing = true
        progressMessage = "Copying..."
        defer { isProcessing = false }

        let provider = fs.provider(for: sources.first ?? "")
        try await provider.copyItems(from: sources, to: destination)
    }

    func executeCopyWithRename(source: String, destinationDir: String, newName: String) async throws {
        isProcessing = true
        progressMessage = "Copying..."
        defer { isProcessing = false }

        let destPath = (destinationDir as NSString).appendingPathComponent(newName)
        let fm = FileManager.default
        guard fm.fileExists(atPath: source) else {
            throw FileSystemError.notFound(source)
        }
        if fm.fileExists(atPath: destPath) {
            throw FileSystemError.alreadyExists(destPath)
        }
        try fm.copyItem(atPath: source, toPath: destPath)
    }

    func executeMove(sources: [String], destination: String) async throws {
        isProcessing = true
        progressMessage = "Moving..."
        defer { isProcessing = false }

        let provider = fs.provider(for: sources.first ?? "")
        try await provider.moveItems(from: sources, to: destination)
    }

    func executeMoveWithRename(source: String, destinationDir: String, newName: String) async throws {
        isProcessing = true
        progressMessage = "Moving..."
        defer { isProcessing = false }

        let destPath = (destinationDir as NSString).appendingPathComponent(newName)
        let fm = FileManager.default
        guard fm.fileExists(atPath: source) else {
            throw FileSystemError.notFound(source)
        }
        if fm.fileExists(atPath: destPath) {
            throw FileSystemError.alreadyExists(destPath)
        }
        try fm.moveItem(atPath: source, toPath: destPath)
    }

    func executeMkdir(at path: String, name: String) async throws {
        isProcessing = true
        progressMessage = "Creating folder..."
        defer { isProcessing = false }

        let provider = fs.provider(for: path)
        try await provider.createDirectory(at: path, name: name)
    }

    func executeDelete(paths: [String]) async throws {
        isProcessing = true
        progressMessage = "Deleting..."
        defer { isProcessing = false }

        let provider = fs.provider(for: paths.first ?? "")
        try await provider.deleteItems(paths)
    }

    func executeRename(at path: String, to newName: String) async throws {
        isProcessing = true
        progressMessage = "Renaming..."
        defer { isProcessing = false }

        let provider = fs.provider(for: path)
        try await provider.rename(at: path, to: newName)
    }

    func dismiss() {
        isShowingDialog = false
        dialogType = .none
        dialogInput = ""
        dialogMessage = ""
    }
}
