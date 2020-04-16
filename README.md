# Godot 3 2D Destructible Objects

A script that takes a sprite, divides it into blocks and makes them explode 💥!

![Godot-3-2D-Destructible-Objects](examples/Godot-3-2D-Destructible-Objects.gif)

## Prerequisites

Each destructible object must follow the structure shown below. It can be its own `Scene` file.

```
RigidBody2D
├── Sprite
└── CollisionShape2D
    └── RectangleShape2D
```

The `CollisionShape2D` is not actually needed, so you can ommit it. But then you'll get this warning message .....xxxxxx

## Usage

* Create a `Node2D` that will contain all the destructibles objects (e.g. `destructible_objects_container`). *Optional step.*
* Create a `Node2D` as a child node of the prior container node (e.g. `destructible_object_01`).
* Instance the `destructible_object` scene file or recreate the structure show above, in the [prerequisites](#prerequisites).
* Attach `destructible_object.gd` to the destructible object (the `RigidBody2D`) as a `Script`.

**IMPORTANT NOTE**

If you are using an xxxxxx...........

![Godot-3-2D-Destructible-Objects-Tree](examples/tree.png)

The reason for organizing it this way is because then you can add particles (`Partcicles2D` or `CPUParticles2D`), fake particles (like the ones provided with this project), hitboxes (`Area2D`) or whatever you feel like to the `Node2D` (e.g. `destructible_object_01`) holding the main `RigidBody2D` and you can then use this script to control those nodes.

But the mininum requirements are the structure shown in the [prerequisites](#prerequisites), plus attaching the `destructible_object.gd` script to the ``RigidBody2D`.

Of course, you can recreate that structure in GDScript, with something like this:

```
var node = Node2D.new()
node.name = "destructible_objects_container"
get_parent().add_child(node, true)

var rigid_body = RigidBody2D.new()
rigid_body.name = "destructible_object"

var sprite = Sprite.new()
# Set the sprite's texture, size, etc.
sprite.texture = preload("res://path/to/texture.png")
...

var collision = CollisionShape2D.new()
collision.shape = RectangleShape2D.new()
collision.shape.extents = Vector2(..., ...)

rigid_body.add_child(sprite, true)
rigid_body.add_child(collision, true)

var script = preload("res://path/to/destructible_object.gd")
rigid_body.set_script(script)

# Here you can set the 'rigid_body' variables from the script.
rigid_body.blocks_per_side = ...
rigid_body.blocks_impulse = ...

node.add_child(rigid_body, true)
```

### Make the objects explode

Once you have set up all the destructible objects, it's time to make them explode!

To do that, you just have to find the destructible object you want to destroy and set its `object.detonate` property to `true`.

You can make use of the `object_group` variable, which adds each destructible object to its own group, to find them:

```
for destructible_object in get_tree().get_nodes_in_group("destructible_objects"):
    if destructible_object.object.can_detonate:
        destructible_object.object.detonate = true
```

## Parameters

![Godot-3-2D-Destructible-Objects-Parameters](examples/parameters.png)

### Object group

| Name | Type | Description | Default |
| --- | --- | --- | --- |
| `object_group` | `String` |  Renames the group's name of the object. | `destructible_objects` |

### Blocks per side

| Name | Type | Description | Default |
| --- | --- | --- | --- |
| `blocks_per_side` | `Vector2` | The blocks per side. | `Vector2(6, 6)` |

Each value must be a positive integer.

### Blocks impulse

| Name | Type | Description | Default |
| --- | --- | --- | --- |
| `blocks_impulse` | `float` | The *force* of the blocks when they explode. | `600` |

### Blocks gravity scale

| Name | Type | Description | Default |
| --- | --- | --- | --- |
| `blocks_gravity_scale` | `float` | The gravity of the blocks. | `10` |

### Random debris scale

| Name | Type | Description | Default |
| --- | --- | --- | --- |
| `random_debris_scale` | `bool` | Controls whether some random blocks will scale to half its size. | `true` |

### Debris max time

| Name | Type | Description | Default |
| --- | --- | --- | --- |
| `debris_max_time` | `float` | The seconds it will pass until the blocks become `STATIC` or, if `remove_debris` is set to `true`, they dissapear. | `5` |

### Remove debris

| Name | Type | Description | Default |
| --- | --- | --- | --- |
| `remove_debris` | `bool` | Controls whether the debris stays or disappears. If set to `true`, the debris will dissapear when `debris_max_time` is over. | `false` |

### Collision layers

| Name | Type | Description | Default |
| --- | --- | --- | --- |
| `collision_layers` | `int` | The collision layers of the blocks. | `1` |

Sum all the values of the layers.

**Example**: `Layer 1` value is `1`. `Layer 5` value is `16`. So `collision_layers` would be `17`.

### Collision masks

| Name | Type | Description | Default |
| --- | --- | --- | --- |
| `collision_masks` | `int` | The collision masks of the blocks. | `1` |

Sum all the values of the layers.

**Example**: `Layer 1` value is `1`. `Layer 5` value is `16`. So `collision_layers` would be `17`.

### Collision one way

| Name | Type | Description | Default |
| --- | --- | --- | --- |
| `collision_one_way` | `bool` | Set `one_way_collision` for the blocks. | `false` |

### Explosion delay

| Name | Type | Description | Default |
| --- | --- | --- | --- |
| `explosion_delay` | `bool` | Adds a delay of before setting `object.detonate` to `false`. | `false` |

Sometimes `object.detonate` is set to `false` so quickly that the explosion never happens. If this happens, try setting `explosion_delay` to `true`.

### Fake explosions group

| Name | Type | Description | Default |
| --- | --- | --- | --- |
| `fake_explosions_group` | `String` |  Renames the group's name of the fake explosion particles. | `fake_explosion_particles` |

This project provides an extra script for creating [fake explosion particles](https://github.com/hiulit/Godot-3-2D-Fake-Explosion-Particles). That script uses a group name to be able to find the fake explosion particles more easily.

### Randomize seed

| Name | Type | Description | Default |
| --- | --- | --- | --- |
| `randomize_seed` | `bool` |  Randomize the seed. | `false` |

### Debug mode

| Name | Type | Description | Default |
| --- | --- | --- | --- |
| `debug_mode` | `bool` |  Prints some debug data. | `false` |

## Changelog

See [CHANGELOG](CHANGELOG.md).

## Authors

* Me 😛 [hiulit](https://github.com/hiulit).

## Credits

Thanks to:

* [Airvikar](https://www.youtube.com/user/Airvikar) - For this [Youtube video](https://www.youtube.com/watch?v=ExX7Qyldtfg), which is the code base for my script.
* [Securas (@Securas2010)](https://twitter.com/Securas2010) - For all the [great games](https://securas.itch.io/) and [Twitch streams](https://www.twitch.tv/sec_ras/videos?filter=all&sort=time) that give me lots of ideas, and particularly, the destructible objects one.
* [Scott Lembcke (@slembcke)](https://twitter.com/slembcke) - For letting me know about Voronoi regions (which aren't currently available) and helping me with adding more depth to the explosion (random collisions and z-index).
* [Justo Delgado (@mrcdk)](https://github.com/mrcdk) - For the code to [create polygons out of images](https://github.com/godotengine/godot/issues/31323#issuecomment-520517893), which I used in my `create_polygon_collision()` function.

## License

[MIT License](LICENSE).