## Nim version of Hello World SQLite plugin
##
## Test with something like the following:
##
## sqlite3 < examples/hello_world.sql
## 1|Hello there Alice, your ID is 1|Goodbye for now Alice|5
## 2|Hello there Bob, your ID is 2|Goodbye for now Bob|3
##
## See README.md for more information if you receive an error about no "load" command
##
## Error: unknown command or invalid arguments:  "load". Enter ".help" for help
##

import os
import .. / sqlite3ext

## Can define via macro
sqliteFunction:
  func helloFunc*(someText: string, someInt32: int32) : string =
    result = "Hello there " & someText & ", your ID is " & $someInt32

# or via pragma
proc goodbyeFunc*(someText: string) : string {.sqliteFunction.} =
  result = "Goodbye for now " & someText

proc numberFunc*(someText: string) : int {.sqliteFunction.} =
  result = len(someText)

# Call this macro once after all extension functions have been defined
sqliteInit()
