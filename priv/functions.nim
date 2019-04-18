## Modules

import helpers
import macros

type
  FuncDef = ref object
    sqlFunc : string
    numOfArgs : int
    implementingProc : NimNode
    # TODO - how do we implement this?
    # userData : string

# Keep track of which proc/func have been setup via the sqliteFunction
# macro, so that when SQLite calls the entry point init function, we 
# can properly register them with SQLite
var funcsToInit {.compiletime.} : seq[FuncDef] = @[]

proc standardSQLiteParameters() : NimNode =
  ## Builds a NimNode for the standard parameters that SQLite will
  ## pass when invoking your custom function. 
  result = newNimNode(nnkFormalParams)
  result.add(newEmptyNode())
        .add(parameterNode("context", "Pcontext"))
        .add(parameterNode("argcount", "int32"))
        .add(parameterNode("argv", "PValueArg"))

proc callOriginal(procName: string, formalParms: NimNode) : NimNode =
  ## Builds a NimNode to call the original proc that was passed
  ## to the sqliteFunction macro. The original proc parameters are
  ## used to figure out which SQLite functions should be used
  formalParms.expectKind(nnkFormalParams)
  result = newNimNode(nnkCall)
  result.add(newIdentNode(procName))

  let argcount = len(formalParms) - 1
  for i in 1 .. argcount:
    let
      argName = formalParms[i][0]
      argType = formalParms[i][1]
      argKind = stringAsParamKind($argType)
      parmNbr = i - 1

    case argKind:
    of sqliteParamString:
      result.add(valueTextParm(parmNbr))
    of sqliteParamInt:
      result.add(valueIntParm(parmNbr))
    of sqliteParamInt32:
      result.add(valueInt32Parm(parmNbr))

proc sqliteFunctionBody(origProcName: string, origProcDef: NimNode) : NimNode =
  ## Builds up the body of our glue proc that handles converting
  ## between the proc supplied to the sqliteFunction macro and the
  ## format that SQLite expects
  result = newStmtList()

  let
    argcount = getArgCount(origProcDef[3])
    resultType = $origProcDef[3][0]
    resultKind = stringAsResultKind($resultType)
  
  result.add(argCountAssertion(argcount))

  let varSection = newNimNode(nnkVarSection)

  # So this is automatically assigning the type
  varSection.add(newIdentDefs(newIdentNode("output"),
                              newEmptyNode(),
                              callOriginal(origProcName, origProcDef[3])))
  case resultKind:
  of sqliteResString:
    varSection.add(lengthOfOutput())
  of sqliteResInt:
    discard
  # TODO : what other types need this sort of calculation?

  result.add(varSection)

  case resultKind:
  of sqliteResString:
    result.add(sqliteResultText())
  of sqliteResInt:
    result.add(sqliteResultInt())

macro sqliteFunction*(body: untyped) : typed =
  ## This is the main entry point for defining a proc/func that 
  ## will be available as a function in SQLite
  ##
  ## See examples / hello_world.nim

  let
    # TODO - allow method?
    allowedKinds = { nnkProcDef, nnkFuncDef }
    isPragma = body.kind in allowedKinds
    procDef = if isPragma:
                body
              else:
                assert body.len == 1, "Only 1 proc or func can be defined"
                body[0].expectKind(allowedKinds)
                body[0]
    argcount = getArgCount(procDef[3])
    procNameVisibilityNode = procDef[0].copyNimTree()
    procNameNode = if procNameVisibilityNode.kind == nnkPostfix:
                     procNameVisibilityNode[1]
                   else:
                     procNameVisibilityNode
    procName = $procNameNode
    procNameForSQLite = "sqlite_" & procName
    # TODO - is the calling convention the same on all platforms?
    callingConv = "cdecl"

  var wrapperProcDef = newNimNode(nnkProcDef)
  wrapperProcDef.add(newIdentNode(procNameForSQLite))
                .add(newEmptyNode())
                .add(newEmptyNode())
                .add(standardSQLiteParameters())
                .add(newNimNode(nnkPragma).add(newIdentNode(callingConv)))
                .add(newEmptyNode())
                .add(sqliteFunctionBody($procName, procDef))

  result = newStmtList()
  result.add(body)
  result.add(wrapperProcDef)
  echo result.toStrLit

  let funcDef = FuncDef(sqlFunc : $procName, 
                        numOfArgs : argcount,
                        implementingProc: newIdentNode(procNameForSQLite))
  funcsToInit.add(funcDef)

template initFunc(sqlFunc: string, numOfArgs: int, funcImplementation: NimNode) =
  ## template for initializing/registering each wrapper function
  ##

  # SQLite wants a pointer to a user data structure in order to supply
  # additional data, so we should figure out how to support that
  var userData = cast[pointer](0)

  # The ''result'' variable has been initialized to SQLITE_OK in the
  # sqlite3ext entry point template
  result = create_function(sqlite3,
                           sqlFunc,
                           numOfArgs.int32,
                           SQLITE_UTF8.int32,
                           userData,
                           funcImplementation,
                           cast[Create_function_step_func](0),
                           cast[Create_function_final_func](0))
  if result != SQLITE_OK:
    return result

proc getInitFuncs*() : NimNode =
  ## Build the registration code AST for any functions that have been defined
  ##
  ## This is used in sqlite3ext to help build the overall entry point proc
  result = newStmtList()
  
  for fti in funcsToInit:
    result.add(getAst(initFunc(fti.sqlFunc, 
                               fti.numOfArgs, 
                               fti.implementingProc)))

  # echo result.toStrLit
