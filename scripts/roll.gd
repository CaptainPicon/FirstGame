extends State

@export var idle_state: State
@export var fall_state: State
@export var move_state: State
@export var jump_state: State
@export var roll_distance:= 60
@export var roll_speed: float = 100

var roll_direction: Vector2
var roll_start_position: Vector2
var roll_target_position: Vector2


func enter() -> void:
	super()
	# determine direction
	roll_direction = Vector2.LEFT if parent.animations.flip_h else Vector2.RIGHT
	
	# Record start and target positions
	roll_start_position = parent.global_position
	roll_target_position = roll_start_position + roll_direction * roll_distance
	
	# Apply horizontal velocity
	parent.velocity.x = roll_direction.x * roll_speed
	

func process_input(event: InputEvent) -> State:
	if Input.is_action_just_pressed('jump') and parent.is_on_floor():
		return jump_state
	if Input.is_action_just_pressed('move_left') or Input.is_action_just_pressed('move_right'):
		return move_state
		
	return null


func process_physics(delta: float) -> State:

	# Calculate distance to target
	var to_target = roll_target_position - roll_start_position
	
	# Stop roll after reaching the target distance
	var distance_traveled = abs(parent.global_position.x - roll_start_position.x)
	if distance_traveled >= roll_distance:
		parent.velocity.x = 0
		return move_state

	
	# move with physics
	parent.move_and_slide() 
	
	# Stop if we hit a wall
	if parent.is_on_wall():
		parent.velocity.x = 0
		return idle_state
		
	#stop if rolling above ground
	if not parent.is_on_floor():
		parent.velocity.x = 0
		return fall_state
		
	return null
