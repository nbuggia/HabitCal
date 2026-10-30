# Contracts

\[The promises this product makes to other systems and to users' files, which must hold across every change: file formats, filenames other software reads, URL schemes, public APIs, update feeds, sync protocols. Each one is behavior a change must not break by accident. ARCHITECTURE.md names the component that implements each; DECISIONS.md holds why, cited here as D-NNN. Leave out any field with nothing in it.\]

## \[Contract name\]

- **Promise:** \[exactly what holds, precise enough to test: the format, the fields, the filename pattern, the response shape\]
- **Relied on by:** \[who or what breaks if it changes: users' existing files, a companion app, a third-party integration\]
- **Versioning:** \[how a change to it is introduced, and how old versions are still read\]
- **Tested by:** \[the contract tests that hold it, by name\]
