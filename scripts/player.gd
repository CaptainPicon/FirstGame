extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -300.0
const ROLL_SPEED = 100.0
const ROLL_DURATION = 0.5  # seconds

@onready var animated_sprite = $AnimatedSprite2D
@onready var jump_sound = $JumpSound
@onready var roll_timer = Timer.new()
@onready var iframe_timer = Timer.new()

# State tracking
enum State { IDLE, RUN, JUMP, ROLL }
var current_state: State = State.IDLE

# Invincibility
var invincible: bool = false
var roll_elapsed: float = 0.0

func _ready():
	add_child(roll_timer)
	add_child(iframe_timer)
	roll_timer.one_shot = true
	iframe_timer.one_shot = true
	roll_timer.connect("timeout", Callable(self, "_on_roll_finished"))
	iframe_timer.connect("timeout", Callable(self, "_on_iframes_end"))

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# State machine
	match current_state:
		State.IDLE:
			state_idle()
		State.RUN:
			state_run()
		State.JUMP:
			state_jump()
		State.ROLL:
			state_roll(delta)
	
	move_and_slide()
	set_invincible_effect(invincible)

func change_state(new_state: State) -> void:
	if current_state == new_state:
		return
	current_state = new_state

# --- STATE: IDLE ---
func state_idle():
	animated_sprite.play("idle")
	velocity.x = move_toward(velocity.x, 0, SPEED)  # stop sliding

	var direction = Input.get_axis("move_left", "move_right")
	if direction != 0:
		change_state(State.RUN)
	elif Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jump_sound.play()
		change_state(State.JUMP)
	elif Input.is_action_just_pressed("roll") and is_on_floor():
		start_roll()

# --- STATE: RUN ---
func state_run():
	var direction = Input.get_axis("move_left", "move_right")
	if direction == 0:
		change_state(State.IDLE)
	else:
		velocity.x = direction * SPEED
		animated_sprite.play("run")
		animated_sprite.flip_h = direction < 0

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jump_sound.play()
		change_state(State.JUMP)
	elif Input.is_action_just_pressed("roll"):
		start_roll()

# --- STATE: JUMP ---
func state_jump():
	animated_sprite.play("jump")
	
	# Horizontal control while jumping
	var direction = Input.get_axis("move_left", "move_right")
	velocity.x = direction * SPEED

	# Landing transitions
	if is_on_floor():
		if direction == 0:
			change_state(State.IDLE)
		else:
			change_state(State.RUN)

# --- STATE: ROLL ---
func state_roll(delta):
	roll_elapsed += delta
	animated_sprite.play("roll")

	# Move in facing direction
	if animated_sprite.flip_h:
		velocity.x = -ROLL_SPEED
	else:
		velocity.x = ROLL_SPEED

	# ✅ Allow canceling the roll after 0.15s
	if roll_elapsed > 0.15:
		if Input.is_action_just_pressed("jump") and is_on_floor():
			cancel_roll()
			velocity.y = JUMP_VELOCITY
			jump_sound.play()
			change_state(State.JUMP)

# --- START / END ROLL ---
func start_roll():
	change_state(State.ROLL)
	roll_elapsed = 0.0
	invincible = true
	iframe_timer.start(ROLL_DURATION * 1)  # Invincible for 60% of roll
	roll_timer.start(ROLL_DURATION)

func cancel_roll():
	invincible = false
	roll_timer.stop()
	iframe_timer.stop()

func _on_roll_finished():
	invincible = false
	var direction = Input.get_axis("move_left", "move_right")
	if is_on_floor():
		if direction == 0:
			change_state(State.IDLE)
		else:
			change_state(State.RUN)
	else:
		change_state(State.JUMP)

func _on_iframes_end():
	invincible = false

# --- VISUAL EFFECTS ---
func set_invincible_effect(enabled: bool):
	if enabled:
		animated_sprite.modulate = Color(1.8, 1.8, 1.8, 1)  # flash white
	else:
		animated_sprite.modulate = Color(1, 1, 1, 1)
