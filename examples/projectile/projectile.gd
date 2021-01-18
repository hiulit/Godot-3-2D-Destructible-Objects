extends RigidBody2D

export var shock_wave_radius = 100
export var shock_wave_threshold = 0.5

var last_frame_linear_velocity

var destroy = false
var collapse = false
var only_shock_wave = false
var debug_mode = false
var remove = false

func _ready():
	connect("body_entered", self, "collide")


func _physics_process(_delta):
	last_frame_linear_velocity = linear_velocity


func collide(body):
	if body.is_in_group("destructible_objects"):
		# Disconnect the signal when colliding (as we just need to detect one collision),
		# but keep the projectile in the scene.
		disconnect("body_entered", self, "collide")

		if destroy or collapse:
			# Get the projectile's linear velocity of the last frame if you want the projectile to follow its path.
			# If you want to just collide and stop, don't use it.
			if last_frame_linear_velocity:
				linear_velocity = last_frame_linear_velocity

			if destroy and collapse:
				# Reset the destructible and collapsible blocks array.
				body.object.destructible_blocks.resize(0)
				body.object.collapsible_blocks.resize(0)

				for block in body.object.blocks_container.get_children():
					if only_shock_wave:
						if global_position.distance_to(block.global_position) < shock_wave_radius * shock_wave_threshold:
							if debug_mode:
								block.modulate = Color("#00ff00")
							body.object.destructible_blocks.append(block)
						elif global_position.distance_to(block.global_position) > shock_wave_radius * shock_wave_threshold and global_position.distance_to(block.global_position) < shock_wave_radius:
							if debug_mode:
								block.modulate = Color("#ff0000")
							body.object.collapsible_blocks.append(block)
					else:
						if global_position.distance_to(block.global_position) < shock_wave_radius:
							body.object.destructible_blocks.append(block)
						else:
							body.object.collapsible_blocks.append(block)

				# Tell the object to detonate and collapse.
				if not debug_mode:
					body.object.detonate = true
					body.object.collapse = true

			if destroy and not collapse:
				# Reset the destructible blocks array.
				body.object.destructible_blocks.resize(0)
	
				for block in body.object.blocks_container.get_children():
					# Get only the blocks that are inside the shock wave radius.
					if only_shock_wave:
						if global_position.distance_to(block.global_position) < shock_wave_radius:
							if debug_mode:
								block.modulate = Color("#ff0000")
							body.object.destructible_blocks.append(block)
					# Get all the blocks.
					else:
						body.object.destructible_blocks.append(block)

				# Tell the object to detonate.
				if not debug_mode:
					body.object.detonate = true

			if collapse and not destroy:
				# Reset the collapsible blocks array.
				body.object.collapsible_blocks.resize(0)

				# Populate the collapsible blocks array.
				for block in body.object.blocks_container.get_children():
					# Get only the blocks that are inside the shock wave radius.
					if only_shock_wave:
						if global_position.distance_to(block.global_position) < shock_wave_radius:
							if debug_mode: block.modulate = Color("#ff0000")
							body.object.collapsible_blocks.append(block)
					# Get all the blocks.
					else:
						body.object.collapsible_blocks.append(block)

				# Tell the object to collapse.
				if not debug_mode:
					body.object.collapse = true

			if debug_mode and only_shock_wave:
				# Set the object to static mode and remove
				call_deferred("set_mode", MODE_STATIC)
#				body.remove_cover_sprite()
				body.position = Vector2(-9999, -9999)

				return

		# Or free the node when colliding if you don't need it anymore.
		if remove:
			queue_free()
