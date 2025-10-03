Golden vectors validate parsing and safety. Each case has:
- raw.txt         TL1 session excerpt (command + response)
- expected.json   normalized parse result
- notes.md        edge cases, comments, cross-refs

Run plan during dev:
1) Parse raw.txt → JSON
2) Deep-compare with expected.json
3) Check notes.md expectations (safety banners, approvals)
