extends NavigationAgent2D
class_name PawnNavigator2D

var buffered_target: Vector2

signal set_target(target: Vector2)

func transfer_buffered_to_main():
	target_position = buffered_target

func _set_target(target: Vector2):
	buffered_target = target

func _ready():
	set_target.connect(_set_target)
