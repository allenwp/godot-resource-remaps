This is an implementation of [this proposal](https://github.com/godotengine/godot-proposals/issues/10051).

Here are the original design notes and rational for the design of this add-on:

### Describe the problem or limitation you are having in your project

There is no built-in functionality to help remap resources based on which export I am targeting. Here are some examples of when I want to remap resources:

- Remap an Xbox controller diagram packed scene to a touch screen controls diagram packed scene when exporting to Google Play and App Store.
- Remap a high quality Ogg Vorbis music file to a low quality MP3 music file when exporting to Google Play and App Store.

I have written a [blog post](https://allenwp.com/?p=1467) that describes a number of challenges and solutions to porting games with the Godot engine. This post covers a number of topics that are related to the topics addressed in this proposal.

This proposal stems from a [discussion (#5189)](https://github.com/godotengine/godot-proposals/discussions/5189) and is one of two proposals that aim to improve porting efficiency and user experience. The other proposal is #10034.

### Describe the feature / enhancement and how it helps to overcome the problem or limitation

The resource remaps functionality will appear similar to the existing localization remaps functionality. It will behave differently because it will be based off of feature tags and remapping will be done at the time of export.

![Mockup of resource remaps view](https://github.com/godotengine/godot-proposals/assets/17506573/4c156c59-1497-42e9-a82c-36e02da6f3a4)

Here are a few important things to note about this design:

1) The new Resource Remap view is implemented almost identically to the existing Localization Remaps view.
2) Overrides are implemented with similar behaviour to project settings overrides: the first override in the list that matches a feature tag in the export will be chosen when exporting the project. If no overrides match any feature tags in the export, no overrides will be used.
3) Arrow buttons enable easily changing priority of remaps. This is especially valuable in Android exports that may share some, but not all feature tags. For example, a `meta_quest` could be positioned higher to take precedence over a `mobile` feature tag on this list.
4) Resource Remaps are added to project settings because these are similar to Localization Remaps, which already exist in the Project Settings. Having these two remaps in the same part of the editor makes this new feature easier to find.

### Excluding Resources

When a project is exported, only one resource in the resource remap group should be exported and all others should be excluded. This can allow the user to reduce the app size of a mobile export by remapping a high quality music file to a low quality music file. This is especially valuable because it is not reasonable to include a full MP3 encoder in the Godot editor, so having separately encoded MP3 files is necessary.

I suspect this behaviour could lead to user-error if a user doesn't realize that one of their resources is a part of a resource remap group. To mitigate this, icons could be added in the file system views to denote that resources are a part of a resource remap group.

![Mockup of adding icons to the file system dock](https://github.com/godotengine/godot-proposals/assets/17506573/92ccc76d-c452-445d-b45b-c372d5013228)

- An icon is added beside files that are a part of a resource remap group. The icon is supposed to be one file with lines going to three other files, but it's really really rough sketch. This idea obviously needs some finesse.
- The tooltip for the file has a line describing that it is a part of a resource remap.

### Interaction with Localization Remaps

Localization remapping should be performed after this resource remapping. This is natural because the resource remapping happens at export time and localization remapping must happen at runtime.

When performing resource remapping on localized resources, the root resource that is used in localization remapping should also be used as the root for resource remapping. I believe this is obvious and natural.

### Implementation Details

I expect this feature can be implemented using the same plumbing that is used to support textures with different compression formats, such as astc for mobile exports and bptc for PC exports. I have not looked into this futher, so I might be somewhat wrong about this assumption.

### Potential Problems

I'm assuming that resource remapping is already well established in the engine for localization remaps, so I don't expect any new problems. That said, because this remap is happening at export time, there could be new issues that come up.

Specifically, care would need to be taken with the "Export selected scenes/resources (and dependencies)" feature. I'm not sure exactly how this proposal would interact with determining dependencies.

I am not certain if remapping packed scenes is actually a good idea because it might fight against the possibility for packed scene refactoring tools in the future... But again, since remapping packed scenes already exists for localization, I believe this ship has already sailed.

### Other Rational
- Project setting overrides that use feature tags set a strong precedence for how feature tags can be used in porting. This proposal continues development of feature tags to be the central tool of portability in the Godot engine.
- Feature tags have already been demonstrated as very powerful by allowing two Android exports to have different behaviour, such as a VR export and a touch screen export that may have very different behaviours.