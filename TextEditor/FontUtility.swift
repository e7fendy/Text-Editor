//
//  FontUtility.swift
//  TextEditor
//
//  Created by Fendy Wu on 2022/3/8.
//

import Foundation
import UIKit

class FontUtility {
    
    static let shared = FontUtility()
    
    var didRegisterFont: [String] = []
    
    func isRegisteredFont(data: CFData) -> Bool {
        guard let provider = CGDataProvider(data: data), let cgfont = CGFont(provider) else {
            return false
        }
        
        guard let postScriptName = cgfont.postScriptName as String? else {
            return false
        }
        
        return self.didRegisterFont.contains(postScriptName)
    }
    
    func registerFont(data: CFData) -> Bool{
        guard let provider = CGDataProvider(data: data), let cgfont = CGFont(provider) else {
            return false
        }
        
        guard CTFontManagerRegisterGraphicsFont(cgfont, nil) else {
            return false
        }
        
        guard let postScriptName = cgfont.postScriptName as String? else {
            CTFontManagerUnregisterGraphicsFont(cgfont, nil)
            return false
        }
        
        self.didRegisterFont.append(postScriptName)
        
        return true
    }
}
