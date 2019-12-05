extends Node2D

export (int) var min_particles_number = 200
export (int) var max_particles_number = 400

export (float) var min_particles_gravity = 200
export (float) var max_particles_gravity = 600

export (float) var min_particles_velocity = 200
export (float) var max_particles_velocity = 600

export (int) var max_particles_position_x = ProjectSettings.get_setting("display/window/size/width")
export (int) var max_particles_position_y = ProjectSettings.get_setting("display/window/size/height")

export (int) var min_particles_size = 2
export (int) var max_particles_size = 6

export (bool) var get_random_position = false
export (bool) var start_timer = false
export (bool) var particles_explode = false

var particles = []
var particles_number
var particles_initial_position
var particles_colors = [
	Color("#ffffff"),
	Color("#000000"),
	Color("#ff004d"),
	Color("#ffa300"),
	Color("#ffec27")
]

var particles_timer
var particles_timer_wait_time = 1

func _ready():
	Engine.time_scale = 0.5
	# Add to a group so it can be found from anywhere.
	add_to_group("fake_explosion_particles")

	# Create the initial particles.
	particles_initial_position = _get_random_position() if get_random_position else position
	particles_number = _get_random_number()
	_create_particles()

	# Create a timer.
	particles_timer = Timer.new()
	particles_timer.one_shot = false
	particles_timer.wait_time = particles_timer_wait_time
	particles_timer.set_timer_process_mode(1)
	particles_timer.connect("timeout", self, "_on_timer_timeout")

	add_child(particles_timer, true)

	if start_timer: particles_timer.start()


func _process(delta):
	# If there are particles in the particles array and
	# 'particles_explode' is 'true', make them explode.
	if particles.size() > 0 and particles_explode == true:

		_particles_explode(delta)

		# Redraw the particles every frame.
		update()

	# If there are no particles in the particles array, free the node.
	if particles.size() == 0:
		queue_free()


func _draw():
	for particle in particles:
		# Draw the particles.
		draw_rect(Rect2(particle.position, particle.size), particle.color)


func _particles_explode(delta):
	for particle in particles:
		particle.velocity.x *= 1
		particle.velocity.y *= 1
		particle.position += (particle.velocity + particle.gravity) * delta

		# Fade out the particles.
		if particle.color.a > 0:
			particle.color.a -= particle.alpha * delta

			if particle.color.a < 0:
				particle.color.a = 0

		# If the particle is invisible...
		if particle.color.a == 0:
			# ... if there are particles in the particles array...
			if particles.size() > 0:
				# ... find the particle in the particles array...
				var i = particles.find(particle)
				# ... and remove it from the particles array.
				particles.remove(i)


func _create_particles():
	# Empty the particles array.
	particles.clear()

	for i in particles_number:
		# Create the particle object.
		var particle = {
			alpha = null,
			color = null,
			gravity = null,
			position = particles_initial_position,
			size = null,
			velocity = null
		}

		# Assign random variables to the particle object.
		particle.alpha = _get_random_alpha()
		particle.color = _get_random_color()
		particle.gravity = _get_random_gravity()
		particle.size = _get_random_size()
		particle.velocity = _get_random_velocity()

		# Push the particle to the particles array.
		particles.push_back(particle)


func _get_random_alpha():
	randomize()
	var random_alpha = rand_range(1, 10)
	return random_alpha


func _get_random_color():
	randomize()
	var random_color = particles_colors[randi() % particles_colors.size()]
	return random_color


func _get_random_gravity():
	randomize()
	var random_gravity = Vector2(
							rand_range(
								-rand_range(min_particles_gravity, max_particles_gravity),
								rand_range(min_particles_gravity, max_particles_gravity)
							),
							rand_range(
								rand_range(min_particles_gravity * 2, max_particles_gravity * 2),
								rand_range(min_particles_gravity * 2, max_particles_gravity * 2)
							)
						)
	return random_gravity


func _get_random_number():
	randomize()
	var random_number = round(rand_range(min_particles_number, max_particles_number))
	return random_number


func _get_random_position():
	randomize()
	var random_position_x = rand_range(0, max_particles_position_x)
	var random_position_y = rand_range(0, max_particles_position_y)
	var random_position = Vector2(random_position_x, random_position_y)
	return random_position


func _get_random_size():
	randomize()
	var random_size = randi() % max_particles_size + min_particles_size
	random_size = Vector2(random_size, random_size)
	return random_size


func _get_random_velocity():
	randomize()
	var random_velocity = Vector2(
							rand_range(
								-rand_range(min_particles_velocity, max_particles_velocity),
								rand_range(min_particles_velocity, max_particles_velocity)
							),
							rand_range(
								-rand_range(min_particles_velocity * 2, max_particles_velocity * 2),
								-rand_range(min_particles_velocity * 2, max_particles_velocity * 2)
							)
						)
	return random_velocity


func _on_timer_timeout():
	# Create new particles every time the timer times out.
	particles_initial_position = _get_random_position() if get_random_position else position
	particles_number = _get_random_number()
	_create_particles()
