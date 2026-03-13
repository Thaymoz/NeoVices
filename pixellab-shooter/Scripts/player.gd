extends CharacterBody2D
class_name Player

signal player_died

@export var bullet_scene : PackedScene
var can_shoot : bool = true
var cd_shoot : float = 0.4

var move_speed := 300.0
var move_direction := Vector2.ZERO

@onready var player_health: ProgressBar = %player_health
@export var max_health := 100 
var current_health := max_health

var knowback_velocity : Vector2 = Vector2.ZERO
var knowcback_decay : float = 800
var knockback_force : float = 250

@onready var collision: CollisionShape2D = $hitbox/collision
@onready var sprite: Sprite2D = $Sprite


var powerups = {
	"rapid_fire" : false,
	"mega_shoot" : false,
	"freze_enemies" : false,
}

var margin : int = 80
@onready var viewport_size := get_viewport_rect().size

func  _ready() -> void:
	Global.player = self

func _process(_delta: float) -> void:
#clamp ele delemita a area
	global_position.x = clamp(global_position.x,margin, viewport_size.x - margin)
	global_position.y = clamp(global_position.y,margin, viewport_size.y - margin)

func _physics_process(delta: float) -> void:
	
	if knowback_velocity.length() > 1:
		velocity = knowback_velocity
		knowback_velocity = knowback_velocity.move_toward(Vector2.ZERO, knowcback_decay * delta)
	else:
		move_direction = Input.get_vector("move_left","move_right","move_up","move_down")
		velocity = move_direction * move_speed
#Aqui verifica a possição de onde esta mirando + o click literal do tiro
	var mouse_dir = get_global_mouse_position() - global_position
	if Input.is_action_pressed("shoot") and can_shoot == true:
		_shoot(mouse_dir)
	look_at(get_global_mouse_position())
	
	move_and_slide()


func _shoot(direction):
#calculo para atirar
	can_shoot = false
	var bullet_instance = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet_instance)
	bullet_instance.global_position = global_position
	bullet_instance.set_direction(direction)
	
	if powerups["mega_shoot"]:
		bullet_instance.scale *= 3
		bullet_instance.damage = 2
		
	await get_tree().create_timer(cd_shoot).timeout
	can_shoot = true


func apply_powerup(type : String):
#combinar algo
	match  type:
		"rapid_fire":
			powerups["rapid_fire"] = true
			cd_shoot = 0.01
			await get_tree().create_timer(3).timeout
			powerups["rapid_fire"] = false
			cd_shoot = 0.3
		"mega_shoot":
			powerups["mega_shoot"] = true
			
			await get_tree().create_timer(3).timeout
			powerups["mega_shoot"] = false
			
		"freze_enemies":
			powerups["freze_enemies"] = true
			Global.freze_enemies.emit(5.0)
			await get_tree().create_timer(3).timeout
			powerups["freze_enemies"] = false
			
func take_damage(amount : int, source_position : Vector2):
	if current_health <= 0:
		CameraEffects.start_shake(10.0)
		visible = false
		collision.call_deferred("set", "disabled", false)
		set_physics_process(false)
		await get_tree().create_timer(1).timeout
		emit_signal("player_died")
	else:
		current_health -= amount
		current_health = clamp(current_health, 0, max_health)
		player_health.value = current_health
		var knockback_dir = (position - source_position).normalized()
		apply_knockback(knockback_dir * knockback_force)

func apply_knockback(force: Vector2):
	knowback_velocity = force
	
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		take_damage(10, body.global_position) 
	if body.is_in_group("boss"):
		take_damage(20, body.global_position) 
