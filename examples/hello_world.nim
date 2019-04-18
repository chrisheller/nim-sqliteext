## Nim version of Hello World SQLite plugin
##
## Test with something like the following:
##
## sqlite3
## sqlite> .load examples/libhello_world
## sqlite> CREATE TABLE testing(id INTEGER PRIMARY KEY, name STRING);
## sqlite> insert into testing values (1, 'Alice'), (2, 'Bob');
## sqlite> select id, helloFunc(name, id), goodbyeFunc(name), numberFunc(name) from testing;
## 1|Hello there Alice, your ID is 1|Goodbye for now Alice|5
## 2|Hello there Bob, your ID is 2|Goodbye for now Bob|3
## sqlite> 
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
