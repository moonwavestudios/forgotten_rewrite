extends Control

signal progress_changed(new_value: float)  # 0.0 – 1.0
signal minigame_completed
signal minigame_failed

const CIRCLE_RADIUS := 40.0
const APPROACH_DURATION  := 1.2    # seconds for ring to close onto circle
const SPAWN_INTERVAL_MIN := 0.7
const SPAWN_INTERVAL_MAX := 1.4
const HIT_WINDOW  := 0.35   # timing leniency (seconds either side of ideal)
const PROGRESS_HIT := 0.08
const PROGRESS_MISS := 0.05
const MAX_MISSES := 5

var _progress    : float = 0.0
var _misses      : int   = 0
var _circles     : Array = []
var _spawn_timer : float = 0.0
var _next_spawn  : float = 0.0
var _running     : bool  = false

@onready var _bar : ProgressBar = $ProgressBar

func _ready() -> void:
	_bar.min_value = 0.0
	_bar.max_value = 1.0
	_bar.value     = 0.0
	_schedule_next()
	start()

func start() -> void:
	_progress = 0.0
	_misses   = 0
	_running  = true
	_circles.clear()
	_bar.value = 0.0
	queue_redraw()

func stop() -> void:
	_running = false
	_circles.clear()
	queue_redraw()

func _process(delta: float) -> void:
	if not _running:
		return

	_spawn_timer += delta
	if _spawn_timer >= _next_spawn:
		_spawn_timer = 0.0
		_spawn_circle()
		_schedule_next()

	var now      := Time.get_ticks_msec() / 1000.0
	var to_erase : Array = []

	for c in _circles:
		var age = now - c["t"]
		if age > APPROACH_DURATION + HIT_WINDOW:
			_on_miss()
			to_erase.append(c)

	for c in to_erase:
		_circles.erase(c)

	queue_redraw()

func _input(event: InputEvent) -> void:
	if not _running:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_handle_click(event.position)

func _schedule_next() -> void:
	_next_spawn = randf_range(SPAWN_INTERVAL_MIN, SPAWN_INTERVAL_MAX)

func _spawn_circle() -> void:
	var pad  := CIRCLE_RADIUS + 8.0
	var sz   := get_rect().size
	_circles.append({
		"pos": Vector2(randf_range(pad, sz.x - pad), randf_range(pad, sz.y - pad)),
		"t":   Time.get_ticks_msec() / 1000.0
	})

func _handle_click(click_pos: Vector2) -> void:
	var now       := Time.get_ticks_msec() / 1000.0
	var best       = null
	var best_dist := INF

	for c in _circles:
		var dist : float = c["pos"].distance_to(click_pos)
		if dist <= CIRCLE_RADIUS and dist < best_dist:
			best      = c
			best_dist = dist

	if best == null:
		return

	var timing_err = abs((now - best["t"]) - APPROACH_DURATION)
	_circles.erase(best)

	if timing_err <= HIT_WINDOW:
		_on_hit()
	else:
		_on_miss()

	queue_redraw()

func _on_hit() -> void:
	_misses = 0
	_set_progress(_progress + PROGRESS_HIT)

func _on_miss() -> void:
	_misses += 1
	_set_progress(_progress - PROGRESS_MISS)
	if _misses >= MAX_MISSES:
		_running = false
		_circles.clear()
		queue_redraw()
		emit_signal("minigame_failed")

func _set_progress(v: float) -> void:
	_progress  = clampf(v, 0.0, 1.0)
	_bar.value = _progress
	emit_signal("progress_changed", _progress)
	if _progress >= 1.0:
		_running = false
		_circles.clear()
		queue_redraw()
		emit_signal("minigame_completed")

func _draw() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	for c in _circles:
		var elapsed : float  = now - c["t"]
		var t       : float  = clampf(elapsed / APPROACH_DURATION, 0.0, 1.0)
		var alpha   : float  = clampf(elapsed / 0.12, 0.0, 1.0)
		var pos     : Vector2 = c["pos"]

		var ring_r := lerpf(CIRCLE_RADIUS * 2.8, CIRCLE_RADIUS, t)
		draw_arc(pos, ring_r, 0.0, TAU, 64, Color(1.0, 0.6, 0.2, 0.85 * alpha), 2.5, true)

		# Circle fill
		draw_circle(pos, CIRCLE_RADIUS, Color(0.95, 0.2, 0.3, 0.88 * alpha))

		# Circle outline
		draw_arc(pos, CIRCLE_RADIUS, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.8 * alpha), 2.5, true)
