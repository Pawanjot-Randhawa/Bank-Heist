extends CharacterBody3D

@onready var animation_player: AnimationPlayer = $"modular-men/AnimationPlayer"

func take_damage():
	print("took hit")
	animation_player.play("CharacterArmature|HitRecieve")
	await animation_player.animation_finished
	animation_player.play("CharacterArmature|Idle")
