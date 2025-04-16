extends AnimatedSprite2D
# Array of text lines to display
var text_lines = [
	"Si te fijas, la varilla tiene punta",
	"Y para nosotros, en broma",
	"Decimos que es tecnologia de punta",
	"Cuando encuentras un lugar",
	"que te parece que es una fosa",
	"la agarras y la entierras",
	"entierras la varilla",
	"y si la tierra fue removida o está floja",
	"la varilla se va sin necesidad de golpear",
	"cuando ya la enterramos",
	"pues olemos la punta de la varilla",
	"la olemos sí",
	"y llega el olor fétido",
	"¿Qué es la sanguaza?",
	"es la sangre podrida"
]
# Counter for visibility changes
var visibility_counter = 0
# References to labels
@onready var text_label = $TextForensic
@onready var static_noise = $NoiseStatic
@onready var text_number = $Number

const scene_game = preload("res://scenes/desert_01.tscn")

# Create an array to track used numbers
var available_numbers = []

func _ready():
	# Initialize the labels
	initialize_available_numbers()
	update_display()
	
	# Connect to visibility changed signal
	visibility_changed.connect(on_visibility_changed)

# Initialize array with numbers 1-99
func initialize_available_numbers():
	available_numbers = []
	for i in range(1, 100):
		available_numbers.append(i)
	# Shuffle to randomize initial order
	available_numbers.shuffle()

# Called when the visibility of the object changes
func on_visibility_changed():
	# Only increment counter and update text when object becomes visible
	if is_visible_in_tree():
		visibility_counter += 1
		static_noise.play()
		update_display()
		if visibility_counter >= 16:
			visible = false
			TransScene.transition()
			await TransScene.on_transition_finished
			get_tree().change_scene_to_packed(scene_game)

# Update the text and counter displays
func update_display():
	# Update text label with the current line (cycling through the array)
	if text_label and text_lines.size() > 0:
		# Get the appropriate line based on the counter (loop back to start if needed)
		var line_index = (visibility_counter - 1) % text_lines.size()
		text_label.text = text_lines[line_index]
	
	# Update number display with a random non-repeating number
	update_number_display()

# Update the number display with a random non-repeating number
func update_number_display():
	if text_number:
		# If we've used all numbers, reset the available numbers
		if available_numbers.size() == 0:
			initialize_available_numbers()
		
		# Get a random number from our available numbers
		var random_index = randi() % available_numbers.size()
		var number = available_numbers[random_index]
		
		# Remove the used number from the available list
		available_numbers.remove_at(random_index)
		
		# Display the number
		text_number.text = str(number)

# Alternative method if you need to manually trigger the visibility change
func trigger_visibility(is_visible):
	if is_visible:
		visibility_counter += 1
		static_noise.play()
		update_display()
