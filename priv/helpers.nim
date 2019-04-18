# Helper procs for constructing SQLite glue code

import macros
import strutils

type
  SQLiteParamKind* = enum
    sqliteParamString, sqliteParamInt, sqliteParamInt32
  SQLiteResKind* = enum
    sqliteResString, sqliteResInt

proc stringAsParamKind*(paramType: string): SQLiteParamKind =
  result = parseEnum[SQLiteParamKind]("sqliteParam" & paramType)

proc stringAsResultKind*(resultType: string): SQLiteResKind =
  result = parseEnum[SQLiteResKind]("sqliteRes" & resultType)

proc getArgCount*(params: NimNode) : int =
  params.expectKind(nnkFormalParams)
  result = len(params) - 1  # subtract one for result node in params

proc argCountAssertion*(argcount: int) : NimNode =
  ## Builds a NimNode like the following
  ##    assert argcount == 2
  result = newNimNode(nnkCommand)
  result.add(newIdentNode("assert"))
        .add(newNimNode(nnkInfix).add(newIdentNode("=="))
                                 .add(newIdentNode("argcount"))
                                 .add(newIntLitNode(argcount)))

proc parameterNode*(parmName: string, parmType: string) : NimNode =
  result = newIdentDefs(newIdentNode(parmName), 
                        newIdentNode(parmType), 
                        newEmptyNode())

proc valueParm(parmNbr: int, parmConv, parmFunc: string) : NimNode =
  ## Builds a NimNode for extracting text from the SQLite
  ## parameter passed in argv
  ## e.g. $value_text(argv[0])
  let argv = newNimNode(nnkBracketExpr).add(newIdentNode("argv"))
                                       .add(newIntLitNode(parmNbr))
  
  result = newNimNode(nnkPrefix)
  if parmConv.len > 0:
    result.add(newIdentNode(parmConv))

  result.add(newNimNode(nnkCall).add(newIdentNode(parmFunc))
                                .add(argv))

proc valueTextParm*(parmNbr: int) : NimNode =
  result = valueParm(parmNbr, "$", "value_text")
  
proc valueIntParm*(parmNbr: int) : NimNode =
  result = valueParm(parmNbr, "int", "value_int")
  
proc valueInt32Parm*(parmNbr: int) : NimNode =
  result = valueParm(parmNbr, "int32", "value_int")
  
proc sqliteResultInt*() : NimNode =
  ## Builds a NimNode for calling the SQLite result_int() function
  ## This relies on the ''output'' variable being already setup
  result = newNimNode(nnkCall)
  result.add(newIdentNode("result_int"))
        .add(newIdentNode("context"))
        .add(newDotExpr(newIdentNode("output"), 
                        newIdentNode("int32")))

proc sqliteResultText*() : NimNode =
  ## Builds a NimNode for calling the SQLite result_text() function
  ## This relies on the ''output'' and ''length'' variables being
  ## already setup
  result = newNimNode(nnkCall)
  result.add(newIdentNode("result_text"))
        .add(newIdentNode("context"))
        .add(newIdentNode("output"))
        .add(newDotExpr(newIdentNode("length"), 
                        newIdentNode("int32")))
        .add(newIdentNode("SQLITE_TRANSIENT"))

proc lengthOfOutput*() : NimNode =
  let plusOne = newNimNode(nnkInfix)
  plusOne.add(newIdentNode("+"))
         .add(newDotExpr(newIdentNode("output"), 
                         newIdentNode("len")))
         .add(newIntLitNode(1))
  result = newIdentDefs(newIdentNode("length"),
                        newEmptyNode(),
                        plusOne)

