# =============================================================================
# 3. DIALOGUE NPC (scripts/npcs/DialogueNPC.gd)
# =============================================================================

# NOTE: Create new script file for this class
extends Area2D
class_name SocialNPC

@export var npc_name: String = "Unknown"
@export var archetype: SocialDNAManager.NPCArchetype = SocialDNAManager.NPCArchetype.AUTHORITY

# Visual components
@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

var current_compatibility: float = 0.0

# Hardcoded greetings for Phase 1 (will move to database in Phase 2)
var greetings := {
	SocialDNAManager.NPCArchetype.AUTHORITY: {
		"excellent": ["Outstanding! I can see you understand how things work.", "Perfect. Someone who gets straight to the point."],
		"good": ["Good to meet someone competent.", "I respect that approach."],
		"neutral": ["State your business.", "What do you need?"],
		"poor": ["I don't have time for this.", "Make it quick."],
		"terrible": ["This is a waste of my time.", "Guards, escort this person out."]
	},
	SocialDNAManager.NPCArchetype.INTELLECTUAL: {
		"excellent": ["Fascinating! I sense great depth in your approach.", "How delightfully nuanced. We must discuss this further."],
		"good": ["An interesting perspective, I'm sure.", "Your approach shows thoughtfulness."],
		"neutral": ["How curious. What brings you here?", "I'm listening."],
		"poor": ["I doubt you'd appreciate the complexities involved.", "Perhaps someone else could help you."],
		"terrible": ["This conversation is beneath both of us.", "Your approach lacks any intellectual merit."]
	}
}

signal npc_clicked(npc: SocialNPC)

func _ready():
	# Setup visual representation
	setup_visuals()
	
	# Connect signals
	input_event.connect(_on_input_event)
	SocialDNAManager.social_dna_changed.connect(_on_social_dna_changed)
	
	# Calculate initial compatibility
	update_compatibility()

func setup_visuals():
	# Create simple visual representation
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)
	
	if not label:
		label = Label.new()
		label.position = Vector2(-50, -80)
		label.size = Vector2(100, 60)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		add_child(label)
	
	# Set archetype-based appearance
	match archetype:
		SocialDNAManager.NPCArchetype.AUTHORITY:
			sprite.modulate = Color.RED
		SocialDNAManager.NPCArchetype.INTELLECTUAL:
			sprite.modulate = Color.BLUE
	
	# Create simple colored rectangle as sprite if none exists
	if not sprite.texture:
		var image = Image.create(40, 60, false, Image.FORMAT_RGB8)
		image.fill(Color.WHITE)
		sprite.texture = ImageTexture.create_from_image(image)

func update_compatibility():
	current_compatibility = SocialDNAManager.calculate_compatibility(archetype)
	update_display()

func update_display():
	var compat_desc = SocialDNAManager.get_compatibility_description(current_compatibility)
	var compat_color = SocialDNAManager.get_compatibility_color(current_compatibility)
	
	label.text = "%s\n%s\n%.2f\n%s" % [
		npc_name,
		SocialDNAManager.get_archetype_name(archetype),
		current_compatibility,
		compat_desc
	]
	
	# Visual feedback through modulation
	var base_color = Color.RED if archetype == SocialDNAManager.NPCArchetype.AUTHORITY else Color.BLUE
	sprite.modulate = base_color.lerp(compat_color, 0.3)

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			interact()

func interact():
	var greeting = get_greeting()
	print("%s: %s" % [npc_name, greeting])
	npc_clicked.emit(self)

func get_greeting() -> String:
	var archetype_greetings = greetings[archetype]
	var greeting_category: String
	
	# Determine greeting category based on compatibility
	if current_compatibility >= 1.5:
		greeting_category = "excellent"
	elif current_compatibility >= 0.8:
		greeting_category = "good"
	elif current_compatibility >= -0.3:
		greeting_category = "neutral"
	elif current_compatibility >= -0.8:
		greeting_category = "poor"
	else:
		greeting_category = "terrible"
	
	var possible_greetings = archetype_greetings[greeting_category]
	return possible_greetings[randi() % possible_greetings.size()]

func _on_social_dna_changed(_new_dna: Dictionary):
	var old_compatibility = current_compatibility
	update_compatibility()
	
	# Visual feedback for compatibility changes
	if abs(current_compatibility - old_compatibility) > 0.1:
		flash_feedback(current_compatibility > old_compatibility)

func flash_feedback(positive: bool):
	var flash_color = Color.GREEN if positive else Color.RED
	var original_modulate = sprite.modulate
	
	sprite.modulate = flash_color
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", original_modulate, 0.5)
