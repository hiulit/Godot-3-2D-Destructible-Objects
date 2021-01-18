extends RigidBody2D

export (String) var object_group = "destructible_objects"
export (Vector2) var blocks_per_side = Vector2(10, 10)
export (float) var blocks_impulse = 100
export (bool) var random_debris_scale = false
export (float) var debris_max_time = 3
export (bool) var remove_debris = true
export (bool) var random_depth = true
export (bool) var random_collision = true
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
	self.set_mode(MODE_STATIC)
	self.sleeping = true

	object = {
		blocks = [],
		blocks_container = Node2D.new(),
		blocks_impulse = blocks_impulse * self.mass * self.gravity_scale,
		blocks_per_side = blocks_per_side,
		blocks_total = blocks_per_side.x * blocks_per_side.y,
		can_collapse = true,
		can_detonate = true,
		collapse = false,
		collapsible_blocks = [],
		collision = null,
		collision_type = null,
		collision_layers = collision_layers,
		collision_masks = collision_masks,
		collision_name = null,
		collision_one_way = collision_one_way,
		color_tween = Tween.new(),
		debris_max_time = debris_max_time,
		debris_timer = Timer.new(),
		destructible_blocks = [],
		detonate = false,
		has_detonated = false,
		has_collapsed = false,
		has_particles = false,
		offset = Vector2.ZERO,
		opacity_tween = Tween.new(),
		parent = get_parent(),
		particles = null,
		poly_intersect = null,
		poly_intersect_name = null,
		remove_debris = remove_debris,
		size = Vector2(),
		sprite = null,
#		sprite_centered = null,
		sprite_name = null,
		sprite_texture = null,
		poly_block_name = "poly_block",
		poly_sprite = null,
		poly_sprite_name = "poly_sprite"
	}

	# Add object to group.
	add_to_group(object_group)
	
	# Add a unique name to 'blocks_container'.
	object.blocks_container.name = self.name + "_blocks_container"

	# Randomize the seed of the random number generator.
	if randomize_seed:
		randomize()

	# Look for a 'Sprite' and a 'CollisionShape2D' or 'CollisionPolygon2D'.
	for child in get_children():
		if child is Sprite:
			object.sprite = child
			object.sprite_name = child.name
			object.sprite_texture = child.texture

		if child is CollisionShape2D:
			object.collision = child
			object.collision_type = "shape"
			object.collision_name = child.name

		if child is CollisionPolygon2D:
			object.collision = child
			object.collision_type = "polygon"
			object.collision_name = child.name

	# Check if there is least a 'Sprite' for the script to work properly.
	if not object.sprite:
		printerr("------------------------------------------------------------------")
		printerr("ERROR: The '%s' node must contain at least a 'Sprite'!" % self.name)
		printerr("------------------------------------------------------------------")
		object.can_detonate = false
		object.can_collapse = false
		self.set_mode(MODE_STATIC)
		return
	else:
		if object.sprite.get_scale() != Vector2.ONE:
			printerr("------------------------------------")
			printerr("ERROR: The 'Sprite' can't be scaled!")
			printerr("------------------------------------")
			object.can_detonate = false
			object.can_collapse = false
			self.set_mode(MODE_STATIC)
			return

	# Check if 'blocks_per_side' values are positive integers.
	if step_decimals(object.blocks_per_side.x) != 0 or step_decimals(object.blocks_per_side.y) != 0:
		printerr("----------------------------------------------------------------------------------------------------------------------------------------------------")
		printerr("ERROR: The '%s' node's 'block_per_side' values (%s, %s) must be positive integers!" % [self.name, object.blocks_per_side.x, object.blocks_per_side.y])
		printerr("----------------------------------------------------------------------------------------------------------------------------------------------------")
		object.can_detonate = false
		object.can_collapse = false
		self.set_mode(MODE_STATIC)
		return

	# Set the debris timer node, or not.
	if debris_max_time > 0:
		object.debris_timer.connect("timeout", self ,"_on_debris_timer_timeout") 
		object.debris_timer.set_one_shot(true)
		object.debris_timer.set_wait_time(object.debris_max_time)
		object.debris_timer.name = debris_timer_name
		add_child(object.debris_timer, true)
	else:
		object.debris_timer = null

	# Set the color tween node.
	object.color_tween.name = color_tween_name
	add_child(object.color_tween, true)

	# Set the opacity tween node, or not.
	if object.remove_debris:
		object.opacity_tween.name = opacity_tween_name
		add_child(object.opacity_tween, true)

	# Check if the object has particles.
	call_deferred("check_for_particles")

	if debug_mode:
		print("-------------------------------")
		print("Debug mode for '%s'" % self.name)
		print("-------------------------------")

	if debug_mode:
		print("blocks per side: ", object.blocks_per_side)
		print("total blocks: ", object.blocks_total)

	# Check if the sprite is using 'Region' to get the proper size.
	if object.sprite.region_enabled:
		object.size = Vector2(
			float(object.sprite.region_rect.size.x),
			float(object.sprite.region_rect.size.y)
		)
	else:
		object.size = Vector2(
			float(object.sprite.texture.get_width()),
			float(object.sprite.texture.get_height())
		)

	if debug_mode:
		print("size: ", object.size)

	# Check if the sprite is centered to get the offset.
	if object.sprite.centered:
		object.offset = object.size / 2
	else:
		printerr("-------------------------------------")
		printerr("ERROR: The 'Sprite' must be centered!")
		printerr("-------------------------------------")

		return

	if debug_mode:
		print("offset: ", object.offset)

	# Create the blocks and set each own properties.

	# Initiate the loop's index.
	var i = 0

	# Loop through all the blocks of each side.
	for x in object.blocks_per_side.x:
		for y in object.blocks_per_side.y:
			# Create each block by duplicating the object.
			var block = self.duplicate(8)
			
			if debug_mode:
				block.modulate = Color(rand_range(0, 1), rand_range(0, 1), rand_range(0, 1), 0.9)

			# Add a unique name to each block.
			block.name = self.name + "_block_" + str(i)

			# Set each block to STATIC mode, so it doesn't move.
			block.set_mode(MODE_STATIC)

			# Put each block to sleep.
			block.sleeping = true

			# Set each block's mass depending on the object's mass and the total number of blocks.
			block.mass = self.mass / object.blocks_total

			# Set each block collision's properties.
			if random_collision:
				block.set_collision_layer(0 if randf() < 0.5 else object.collision_layers)
				block.set_collision_mask(0 if randf() < 0.5 else object.collision_masks)
			if object.collision_one_way: block.get_node(object.collision_name).one_way_collision = true

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
				Tween.EASE_IN
			)

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
					Tween.EASE_IN
				)

			# Create a new image texture for each block's sprite.
			var block_texture = ImageTexture.new()
			# Set the image texture's position.
			var block_texture_position = Vector2(
				round(x * (object.size.x / object.blocks_per_side.x)),
				round(y * (object.size.y / object.blocks_per_side.y))
			)
			# Set the image texture's size.
			var block_texture_size = Vector2(
				round(object.size.x / object.blocks_per_side.x),
				round(object.size.y / object.blocks_per_side.y)
			)
			# Set the image texture's rect using the previous position and size.
			var block_texture_rect = Rect2(block_texture_position, block_texture_size)
			# Create a new texture from the image texture.
			block_texture.create_from_image(
				object.sprite.texture.get_data().get_rect(block_texture_rect),
				0
			)
			# Set the new texture to the block's sprite.
			var block_sprite = block.get_node(object.sprite_name)
			block_sprite.texture = block_texture

			# Create a new 'CollisionPolygon2D' for each block.
			# If the function return false, meaning it couldn't create a collision,
			# continue the loop.
			if not create_polygon_collision(block_sprite, block):
				continue

			# Postion each block.
			block.position = Vector2(
				block_texture_position.x + position.x - (object.offset.x - (object.offset.x / object.blocks_per_side.x)),
				block_texture_position.y + position.y - (object.offset.y - (object.offset.y / object.blocks_per_side.y))
			)

			block.get_node(object.collision_name).disabled = true

			# Add each block to the blocks container.
			object.destructible_blocks.append(block)
			object.blocks_container.add_child(block, true)

			# Update the index.
			i += 1

	if debug_mode:
		print("total actual blocks: ", object.blocks_container.get_child_count())

	# Add the blocks to the blocks container.
	call_deferred("add_blocks", object)

	if debug_mode:
		print("-------------------------------")


func _physics_process(delta):
	if object.can_collapse and object.collapse:
		collapse()

	if object.can_detonate and object.detonate:
		detonate()

	if object.has_detonated or object.has_collapsed:
		# Add a delay of 'delta' before counting the blocks.
		# Sometimes the last one doesn't get counted.
		if explosion_delay:
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


func check_for_particles():
	# Check if the parent node has particles as a child.
	for child in object.parent.get_children():
		if child is Particles2D or child is CPUParticles2D or child.is_in_group(fake_explosions_group):
			object.particles = child
			object.has_particles = true


func collapse():
	if debug_mode: print("'%s' object has collapsed!" % self.name)
	print("lala")
	object.can_collapse = false
	object.has_collapsed = true

	self.visible = false
	self.object.collision.disabled = true
	# Set self object back to RIGID, so the blocks can work properly.
	self.set_mode(MODE_RIGID)

	for block in object.collapsible_blocks:
		# Set each block's 'z_index'.
		if random_depth:
			block.z_index = 0 if randf() < 0.5 else -1
		block.get_node(object.collision_name).disabled = false
		block.set_mode(MODE_RIGID)

	# Start the debris timer if the timer exists.
	if print(node_exists(object.debris_timer)):
		object.debris_timer.start()


func detonate():
	if debug_mode:
		print("'%s' object has detonated!" % self.name)

	object.can_detonate = false
	object.has_detonated = true

#	remove_cover_sprite()

	self.visible = false
	self.object.collision.disabled = true
	# Set self object back to RIGID, so the blocks can work properly.
	self.set_mode(MODE_RIGID)

	# Check if the object has particles and if so, start emitting them.
	if object.has_particles:
		if object.particles.is_in_group(fake_explosions_group):
			object.particles.particles_explode = true
		else:
			object.particles.emitting = true

	# Set properties to each block.
	for block in object.destructible_blocks:
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

		# Set each block's 'z_index'.
		if random_depth:
			block.z_index = 0 if randf() < 0.5 else -1

		# Start each block's color tween to make them darker.
		block.get_node(color_tween_name).start()

		block.get_node(object.collision_name).disabled = false

		# Set each block to RIGID mode.
		block.set_mode(MODE_RIGID)

	# Start the debris timer if the timer exists.
	if node_exists(object.debris_timer):
		object.debris_timer.start()


func explosion(delta):
	if object.detonate:
		if debug_mode:
			print("'%s' object has exploded!" % self.name)

		for block in object.destructible_blocks:
			# Create a random angular velocity for each block, depending on its mass.
			var block_angular_velocity = rand_range(
				-(blocks_impulse / block.weight),
				blocks_impulse / block.weight
			)
			# Set the angular velocity for each block.
			block.angular_velocity = block_angular_velocity
			# Create a random impulse for each block.
			var block_rotation = rand_range(0, 360)
			var block_impulse = (Vector2.ONE * blocks_impulse).rotated(deg2rad(block_rotation))
			block.apply_central_impulse(block_impulse)

		if object.can_collapse and object.collapse:
			call_deferred("collapse")

		# Remove the cover sprite.
#		remove_cover_sprite()

		# Add a delay before setting 'object.detonate' to 'false'.
		# Sometimes 'object.detonate' is set to 'false' so quickly that the explosion never happens.
		# If this happens, try setting 'explosion_delay' to 'true'.
		if explosion_delay:
			explosion_delay_timer_limit = delta
			explosion_delay_timer += delta
			if explosion_delay_timer > explosion_delay_timer_limit:
				explosion_delay_timer -= explosion_delay_timer_limit
				object.detonate = false
		else:
			object.detonate = false


func _on_debris_timer_timeout():
	if debug_mode:
		print("'%s' object's debris timer (%ss) timed out!" % [self.name, debris_max_time])

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
	# Get the sprite's texture.
	var texture = sprite.texture
	# Get the sprite texture's size.
	var texture_size = sprite.texture.get_size()
	# Get the image from the sprite's texture.
	var image = texture.get_data()

	# Create a new bitmap.
	var bitmap = BitMap.new()
	# Create the bitmap from the image. We set the minimum alpha threshold.
	bitmap.create_from_image_alpha(image, 0.01) # 0.1 (default threshold).
	# Get the rect of the bitmap.
	var bitmap_rect = Rect2(Vector2(0, 0), bitmap.get_size())
	# Grow the bitmap if you need (we don't need it in this case).
#	bitmap.grow_mask(0, rect) # 2
	# Convert all the opaque parts of the bitmap into polygons.
	var polygons = bitmap.opaque_to_polygons(bitmap_rect, 0) # 2 (default epsilon).

	# Check if there are polygons.
	if polygons.size() > 0:
		# Remove the parent object's collision, as we won't need it.
		for child in parent.get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				child.queue_free()

		# Create the new collision/s.
		# Loop through all the polygons.
		for i in polygons.size():
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
			# Add the collision to the block.
			object.collision_name = collision.name
			parent.add_child(collision, true)

			return true
	else:
		# If the aren't any polygons to create collisions, remove the block.
		parent.queue_free()

		return false


func create_polygon_from_sprite(sprite):
	# Get the sprite's texture.
	var texture = sprite.texture
	# Get the sprite texture's size.
	var texture_size = sprite.texture.get_size()
	# Get the image from the sprite's texture.
	var image = texture.get_data()

	# Create a new bitmap.
	var bitmap = BitMap.new()
	# Create the bitmap from the image. We set the minimum alpha threshold.
	bitmap.create_from_image_alpha(image, 0.01) # 0.1 (default threshold).
	# Get the rect of the bitmap.
	var bitmap_rect = Rect2(Vector2(0, 0), bitmap.get_size())
	# Grow the bitmap if you need (we don't need it in this case).
#	bitmap.grow_mask(0, rect) # 2
	# Convert all the opaque parts of the bitmap into polygons.
	var polygons = bitmap.opaque_to_polygons(bitmap_rect, 0) # 2 (default epsilon).

	# Check if there are polygons.
	if polygons.size() > 0:
		# Loop through all the polygons.
		for i in polygons.size():
			# Create a new 'Polygon2D'.
			var polygon = Polygon2D.new()
			# Set the polygon.
			polygon.polygon = polygons[i]
			# Set the texture.
			polygon.texture = texture

			# Check if the sprite is centered to get the proper position.
			if sprite.centered:
				polygon.position = sprite.position - (texture_size / 2)
			else:
				polygon.position = sprite.position

			# Take the sprite's scale into account and apply it to the position.
			polygon.scale = sprite.scale
			polygon.position *= polygon.scale

			polygon.name = "poly_sprite"

			return polygon
	else:
		return false


func boolean_polygon(operation, poly_base, poly_mask):
	var polys_final = []
	var polys_operation = []

	# Union.
	if operation == "merge":
		polys_operation = Geometry.merge_polygons_2d(poly_base.polygon, poly_mask.polygon)
	# Difference.
	elif operation == "clip":
		polys_operation = Geometry.clip_polygons_2d(poly_base.polygon, poly_mask.polygon)
	# Common area.
	elif operation == "intersect":
		polys_operation = Geometry.intersect_polygons_2d(poly_base.polygon, poly_mask.polygon)
	# All but common area.
	elif operation == "exclude":
		polys_operation = Geometry.exclude_polygons_2d(poly_base.polygon, poly_mask.polygon)

	for i in polys_operation.size():
		var new_poly = Polygon2D.new()
		new_poly.name = "poly_final_" + operation + str(i)
		new_poly.texture = object.sprite_texture
		new_poly.polygon = polys_operation[i]

		polys_final.append(new_poly)

	return polys_final


func create_poly_block(x, y):
	# Create the "poly_block" points.
	var poly_block_points = PoolVector2Array([
		Vector2(0, 0),
		Vector2((object.size.x / object.blocks_per_side.x), 0),
		Vector2((object.size.x / object.blocks_per_side.x), (object.size.y / object.blocks_per_side.y)),
		Vector2(0, (object.size.y / object.blocks_per_side.y))
	])

	# Position each point.
	for i in poly_block_points.size():
		var new_point = Vector2(
				poly_block_points[i].x + (x * (object.size.x / object.blocks_per_side.x)),
				poly_block_points[i].y + (y * (object.size.y / object.blocks_per_side.y))
			)
		poly_block_points[i] = new_point

	# Reposition each point taking the offset into account.
	for i in poly_block_points.size():
		var new_point = poly_block_points[i] - (Vector2.ONE * object.offset)
		poly_block_points[i] = new_point

	# Create the new "poly_block" node.
	var poly_block = Polygon2D.new()
	poly_block.name = object.poly_block_name
	poly_block.polygon = poly_block_points
	poly_block.texture = object.sprite_texture
	poly_block.texture_offset = object.offset

	return poly_block


#func calculate_centroid(polygon):
#	var centroid = Vector2.ZERO
#
#	for i in polygon.size():
#		centroid.x += polygon[i].x
#		centroid.y += polygon[i].y
#
#	centroid /= polygon.size()
#
#	return centroid


func node_exists(node):
	if is_instance_valid(node) and node != null and \
			node is Node and node.is_inside_tree():

		return true

	return false
