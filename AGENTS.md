# PitBull compatibility project

The goal is to replace library-dependent application code with PitBull-owned
code over successive milestones.

Any directory named lib or libs (case-insensitive), including nested module
folders and the sibling PitBull4_DogTagTexts addon, is read-only. Preserve every
file's bytes, name, version, formatting, assets, and inventory against
Tests/library_baseline_hashes.json. Do not patch, vendor-fork, refresh, replace,
add, or delete library files in a milestone.

Do not work around this rule by monkey-patching shared library functions,
constructors, library versions, Blizzard globals, or namespace APIs at runtime.
Compatibility adapters and native controls belong in application files.
Consumer-defined widget types with PitBull-specific names may temporarily use
the normal AceGUI registration API; never replace its built-in types.

Keep saved profiles compatible. Prefer native event-driven implementations.
Run Tests/verify_library_boundary.py before packaging. A changed-only
distribution must contain no file under a lib/libs directory. A full release
may include the unchanged baseline libraries while migration continues.

When starting from a new user-supplied library baseline, record that supplied
baseline explicitly before application work. Never silently update the
baseline hashes to accept a library edit.
