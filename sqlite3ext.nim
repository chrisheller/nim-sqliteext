## Module to help with building SQLite extensions in Nim
##
## See examples directory to get started

import macros
import os
import sqlite3
import strutils

import priv / functions

export sqlite3
export sqliteFunction

template entryPoint(initProcName: untyped, initFuncs: NimNode) {.dirty.} =
  ## Creates the initial portion of the entry point function that
  ## SQLite will call to initialize everything

  {.emit:"""
  #include <sqlite3ext.h>
  SQLITE_EXTENSION_INIT1
  """
  .}

  proc initProcName(sqlite3 : PSqlite3, 
                    pzErrMsg: ptr string, 
                    pApi: ptr int32) : cint {.exportc.} =
    result = SQLITE_OK

    {.emit:"""
    SQLITE_EXTENSION_INIT2(pApi);
    """
    .}

    initFuncs

proc filterNonAscii(txt: string) : string =
  result = newStringOfCap(txt.len)
  for c in txt:
    if c.isAlphaAscii:
      result.add(c)

proc calcEntryPointName(fileName: string) : string =
  ## See https://www.sqlite.org/loadext.html#programming_loadable_extensions
  var filename = fileName.splitFile().name
  if filename.startswith("lib"):
    filename = filename.substr(3)
  "sqlite3_" & filename.filterNonAscii() & "_init"

macro sqliteInit*() : typed =
  ## This macro should be called after all functions have been defined. 
  ## It will define the single entry point function that SQLite will be
  ## call to register the functions for use with SQLite
  let
    fileName = callsite().lineInfoObj.filename
    procName = calcEntryPointName(fileName)

  result = getAst(entryPoint(newIdentNode(procName), getInitFuncs()))


