extends State

@export
var fall_state: State
@export
var idle_state: State
@export
var jump_state: State
@export
var roll_state: State

var last_input_direction := 0

func process_input(event: InputEvent) -> State:
	if Input.is_action_just_pressed('jump') and parent.is_on_floor():
		return jump_state
	if Input.is_action_just_pressed('roll') and parent.is_on_floor():
		return roll_state
		
	return null


func process_physics(delta: float) -> State:
	parent.velocity.y += gravity * delta
	
	var direction := get_smooth_direction()
	
	parent.velocity.x = direction * move_speed

	if direction != 0:
		parent.animations.flip_h = direction < 0
	else:
		return idle_state

	parent.move_and_slide()

	if not parent.is_on_floor():
		return fall_state

	return null


func get_smooth_direction() -> float:
	var direction := 0

	# Track which direction was pressed most recently
	if Input.is_action_just_pressed("move_right"):
		last_input_direction = 1
	elif Input.is_action_just_pressed("move_left"):
		last_input_direction = -1

	# Handle held inputs
	var pressing_left = Input.is_action_pressed("move_left")
	var pressing_right = Input.is_action_pressed("move_right")

	if pressing_right and not pressing_left:
		direction = 1
	elif pressing_left and not pressing_right:
		direction = -1
	elif pressing_right and pressing_left:
		direction = last_input_direction
	else:
		direction = 0

	return direction
