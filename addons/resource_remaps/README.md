# Godot Resource Remaps
Editor plugin for Godot that enables remapping resources by feature. An essential tool for porting your Godot project!

![Resource Remaps project settings screenshot](./meta/screenshot.png)

# Features
- Remap any resource or file in your project to a different one when your project is exported, based on the [feature tags](https://docs.godotengine.org/en/stable/tutorials/export/feature_tags.html) of that export.
- Quickly and easily reduce export size when supporting different platforms.
    - _Any remaps that are not used will automatically be excluded from the exported project._
- Compliments existing [Resource Export Modes](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html#resource-options).
- A productive Project Settings GUI including undo/redo support.
- Uses Godot's [EditorExportPlugin](https://docs.godotengine.org/en/stable/classes/class_editorexportplugin.html) functionality.

# Examples
- Remap high quality music files used in the PC exports to be low quality mobile music files in the mobile exports.
- Change button call-out textures to represent the controller used by the platform.
- Make menu scenes appear different in the mobile game than the PC game.

# Usage
## Installation
1) Install the add-on by copying the files from the release package into your project's `addons` folder.
2) Enable the plugin in your Project Settings.

## Adding Resource Remaps
1) Open Project Settings and select the `Resource Remaps` tab.
2) Add the path of the resource you would like to remap by tapping the `Add...` button on the top right.
3) Add remap(s) by tapping the `Add..` button that is to the right of `Remaps by Feature:`.
    - _Tip: multiple remap paths can be added at once by holding `shift` or `ctrl` when selecting files!_
4) Change the `Feature` for each remap.
5) Reorder remaps to change priority.
    - _From top to bottom, the first remap in this list to match a feature in the export will be used. Any resources in this list that are not used will be excluded from the export._

## Inherited Resources and Scenes
Care must be taken when remapping inherited resources, such as inherited scenes. For example, you cannot remap a base scene to an inherited scene because the base scene would no longer exist for the inherited scene to inherit from.

To work around this limitation, use a default scene that inherits from a base scene throughout your project. Next, remap the default scene to other scenes that also inherit from the base scene. An example of this approach is included in the example project of this GitHub repository.

# Requirements
## Godot 4.3
**Godot 4.3 or later is required for this plugin.**

## Earlier Versions of Godot
A custom build of the Godot editor is required for versions earlier than Godot 4.3. At minimum, you will need to cherry pick [commit 8e65966](https://github.com/godotengine/godot/commit/8e6596629a7e239bb3b8008b96554850d5688233).

# Design Rational
...Can be found in the [design notes](./meta/DESIGN_NOTES.md) file.

# Special Thanks
Thanks to [KoBeWi](https://github.com/KoBeWi) for giving guidance throughout development of this plugin!