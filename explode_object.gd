extends RigidBody2D

export (int, 2, 10, 2) var blocks_per_side = 6
export (float) var blocks_impulse = 150
export (float) var blocks_gravity_scale = 6
export (float) var debris_max_time = 5
export (bool) var remove_debris = false
export (int) var collision_layers = 1
export (int) var collision_masks = 1
export (bool) var debug_mode = false

var object = {}

func _ready():
	object = {
		blocks = [],
		blocks_container = Node2D.new(),
		blocks_gravity_scale = blocks_gravity_scale,
		blocks_impulse = blocks_impulse,
		blocks_per_side = blocks_per_side,
		can_detonate = true,
		collision_extents = Vector2(),
		collision_layers = collision_layers,
		collision_masks = collision_masks,
		collision_name = null,
		collision_position = Vector2(),
		debris_max_time = debris_max_time,
		debris_timer = Timer.new(),
		detonate = false,
		frame = 0,
		has_particles = false,
		height = 0,
		hframes = 1,
		offset = Vector2(),
		parent = get_parent(),
		particles_name = null,
		remove_debris = remove_debris,
		scene = PackedScene.new(),
		sprite_name = null,
		vframes = 1,
		width = 0
	}

	# Randomize the seed of the random number generator
	randomize()

	# Dulicate the object's scene
	object.scene.pack(duplicate(8))

	if not self is RigidBody2D:
		print("ERROR: The '%s' node must be a 'RigidBody2D'" % self.name)
		object.can_detonate = false
		return

	for child in get_children():
		if child is Sprite:
			object.sprite_name = child.name

		if child is CollisionShape2D:
			object.collision_name = child.name

	if not object.sprite_name and not object.collision_name:
		print("ERROR: The 'RigidBody2D' (%s) must contain at least a 'Sprite' and a 'CollisionShape2D'." % self.name)
		object.can_detonate = false
		return

	if object.blocks_per_side % 2 != 0:
		print("ERROR: 'blocks_per_side' in '%s' must be an even number!" % self.name)
		object.can_detonate = false
		return

	# Set the debris timer
	object.debris_timer.connect("timeout", self ,"_on_debris_timer_timeout") 
	object.debris_timer.set_one_shot(true)
	object.debris_timer.set_wait_time(object.debris_max_time)
	add_child(object.debris_timer)

	if debug_mode: print("--------------------------------")
	if debug_mode: print("Debug mode for '%s'" % self.name)
	if debug_mode: print("--------------------------------")

	# Use vframes and hframes to divide the sprite
	get_node(object.sprite_name).vframes = object.blocks_per_side
	get_node(object.sprite_name).hframes = object.blocks_per_side
	object.vframes = get_node(object.sprite_name).vframes
	object.hframes = get_node(object.sprite_name).hframes

	if debug_mode: print("object's blocks per side: ", object.blocks_per_side)
	if debug_mode: print("object's total blocks: ", object.blocks_per_side * object.blocks_per_side)

	# Check if the sprite is using Region to get the proper width and height
	if get_node(object.sprite_name).region_enabled:
		object.width = float(get_node(object.sprite_name).region_rect.size.x)
		object.height = float(get_node(object.sprite_name).region_rect.size.y)
	else:
		object.width = float(get_node(object.sprite_name).texture.get_width())
		object.height = float(get_node(object.sprite_name).texture.get_height())

	if debug_mode: print("object's width: ", object.width)
	if debug_mode: print("object's height: ", object.height)

	# Check if the sprite is centered to get the offset
	if get_node(object.sprite_name).centered:
		object.offset = Vector2(object.width / 2, object.height / 2)

		if debug_mode: print("object is centered!")
		if debug_mode: print("object's offset: ", object.offset)

	object.collision_extents = Vector2((object.width / 2) / object.hframes,\
										(object.height / 2) / object.vframes)

	if debug_mode: print("object's collision_extents: ", object.collision_extents)

	object.collision_position = Vector2((ceil(object.collision_extents.x) - object.collision_extents.x) * -1,\
										(ceil(object.collision_extents.y) - object.collision_extents.y) * -1)

	if debug_mode: print("object's collision_position: ", object.collision_position)

	# Set each block's properties
	for n in range(object.vframes * object.hframes):
		object.blocks.append(object.scene.instance())

		# Create a new collision shape for each block
		var shape = RectangleShape2D.new()
		shape.extents = object.collision_extents

		object.blocks[n].set_mode(MODE_STATIC)
		object.blocks[n].get_node(object.sprite_name).vframes = object.vframes
		object.blocks[n].get_node(object.sprite_name).hframes = object.hframes
		object.blocks[n].get_node(object.sprite_name).frame = n
		object.blocks[n].get_node(object.collision_name).shape = shape
		object.blocks[n].get_node(object.collision_name).position = object.collision_position

		if debug_mode: object.blocks[n].modulate = Color(rand_range(0, 1), rand_range(0, 1), rand_range(0, 1), 0.9)

	# Position each block in place to create the whole sprite
	for x in range(object.hframes):
		for y in range(object.vframes):
			object.blocks[object.frame].position = Vector2(\
				y * (object.width / object.hframes) - object.offset.x + object.collision_extents.x + position.x,\
				x * (object.height / object.vframes) - object.offset.y + object.collision_extents.y + position.y)

			if debug_mode: print("object[", object.frame, "] position: ", object.blocks[object.frame].position)

			object.frame += 1

	call_deferred("add_children", object)

	if debug_mode: print("--------------------------------")


func _physics_process(delta):
	if Input.is_key_pressed(KEY_Q) and object.can_detonate or\
	if Input.is_key_pressed(KEY_Q) and object.can_detonate or \
		Input.is_mouse_button_pressed(BUTTON_LEFT) and object.can_detonate:
		# This is what triggers the explosion, setting 'object.detonate' to 'true',
		object.detonate = true

	if object.detonate:
		detonate()


func _integrate_forces(state):
	explosion()


func add_children(object):
	for i in range(object.blocks.size()):
		object.blocks_container.add_child(object.blocks[i])

	object.parent.add_child(object.blocks_container)

	# Move the self element faaaar away, instead of removing it,
	# so we can still use the script and its functions.
	self.position = Vector2(-999999, -999999)
#	self.queue_free()


func detonate():
	object.can_detonate = false

	for child in object.parent.get_children():
		if child is Particles2D or child is CPUParticles2D:
			object.particles_name = child.name
			object.has_particles = true

	if object.has_particles:
		object.parent.get_node(object.particles_name).emitting = true

	for i in range(object.blocks_container.get_child_count()):
		var child = object.blocks_container.get_child(i)

		var child_gravity_scale = blocks_gravity_scale
		child.gravity_scale = child_gravity_scale

		var child_scale = rand_range(0.5, 1.5)
		child.get_node(object.sprite_name).scale = Vector2(child_scale, child_scale)
		child.get_node(object.collision_name).scale = Vector2(child_scale, child_scale)

		child.set_collision_layer(0 if randf() < 0.5 else object.collision_layers)
		child.set_collision_mask(0 if randf() < 0.5 else object.collision_masks)

		child.z_index = 0 if randf() < 0.5 else -1

		var child_color = rand_range(100, 255) / 255
		var color_tween = Tween.new()
		add_child(color_tween)
		color_tween.interpolate_property(
			child,
			"modulate", 
			Color(1.0, 1.0, 1.0, 1.0),
			Color(child_color, child_color, child_color, 1.0),
			0.25,
			Tween.TRANS_LINEAR,
			Tween.EASE_IN)
		color_tween.start()

		child.set_mode(MODE_RIGID)

	object.debris_timer.start()


func explosion():
	if object.detonate:
		if debug_mode: print("'%s' object exploded!" % self.name)

		for i in range(object.blocks_container.get_child_count()):
			var child = object.blocks_container.get_child(i)

			child.add_torque((blocks_impulse / 2) * (blocks_per_side * rand_range(1.0, blocks_per_side)))
			child.apply_impulse(Vector2(rand_range(-blocks_impulse / 2, blocks_impulse / 2),\
										rand_range(-blocks_impulse, blocks_impulse * 2)),\
								Vector2(rand_range(-blocks_impulse / 2, blocks_impulse / 2),\
										rand_range(-blocks_impulse, -blocks_impulse * 2)))

		object.detonate = false


func _on_debris_timer_timeout():
	if debug_mode: print("'%s' object's debris timer (%ss) timed out!" % [self.name, debris_max_time])

	for i in range(object.blocks_container.get_child_count()):
		var child = object.blocks_container.get_child(i)

		if not object.remove_debris:
			child.set_mode(MODE_STATIC)
			child.get_node(object.collision_name).disabled = true
		else:
			var color_r = child.modulate.r
			var color_g = child.modulate.g
			var color_b = child.modulate.b
			var color_a = child.modulate.a

			var opacity_tween = Tween.new()
			add_child(opacity_tween)
			opacity_tween.connect("tween_completed", self, "_on_opacity_tween_completed")
			opacity_tween.interpolate_property(
				child,
				"modulate", 
				Color(color_r, color_g, color_b, color_a),
				Color(color_r, color_g, color_b, 0.0),
				rand_range(0.0, 1.0),
				Tween.TRANS_LINEAR,
				Tween.EASE_IN)
			opacity_tween.start()


func _on_opacity_tween_completed(obj, key):
	obj.queue_free()

	# Remove the parent node after the last block is gone.
	if object.blocks_container.get_child_count() == 1:
		object.parent.queue_free()
		self.queue_free()
