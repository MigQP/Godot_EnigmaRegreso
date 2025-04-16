extends Camera2D
var length = 20  # Minimum swipe distance
var startPos: Vector2
var curPos: Vector2
var swiping = false
var threshold = 10  # Threshold for determining direction

# Variables for the finder sprite movement
var down_swipe_count = 0
var original_y_position = 0
var move_distance = 5  # The amount to move down each time (adjust as needed)
@onready var finder = $Finder  # Reference to your AnimatedSprite2D

# Lerp variables
var target_position = Vector2.ZERO
var lerp_speed = 5.0  # Adjust this to control lerp speed (higher = faster)
var is_lerping = false

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

func _process(delta):
	# Handle lerping movement
	if is_lerping and finder:
		finder.position = finder.position.lerp(target_position, lerp_speed * delta)
		
		# Check if we've essentially reached the target (within a small threshold)
		if finder.position.distance_to(target_position) < 0.5:
			finder.position = target_position  # Snap to exact position
			is_lerping = false
	
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
		down_swipe_count += 1
		print("Down swipe count: ", down_swipe_count)
		
		# Calculate new target position
		if down_swipe_count >= 4:
			# On third swipe, go back to original position
			target_position = Vector2(finder.position.x, original_y_position)
			down_swipe_count = 0
			print("Reset finder position to original")
		else:
			# Move down on first and second swipes
			target_position = Vector2(finder.position.x, finder.position.y + move_distance)
		
		# Start lerping to the target position
		is_lerping = true
