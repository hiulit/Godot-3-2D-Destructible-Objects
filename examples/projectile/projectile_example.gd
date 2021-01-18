extends Node2D

onready var destroy_checkbox = $GUI/destroy_checkbox
onready var collapse_checkbox = $GUI/collapse_checkbox
onready var only_shock_wave_checkbox = $GUI/only_shock_wave_checkbox
onready var show_shock_wave_checkbox = $GUI/show_shock_wave_checkbox
onready var shock_wave_debug_mode_checkbox = $GUI/shock_wave_debug_mode_checkbox

onready var projectile = $projectile
onready var projectile_collision = $projectile/collision

export (Vector2) var projectile_linear_velocity = Vector2(1000, -500)

var detonate = false
var collapse = false

var show_shock_wave = false


func _physics_process(_delta):
	if detonate:
		for destructible_object in get_tree().get_nodes_in_group("destructible_objects"):
			if destructible_object.object.can_detonate:
				destructible_object.object.detonate = true

	update()


func _draw():
	if is_instance_valid(projectile):
		draw_circle(projectile.global_position, projectile_collision.shape.radius, Color("#ffffff"))

		if show_shock_wave:
			if projectile.destroy or projectile.collapse:
				draw_circle_arc(projectile.global_position, projectile.shock_wave_radius, 0, 360, Color("#ff0000"))

			if projectile.destroy and projectile.collapse:
				draw_circle_arc(projectile.global_position, projectile.shock_wave_radius * projectile.shock_wave_threshold, 0, 360, Color("#00ff00"))


func draw_circle_arc(center, radius, angle_from, angle_to, color):
	var nb_points = 180
	var points_arc = PoolVector2Array()

	for i in range(nb_points + 1):
		var angle_point = deg2rad(angle_from + i * (angle_to - angle_from) / nb_points - 90)
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)

	for index_point in range(nb_points):
		draw_line(points_arc[index_point], points_arc[index_point + 1], color)


func _on_reset_button_pressed():
	var reset = get_tree().reload_current_scene()
	if reset != OK:
		# Print error.
		print(reset)


func _on_launch_button_pressed():
	if is_instance_valid(projectile):
		projectile.linear_velocity = projectile_linear_velocity


func _on_detonate_button_pressed():
	detonate = true


func _on_destroy_checkbox_toggled(button_pressed):
	if is_instance_valid(projectile):
		projectile.destroy = button_pressed
		only_shock_wave_checkbox.disabled = not (button_pressed or collapse_checkbox.pressed)
		show_shock_wave_checkbox.disabled = not (button_pressed or collapse_checkbox.pressed)


func _on_collapse_checkbox_toggled(button_pressed):
	if is_instance_valid(projectile):
		projectile.collapse = button_pressed
		only_shock_wave_checkbox.disabled = not (button_pressed or destroy_checkbox.pressed)
		show_shock_wave_checkbox.disabled = not (button_pressed or destroy_checkbox.pressed)


func _on_only_shock_wave_checkbox_toggled(button_pressed):
	if is_instance_valid(projectile):
		projectile.only_shock_wave = button_pressed
		shock_wave_debug_mode_checkbox.disabled = not button_pressed


func _on_show_shock_wave_checkbox_toggled(button_pressed):
	if is_instance_valid(projectile):
		show_shock_wave = button_pressed


func _on_shock_wave_debug_mode_checkbox_toggled(button_pressed):
	if is_instance_valid(projectile):
		projectile.debug_mode = button_pressed
		show_shock_wave_checkbox.pressed = button_pressed


func _on_remove_projectile_checkbox_toggled(button_pressed):
	if is_instance_valid(projectile):
		projectile.remove = button_pressed
