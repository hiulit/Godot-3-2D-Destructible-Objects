# CHANGELOG

## Unreleased

### Added

* New parameter: `randomize_seed` - To let the user randomize the seed, or not. Default is set to false.

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