extends RigidBody2D

export (String) var object_group = "destructible_objects"
export (Vector2) var blocks_per_side = Vector2(6, 6)
export (float) var blocks_impulse = 600
export (float) var blocks_gravity_scale = 10
export (bool) var random_debris_scale = false
export (float) var debris_max_time = 5
export (bool) var remove_debris = false
export (int) var collision_layers = 1
export (int) var collision_masks = 1
export (bool) var collision_one_way = false
export (bool) var explosion_delay = false
export (String) var fake_explosions_group = "fake_explosion_particles"
export (bool) var randomize_seed = false
export (bool) var debug_mode = false

var object = {}

var debris_timer_name = "debris_timer"
var opacity_tween_name = "opacity_tween"
var color_tween_name = "color_tween"

var cover_sprite_name = "cover_sprite"

var explosion_delay_timer = 0
var explosion_delay_timer_limit = 0

func _ready():
#	Engine.time_scale = 0.1
	object = {
		blocks = [],
		blocks_container = Node2D.new(),
		blocks_gravity_scale = blocks_gravity_scale,
		blocks_impulse = blocks_impulse,
		blocks_per_side = blocks_per_side,
		blocks_total = blocks_per_side.x * blocks_per_side.y,
		can_detonate = true,
		collision_layers = collision_layers,
		collision_masks = collision_masks,
		collision_name = null,
		collision_one_way = collision_one_way,
		color_tween = Tween.new(),
		debris_max_time = debris_max_time,
		debris_timer = Timer.new(),
		detonate = false,
		has_detonated = false,
		has_particles = false,
		offset = Vector2(),
		opacity_tween = Tween.new(),
		parent = get_parent(),
		particles = null,
		remove_debris = remove_debris,
		size = Vector2(),
		sprite_name = null,
	}

	# Add object to group.
	add_to_group(object_group)
	
	# Add a unique name to 'blocks_container'.
	object.blocks_container.name = self.name + "_blocks_container"

	# Randomize the seed of the random number generator.
	if randomize_seed: randomize()

	# Look for a 'Sprite' and a 'CollisionShape2D' or 'CollisionShape2D'.
	for child in get_children():
		if child is Sprite:
			object.sprite_name = child.name

		if child is CollisionShape2D or child is CollisionPolygon2D:
			object.collision_name = child.name

	# Check if there is least a 'Sprite' for the script to work properly.
	if not object.sprite_name:
		printerr("------------------------------------------------------------------")
		printerr("ERROR: The '%s' node must contain at least a 'Sprite'!" % self.name)
		printerr("------------------------------------------------------------------")
		object.can_detonate = false
		self.set_mode(MODE_STATIC)
		return

	# Check if 'blocks_per_side' values are positive integers.
	if step_decimals(object.blocks_per_side.x) != 0 or step_decimals(object.blocks_per_side.y) != 0:
		printerr("---------------------------------------------------------------------------------------------------------------------------------------------")
		printerr("ERROR: The '%s' node's 'block_per_side' values (%s, %s) must be positive integers!" % [self.name, object.blocks_per_side.x, object.blocks_per_side.y])
		printerr("---------------------------------------------------------------------------------------------------------------------------------------------")
		object.can_detonate = false
		self.set_mode(MODE_STATIC)
		return

	# Set the debris timer, or not.
	if debris_max_time > 0:
		object.debris_timer.connect("timeout", self ,"_on_debris_timer_timeout") 
		object.debris_timer.set_one_shot(true)
		object.debris_timer.set_wait_time(object.debris_max_time)
		object.debris_timer.name = debris_timer_name
		add_child(object.debris_timer, true)
	else:
		object.debris_timer = null

	# Set the color tween.
	object.color_tween.name = color_tween_name
	add_child(object.color_tween, true)

	# Set the opacity tween, or not.
	if object.remove_debris:
		object.opacity_tween.name = opacity_tween_name
		add_child(object.opacity_tween, true)

	# Check if the object has particles.
	call_deferred("check_for_particles")

	if debug_mode: print("--------------------------------")
	if debug_mode: print("Debug mode for '%s'" % self.name)
	if debug_mode: print("--------------------------------")

	if debug_mode: print("blocks per side: ", object.blocks_per_side)
	if debug_mode: print("total blocks: ", object.blocks_total)

	# Check if the sprite is using 'Region', to get the proper size.
	if get_node(object.sprite_name).region_enabled:
		object.size = Vector2(
			float(get_node(object.sprite_name).region_rect.size.x),
			float(get_node(object.sprite_name).region_rect.size.y)
		)
	else:
		object.size = Vector2(
			float(get_node(object.sprite_name).texture.get_width()),
			float(get_node(object.sprite_name).texture.get_height())
		)

	if debug_mode: print("size: ", object.size)

	# Check if the sprite is centered to get the offset.
	if get_node(object.sprite_name).centered:
		object.offset = object.size / 2

	if debug_mode: print("offset: ", object.offset)

	# Create the blocks and set each own properties.
	# Initiate the loop's index.
	var i = 0
	# Loop through all the blocks of each side.
	for x in range(object.blocks_per_side.x):
		for y in range(object.blocks_per_side.y):
			# Create each block by duplicating the object.
			var block = self.duplicate(8)
			# Add a unique name to each block.
			block.name = self.name + "_block_" + str(i)

			# Create a new image texture for each block's sprite.
			var block_texture = ImageTexture.new()
			# Set the image texture's position.
			var block_texture_position = Vector2(
				x * (object.size.x / object.blocks_per_side.x),
				y * (object.size.y / object.blocks_per_side.y)
			)
			# Set the image texture's size.
			var block_texture_size = Vector2(
				object.size.x / object.blocks_per_side.x,
				object.size.y / object.blocks_per_side.y
			)
			# Set the image texture's rect using the previous position and size.
			var block_texture_rect = Rect2(block_texture_position, block_texture_size)
			# Create a new texture from the image texture.
			block_texture.create_from_image(
				get_node(object.sprite_name).texture.get_data().get_rect(block_texture_rect),
				0
			)
			# Set the new texture to the block's sprite.
			var block_sprite = block.get_node(object.sprite_name)
			block_sprite.texture = block_texture

			# Create a new 'CollisionPolygon2D' for each block.
			create_polygon_collision(block_sprite, block)
#			call_deferred("create_polygon_collision", block_sprite, block)

			# Set each block to STATIC mode.
			block.set_mode(MODE_STATIC)

			# Put each block to sleep.
			block.sleeping = true

			# Postion each block.
			block.position = Vector2(
				block_texture_position.x + position.x - (object.offset.x - (object.offset.x / object.blocks_per_side.x)),
				block_texture_position.y + position.y - (object.offset.y - (object.offset.y / object.blocks_per_side.y))
			)
			# Take the scale into account.
			block.position *= get_node(object.sprite_name).get_scale()

			# Set each block collision's properties.
			block.set_collision_layer(0 if randf() < 0.5 else object.collision_layers)
			block.set_collision_mask(0 if randf() < 0.5 else object.collision_masks)
			if object.collision_one_way: block.get_node(object.collision_name).one_way_collision = true

			# Add gravity to each block.
			block.gravity_scale = blocks_gravity_scale

			# Set each block's color tween.
			var explosion_color = rand_range(100, 200) / 255
			var block_explosion_color = Color(explosion_color, explosion_color, explosion_color, 1.0)
			var block_color_tween = block.get_node(color_tween_name)
			block_color_tween.connect("tween_completed", self, "_on_color_tween_completed")
			block_color_tween.interpolate_property(
				block,
				"modulate", 
				Color(1.0, 1.0, 1.0, 1.0),
				block_explosion_color,
				0.25,
				Tween.TRANS_LINEAR,
				Tween.EASE_IN)

			# Set each block's opacity tween.
			if object.remove_debris:
				var block_color_r = block_explosion_color.r
				var block_color_g = block_explosion_color.g
				var block_color_b = block_explosion_color.b
				var block_color_a = block_explosion_color.a
				var block_opacity_tween = block.get_node(opacity_tween_name)
				block_opacity_tween.connect("tween_completed", self, "_on_opacity_tween_completed")
				block_opacity_tween.interpolate_property(
					block,
					"modulate", 
					Color(block_color_r, block_color_g, block_color_b, block_color_a),
					Color(block_color_r, block_color_g, block_color_b, 0.0),
					rand_range(0.0, 1.0),
					Tween.TRANS_LINEAR,
					Tween.EASE_IN)

			# Set each block's 'z_index'.
			block.z_index = 0 if randf() < 0.5 else -1

			if debug_mode: block.modulate = Color(rand_range(0, 1), rand_range(0, 1), rand_range(0, 1), 0.9)

			# Add each block to the blocks container.
			object.blocks_container.add_child(block, true)

			# Update the index.
			i += 1

	# Add the blocks to the blocks container.
	call_deferred("add_blocks", object)

	if debug_mode: print("--------------------------------")


func _physics_process(delta):
	if object.can_detonate and object.detonate:
		detonate()

	if object.has_detonated:
		# Add a delay of 'delta' before counting the blocks.
		# Sometimes the last one doesn't get counted.
		if explosion_delay:
			# Removed the yield timer because it was throwing
			# 'Resumed after yield, but class instance is gone' errors
			# when freeing the blocks.
			# yield(get_tree().create_timer(delta), "timeout")
			explosion_delay_timer_limit = delta
			explosion_delay_timer += delta
			if explosion_delay_timer > explosion_delay_timer_limit:
				explosion_delay_timer -= explosion_delay_timer_limit
				# Remove the parent node after the last block is gone.
				if object.blocks_container.get_child_count() == 0:
					object.parent.queue_free()
		else:
			# Remove the parent node after the last block is gone.
			if object.blocks_container.get_child_count() == 0:
				object.parent.queue_free()


func _integrate_forces(state):
	explosion(state.step)


func add_blocks(child_object):
	# Add the blocks to the blocks container.
	child_object.parent.add_child(child_object.blocks_container, true)

	# Add a cover sprite to hide the possible mini gaps between blocks.
	# Don't add it 'debug_mode' is set to 'true', so we can't see the debug blocks.
	if not debug_mode: add_cover_sprite()

	# Move the self object faaaar away, instead of removing it,
	# so we can still use the script and its functions.
	self.position = Vector2(-999999, -999999)
	# Set the object to sleep so it won't interact with the world.
	self.sleeping = true
	# If for some reason it wakes up,
	# we make it invisible so at least we won't see it.
	self.visible = false


func add_cover_sprite():
	# Duplicate the object's sprite.
	var cover_sprite = Sprite.new()
	cover_sprite.name = cover_sprite_name
	cover_sprite.texture = get_node(object.sprite_name).texture
	cover_sprite.scale = get_node(object.sprite_name).scale
	cover_sprite.centered = get_node(object.sprite_name).centered
	object.parent.add_child(cover_sprite, true)


func check_for_particles():
	# Check if the parent node has particles as a child.
	for child in object.parent.get_children():
		if child is Particles2D or child is CPUParticles2D or child.is_in_group(fake_explosions_group):
			object.particles = child
			object.has_particles = true


func detonate():
	object.can_detonate = false
	object.has_detonated = true

	# Remove the cover sprite.
	if object.parent.has_node(cover_sprite_name):
		object.parent.get_node(cover_sprite_name).queue_free()

	# Check if the object has particles and if so, start emitting them.
	if object.has_particles:
		if object.particles.is_in_group(fake_explosions_group):
			object.particles.particles_explode = true
		else:
			object.particles.emitting = true

	# Set properties to each block.
	for block in object.blocks_container.get_children():
		# Set each block's scale.
		# If 'random_debris_scale' is set to 'true',
		# some random blocks will scale to half its size.
		# The scale will affect the block's mass, which by default is 1.
		if random_debris_scale:
			var block_scale = 0.5 if randf() < 0.5 else 1.0
			block.get_node(object.sprite_name).scale *= Vector2(block_scale, block_scale)
			block.get_node(object.collision_name).scale *= Vector2(block_scale, block_scale)
			block.get_node(object.collision_name).position *= Vector2(block_scale, block_scale)
	
			# Set each block's mass depending on its scale.
			block.mass *= block_scale 

		# Start each block's color tween to make them darker.
		block.get_node(color_tween_name).start()

		# Set each block to RIGID mode.
		block.set_mode(MODE_RIGID)

	# Start the debris timer if the timer exists.
	if object.debris_timer: object.debris_timer.start()


func explosion(delta):
	if object.detonate:
		if debug_mode: print("'%s' object exploded!" % self.name)

		for block in object.blocks_container.get_children():
			# Create a random angular velocity for each block, depending on its mass.
			var block_angular_velocity = rand_range(
				(block.mass * (blocks_impulse / blocks_gravity_scale)) / 2,
				block.mass * (blocks_impulse / blocks_gravity_scale)
			)
			# Set the angular velocity for each block.
			block.angular_velocity = block_angular_velocity
			# Create a random impulse for each block, depending on its mass.
			var block_impulse = Vector2(
				rand_range(-blocks_impulse, blocks_impulse),
				rand_range(-blocks_impulse, (-blocks_impulse / blocks_gravity_scale))
			)
			# Apply a central impulse to each block.
			block.apply_central_impulse(block_impulse)

		# Add a delay before setting 'object.detonate' to 'false'.
		# Sometimes 'object.detonate' is set to 'false' so quickly that the explosion never happens.
		# If this happens, try setting 'explosion_delay' to 'true'.
		if explosion_delay:
			# Removed the yield timer because it was throwing
			# 'Resumed after yield, but class instance is gone' errors
			# when freeing the blocks.
			# yield(get_tree().create_timer(delta), "timeout")
			explosion_delay_timer_limit = delta
			explosion_delay_timer += delta
			if explosion_delay_timer > explosion_delay_timer_limit:
				explosion_delay_timer -= explosion_delay_timer_limit
				object.detonate = false
		else:
			object.detonate = false


func _on_debris_timer_timeout():
	if debug_mode: print("'%s' object's debris timer (%ss) timed out!" % [self.name, debris_max_time])

	for block in object.blocks_container.get_children():
		# Remove the debris timer node, as we don't need it anymore.
		block.get_node(debris_timer_name).queue_free()

		# If 'remove_debris' is set to 'true',
		# start the opacity tween node (to make the blocks disappear).
		if object.remove_debris:
			block.get_node(opacity_tween_name).start()
		else:
			# Set each block to STATIC mode.
			block.set_mode(MODE_STATIC)
			# Disable each block's collision.
			block.get_node(object.collision_name).disabled = true
			# Remove the self object, as we don't need it anymore.
			self.queue_free()


func _on_color_tween_completed(obj, _key):
	# Remove the color tween from each block when it has finished itself.
	obj.get_node(color_tween_name).queue_free()


func _on_opacity_tween_completed(obj, _key):
	# Remove the block when the opacity tween has finished.
	obj.queue_free()


func create_polygon_collision(sprite, parent):
	# We need to get the image from the texture or load the image
	# directly if you imported it as an Image.
	# In this case, we get the image from the sprite's texture.

	# Get the sprite's texture.
	var texture = sprite.texture
	# Get the sprite texture's size.
	var texture_size = sprite.texture.get_size()
	# Get the image from the sprite's texture.
	var image = texture.get_data()

	# Create a new bitmap.
	var bitmap = BitMap.new()
	# Create the bitmap from the image. We set the minimum alpha threshold.
	bitmap.create_from_image_alpha(image, 0.01) # 0.1 (default threshold)
	# Get the rect of the bitmap.
	var bitmap_rect = Rect2(Vector2(0, 0), bitmap.get_size())
	# Grow the bitmap if you need (we don't need it in this case).
#	bitmap.grow_mask(0, rect) # 2
	# Convert all the opaque parts of the bitmap into polygons.
	var polygons = bitmap.opaque_to_polygons(bitmap_rect, 0) # 2

	# Check if there are polygons.
	if polygons.size() > 0:
		# Remove the parent object's collision, as we won't need it.
		for child in parent.get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				child.queue_free()

		# Loop through all the polygons.
		for i in range(polygons.size()):
			# Create a new 'CollisionPolygon2D'.
			var collision = CollisionPolygon2D.new()
			collision.name = "collision_polygon"
			# Set its polygon to the first polygon you've got
			collision.polygon = polygons[i]
			# Position the collision to the same position as the sprite's. 
			# Check if the sprite is centered to get the proper position.
			if sprite.centered:
				collision.position = sprite.position - (texture_size / 2)
			else:
				collision.position = sprite.position
			# Take the sprite's scale into account and apply it to the position.
			collision.scale = sprite.scale
			collision.position *= collision.scale

			# and add it to the node
			object.collision_name = collision.name
			parent.add_child(collision, true)
	else:
		# If the aren't any polygons, remove the parent node.
		parent.queue_free()
