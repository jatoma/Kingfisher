//
//  ImageBackgroundDownloader.swift
//  Kingfisher

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// `ImageBackgroundDownloader` downloading manager with background download option.
open class ImageBackgroundDownloader: ImageDownloader {
    /// The default downloader.
    public static let shared = ImageBackgroundDownloader(name: "background")
    public static var backgroundSessionCompletionHandler: (() -> Void)?
    public let sessionIdentifier: String

    override public init(name: String) {
        sessionIdentifier = "com.onevcat.Kingfisher.BackgroundSession.Identifier.\(name)"
        super.init(name: name)
        sessionHandler = ImageBackgroundDownloaderSessionHandler()
        sessionDelegateQueue = nil
        dispatchOnCallbackQueue = false
        authenticationChallengeResponder = sessionHandler
        //sets configuration and creates also new session
        sessionConfiguration = backgroundSessionConfiguration(identifier: sessionIdentifier)
    }

    private func backgroundSessionConfiguration (identifier: String) -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        configuration.sessionSendsLaunchEvents = true
        return configuration
    }

    override  func sessionTask(with request: URLRequest) -> URLSessionTask? {
        guard let session = session else { return nil }
        return session.downloadTask(with: request)
    }
}

/// Extends class `ImageDownloaderSessionHandler` with additional delegate `URLSessionDownloadDelegate`.
// See ImageDownloaderSessionHandler
final class ImageBackgroundDownloaderSessionHandler: ImageDownloaderSessionHandler, URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let url = downloadTask.originalRequest?.url else {
            return
        }

        guard let downloader = downloadHolder else {
            return
        }

        guard let fetchLoad = downloader.fetchLoad(for: url) else {
            return
        }

        guard  let data = NSMutableData(contentsOf: location) else {
            return
        }

        fetchLoad.responseData = data
    }

    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        if let backgroundCompletion = ImageBackgroundDownloader.backgroundSessionCompletionHandler {
            DispatchQueue.main.async(execute: {
                ImageBackgroundDownloader.backgroundSessionCompletionHandler = nil
                backgroundCompletion()
            })
        }
    }
}
