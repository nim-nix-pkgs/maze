## dig is the algorithm to generate a maze.
##
## Japanese
## ========
##
## dig は穴掘り法に基づいて迷路を生成するモジュールです。
##
## See also
## ----
##
## * `迷路自動生成アルゴリズム <http://www5d.biglobe.ne.jp/stssk/maze/make.html>`_

import sequtils, strutils, random, strformat
import types
export types

proc setRoadFrame(maze: var Maze) =
  ## 一番外の外壁に道をセット
  # top
  let stage = maze.stage
  for x, col in stage[0]:
    maze.stage[0][x] = road
  # left
  for y, row in stage:
    maze.stage[y][0] = road
  # right
  for y, row in stage:
    maze.stage[y][^1] = road
  # bottom
  for x, col in stage[^1]:
    maze.stage[^1][x] = road

proc isDiggable(maze: Maze, x, y: int): bool =
  ## `x`, `y`の座標の上下左右は掘り進める状態かどうかを判定する。
  let stage = maze.stage
  # top
  if stage[y-1][x] == wall and stage[y-2][x] == wall:
    return true
  # left
  if stage[y][x-1] == wall and stage[y][x-2] == wall:
    return true
  # right
  if stage[y][x+1] == wall and stage[y][x+2] == wall:
    return true
  # buttom
  if stage[y+1][x] == wall and stage[y+2][x] == wall:
    return true
  return false

proc digUp(maze: var Maze, x, y: int): tuple[x, y: int] =
  ## 上方向に掘る。
  maze.stage[y][x] = road
  var y2 = y
  var cell = maze.stage[y2-1][x]
  var cell2 = maze.stage[y2-2][x]
  while cell == wall and cell2 == wall:
    maze.stage[y2-1][x] = road
    dec(y2)
    cell = maze.stage[y2-1][x]
    cell2 = maze.stage[y2-2][x]
  return (x: x, y: y2)

proc digLeft(maze: var Maze, x, y: int): tuple[x, y: int] =
  ## 左方向に掘る。
  maze.stage[y][x] = road
  var x2 = x
  var cell = maze.stage[y][x-1]
  var cell2 = maze.stage[y][x-2]
  while cell == wall and cell2 == wall:
    maze.stage[y][x2-1] = road
    dec(x2)
    cell = maze.stage[y][x2-1]
    cell2 = maze.stage[y][x2-2]
  return (x: x2, y: y)

proc digRight(maze: var Maze, x, y: int): tuple[x, y: int] =
  ## 右方向に掘る。
  maze.stage[y][x] = road
  var x2 = x
  var cell = maze.stage[y][x+1]
  var cell2 = maze.stage[y][x+2]
  while cell == wall and cell2 == wall:
    maze.stage[y][x2+1] = road
    inc(x2)
    cell = maze.stage[y][x2+1]
    cell2 = maze.stage[y][x2+2]
  return (x: x2, y: y)

proc digDown(maze: var Maze, x, y: int): tuple[x, y: int] =
  ## 下方向に掘る。
  maze.stage[y][x] = road
  var y2 = y
  var cell = maze.stage[y2+1][x]
  var cell2 = maze.stage[y2+2][x]
  while cell == wall and cell2 == wall:
    maze.stage[y2+1][x] = road
    inc(y2)
    cell = maze.stage[y2+1][x]
    cell2 = maze.stage[y2+2][x]
  return (x: x, y: y2)

proc randDig(maze: var Maze, x, y: int): tuple[x, y: int] =
  ## ランダムな方向に掘り進む。
  let r = rand(3)
  case r
  of 0:
    # up
    maze.digUp(x, y)
  of 1:
    # left
    maze.digLeft(x, y)
  of 2:
    # right
    maze.digRight(x, y)
  else:
    # down
    maze.digDown(x, y)

proc newStartPos(maze: Maze): tuple[x, y: int] =
  ## ランダムに偶数座標を返却する。
  let width = maze.width
  let height = maze.height
  (x: ((width-4)/2-1).int.rand*2+2, y: ((height-4)/2-1).int.rand*2+2)

proc isContinuableToDig(maze: Maze): bool =
  ## 配置可能な全て載せるのdiggableをチェック
  for y in 2..<int(maze.height/2-1):
    for x in 2..<int(maze.width/2-1):
      if maze.isDiggable(x*2, y*2):
        return true

proc newMazeByDigging*(width, height: int, randomSeed = true, seed = 0): Maze =
  ## Returns a `Maze` object that generated by digging algorithm.
  ##
  ## **Japanese:**
  ##
  ## 穴掘り法で迷路を生成する。
  runnableExamples:
    ## Generate random maze
    var maze = newMazeByDigging(20, 20)
    echo maze.format(" ", "#")
    ## Set random seed
    var maze2 = newMazeByDigging(20, 20, randomSeed = true, seed = 1)
    echo maze2.format(" ", "#")
  result.width = width
  result.height = height
  result.stage = newSeqWith(height, newSeqWith(width, wall))
  result.setRoadFrame()

  if randomSeed:
    randomize()
  else:
    randomize(seed)

  # ランダムに一箇所点を選ぶ。
  # 選んだ点が壁にならないようにする。
  var (x, y) = result.newStartPos()
  while result.isContinuableToDig():
    while result.isDiggable(x, y):
      discard result.randDig(x, y)
      (x, y) = result.newStartPos()
      while result.stage[y][x] != road:
        (x, y) = result.newStartPos()
    (x, y) = result.newStartPos()
    while result.stage[y][x] != road:
      (x, y) = result.newStartPos()

iterator generatesMazeProcessByDigging*(width, height: int, randomSeed = true, seed = 0): Maze =
  ## Returns a generated maze and draft mazes.
  ##
  ## **Japanese:**
  ##
  ## 穴掘り法で迷路を生成する。最終的に生成の完了した迷路の、生成の過程をイテレ
  ## ータとして返却する。
  ##
  ## See also:
  ## * `newMazeByDigging proc <#newMazeByDigging,int,int,int>`_
  runnableExamples:
    ## Generate random maze
    for maze in generatesMazeProcessByDigging(20, 20):
      echo maze.format(" ", "#")
  var maze = Maze(width: width, height: height, stage: newSeqWith(height, newSeqWith(width, wall)))
  maze.setRoadFrame()

  if randomSeed:
    randomize()
  else:
    randomize(seed)

  # ランダムに一箇所点を選ぶ。
  # 選んだ点が壁にならないようにする。
  var (x, y) = maze.newStartPos()
  while maze.isContinuableToDig():
    while maze.isDiggable(x, y):
      discard maze.randDig(x, y)
      (x, y) = maze.newStartPos()
      yield maze
      while maze.stage[y][x] != road:
        (x, y) = maze.newStartPos()
    (x, y) = maze.newStartPos()
    while maze.stage[y][x] != road:
      (x, y) = maze.newStartPos()

