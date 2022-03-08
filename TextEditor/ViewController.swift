//
//  ViewController.swift
//  TextEditor
//
//  Created by Fendy Wu on 2022/3/2.
//

import UIKit

class TableViewCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    
    var taskId: String?
}

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var previewLabel: UILabel!
    
    private var downloadTasks: [URLSessionDownloadTask]?
    
    private var fonts: [WebFontItem]?
    private var tasks: [Int: String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.prefetchDataSource = self
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.textField.delegate = self
        self.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        WebFontManager.shared.getList { webFontInfo in
            self.fonts = webFontInfo?.items
            self.tableView.reloadData()
            
            self.tableView.selectRow(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .none)
            if let font = self.fonts?.first {
                _ = WebFontManager.shared.addTask(font, completion: { _, _ in
                    self.updatePreview()
                })
            }
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        self.updatePreview()
    }
    
    func updatePreview() {
        guard let selectedIndexPath = self.tableView.indexPathForSelectedRow, let font = self.fonts?[selectedIndexPath.row] else {
            return
        }
        
        if self.textField.text?.isEmpty ?? true {
            return
        }
        
        self.previewLabel.text = self.textField.text
        self.previewLabel.font = UIFont(name: font.family, size: 20)
    }

}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.updatePreview()
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return (self.fonts?.isEmpty ?? true) ? "Loading..." : nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fonts?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as? TableViewCell else {
            return tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath)
        }
        
        if let font = self.fonts?[indexPath.row] {
            cell.label.text = font.family
            cell.label.alpha = 0
            cell.taskId = WebFontManager.shared.addTask(font, completion: { taskId, error in
                if cell.taskId != taskId {
                    return
                }
                cell.label.font = UIFont(name: font.family, size: 17)
                
                UIView.animate(withDuration: 0.3, animations: {
                    cell.label.alpha = 1.0
                })
            })
        }
        
        return cell
    }
}

extension ViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if let font = self.fonts?[indexPath.row] {
                let taskId = WebFontManager.shared.addTask(font)
                self.tasks[indexPath.row] = taskId
            }
        }
    }

    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if let taskId = self.tasks[indexPath.row] {
                WebFontManager.shared.cancelTask(taskId)
            }
        }
    }

}
