extends RigidBody2D

export(PackedScene) var lala
var obj_scene = load("res://box.tscn")

var obj = []
var obj_width
var obj_height
var obj_offset = Vector2()
var obj_collision_extents = Vector2()
var obj_collision_position = Vector2()
var obj_vframes
var obj_hframes
var frames = 0
var sprite_name = "sprite"
var collision_name = "collision"
var destructible_collision_layers = 16
var destructible_collision_masks = 1 + 16

var drops = []

var impulse = 500

var detonate
var timer = 0
var max_time = 500

func _ready():
	print(get_path())
	print("lala: ", lala)
	print("obj_scene: ", obj_scene)

	get_node(sprite_name).vframes = 4
	get_node(sprite_name).hframes = 4
	obj_vframes = get_node(sprite_name).vframes
	obj_hframes = get_node(sprite_name).hframes

	if get_node(sprite_name).region_enabled:
		obj_width = get_node(sprite_name).region_rect.size.x
		obj_height = get_node(sprite_name).region_rect.size.y
	else:
		obj_width = get_node(sprite_name).texture.get_width()
		obj_height = get_node(sprite_name).texture.get_height()
#	print("sprite's width: ", obj_width)
#	print("sprite's height: ", obj_height)

	if get_node(sprite_name).centered:
#		print("sprite is centered!")
		obj_offset = Vector2(obj_width / 2, obj_height / 2)
#		print("sprite's offset: ", obj_offset)
	
	obj_collision_extents = Vector2((obj_width / 2) / obj_hframes,\
									(obj_height / 2) / obj_vframes)
#	print("object's collision_extents: ", obj_collision_extents)

	obj_collision_position = Vector2((ceil(obj_collision_extents.x) - obj_collision_extents.x) * -1,\
									(ceil(obj_collision_extents.y) - obj_collision_extents.y) * -1)
#	print("object's collision_position: ", obj_collision_position)

	for n in range(obj_vframes * obj_hframes):
		obj.append(lala.instance())
		
#		obj[n].set_collision_layer(destructible_collision_layers)
#		obj[n].set_collision_mask(destructible_collision_masks)

		obj[n].set_mode(MODE_STATIC) # static mode
#		obj[n].get_node(collision_name).disabled = true
		
#		obj[n].set_use_custom_integrator(true)
#		obj[n].set_sleeping(true)

		obj[n].get_node(sprite_name).vframes = obj_vframes
		obj[n].get_node(sprite_name).hframes = obj_hframes
		obj[n].get_node(sprite_name).frame = n
		obj[n].get_node(collision_name).shape.extents = obj_collision_extents
		obj[n].get_node(collision_name).position = obj_collision_position

#		obj[n].modulate = Color(rand_range(0,1), rand_range(0,1), rand_range(0,1), 0.5)

	# Position every block in place to create the whole sprite
	for x in range(obj_hframes):
		for y in range(obj_vframes):
			obj[frames].position = Vector2(\
				y * (obj_width / obj_hframes) - obj_offset.x + obj_collision_extents.x + position.x,\
				x * (obj_height / obj_vframes) - obj_offset.y + obj_collision_extents.y + position.y)

#			print("object ", frames, " position: ", obj[frames].position)
			frames += 1

	call_deferred("add_children")


func _physics_process(delta):
	if detonate:
		for i in range(get_parent().get_child_count()):
			var child = get_parent().get_child(i)
			child.set_collision_layer(destructible_collision_layers)
			child.set_collision_mask(destructible_collision_masks)
			child.set_mode(MODE_RIGID)

		timer += int(delta * 60)
 
		if timer >= max_time:
			for i in range(get_parent().get_child_count()):
				var child = get_parent().get_child(i)
				child.set_mode(MODE_STATIC)
				child.get_node(collision_name).disabled = true

			timer = 0
			detonate = false

#			for i in range(get_parent().get_child_count()):
#				var child = get_parent().get_child(i)
#				print("sleeping: ", child.sleeping)
#
#				if child.get_linear_velocity().x and child.get_linear_velocity().y < 0.5:
#					child.set_mode(MODE_STATIC)
#					child.get_node(collision_name).disabled = true
#				else:
#					print(child.get_linear_velocity())
				

#	if detonate:
#		timer += delta * 60
#		print(timer)
#
#	if timer >= max_time:
#		detonate = false
#		print("exceed time: ", max_time)
#		for i in range(get_parent().get_child_count()):
#			var child = get_parent().get_child(i)
#			if child.get_linear_velocity() != Vector2(0, 0):
#				print(child.get_linear_velocity().x)
#				child.set_mode(MODE_STATIC)
#				child.get_node(collision_name).disabled = true

#	if Input.is_key_pressed(KEY_Q):
#		detonate = true


func _integrate_forces(state):
	if Input.is_key_pressed(KEY_Q):
		explosion()


func add_children():
	for i in range(obj.size()):
		get_parent().add_child(obj[i])

	self.position = Vector2(-9999, -9999) # Move the self element faaaar away, instead of removing it.
#	self.queue_free()


func explosion():
	detonate = true

	for i in range(get_parent().get_child_count()):
		var child = get_parent().get_child(i)

		var child_scale = rand_range(0.5, 1.5)
		child.get_node(sprite_name).scale = Vector2(child_scale, child_scale)
		child.get_node(collision_name).scale = Vector2(child_scale, child_scale)

		var child_gravity_scale = rand_range(1, 5)
		child.gravity_scale = child_gravity_scale

		child.mass = rand_range(1, 50)
		child.apply_torque_impulse(100)
		child.apply_impulse(Vector2(0, 0), Vector2(rand_range(-impulse, impulse), rand_range(-(impulse / 2), -impulse)))
