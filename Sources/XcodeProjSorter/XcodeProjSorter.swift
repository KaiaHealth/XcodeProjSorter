//
//  Sorter.swift
//  
//
//  Created by Nelson on 2021/11/28.
//

import Foundation
import PathKit
import XcodeProj

public final class XcodeProjSorter {
    let path: Path
    let project: XcodeProj
    let options: String.CompareOptions
    let typeSort: Bool
    let folders: [String]?

    public init(
        fileAtPath: String,
        options: String.CompareOptions,
        typeSort: Bool,
        folders: [String]? = nil
    ) throws {
        self.path = Path(fileAtPath)
        self.project = try XcodeProj(path: path)
        self.options = options
        self.typeSort = typeSort
        self.folders = folders
    }

    public func sort() throws {
        sortGroups()
        sortSourcesBuildPhase()
        sortResourcesBuildPhase()

        try project.write(path: path)
    }
}

extension XcodeProjSorter {
    // Project Navigator
    func sortGroups() {
        for group in project.pbxproj.groups {
            // Check if the user defined specific folders instead of sorting all folders' content
            if let folders = folders {
                // Skip the root directory
                guard group.parent != nil else {
                    continue
                }
                // Skip if the group wasn't specified for sorting
                if let path = group.path,
                   !folders.contains(path) {
                    continue
                }
            }

            group.children.sort { lhs, rhs in
                if lhs is PBXGroup && !(rhs is PBXGroup) {
                    return !typeSort
                } else if !(lhs is PBXGroup) && rhs is PBXGroup {
                    return typeSort
                } else {
                    let lhsName = lhs.name ?? lhs.path ?? ""
                    let rhsName = rhs.name ?? rhs.path ?? ""
                    return sortNames(lhs: lhsName, rhs: rhsName)
                }
            }
        }

        for group in project.pbxproj.variantGroups {
            group.children.sort { lhs, rhs in
                let lhsName = lhs.name ?? lhs.path ?? ""
                let rhsName = rhs.name ?? rhs.path ?? ""
                return sortNames(lhs: lhsName, rhs: rhsName)
            }
        }
    }

    // Compile Sources Phase
    func sortSourcesBuildPhase() {
        for sourceBuildPhase in project.pbxproj.sourcesBuildPhases {
            sourceBuildPhase.files?.sort { lhs, rhs in
                let lhsName = lhs.file?.name ?? lhs.file?.path ?? ""
                let rhsName = rhs.file?.name ?? rhs.file?.path ?? ""
                return sortNames(lhs: lhsName, rhs: rhsName)
            }
        }
    }

    // Copy Bundle Resources Phase
    func sortResourcesBuildPhase() {
        for resourcesBuildPhase in project.pbxproj.resourcesBuildPhases {
            resourcesBuildPhase.files?.sort { lhs, rhs in
                let lhsName = lhs.file?.name ?? lhs.file?.path ?? ""
                let rhsName = rhs.file?.name ?? rhs.file?.path ?? ""
                return sortNames(lhs: lhsName, rhs: rhsName)
            }
        }
    }

    func sortNames(lhs: String, rhs: String) -> Bool {
        return lhs.compare(rhs, options: options) == .orderedAscending
    }
}
