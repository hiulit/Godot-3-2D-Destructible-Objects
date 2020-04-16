# CHANGELOG

## Unreleased

* Up to date

## [2.0.0] - 2020-04-16

**NOTE**: This release may contain breaking changes!

This major release removes the limitaton of using square or rectangle sprites. Now it's possible to use any kind of shape, with transparency

### Addded

* New parameter: `random_debris_scale` - Controls whether some random debris will scale to half its size.
* New parameter: `group_name` - To add each destructible oject to its own group.
* New `object` attributes:
  * `object.blocks_total` (`blocks_per_side.x` * `blocks_per_side.y`).
  * `object.color_tween`.
  * `object.opacity_tween`.
  * `object.size`. See the [Changed](#changed) section for more information.
* New reset button in `test.tscn` to be able to reset the scene.
* New script: `test.gd` - To control the new reset button in `test.tscn` along with the input process to detonate the destructible object (removed from `destructible_object.gd`).

### Changed

* `blocks_per_side` is now a `Vector2`. Its values must be positive integers.
* `object.width` and `object.height` are now joined into a new `Vector2` called `object.size`.

### Fixed

* The color and opacity tweens are both now added in the `_ready()` functions instead of adding them on the `detonate()` and `_on_debris_timer_timeout()` respectively (for better performance).
* The debris timer and the opacity tween are now added only if necessary. For the debris timer we check `if debris_max_time > 0` and for the the opacity tween we check `if object.remove_debris`.
* Checking for particles (`check_for_particles()`) is now done in the `_ready()` function (for better performance).
* Changed `apply_impulse()` for `apply_central_impulse()` plus the addition of random `angular_velocity` for each block.

### Deprecated

* ~~`explode_object.gd`~~ is now `destructible_object.gd`.
* ~~`object.collision_extents`~~.
* ~~`object.collision_position`~~.
* ~~`object.frame`~~.
* ~~`object.height`~~.
* ~~`object.hframes`~~.
* ~~`object.hvrames`~~.
* ~~`object.width`~~.
* Input process to detonate the destructible object has been moved to its own script (`test.gd`).


## [1.3.0] - 2020-03-25

### Added

* New parameter: `randomize_seed` - To let the user randomize the seed, or not. Default is set to `false`.
* New parameter: `collision_one_way` - To set `one_way_collision` to the blocks. Default is set to `false`.
* Each block now has a different mass depending on its size.
* Set a maximum of 10 blocks per side.

### Changed

* `yield(get_tree().create_timer(time), timeout)` function for a manually created timer because it was throwing `Resumed after yield, but class instance is gone` errors when freeing the blocks.

### Fixed

* Check if `object.can_detonate` before actually detonating.

## [1.2.0] - 2019-12-05

### Added

* [Fake particles](https://github.com/hiulit/Godot-3-2D-Fake-Explosion-Particles) to simulate an explosion.
* New parameter: `explosion_delay` - Adds a delay of before setting `object.detonate` to `false`.
* New parameter: `fake_explosions_group` - To rename the group's name of the fake explosion particles. 
* Better debugging.

### Changed

* `PackedScene.new()` for `duplicate()`.
* `apply_impulse()` for `apply_central_impulse`.
* Default settings to be consistent with the new `apply_central_impulse()` function.

### Fixed

* Remove the parent node after the last block is gone (for better performance).
* Remove the `self` element when it's not needed it anymore (for better performance).

### Removed

* `add_torque()`.

## [1.1.0] - 2019-09-13

### Added

* New parameter: `remove_debris` - To control whether the debris stays or disappears.

### Changed

* Tweaked the applied torque a little bit.

## [1.0.0] - 2019-07-15

* Released stable version.
