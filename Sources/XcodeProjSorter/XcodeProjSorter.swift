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
    public struct SortScope {
        let root: Bool
        let buildPhasesSources: Bool
        let buildPhasesResources: Bool

        public init(root: Bool, buildPhasesSources: Bool, buildPhasesResources: Bool) {
            self.root = root
            self.buildPhasesSources = buildPhasesSources
            self.buildPhasesResources = buildPhasesResources
        }
    }

    let path: Path
    let project: XcodeProj
    let options: String.CompareOptions
    let typeSort: Bool
    let sortScope: SortScope

    public init(
        fileAtPath: String,
        options: String.CompareOptions,
        typeSort: Bool,
        sortScope: SortScope
    ) throws {
        self.path = Path(fileAtPath)
        self.project = try XcodeProj(path: path)
        self.options = options
        self.typeSort = typeSort
        self.sortScope = sortScope
    }

    public func sort() throws {
        let didSortGroups = sortGroups()
        let didSortSourcesBuildPhases = sortScope.buildPhasesSources && sortSourcesBuildPhase()
        let didSortResourcesBuildPhases = sortScope.buildPhasesResources && sortResourcesBuildPhase()

        if didSortGroups || didSortSourcesBuildPhases || didSortResourcesBuildPhases {
            try project.writePBXProj(path: path, outputSettings: .init())
        } else {
            print("No change required in the order of project files. PBXProj file is left untouched.")
        }
    }
}

extension XcodeProjSorter {
    // Project Navigator
    func sortGroups() -> Bool {
        var didSortElements = false
        for group in project.pbxproj.groups {
            if !sortScope.root && group.parent == nil {
                continue
            }

            let elementsSorted = group.children.sorted { lhs, rhs in
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

            if group.children != elementsSorted {
                group.children = elementsSorted
                didSortElements = true
            }
        }

        for group in project.pbxproj.variantGroups {
            let elementsSorted = group.children.sorted { lhs, rhs in
                let lhsName = lhs.name ?? lhs.path ?? ""
                let rhsName = rhs.name ?? rhs.path ?? ""
                return sortNames(lhs: lhsName, rhs: rhsName)
            }

            if group.children != elementsSorted {
                group.children = elementsSorted
                didSortElements = true
            }
        }

        return didSortElements
    }

    // Compile Sources Phase
    func sortSourcesBuildPhase() -> Bool {
        var didSortElements = false
        for sourceBuildPhase in project.pbxproj.sourcesBuildPhases {
            let elementsSorted = sourceBuildPhase.files?.sorted { lhs, rhs in
                let lhsName = lhs.file?.name ?? lhs.file?.path ?? ""
                let rhsName = rhs.file?.name ?? rhs.file?.path ?? ""
                return sortNames(lhs: lhsName, rhs: rhsName)
            }

            if sourceBuildPhase.files != elementsSorted {
                sourceBuildPhase.files = elementsSorted
                didSortElements = true
            }
        }

        return didSortElements
    }

    // Copy Bundle Resources Phase
    func sortResourcesBuildPhase() -> Bool {
        var didSortElements = false
        for resourcesBuildPhase in project.pbxproj.resourcesBuildPhases {
            let elementsSorted = resourcesBuildPhase.files?.sorted { lhs, rhs in
                let lhsName = lhs.file?.name ?? lhs.file?.path ?? ""
                let rhsName = rhs.file?.name ?? rhs.file?.path ?? ""
                return sortNames(lhs: lhsName, rhs: rhsName)
            }


            if resourcesBuildPhase.files != elementsSorted {
                resourcesBuildPhase.files = elementsSorted
                didSortElements = true
            }
        }

        return didSortElements
    }

    func sortNames(lhs: String, rhs: String) -> Bool {
        return lhs.compare(rhs, options: options) == .orderedAscending
    }
}
