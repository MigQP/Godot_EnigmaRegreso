extends Camera2D
var length = 20  # Minimum swipe distance
var startPos: Vector2
var curPos: Vector2
var swiping = false
var threshold = 10  # Threshold for determining direction
# Variables for the finder sprite movement
var down_swipe_count = 0
var original_y_position = 0
var move_distance = 10  # The amount to move down each time (adjust as needed)
@onready var finder = $Finder  # Reference to your AnimatedSprite2D
# Audio reference
@onready var dig_sound = $DigSound  # Reference to your AudioStreamPlayer
# Static reference - we'll get this through get_node or find_node
var static_object = null
# Lerp variables
var target_position = Vector2.ZERO
var lerp_speed = 5.0  # Adjust this to control lerp speed (higher = faster)
var is_lerping = false
# Static display variables
var can_swipe = true
var static_timer = 0.0
var static_display_duration = 1.5
var static_delay_timer = 0.0
var static_delay_duration = 0.4
var waiting_for_static = false
# Random position variables
var min_x_position = -100  # Minimum x position (adjust based on your game's needs)
var max_x_position = 100   # Maximum x position (adjust based on your game's needs)
var visibility_count = 0

func _ready():
	# Set up the "press" input action programmatically if it doesn't exist
	if not InputMap.has_action("press"):
		InputMap.add_action("press")
		
		# Add mouse button as an event for "press"
		var mouse_event = InputEventMouseButton.new()
		mouse_event.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("press", mouse_event)
		
		# Add touch screen event for mobile
		var touch_event = InputEventScreenTouch.new()
		touch_event.index = 0  # First finger touch
		InputMap.action_add_event("press", touch_event)
		
		print("'press' input action created")
	
	# Store the original y position of the finder sprite
	if finder:
		original_y_position = finder.position.y
		target_position = finder.position
		print("Original finder position: ", original_y_position)
	else:
		push_error("Finder sprite not found! Make sure you have an AnimatedSprite2D named 'Finder' as a child of this Camera2D.")
		
	# Check if the audio player exists
	if not has_node("DigSound"):
		push_error("DigSound AudioStreamPlayer not found! Add an AudioStreamPlayer named 'DigSound' as a child of this Camera2D.")
	
	# Try to find the static object in the scene
	static_object = get_node("/root/Node2D/Static") # Adjust this path to match your scene structure
	
	# If that didn't work, try a more general approach
	if not static_object:
		static_object = get_tree().get_root().find_child("Static", true, false)
	
	# Initialize static object as invisible
	if static_object:
		static_object.visible = false
	else:
		push_error("Static object not found! Make sure you have a node named 'Static' in your scene.")

func _process(delta):
	# Handle static display timer
	if waiting_for_static:
		static_delay_timer += delta
		if static_delay_timer >= static_delay_duration:
			waiting_for_static = false
			static_delay_timer = 0.0
			
			# Show the static object
			if static_object && visibility_count <= 16:
				static_object.visible = true
				can_swipe = false  # Disable swiping
			# Start the static display timer
			static_timer = static_display_duration
	
	# Handle static object display time
	if not can_swipe and static_timer > 0:
		static_timer -= delta
		if static_timer <= 0:
			# Time's up, hide static and re-enable swiping
			if static_object:
				static_object.visible = false
				
				# Get a random x position within the specified range
				var random_x = randf_range(min_x_position, max_x_position)
				
				# Set target position with the random x and original y
				target_position = Vector2(random_x, original_y_position)
				
				# Reset finder position
				if finder:
					finder.position.x = random_x
					finder.position.y = original_y_position
				
			can_swipe = true
			is_lerping = false
	
	# Handle lerping movement (only for downward movement)
	if is_lerping and finder:
		finder.position = finder.position.lerp(target_position, lerp_speed * delta)
		
		# Check if we've essentially reached the target (within a small threshold)
		if finder.position.distance_to(target_position) < 0.5:
			finder.position = target_position  # Snap to exact position
			is_lerping = false
	
	# Only process swipe input if swiping is allowed
	if can_swipe:
		# Start tracking when the press action begins
		if Input.is_action_just_pressed("press"):
			swiping = true
			startPos = get_global_mouse_position()
			print("Start Position: ", startPos)
		
		# Continue tracking while pressed
		if Input.is_action_pressed("press"):
			if swiping:
				curPos = get_global_mouse_position()
				
				# Check if the swipe is long enough
				if startPos.distance_to(curPos) >= length:
					# Determine swipe direction
					var dx = abs(startPos.x - curPos.x)
					var dy = abs(startPos.y - curPos.y)
					
					if dx > dy and dy <= threshold:
						# Horizontal swipe (x difference is larger, y difference is small)
						print("Horizontal Swipe")
						if curPos.x > startPos.x:
							print("Right Swipe")
							# Add your right swipe action here
						else:
							print("Left Swipe")
							# Add your left swipe action here
						swiping = false
					
					elif dy > dx and dx <= threshold:
						# Vertical swipe (y difference is larger, x difference is small)
						print("Vertical Swipe")
						if curPos.y > startPos.y:
							print("Down Swipe")
							handle_down_swipe()
						else:
							print("Up Swipe")
							# Add your up swipe action here
						swiping = false
		
		# Reset when press is released
		elif Input.is_action_just_released("press"):
			swiping = false

func handle_down_swipe():
	if finder:
		# Play the dig sound
		if dig_sound and dig_sound.stream:
			dig_sound.play()
		else:
			print("Warning: DigSound not properly set up")
			
		down_swipe_count += 1
		print("Down swipe count: ", down_swipe_count)
		
		# Calculate new target position
		if down_swipe_count >= 3:
			# On fourth swipe, go back to original position and trigger static
			down_swipe_count = 0
			visibility_count += 1
			print("Reset finder position and triggering static")
			
			# Start the delay before showing static
			waiting_for_static = true
			static_delay_timer = 0.0
		else:
			# Move down on first, second, and third swipes
			target_position = Vector2(finder.position.x, finder.position.y + move_distance)
		
		# Start lerping to the target position
		is_lerping = true
