# nim-sqliteext
Create SQLite extensions in Nim

# What is it?
This module allows you to define extension functions for SQLite in native Nim.  The `sqliteFunction` macro that this module provides will take your proc (or func) and create the wrapper code that SQLite will call when your function is used in SQL. 

Once all of your extension functions are defined, you'll need to invoke `sqliteInit` in order to define the entry point function that SQLite will call and get all of your functions registered with SQLite. 

See [hello_world.nim](examples/hello_world.nim) for some simple examples to get started with. 

# Type Mapping
Your Nim proc/func can accept 0 to *N* parameters. Each parameter must be a `string` or `int`/`int32`. Your proc/func must return either a `string` or `int`/`int32`.  These were enough to prove out the basic functionality, but should be expanded to cover additional types. 

# Limitations
SQLite supports passing a pointer to a user-defined data structure when the function is first registered with SQLite. This pointer can then be accessed in an extension function.  This module does not currently support this functionality. 

So far this only supports defining functions for SQLite. Other types of SQLite extensions (such as virtual tables) are not supported. 

Eventually this module should support those, but there are not any short-term plans for working on that. Pull requests welcome though.  See https://www.sqlite.org/loadext.html for more information about what types of extensions SQLite supports. 

# I got an error in SQLite!
If you receive an error like the following when you try loading an extension in SQLite, your version of SQLite was not compiled with loadable module support (due to security reasons). You'll want to compile SQLite separately that supports this. 

> SQLite version 3.19.3 2017-06-27 16:48:08
> Enter ".help" for usage hints.
> Connected to a transient in-memory database.
> Use ".open FILENAME" to reopen on a persistent database.
> sqlite> .load examples/libhello_world.dylib 
> Error: unknown command or invalid arguments:  "load". Enter ".help" for help
> sqlite> 

TODO: add further instructions here about compiling SQLite. 
