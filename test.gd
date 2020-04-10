extends Node2D

var reset_button = Button.new()
var detonate = false

func _ready():
	reset_button.name = "reset_button"
	reset_button.text = "Reset"
	reset_button.rect_position = Vector2(10, 10)
	reset_button.rect_size = Vector2(56, 28)
	reset_button.connect("pressed", self, "_on_reset_button_pressed")
	add_child(reset_button, true)


func _input(event):
	if event.is_action_pressed("ui_accept"):
		detonate = true
		set_process_input(false)


func _physics_process(_delta):
	if detonate:
		for destructible_object in get_tree().get_nodes_in_group("destructible_objects"):
			if destructible_object.object.can_detonate:
				destructible_object.object.detonate = true
		set_physics_process(false)


func _on_reset_button_pressed():
	var reset = get_tree().reload_current_scene()
	if reset == OK:
		print("-----")
		print("RESET")
		print("-----")
	else:
		print(reset)
