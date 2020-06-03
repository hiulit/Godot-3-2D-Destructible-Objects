extends Node2D

var reset_button = Button.new()
var detonate_button = Button.new()

var detonate = false

var explosion_delay_timer = 0
var explosion_delay_timer_limit = 0.5

func _ready():
	reset_button.name = "reset_button"
	reset_button.text = "Reset"
	reset_button.rect_position = Vector2(10, 10)
	reset_button.rect_size = Vector2(56, 28)
	reset_button.connect("pressed", self, "_on_reset_button_pressed")
	add_child(reset_button, true)

	detonate_button.name = "detonate_button"
	detonate_button.text = "Detonate"
	detonate_button.rect_position = Vector2(100, 10)
	detonate_button.rect_size = Vector2(56, 28)
	detonate_button.connect("pressed", self, "_on_detonate_button_pressed")
	add_child(detonate_button, true)


func _input(event):
	if event.is_action_pressed("ui_accept"):
		detonate = true
		set_process_input(false)


func _physics_process(delta):
	if detonate:
		for destructible_object in get_tree().get_nodes_in_group("destructible_objects"):
			if destructible_object.object.can_detonate:
#				explosion_delay_timer_limit = delta
				explosion_delay_timer += delta
				if explosion_delay_timer > explosion_delay_timer_limit:
					explosion_delay_timer -= explosion_delay_timer_limit
					destructible_object.blocks_impulse = 50
#					destructible_object.object.has_particles = false
					destructible_object.object.detonate = true
#		set_physics_process(false)


func _on_reset_button_pressed():
	var reset = get_tree().reload_current_scene()
	if reset == OK:
		print("-----")
		print("RESET")
		print("-----")
	else:
		# Print error.
		print(reset)


func _on_detonate_button_pressed():
	detonate = true
