extends Node

## Whether the game is running/exported in debug mode
var debug: bool = OS.is_debug_build()

## Whether the game is running in Web broswer
var is_web: bool = OS.has_feature("web")

## Game player instance
var player: Player = Player.new()
