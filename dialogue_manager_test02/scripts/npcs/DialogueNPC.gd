# =============================================================================
# SOCIAL NPC - Phase 2A Updated
# File: scripts/npcs/DialogueNPC.gd (replace existing file)
# Integrates with new conversation system
# =============================================================================

extends Area2D
class_name SocialNPC

@export var npc_name: String = "Unknown"
@export var archetype: SocialDNAManager.NPCArchetype = SocialDNAManager.NPCArchetype.AUTHORITY

# Visual components
@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

var current_compatibility: float = 0.0

# Signals
signal npc_clicked(npc: SocialNPC)
signal conversation_requested(npc: SocialNPC, conversation_type: ConversationController.ConversationType)

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
		label.position = Vector2(-60, -100)
		label.size = Vector2(120, 80)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		add_child(label)
	
	# Set archetype-based appearance
	match archetype:
		SocialDNAManager.NPCArchetype.AUTHORITY:
			sprite.modulate = Color.RED
		SocialDNAManager.NPCArchetype.INTELLECTUAL:
			sprite.modulate = Color.BLUE
	
	# Create simple colored rectangle as sprite if none exists
	if not sprite.texture:
		var image = Image.create(50, 80, false, Image.FORMAT_RGB8)
		image.fill(Color.WHITE)
		sprite.texture = ImageTexture.create_from_image(image)
	
	# Add collision shape if none exists
	if not has_node("CollisionShape2D"):
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(50, 80)
		collision.shape = shape
		add_child(collision)

func update_compatibility():
	current_compatibility = SocialDNAManager.calculate_compatibility(archetype)
	update_display()

func update_display():
	var compat_desc = SocialDNAManager.get_compatibility_description(current_compatibility)
	var compat_color = SocialDNAManager.get_compatibility_color(current_compatibility)
	
	# Enhanced label with more info
	var trust_info = ""
	if has_method("get_trust_level"):  # Will be available when conversation controller is connected
		trust_info = "\nTrust: Stranger"  # Default for Phase 2A
	
	label.text = "%s\n[%s]\n%.2f - %s%s\n\n[CLICK]\nChat/Topic/Deep" % [
		npc_name,
		SocialDNAManager.get_archetype_name(archetype).to_upper(),
		current_compatibility,
		compat_desc,
		trust_info
	]
	
	# Visual feedback through modulation
	var base_color = Color.RED if archetype == SocialDNAManager.NPCArchetype.AUTHORITY else Color.BLUE
	sprite.modulate = base_color.lerp(compat_color, 0.4)

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				# Quick chat (default)
				start_conversation(ConversationController.ConversationType.QUICK_CHAT)
			MOUSE_BUTTON_RIGHT:
				# Context menu for conversation types
				show_conversation_options()

func start_conversation(conversation_type: ConversationController.ConversationType = ConversationController.ConversationType.QUICK_CHAT):
	print("[NPC] %s: Starting %s conversation" % [npc_name, get_conversation_type_name(conversation_type)])
	
	# Emit signals
	npc_clicked.emit(self)
	conversation_requested.emit(self, conversation_type)

func show_conversation_options():
	print("[NPC] %s: Showing conversation options..." % npc_name)
	print("  [1] Quick Chat (1-2 exchanges)")
	print("  [2] Topic Discussion (3-5 exchanges) - Trust: Professional+")
	print("  [3] Deep Conversation (5+ exchanges) - Trust: Trusted+")
	print("  Right-click again for Quick Chat, or use UI buttons when implemented")
	
	# For now, just start a topic discussion
	start_conversation(ConversationController.ConversationType.TOPIC_DISCUSSION)

func get_conversation_type_name(conv_type: ConversationController.ConversationType) -> String:
	match conv_type:
		ConversationController.ConversationType.QUICK_CHAT:
			return "[QUICK]"
		ConversationController.ConversationType.TOPIC_DISCUSSION:
			return "[TOPIC]"
		ConversationController.ConversationType.DEEP_CONVERSATION:
			return "[DEEP]"
		_:
			return "[UNKNOWN]"

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
	tween.tween_property(sprite, "modulate", original_modulate, 0.8)

# =============================================================================
# CONVERSATION INTEGRATION
# =============================================================================

func get_conversation_availability() -> Dictionary:
	# Returns which conversation types are available based on trust level
	# For Phase 2A, all conversations are available (trust will be implemented later)
	
	return {
		"quick_chat": true,
		"topic_discussion": true,  # Normally requires Professional trust
		"deep_conversation": true   # Normally requires Trusted trust
	}

func get_debug_info() -> String:
	var info = "=== %s DEBUG INFO ===\n" % npc_name.to_upper()
	info += "Archetype: %s\n" % SocialDNAManager.get_archetype_name(archetype)
	info += "Compatibility: %.2f (%s)\n" % [current_compatibility, SocialDNAManager.get_compatibility_description(current_compatibility)]
	
	# Show archetype preferences
	info += "Archetype Preferences:\n"
	var preferences = SocialDNAManager.archetype_preferences[archetype]
	for social_type in preferences:
		var pref_value = preferences[social_type]
		var type_name = SocialDNAManager.get_social_type_name(social_type)
		var pref_desc = ""
		if pref_value >= 1.5:
			pref_desc = "LOVES"
		elif pref_value >= 0.5:
			pref_desc = "LIKES"
		elif pref_value >= -0.5:
			pref_desc = "NEUTRAL"
		elif pref_value >= -1.0:
			pref_desc = "DISLIKES"
		else:
			pref_desc = "HATES"
		
		info += "  %s: %+.1f (%s)\n" % [type_name, pref_value, pref_desc]
	
	info += "Available Conversations: Quick, Topic, Deep\n"
	info += "Click: Quick Chat | Right-Click: Topic Discussion"
	
	return info

# Utility method for other systems to get NPC info
func get_npc_data() -> Dictionary:
	return {
		"name": npc_name,
		"archetype": archetype,
		"compatibility": current_compatibility,
		"position": position
	}

# =============================================================================
# INPUT HANDLING FOR DEBUG
# =============================================================================

func _input(event):
	# Show debug info on key press when this NPC is selected
	if event.is_action_pressed("ui_accept") and has_focus():
		print(get_debug_info())

func has_focus() -> bool:
	# Simple focus check - could be enhanced later
	var mouse_pos = get_global_mouse_position()
	var npc_rect = Rect2(global_position - Vector2(25, 40), Vector2(50, 80))
	return npc_rect.has_point(mouse_pos)
