extends Node2D

var player: Player = Global.player

var _delta_second: float = 0.0
var fade_in: bool = false
var fade_out: bool = false

@onready var fader: ColorRect = $CanvasLayer/Fader
@onready var taskbar: Panel = $CanvasLayer/Taskbar
@onready var startmenu: Panel = $CanvasLayer/StartMenu
@onready var layer_paused: CanvasLayer = $CanvasLayer/GroupModals/PauseLayer
@onready var layer_day: CanvasLayer = $CanvasLayer/GroupModals/DayLayer
@onready var layer_confirm: CanvasLayer = $CanvasLayer/GroupModals/ConfirmLayer
@onready var layer_maker: CanvasLayer = $CanvasLayer/GroupWindows/LayerMaker
@onready var layer_skills: CanvasLayer = $CanvasLayer/GroupWindows/LayerSkills

# TODO: Remove this model in future
@onready var layer_new_player: CanvasLayer = $CanvasLayer/GroupModals/NewPlayerLayer


func _ready():
	if Global.debug:
		# For fast debugging purposes
		player.player_name = "Player"

	# Set own visibility for some nodes
	fader.visible = true
	startmenu.visible = false
	layer_paused.visible = false
	layer_day.visible = false
	layer_confirm.visible = false
	layer_new_player.visible = false
	layer_maker.visible = false
	layer_maker.get_node("Window/Container/List").visible = true
	layer_maker.get_node("Window/Container/Details").visible = false
	layer_skills.visible = false

	# Set fader state
	fade_out = true
	fader.color.a = 1.0

	# Show first modal
	if not player.player_name:
		layer_new_player.visible = true
	else:
		player.set_day_paused(false)


func _input(event: InputEvent):
	if event.is_action_pressed("Menu"):
		if layer_new_player.visible or layer_day.visible:
			return

		if layer_maker.visible:
			layer_maker.visible = false
			return

		if layer_skills.visible:
			layer_skills.visible = false
			return

		if not player.is_day_paused() and not layer_paused.visible:
			# Pause day
			layer_paused.visible = true
			player.set_day_paused(true)
		else:
			# Unpause day
			layer_paused.visible = false
			player.set_day_paused(false)


func _process(delta: float):
	# Fader cycles
	if fade_out:
		fader.color.a -= delta
		if fader.color.a <= 0.0:
			fader.color.a = 0.0
			fader.visible = false
			fade_out = false

			if not layer_new_player.visible and not layer_day.visible:
				player.set_day_paused(false)

	if fade_in:
		if not player.day.paused:
			player.set_day_paused(true)

		layer_maker.visible = false
		layer_skills.visible = false

		fader.visible = true
		fader.color.a += delta
		if fader.color.a >= 1.0:
			fader.color.a = 1.0
			fade_in = false
			player.next_day()
			layer_day.visible = true
			fade_out = true

	# Game day cycles
	if not player.is_day_paused():
		_delta_second += delta
		player.delta_total += delta
		player._delta_daytime += delta

		# 1/4 second tick (4 updates per second)
		if _delta_second >= 0.25:
			player.cycle()
			_delta_second = 0.0


func _skip_day():
	# Time < 16:00 and Time > 07:00
	if player.day.time < 960 and player.day.time > 420 and player.energy > 40:
		# Ask for skip confirmation
		layer_confirm.visible = true
	else:
		fade_in = true
