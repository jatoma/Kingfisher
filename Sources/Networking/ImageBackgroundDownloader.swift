//
//  ImageBackgroundDownloader.swift
//  Kingfisher

#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct TaskWrapper {
    let task: URLSessionDownloadTask
    let data: Data
}

/// `ImageBackgroundDownloader` downloading manager with background download option.
open class ImageBackgroundDownloader: ImageDownloader {
    /// The default downloader.
    public static let shared = ImageBackgroundDownloader(name: "background")
    public static var backgroundSessionCompletionHandler: (() -> Void)?
    public let sessionIdentifier: String

    override public init(name: String) {
        sessionIdentifier = "com.onevcat.Kingfisher.BackgroundSession.Identifier.\(name)"
        super.init(name: name)
        sessionDelegate = SessionDelegate()
        sessionDelegateQueue = nil
        dispatchOnCallbackQueue = false
        //sets configuration and creates also new session
        sessionConfiguration = backgroundSessionConfiguration(identifier: sessionIdentifier)
    }

    private func backgroundSessionConfiguration (identifier: String) -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        configuration.sessionSendsLaunchEvents = true
        return configuration
    }

    override  func sessionTask(with request: URLRequest) -> URLSessionTask {
        return session.downloadTask(with: request)
    }
}

///// Extends class `ImageDownloaderSessionHandler` with additional delegate `URLSessionDownloadDelegate`.
//// See ImageDownloaderSessionHandler
final class ImageBackgroundDownloaderSessionDelegte: SessionDelegate, URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {

        guard  let mutableData = NSMutableData(contentsOf: location) else {
            return
        }
        
        let taskWrapper = TaskWrapper(task: downloadTask, data: mutableData as Data)
        let result: Result<(Data, URLResponse?), KingfisherError>

        if onDidDownloadBackgroundTaskData.call(taskWrapper) != nil {
            result = .success((taskWrapper.data, downloadTask.response))
            onCompleted(task: downloadTask, result: result)
        }
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
