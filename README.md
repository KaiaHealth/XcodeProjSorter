# XcodeProjSorter

A library with command line interface to sort Xcode's `.xcodeproj` file. It sorts following sessions:
- `PBXGroup` and `PBXVariantGroup`
- `PBXResourcesBuildPhase`
- `PBXSourcesBuildPhase`
- Targets
- Remote Swift packages

## Command Line Tool

You can find the command-line tool project under `CLI` directory and build it by yourself. Or, you can download it from [releases](https://github.com/chiahsien/XcodeProjSorter/releases) page.

## Usage

`xcodeproj-sorter [--case-insensitive] [--numeric] <path-to-xcodeproj-file>`

Use `xcodeproj-sorter -h` for more information.

You can use it to sort Xcode project file before committing it to git version control. Sorting project file can reduce merging conflict possibility.

### 1.
Create a `Tools` directory in project root directory, and put `xcodeproj-sorter` into `Tools` directory.

### 2.
Put following codes into `.git/hooks/pre-commit`.

```bash
#!/bin/bash
#
# Following script is to sort Xcode project files, and add them back to version control.
# The reason to sort project file is that it can reduce project.pbxproj file merging conflict possibility.
# Source: https://github.com/KaiaHealth/XcodeProjSorter/blob/main/README.md
#

echo "Execute pre-commit hook for sorting project files"

GIT_ROOT=$(git rev-parse --show-toplevel)
sorter="$GIT_ROOT/util-scripts/xcodeproj-sorter"
modifiedProjectFiles=$(git diff --name-only --cached | grep "project.pbxproj")

oldIFS=$IFS
IFS=$(echo -en "\n\b")
for filePath in $modifiedProjectFiles; do
  pbxprojPath="$GIT_ROOT/$filePath"
  xcodeprojPath=$(dirname "$pbxprojPath")
  echo "Sorting for $xcodeprojPath"
  $sorter "$xcodeprojPath" --case-insensitive --type-sort
  git add "$xcodeprojPath"
  echo "Done sorting for $xcodeprojPath"
done
IFS=$oldIFS

exit 0
```

### 3.
Put following line into `.gitattributes` then commit it.

```
*.pbxproj merge=union
```

## License

MIT license.
