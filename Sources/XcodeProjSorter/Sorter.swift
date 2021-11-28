//
//  Sorter.swift
//  
//
//  Created by Nelson on 2021/11/28.
//

import Foundation
import PathKit
import XcodeProj

final class Sorter {
    func sort(fileAtPath: String) throws {
        let path = Path(fileAtPath)
        let project = try XcodeProj(path: path)
        let pbxproj = project.pbxproj

        sortGroup(pbxproj: pbxproj)
        sortSourcesBuildPhase(pbxproj: pbxproj)
        sortResourcesBuildPhase(pbxproj: pbxproj)

        try project.write(path: path)
    }
}

private extension Sorter {
    // Project Navigator
    func sortGroup(pbxproj: PBXProj) {
        for group in pbxproj.groups {
            group.children.sort { lhs, rhs in
                if lhs is PBXGroup && !(rhs is PBXGroup) {
                    return true
                } else if !(lhs is PBXGroup) && rhs is PBXGroup {
                    return false
                } else {
                    let lhsName = lhs.name ?? lhs.path ?? ""
                    let rhsName = rhs.name ?? rhs.path ?? ""
                    return numericSort(lhs: lhsName, rhs: rhsName)
                }
            }
        }
    }

    // Compile Sources Phase
    func sortSourcesBuildPhase(pbxproj: PBXProj) {
        for sourceBuildPhase in pbxproj.sourcesBuildPhases {
            sourceBuildPhase.files?.sort { lhs, rhs in
                let lhsName = lhs.file?.name ?? lhs.file?.path ?? ""
                let rhsName = rhs.file?.name ?? rhs.file?.path ?? ""
                return numericSort(lhs: lhsName, rhs: rhsName)
            }
        }
    }

    // Copy Bundle Resources Phase
    func sortResourcesBuildPhase(pbxproj: PBXProj) {
        for resourcesBuildPhase in pbxproj.resourcesBuildPhases {
            resourcesBuildPhase.files?.sort { lhs, rhs in
                let lhsName = lhs.file?.name ?? lhs.file?.path ?? ""
                let rhsName = rhs.file?.name ?? rhs.file?.path ?? ""
                return numericSort(lhs: lhsName, rhs: rhsName)
            }
        }
    }

    func numericSort(lhs: String, rhs: String, result: ComparisonResult = .orderedAscending) -> Bool {
        return lhs.compare(rhs, options: .numeric) == result
    }
}