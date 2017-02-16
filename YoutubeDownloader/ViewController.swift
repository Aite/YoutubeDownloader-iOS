//
//  ViewController.swift
//  YoutubeDownloader
//
//  Created by Alaa Al-Zaibak on 11/02/2017.
//  Copyright © 2017 Alaa Al-Zaibak. All rights reserved.
//

import UIKit
import YoutubeSourceParserKit
import MediaPlayer
import MZDownloadManager

let alertControllerViewTag: Int = 500
let downloadingSectionIndex = 0
let downloadedSectionIndex = 1

class ViewController: UIViewController {

    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var downloadsTableView: UITableView!
    
    var selectedIndexPath : IndexPath!
    var downloadedFilesArray : [String] = []
    
    lazy var downloadManager: MZDownloadManager = { [unowned self] in
        let sessionIdentifer: String = "com.iosDevelopment.MZDownloadManager.BackgroundSession"
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        var completion = appDelegate.backgroundSessionCompletionHandler
        
        let downloadmanager = MZDownloadManager(session: sessionIdentifer, delegate: self, completion: completion)
        return downloadmanager
        }()
    
    var moviePlayer : AVPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        do {
            let contentOfDir: [String] = try FileManager.default.contentsOfDirectory(atPath: MZUtility.baseFilePath as String)
            downloadedFilesArray.append(contentsOf: contentOfDir)
            
            let index = downloadedFilesArray.index(of: ".DS_Store")
            if let index = index {
                downloadedFilesArray.remove(at: index)
            }
            
        } catch let error as NSError {
            print("Error while getting directory content \(error)")
        }
        
        NotificationCenter.default.addObserver(self, selector: NSSelectorFromString("downloadFinishedNotification:"), name: NSNotification.Name(rawValue: MZUtility.DownloadCompletedNotif as String), object: nil)
        
        //        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MZDownloadedViewController.downloadFinishedNotification(_:)), name: DownloadCompletedNotif as String, object: nil)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func download(_ sender: Any) {
//        "http://www.youtube.com/watch?v=swZJwZeMesk"
        guard let urlText = urlTextField.text else {
            let alert = UIAlertController(title: "Error!", message: "Text Field is nil...", preferredStyle: .alert)
            present(alert, animated:true, completion:nil)
            return
        }
        guard let youtubeURL = NSURL(string: urlText) else {
            let alert = UIAlertController(title: "Error!", message: "Invalide URL...", preferredStyle: .alert)
            present(alert, animated:true, completion:nil)
            return
        }
        downloadVideoWithYoutubeURL(url: youtubeURL)
    }
    
    func downloadVideoWithYoutubeURL(url: NSURL) {
        Youtube.h264videosWithYoutubeURL(url as URL, completion: { (videoInfo, error) -> Void in
            if let videoURLString = videoInfo?["url"] as? String {
                if let videoTitle = videoInfo?["title"] as? String {
//                    if let url = URL(string: videoURLString) {
//                        if let urlData = try? Data(contentsOf: url) {
                        
                            let documentsPath = StorageManager.default.documentsPath

                            let filePath="\(documentsPath)/\(videoTitle).mp4";
                            
                            //saving is done on main thread
                            self.downloadManager.addDownloadTask(videoTitle, fileURL: videoURLString, destinationPath: filePath)

//                            DispatchQueue.main.async(execute: { () -> Void in
//                                if StorageManager.default.writeFileAtPath(filePath, content: urlData) {
//                                    print("videoSaved: %d", filePath);
//                                }
//                                else {
//                                    let alert = UIAlertController(title: "Error!", message: "Error while writing file...", preferredStyle: .alert)
//                                    self.present(alert, animated:true, completion:nil)
//                                    return
//                                }
//                            })
//                        }
                        
                        //                        self.moviePlayer = AVPlayer(url: url)
                        //                        let playerLayer = AVPlayerLayer(player: self.moviePlayer)
                        //                        playerLayer.frame = self.view.bounds
                        //                        self.view.layer.addSublayer(playerLayer)
                        //                        self.moviePlayer?.play()
//                    }
                }
            }
        })
    }
    
    func refreshCellForIndex(_ downloadModel: MZDownloadModel, index: Int) {
        let indexPath = IndexPath.init(row: index, section: downloadingSectionIndex)
        let cell = self.downloadsTableView.cellForRow(at: indexPath)
        if let cell = cell {
            let downloadCell = cell as! DownloadTableViewCell
            downloadCell.updateCellForRowAtIndexPath(indexPath, downloadModel: downloadModel)
        }
    }
    
    func removeDownloadedFile(at indexPath: IndexPath) {
        if (indexPath.section == downloadedSectionIndex) {
            let fileName : NSString = downloadedFilesArray[(indexPath as NSIndexPath).row] as NSString
            let fileURL  : URL = URL(fileURLWithPath: (MZUtility.baseFilePath as NSString).appendingPathComponent(fileName as String))
            
            do {
                try FileManager.default.removeItem(at: fileURL)
                downloadedFilesArray.remove(at: (indexPath as NSIndexPath).row)
                downloadsTableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
            } catch let error as NSError {
                debugPrint("Error while deleting file: \(error)")
            }
        }

    }
    
    // MARK: - NSNotification Methods -
    
    func downloadFinishedNotification(_ notification : Notification) {
        let fileName : NSString = notification.object as! NSString
        downloadedFilesArray.append(fileName.lastPathComponent)
        var sections = IndexSet()
        sections.insert(downloadedSectionIndex)
        sections.insert(downloadingSectionIndex)
        downloadsTableView.reloadSections(sections, with: UITableViewRowAnimation.fade)
    }
}

// MARK: UITableViewDatasource Handler Extension

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == downloadingSectionIndex) {
            return "Downloading:"
        }
        else {
            return "Downloaded:"
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == downloadedSectionIndex) {
            return downloadedFilesArray.count
        }
        else { // downloadingSectionIndex
            return downloadManager.downloadingArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.section == downloadedSectionIndex) {
            let cellIdentifier : NSString = "downloaded"
            let cell : UITableViewCell = downloadsTableView.dequeueReusableCell(withIdentifier: cellIdentifier as String, for: indexPath) as UITableViewCell
            
            cell.textLabel?.text = downloadedFilesArray[(indexPath as NSIndexPath).row]
            
            return cell
        }
        else {
            let cellIdentifier : NSString = "downloading"
            let cell : DownloadTableViewCell = self.downloadsTableView.dequeueReusableCell(withIdentifier: cellIdentifier as String, for: indexPath) as! DownloadTableViewCell
            
            let downloadModel = downloadManager.downloadingArray[indexPath.row]
            cell.updateCellForRowAtIndexPath(indexPath, downloadModel: downloadModel)
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.section == downloadedSectionIndex) {
            return 44
        }
        else {
            return 120
        }
    }
}

// MARK: UITableViewDelegate Handler Extension

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.section == downloadedSectionIndex) {
            selectedIndexPath = indexPath
            self.showAlertControllerForOpen()
            tableView.deselectRow(at: indexPath, animated: true)
        }
        else {
            selectedIndexPath = indexPath
            
            let downloadModel = downloadManager.downloadingArray[indexPath.row]
            self.showAppropriateActionController(downloadModel.status)
            
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        self.removeDownloadedFile(at: indexPath)
    }
}

// MARK: UIAlertController Handler Extension

extension ViewController {

    func showAppropriateActionController(_ requestStatus: String) {
        
        if requestStatus == TaskStatus.downloading.description() {
            self.showAlertControllerForPause()
        } else if requestStatus == TaskStatus.failed.description() {
            self.showAlertControllerForRetry()
        } else if requestStatus == TaskStatus.paused.description() {
            self.showAlertControllerForStart()
        }
    }
    
    func showAlertControllerForPause() {
        
        let pauseAction = UIAlertAction(title: "Pause", style: .default) { (alertAction: UIAlertAction) in
            self.downloadManager.pauseDownloadTaskAtIndex(self.selectedIndexPath.row)
        }
        
        let removeAction = UIAlertAction(title: "Remove", style: .destructive) { (alertAction: UIAlertAction) in
            self.downloadManager.cancelTaskAtIndex(self.selectedIndexPath.row)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.view.tag = alertControllerViewTag
        alertController.addAction(pauseAction)
        alertController.addAction(removeAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showAlertControllerForRetry() {
        
        let retryAction = UIAlertAction(title: "Retry", style: .default) { (alertAction: UIAlertAction) in
            self.downloadManager.retryDownloadTaskAtIndex(self.selectedIndexPath.row)
        }
        
        let removeAction = UIAlertAction(title: "Remove", style: .destructive) { (alertAction: UIAlertAction) in
            self.downloadManager.cancelTaskAtIndex(self.selectedIndexPath.row)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.view.tag = alertControllerViewTag
        alertController.addAction(retryAction)
        alertController.addAction(removeAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showAlertControllerForStart() {
        
        let startAction = UIAlertAction(title: "Start", style: .default) { (alertAction: UIAlertAction) in
            self.downloadManager.resumeDownloadTaskAtIndex(self.selectedIndexPath.row)
        }
        
        let removeAction = UIAlertAction(title: "Remove", style: .destructive) { (alertAction: UIAlertAction) in
            self.downloadManager.cancelTaskAtIndex(self.selectedIndexPath.row)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.view.tag = alertControllerViewTag
        alertController.addAction(startAction)
        alertController.addAction(removeAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showAlertControllerForOpen() {
        let openAction = UIAlertAction(title: "Open In...", style: .default) { (alertAction: UIAlertAction) in
            self.openDownloadedFile(at: self.selectedIndexPath)
        }
        
        let removeAction = UIAlertAction(title: "Remove", style: .destructive) { (alertAction: UIAlertAction) in
            self.removeDownloadedFile(at: self.selectedIndexPath)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.view.tag = alertControllerViewTag
        alertController.addAction(openAction)
        alertController.addAction(removeAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func safelyDismissAlertController() {
        /***** Dismiss alert controller if and only if it exists and it belongs to MZDownloadManager *****/
        /***** E.g App will eventually crash if download is completed and user tap remove *****/
        /***** As it was already removed from the array *****/
        if let controller = self.presentedViewController {
            guard controller is UIAlertController && controller.view.tag == alertControllerViewTag else {
                return
            }
            controller.dismiss(animated: true, completion: nil)
        }
    }
}

extension ViewController: UIDocumentInteractionControllerDelegate {
    func openDownloadedFile(at indexPath: IndexPath) {
        if (indexPath.section == downloadedSectionIndex) {
            let fileName : NSString = downloadedFilesArray[(indexPath as NSIndexPath).row] as NSString
            let fileURL  : URL = URL(fileURLWithPath: (MZUtility.baseFilePath as NSString).appendingPathComponent(fileName as String))

            let popup = UIDocumentInteractionController(url: fileURL)
            popup.delegate = self
            popup.presentOpenInMenu(from: view.bounds, in: view, animated: true)
        }
    }
    
//    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
//        return self
//    }
}

extension ViewController: MZDownloadManagerDelegate {
    
    func downloadRequestStarted(_ downloadModel: MZDownloadModel, index: Int) {
        let indexPath = IndexPath.init(row: index, section: downloadingSectionIndex)
        downloadsTableView.insertRows(at: [indexPath], with: UITableViewRowAnimation.fade)
    }
    
    func downloadRequestDidPopulatedInterruptedTasks(_ downloadModels: [MZDownloadModel]) {
        downloadsTableView.reloadData()
    }
    
    func downloadRequestDidUpdateProgress(_ downloadModel: MZDownloadModel, index: Int) {
        self.refreshCellForIndex(downloadModel, index: index)
    }
    
    func downloadRequestDidPaused(_ downloadModel: MZDownloadModel, index: Int) {
        self.refreshCellForIndex(downloadModel, index: index)
    }
    
    func downloadRequestDidResumed(_ downloadModel: MZDownloadModel, index: Int) {
        self.refreshCellForIndex(downloadModel, index: index)
    }
    
    func downloadRequestCanceled(_ downloadModel: MZDownloadModel, index: Int) {
        
        self.safelyDismissAlertController()
        
        let indexPath = IndexPath.init(row: index, section: downloadingSectionIndex)
        downloadsTableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.left)
    }
    
    func downloadRequestFinished(_ downloadModel: MZDownloadModel, index: Int) {
        
        self.safelyDismissAlertController()
        
        downloadManager.presentNotificationForDownload("Ok", notifBody: "Download did completed")
        
        let indexPath = IndexPath.init(row: index, section: downloadingSectionIndex)
        downloadsTableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.left)
        
        let docDirectoryPath : NSString = (MZUtility.baseFilePath as NSString).appendingPathComponent(downloadModel.fileName) as NSString
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: MZUtility.DownloadCompletedNotif as String), object: docDirectoryPath)
    }
    
    func downloadRequestDidFailedWithError(_ error: NSError, downloadModel: MZDownloadModel, index: Int) {
        self.safelyDismissAlertController()
        self.refreshCellForIndex(downloadModel, index: index)
        
        debugPrint("Error while downloading file: \(downloadModel.fileName)  Error: \(error)")
    }
    
    //Oppotunity to handle destination does not exists error
    //This delegate will be called on the session queue so handle it appropriately
    func downloadRequestDestinationDoestNotExists(_ downloadModel: MZDownloadModel, index: Int, location: URL) {
        let myDownloadPath = MZUtility.baseFilePath // + "/Default folder"
        if !FileManager.default.fileExists(atPath: myDownloadPath) {
            try! FileManager.default.createDirectory(atPath: myDownloadPath, withIntermediateDirectories: true, attributes: nil)
        }
        let fileName = MZUtility.getUniqueFileNameWithPath((myDownloadPath as NSString).appendingPathComponent(downloadModel.fileName as String) as NSString)
        let path =  myDownloadPath + "/" + (fileName as String)
        try! FileManager.default.moveItem(at: location, to: URL(fileURLWithPath: path))
        debugPrint("Default folder path: \(myDownloadPath)")
    }
}

