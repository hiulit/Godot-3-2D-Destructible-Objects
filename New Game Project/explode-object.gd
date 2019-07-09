extends RigidBody2D

# TO DO

# - Try to draw polygons out from the collision shapes

export(int, 2, 10, 2) var blocks_per_side = 4
export var blocks_impulse = 200
export var blocks_gravity_scale = 4

var obj_scene = PackedScene.new()
var obj = []
var obj_width
var obj_height
var obj_offset = Vector2()
var obj_collision_extents = Vector2()
var obj_collision_position = Vector2()
var obj_vframes
var obj_hframes
var obj_frame = 0
var sprite_name
var collision_name
var destructible_collision_layers = 16
var destructible_collision_masks = 1 + 16

var can_detonate = true
var has_detonated = false
var detonate = false

var timer = 0
var max_time = 500

var debug_mode = true

func _ready():
	obj_scene.pack(duplicate(8))

	if not self is RigidBody2D:
		print("The '%s' node must be a 'RigidBody2D'" % self.name)
		can_detonate = false
		return

	for child in get_children():
		if child is Sprite:
			sprite_name = child.name
		elif child is CollisionShape2D:
			collision_name = child.name
		else:
			print("The 'RigidBody2D' (%s) must contain at least a 'Sprite' and a 'CollisionShape2D'." % self.name)
			can_detonate = false
			return
	
	if blocks_per_side % 2 != 0:
		print("'blocks_per_side' must be an even number!")
		can_detonate = false
		return

	if debug_mode: print("-------------------------------")
	if debug_mode: print("Debug mode for '%s'" % self.name)
	if debug_mode: print("-------------------------------")

	get_node(sprite_name).vframes = blocks_per_side
	get_node(sprite_name).hframes = blocks_per_side
	obj_vframes = get_node(sprite_name).vframes
	obj_hframes = get_node(sprite_name).hframes

	if get_node(sprite_name).region_enabled:
		obj_width = get_node(sprite_name).region_rect.size.x
		obj_height = get_node(sprite_name).region_rect.size.y
	else:
		obj_width = get_node(sprite_name).texture.get_width()
		obj_height = get_node(sprite_name).texture.get_height()

	if debug_mode: print("object's width: ", obj_width)
	if debug_mode: print("object's height: ", obj_height)

	if get_node(sprite_name).centered:
		obj_offset = Vector2(obj_width / 2, obj_height / 2)

		if debug_mode: print("object is centered!")
		if debug_mode: print("object's offset: ", obj_offset)
	
	obj_collision_extents = Vector2((obj_width / 2) / obj_hframes,\
									(obj_height / 2) / obj_vframes)

	if debug_mode: print("object's collision_extents: ", obj_collision_extents)

	obj_collision_position = Vector2((ceil(obj_collision_extents.x) - obj_collision_extents.x) * -1,\
									(ceil(obj_collision_extents.y) - obj_collision_extents.y) * -1)

	if debug_mode: print("object's collision_position: ", obj_collision_position)

	for n in range(obj_vframes * obj_hframes):
		obj.append(obj_scene.instance())

		obj[n].set_mode(MODE_STATIC)

		obj[n].get_node(sprite_name).vframes = obj_vframes
		obj[n].get_node(sprite_name).hframes = obj_hframes
		obj[n].get_node(sprite_name).frame = n
		obj[n].get_node(collision_name).shape.extents = obj_collision_extents
		obj[n].get_node(collision_name).position = obj_collision_position

		if debug_mode: obj[n].modulate = Color(rand_range(0,1), rand_range(0,1), rand_range(0,1), 0.9)

	# Position every block in place to create the whole sprite
	for x in range(obj_hframes):
		for y in range(obj_vframes):
			obj[obj_frame].position = Vector2(\
				y * (obj_width / obj_hframes) - obj_offset.x + obj_collision_extents.x + position.x,\
				x * (obj_height / obj_vframes) - obj_offset.y + obj_collision_extents.y + position.y)

			if debug_mode: print("object[", obj_frame, "] position: ", obj[obj_frame].position)

			obj_frame += 1

	call_deferred("add_children")


func _physics_process(delta):
	if Input.is_key_pressed(KEY_Q) and can_detonate:
		can_detonate = false
		detonate = true
		has_detonated = true

	if has_detonated:
		timer += int(delta * 60)

		for i in range(get_parent().get_child_count()):
			var child = get_parent().get_child(i)
			child.set_collision_layer(destructible_collision_layers)
			child.set_collision_mask(destructible_collision_masks)
			child.set_mode(MODE_RIGID)
 
		if timer >= max_time:
			for i in range(get_parent().get_child_count()):
				var child = get_parent().get_child(i)
				child.set_mode(MODE_STATIC)
				child.get_node(collision_name).disabled = true

			timer = 0


func _integrate_forces(state):
	explosion()


func add_children():
	for i in range(obj.size()):
		get_parent().add_child(obj[i])

	# Move the self element faaaar away, instead of removing it.
	self.position = Vector2(-9999, -9999)
#	self.queue_free()


func explosion():
	if detonate:
		if debug_mode: print("----------------------")
		if debug_mode: print("Debug mode: Explosion!")
		if debug_mode: print("----------------------")

		for i in range(get_parent().get_child_count()):
			var child = get_parent().get_child(i)

			var child_color = rand_range(100, 255) / 255
			var tween = Tween.new()
			add_child(tween)
			tween.interpolate_property(
				child, "modulate", 
				Color(1.0, 1.0, 1.0, 1.0), Color(child_color, child_color, child_color, 1.0), 0.25,
				Tween.TRANS_LINEAR, Tween.EASE_IN)
			tween.start()

			var child_scale = rand_range(0.5, 1.5)
			child.get_node(sprite_name).scale = Vector2(child_scale, child_scale)
			child.get_node(collision_name).scale = Vector2(child_scale, child_scale)
			
			if debug_mode: print("object[", i, "] scale: ", child_scale)
			
			var child_gravity_scale = blocks_gravity_scale
			child.gravity_scale = child_gravity_scale
			
			if debug_mode: print("object[", i, "] gravity_scale: ", child_gravity_scale)

			child.apply_torque_impulse((blocks_impulse / 2) * blocks_per_side)
			child.apply_impulse(Vector2(rand_range(-blocks_impulse, blocks_impulse),\
										rand_range(-blocks_impulse, blocks_impulse)),\
								Vector2(rand_range(-blocks_impulse, blocks_impulse),\
										rand_range(-blocks_impulse, -blocks_impulse * 2)))

		detonate = false
