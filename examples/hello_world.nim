## Nim version of Hello World SQLite plugin
##
## compile as DLL/.so
##   nim c --app:lib hello_world.nim
##
## Test with something like the following:
##
## sqlite3
## sqlite> .load libhello_world
## sqlite> CREATE TABLE testing(id INTEGER PRIMARY KEY, name STRING);
## sqlite> insert into testing values (1, 'Alice'), (2, 'Bob');
## sqlite> select id, hello(name) from testing;
## 1|Hello Alice
## 2|Hello Bob
## sqlite> 

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

sqliteInit()
