# Depwire workflow for this arm

Use the available Depwire MCP tools as the discovery step before editing code.

1. Connect to the repository and inspect its architecture.
2. Run `affected_files` on the target file before making the core change. Keep
   the returned list as a discovery aid, then independently decide which files
   actually require edits.
3. Use `get_file_context` where a file's relationship to the target is unclear.
4. Implement the change and update all affected consumers across the monorepo.
5. Use `verify_change`, the compiler, and the required test command to check the
   result.

Depwire reports static relationships; compiler and test feedback remain part of
the completion criteria.
