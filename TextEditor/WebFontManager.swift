//
//  WebFontManager.swift
//  TextEditor
//
//  Created by Fendy Wu on 2022/3/2.
//

import Foundation

class WebFontManager: NSObject {
    
    struct TaskInfo {
        var dataTask: URLSessionDataTask?
        var completionBlocks: [WebFontManagerCompletionHandler] = []
    }
    
    typealias WebFontManagerCompletionHandler = (_ taskId: String?, _ error: Error?) -> Void
    
    private let GOOGLE_API_KEY = "YOUR_OWN_GOOGLE_API_KEY"
    static let shared = WebFontManager()
    let lockQueue = DispatchQueue(label: "com.textEditor.WebFontManager")
    var tasks: [String: TaskInfo] = [:] // uuid: taskinfo
    
    override init() {
        //
    }
    
    public func getList(completion: ((WebFontInfo?) -> Void)?) {
        guard let url = URL(string: String(format: "https://www.googleapis.com/webfonts/v1/webfonts?key=%@", GOOGLE_API_KEY)) else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: URLRequest(url: url)) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                DispatchQueue.main.async {
                    completion?(nil)
                }
                return
            }
            
            do {
                let webFontInfo = try JSONDecoder().decode(WebFontInfo.self, from: data)
                DispatchQueue.main.async {
                    completion?(webFontInfo)
                }
            } catch {
                print(error)
                DispatchQueue.main.async {
                    completion?(nil)
                }
            }
        }

        task.resume()
    }
    
    func addTask(_ font: WebFontItem, completion: WebFontManagerCompletionHandler? = nil) -> String? {
        guard let file = font.files.regular, let url = URL(string: file) else {
            completion?(nil, NSError(domain: "", code: 999, userInfo: nil))
            return nil
        }
        
        let uuid = UUID().uuidString
        var isDownloading = false
        var currTask: TaskInfo?
        
        // prepare
        self.lockQueue.sync {
            if self.tasks[uuid] == nil {
                self.tasks[uuid] = TaskInfo()
                currTask = self.tasks[uuid]
            }
            if let completion = completion {
                isDownloading = currTask?.completionBlocks.isEmpty == false
                currTask?.completionBlocks.append(completion)
            }
        }
        
        // return if already downloading
        if isDownloading {
            return uuid
        }
        
        // start task
        currTask?.dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            var myError: Error? = error
            if response == nil {
                myError = NSError(domain: "", code: 999, userInfo: nil)
            } else if let cfdata = data as CFData?, FontUtility.shared.isRegisteredFont(data: cfdata) == false {
                if FontUtility.shared.registerFont(data: cfdata) == false {
                    myError = NSError(domain: "", code: 999, userInfo: nil)
                }
            }
            
            // observe data
            self.lockQueue.sync {
                if let blocks = currTask?.completionBlocks {
                    DispatchQueue.main.async {
                        for completionBlock in blocks {
                            completionBlock(uuid, myError)
                        }
                    }
                }
                self.tasks.removeValue(forKey: uuid)
            }
        }
        
        currTask?.dataTask?.resume()
        
        return uuid
    }
    
    func cancelTask(_ taskId: String) {
        self.lockQueue.sync {
            self.tasks[taskId]?.dataTask?.cancel()
            self.tasks.removeValue(forKey: taskId)
        }
    }
}
