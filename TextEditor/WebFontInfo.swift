//
//  WebFontInfo.swift
//  TextEditor
//
//  Created by Fendy Wu on 2022/3/2.
//

import Foundation

// MARK: - WebFontInfo
struct WebFontInfo: Codable {
    let kind: String
    let items: [WebFontItem]
}

// MARK: - WebFontItem
struct WebFontItem: Codable {
    let kind: String
    let family: String
    let variants: [String]
    let subsets: [String]
    let version: String
    let lastModified: String
    let files: Files
}

// MARK: - Files
struct Files: Codable {
    let the700: String?
    let regular: String?
    let italic, the700Italic: String?

    enum CodingKeys: String, CodingKey {
        case the700 = "700"
        case regular, italic
        case the700Italic = "700italic"
    }
}

