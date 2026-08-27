extends CharacterBody3D
class_name Player

@export_group("Movement")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 10.0
@export var rotation_speed: float = 12.0

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity: float = 0.25
@export var first_person_sensitivity: float = 0.005
@export var tilt_upper_limit: float = PI / 4.0
@export var tilt_lower_limit: float = -PI / 4.0

@export_group("Jump")
@export var jump_height : float = 2.25
@export var jump_time_to_peak : float = 0.4
@export var jump_time_to_descent : float = 0.3
#JUMP CONSTANTS source: https://youtu.be/IOe1aGY6hXA?feature=shared
@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0

#SYNC VARIaBLES
@export var move = false
@export var run = false
@export var on_floor = true

@onready var camera_pivot: Node3D = $Camera_Pivot
@onready var camera: Camera3D = $Camera_Pivot/SpringArm3D/Camera3D



@export var knockback_force: float = 17.0
var knockback_velocity: Vector3 = Vector3.ZERO

var _camera_input_direction := Vector2.ZERO
var _last_movement_direction := Vector3.BACK
var move_speed: float
var locked: bool = false

func _ready() -> void:
	# Default to 3rd person
	move_speed = walk_speed
	camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("sprint"):
		move_speed = sprint_speed
		run = true
	elif event.is_action_released("sprint"):
		move_speed = walk_speed
		run = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion: #Camera rotaion input capture
		if event is InputEventMouseMotion:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				_camera_input_direction = event.screen_relative * mouse_sensitivity

func _physics_process(delta: float) -> void:
	handle_cam_rotation(delta)
	jump_logic(delta)
	var direction: Vector3
	if !locked:
		knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, delta * 10)
		
		var input_dir := Input.get_vector("left", "right", "forward", "back")
		direction = (camera.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed
			move = true
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
			move = false
		
		velocity += knockback_velocity
	move_and_slide()
	#turn the model after moving
	if direction.length() > 0.2:
		_last_movement_direction = direction
	#calculate angle to the last movemnt direction, used to turn model
	var target_angle := Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
	%Man.global_rotation.y = lerp_angle(%Man.rotation.y, target_angle, rotation_speed * delta)


##Rotates the camera based on mouse motion
func handle_cam_rotation(delta):
	#Turn the camera with the mouse motion
	camera_pivot.rotation.x -= _camera_input_direction.y * delta
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, tilt_lower_limit, tilt_upper_limit)
	camera_pivot.rotation.y -= _camera_input_direction.x * delta
	#Reset to zero to prevent constant rotation
	_camera_input_direction = Vector2.ZERO

##Handles Jumping and gravity
func jump_logic(delta) -> void:
	if is_on_floor():
		on_floor = true
		if Input.is_action_just_pressed("jump") and not locked:
			velocity.y = -jump_velocity
	else:
		on_floor = false
	var gravity = jump_gravity if velocity.y > 0.0 else fall_gravity
	velocity.y -= gravity * delta

###Locks Player movement
func lock():
	locked = true
	velocity.x = 0.0
	velocity.z = 0.0

###Unlocks Player Movment
func unlock():
	locked = false
