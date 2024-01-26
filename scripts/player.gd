class_name Player extends Node

var _delta_daytime: float = 0.0

## Display name of Player
var player_name: String = ""

## Total experience amount of Player
var experience: int = 0

## Total money amount of Player
var money: int = 50

## Energy counter of Player. From 0.0 to 100.0.
var energy: float = 100.0

## Mental Health counter of Player. From 0.0 to 100.0.
var mental_health: float = 100.0

## Whether did player slept
var havent_sleep: bool = false

## Total games counter
var game_counter: int = 0

## Total delta seconds passed
var delta_total: float = 0.0

## List of games
var games: Array[Dictionary] = []

## Player skills switches
var skills: Dictionary = {
	"able_ads": false,
	"able_microtransactions": false,
	"able_p2w": false,
	"able_monetize": false,
	"able_paid": false
}

## Player boosters counters
var boosters: Dictionary = {
	"speed": 0,
	"exp": 0,
	"downloads": 0
}

## Day cycle information
var day: Dictionary = {
	"paused": true,
	"count": 1,
	"time": 450
}


func next_day():
	if day.time >= 420:
		day.count += 1

	# Set day time
	if day.count == 1:
		day.time = 450  # 07:30
	else:
		if havent_sleep:
			# From 12:00 To 15:00
			day.time = randi() % 181 + 720
		else:
			# From 09:00 To 12:00
			day.time = randi() % 181 + 540

	# Restore energy
	if havent_sleep:
		energy = clampf(energy + float(randi_range(20, 40)), 0.0, 100.0)
	else:
		energy = clampf(energy + float(randi_range(40, 60)), 0.0, 100.0)

	# Reset no sleep penalty
	havent_sleep = false


func add_game(game_name: String, genre: int) -> void:
	self.game_counter += 1
	var game_data = {
		"id": self.game_counter,
		"name": game_name,
		"genre": genre,
		"finished": false,
		"finished_at": 0.0,
		"downloads": 0,
		"paid_off": 0,
		"rating": 0.0
	}
	self.games.append(game_data)


func is_day_paused() -> bool:
	return day.paused


func set_day_paused(value: bool) -> void:
	day.paused = value


func get_day_count() -> int:
	return day.count


func get_day_time() -> int:
	return day.time


func get_day_time_string() -> String:
	var m: int = int(day.time) % 60
	var h: int = int(day.time / 60.0) % 60
	return "%02d:%02d" % [h, m]


func get_last_game():
	return {} if not games else games[-1]


func get_performance_multiply() -> float:
	if boosters.speed > 0:
		return 1.0 + float(boosters.speed)
	else:
		return 1.0


func get_downloads_multiply() -> int:
	return 1 + boosters.downloads


func get_energy_consuming() -> float:
	return 0.5 * (get_performance_multiply() * 0.125)


func get_experience_multiply() -> int:
	return 1 + boosters.exp


func cycle() -> void:
	"""
	Do day cycle, such as updating player stats and games.
	"""

	if _delta_daytime >= 1.0:
		day.time += int(_delta_daytime)
		_delta_daytime = 0.0

		# On 24:00, set to 00:00 and increase day count
		if day.time >= 1440:
			day.time -= 1440
			day.count += 1
			havent_sleep = true

	if havent_sleep:
		if day.time > 240 and randf() > 0.95:  # 04:00
			mental_health -= 1.0
		if day.time > 180 and randf() > 0.96:  # 03:00
			mental_health -= 1.0
		if day.time > 120 and randf() > 0.97:  # 02:00
			mental_health -= 1.0
		if day.time > 60 and randf() > 0.98:  # 01:00
			mental_health -= 1.0
		if day.time > 30 and randf() > 0.99:  # 00:30
			mental_health -= 1.0

	for game in self.games:
		if game.finished:
			match game.genre:
				1:  # Free with Ads
					game.downloads += get_downloads_multiply()

					if randf() > 0.90:
						var earned: int = randi_range(1, 3) * get_downloads_multiply()
						game.paid_off += earned
						self.money += earned

				2:  # Free with Microtransactions
					game.downloads += get_downloads_multiply()

					if randf() > 0.75:
						var earned: int = randi_range(3, 10) * get_downloads_multiply()
						game.paid_off += earned
						self.money += earned

				3:  # Free with Pay-to-Win
					game.downloads += get_downloads_multiply()

					if randf() > 0.50:
						var earned: int = 10 * get_downloads_multiply()
						game.paid_off += earned
						self.money += earned

				4:  # Free with Monetization
					game.downloads += get_downloads_multiply()

					if randf() > 0.60:
						var earned: int = randi_range(5, 15) * get_downloads_multiply()
						game.paid_off += earned
						self.money += earned

				5:  # Paid
					if randf() > 0.35:
						var earned: int = 20
						game.downloads += 1
						game.paid_off += earned
						self.money += earned

				_:  # Free (any)
					game.downloads += get_downloads_multiply()

		if not game.finished:
			if self.energy <= 0.0 or self.mental_health <= 10.0:
				return

			# Add game finish progress
			game.finished_at += get_performance_multiply()

			# Consume energy
			self.energy -= get_energy_consuming()

			if self.energy < 30.0:
				if randf() > 0.6:
					self.mental_health -= 1.0

			# If making the game is done:
			if game.finished_at >= 100.0:
				game.finished_at = 100.0
				game.finished = true
				self.experience += round(1 * get_experience_multiply())
