# =============================================================================
# ENHANCED SOCIAL NPC - Phase 2B
# File: scripts/npcs/DialogueNPC.gd (REPLACE existing file)
# Adds trust level display, conversation availability, and trust gates
# =============================================================================

extends Area2D
class_name SocialNPC

@export var npc_name: String = "Unknown"
@export var archetype: SocialDNAManager.NPCArchetype = SocialDNAManager.NPCArchetype.AUTHORITY

# Visual components
@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label
@onready var trust_indicator: Label = $TrustIndicator

var current_compatibility: float = 0.0
var current_trust_level: float = 0.0
var conversation_controller: ConversationController = null

# Signals
signal npc_clicked(npc: SocialNPC)
signal conversation_requested(npc: SocialNPC, conversation_type: ConversationController.ConversationType)
signal trust_gate_blocked(npc: SocialNPC, required_trust: String, current_trust: String)

func _ready():
	# Setup visual representation
	setup_visuals()
	
	# Connect signals
	input_event.connect(_on_input_event)
	SocialDNAManager.social_dna_changed.connect(_on_social_dna_changed)
	
	# Try to find conversation controller
	call_deferred("find_conversation_controller")
	
	# Calculate initial compatibility
	update_compatibility()

func find_conversation_controller():
	# Look for conversation controller in the scene
	conversation_controller = get_node("/root/Main/ConversationController")
	if conversation_controller:
		conversation_controller.relationship_changed.connect(_on_relationship_changed)
		update_trust_level()
		print("[NPC %s] Connected to conversation controller" % npc_name)

func setup_visuals():
	# Create sprite if needed
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)
	
	# Create main info label
	if not label:
		label = Label.new()
		label.position = Vector2(-70, -120)
		label.size = Vector2(140, 100)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 9)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		add_child(label)
	
	# Create trust indicator label
	if not trust_indicator:
		trust_indicator = Label.new()
		trust_indicator.position = Vector2(-50, -20)
		trust_indicator.size = Vector2(100, 20)
		trust_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		trust_indicator.add_theme_font_size_override("font_size", 8)
		add_child(trust_indicator)
	
	# Set archetype-based appearance
	match archetype:
		SocialDNAManager.NPCArchetype.AUTHORITY:
			sprite.modulate = Color.RED
		SocialDNAManager.NPCArchetype.INTELLECTUAL:
			sprite.modulate = Color.BLUE
	
	# Create simple colored rectangle as sprite if none exists
	if not sprite.texture:
		var image = Image.create(60, 90, false, Image.FORMAT_RGB8)
		image.fill(Color.WHITE)
		sprite.texture = ImageTexture.create_from_image(image)
	
	# Add collision shape if none exists
	if not has_node("CollisionShape2D"):
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(60, 90)
		collision.shape = shape
		add_child(collision)

func update_compatibility():
	current_compatibility = SocialDNAManager.calculate_compatibility(archetype)
	update_display()

func update_trust_level():
	if conversation_controller:
		current_trust_level = conversation_controller.get_npc_trust_level(self)
		update_display()

func update_display():
	var compat_desc = SocialDNAManager.get_compatibility_description(current_compatibility)
	var compat_color = SocialDNAManager.get_compatibility_color(current_compatibility)
	
	# Get trust info
	var trust_name = get_trust_name(current_trust_level)
	var trust_color = get_trust_color(current_trust_level)
	
	# Get conversation availability
	var available_conversations = get_conversation_availability_display()
	
	# Main label with NPC info
	label.text = "%s\n[%s]\nCompatibility: %.2f\n%s\n\n%s" % [
		npc_name,
		SocialDNAManager.get_archetype_name(archetype).to_upper(),
		current_compatibility,
		compat_desc,
		available_conversations
	]
	
	# Trust indicator
	trust_indicator.text = "Trust: %s (%.1f)" % [trust_name, current_trust_level]
	trust_indicator.modulate = trust_color
	
	# Visual feedback through sprite modulation
	var base_color = Color.RED if archetype == SocialDNAManager.NPCArchetype.AUTHORITY else Color.BLUE
	var trust_influence = trust_color.lerp(Color.WHITE, 0.5)
	sprite.modulate = base_color.lerp(compat_color, 0.3).lerp(trust_influence, 0.2)

func get_trust_name(trust: float) -> String:
	if trust >= 3.0:
		return "Close"
	elif trust >= 2.0:
		return "Trusted"
	elif trust >= 1.0:
		return "Professional" 
	elif trust >= 0.0:
		return "Stranger"
	else:
		return "Hostile"

func get_trust_color(trust: float) -> Color:
	if trust >= 3.0:
		return Color.GOLD  # Close
	elif trust >= 2.0:
		return Color.GREEN  # Trusted
	elif trust >= 1.0:
		return Color.CYAN  # Professional
	elif trust >= 0.0:
		return Color.GRAY  # Stranger
	else:
		return Color.RED  # Hostile

func get_conversation_availability_display() -> String:
	if not conversation_controller:
		return "[CLICK] Quick Chat"
	
	var available_types = []
	var blocked_types = []
	
	# Check each conversation type
	for conv_type in ConversationController.ConversationType.values():
		var availability = conversation_controller.can_start_conversation(self, conv_type)
		
		if availability.can_start:
			match conv_type:
				ConversationController.ConversationType.QUICK_CHAT:
					available_types.append("Quick")
				ConversationController.ConversationType.TOPIC_DISCUSSION:
					available_types.append("Topic")
				ConversationController.ConversationType.DEEP_CONVERSATION:
					available_types.append("Deep")
		else:
			match conv_type:
				ConversationController.ConversationType.TOPIC_DISCUSSION:
					blocked_types.append("Topic [Need: %s]" % availability.required_trust_name)
				ConversationController.ConversationType.DEEP_CONVERSATION:
					blocked_types.append("Deep [Need: %s]" % availability.required_trust_name)
	
	var display_text = "[CLICK] "
	
	# Show available conversations
	if available_types.size() > 0:
		display_text += " | ".join(available_types)
	
	# Show blocked conversations
	if blocked_types.size() > 0:
		if available_types.size() > 0:
			display_text += "\n[LOCKED] "
		else:
			display_text += "[LOCKED] "
		display_text += " | ".join(blocked_types)
	
	return display_text

# =============================================================================
# ENHANCED INTERACTION HANDLING
# =============================================================================

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				# Try different conversation types based on modifiers
				if Input.is_action_pressed("ui_shift"):
					try_conversation(ConversationController.ConversationType.DEEP_CONVERSATION)
				elif Input.is_action_pressed("ui_ctrl"):
					try_conversation(ConversationController.ConversationType.TOPIC_DISCUSSION)
				else:
					try_conversation(ConversationController.ConversationType.QUICK_CHAT)
			MOUSE_BUTTON_RIGHT:
				show_conversation_menu()

func try_conversation(conversation_type: ConversationController.ConversationType):
	print("[NPC] %s: Attempting %s conversation" % [npc_name, get_conversation_type_name(conversation_type)])
	
	# Check if conversation is available
	if conversation_controller:
		var availability = conversation_controller.can_start_conversation(self, conversation_type)
		
		if not availability.can_start:
			handle_trust_gate(availability)
			return
	
	# Start the conversation
	start_conversation(conversation_type)

func handle_trust_gate(availability: Dictionary):
	var type_name = get_conversation_type_name(availability.conversation_type)
	print("[TRUST GATE] %s conversation blocked - Need: %s, Have: %s" % [
		type_name,
		availability.required_trust_name,
		availability.current_trust_name
	])
	
	# Show trust gate message
	show_trust_gate_feedback(availability)
	
	# Emit signal
	trust_gate_blocked.emit(self, availability.required_trust_name, availability.current_trust_name)

func show_trust_gate_feedback(availability: Dictionary):
	# Create temporary feedback label
	var feedback = Label.new()
	feedback.text = "Need %s Trust!\nTry: %s" % [
		availability.required_trust_name,
		get_trust_building_tip()
	]
	feedback.position = Vector2(-60, 20)
	feedback.size = Vector2(120, 40)
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.add_theme_font_size_override("font_size", 8)
	feedback.modulate = Color.ORANGE
	add_child(feedback)
	
	# Flash and remove
	var tween = create_tween()
	tween.parallel().tween_property(feedback, "position:y", feedback.position.y - 20, 1.5)
	tween.parallel().tween_property(feedback, "modulate:a", 0.0, 1.5)
	tween.tween_callback(feedback.queue_free)

func get_trust_building_tip() -> String:
	if current_trust_level < 1.0:
		return "Quick Chats"
	else:
		return "Topic Discussions"

func show_conversation_menu():
	print("[NPC] %s: Conversation Menu:" % npc_name)
	
	if not conversation_controller:
		print("  [ERROR] No conversation controller found")
		return
	
	# Show available conversations
	var available = conversation_controller.get_available_conversation_types(self)
	
	print("  === AVAILABLE CONVERSATIONS ===")
	for conv_type in available:
		var type_name = get_conversation_type_name(conv_type)
		var description = get_conversation_description(conv_type)
		print("  ✓ %s: %s" % [type_name, description])
	
	# Show blocked conversations
	print("  === LOCKED CONVERSATIONS ===")
	for conv_type in ConversationController.ConversationType.values():
		if conv_type not in available:
			var availability = conversation_controller.can_start_conversation(self, conv_type)
			var type_name = get_conversation_type_name(conv_type)
			var description = get_conversation_description(conv_type)
			print("  🔒 %s: %s [Need: %s Trust]" % [type_name, description, availability.required_trust_name])
	
	print("  === CONTROLS ===")
	print("  Left Click: Quick Chat")
	print("  Ctrl+Click: Topic Discussion") 
	print("  Shift+Click: Deep Conversation")
	
	# For now, start a topic conversation as default right-click action
	try_conversation(ConversationController.ConversationType.TOPIC_DISCUSSION)

func start_conversation(conversation_type: ConversationController.ConversationType = ConversationController.ConversationType.QUICK_CHAT):
	print("[NPC] %s: Starting %s conversation" % [npc_name, get_conversation_type_name(conversation_type)])
	
	# Emit signals
	npc_clicked.emit(self)
	conversation_requested.emit(self, conversation_type)

func get_conversation_type_name(conv_type: ConversationController.ConversationType) -> String:
	match conv_type:
		ConversationController.ConversationType.QUICK_CHAT:
			return "Quick Chat"
		ConversationController.ConversationType.TOPIC_DISCUSSION:
			return "Topic Discussion"
		ConversationController.ConversationType.DEEP_CONVERSATION:
			return "Deep Conversation"
		_:
			return "Unknown"

func get_conversation_description(conv_type: ConversationController.ConversationType) -> String:
	match conv_type:
		ConversationController.ConversationType.QUICK_CHAT:
			return "1-2 exchanges, build familiarity"
		ConversationController.ConversationType.TOPIC_DISCUSSION:
			return "3-5 exchanges, discuss important matters"
		ConversationController.ConversationType.DEEP_CONVERSATION:
			return "5+ exchanges, personal and meaningful"
		_:
			return "Unknown conversation type"

# =============================================================================
# EVENT HANDLERS
# =============================================================================

func _on_social_dna_changed(_new_dna: Dictionary):
	var old_compatibility = current_compatibility
	update_compatibility()
	
	# Visual feedback for compatibility changes
	if abs(current_compatibility - old_compatibility) > 0.1:
		flash_feedback(current_compatibility > old_compatibility)

func _on_relationship_changed(npc: SocialNPC, old_trust: float, new_trust: float):
	if npc == self:
		var old_trust_level = current_trust_level
		current_trust_level = new_trust
		update_display()
		
		# Show trust change feedback
		if abs(new_trust - old_trust_level) > 0.05:
			show_trust_change_feedback(old_trust, new_trust)

func show_trust_change_feedback(old_trust: float, new_trust: float):
	var change = new_trust - old_trust
	var change_text = ""
	var color = Color.WHITE
	
	if change > 0:
		change_text = "Trust +%.2f" % change
		color = Color.GREEN
	elif change < 0:
		change_text = "Trust %.2f" % change  # Already includes minus sign
		color = Color.ORANGE
	else:
		return  # No change
	
	# Check for trust level changes
	var old_trust_name = get_trust_name(old_trust)
	var new_trust_name = get_trust_name(new_trust)
	
	if old_trust_name != new_trust_name:
		change_text += "\n%s → %s" % [old_trust_name, new_trust_name]
		color = Color.YELLOW
	
	show_floating_text(change_text, color)

func flash_feedback(positive: bool):
	var flash_color = Color.GREEN if positive else Color.RED
	var original_modulate = sprite.modulate
	
	sprite.modulate = flash_color
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", original_modulate, 0.8)

func show_floating_text(text: String, color: Color):
	var floating_label = Label.new()
	floating_label.text = text
	floating_label.modulate = color
	floating_label.position = Vector2(-30, -50)
	floating_label.add_theme_font_size_override("font_size", 10)
	floating_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(floating_label)
	
	# Animate upward and fade out
	var tween = create_tween()
	tween.parallel().tween_property(floating_label, "position:y", floating_label.position.y - 30, 2.0)
	tween.parallel().tween_property(floating_label, "modulate:a", 0.0, 2.0)
	tween.tween_callback(floating_label.queue_free)

# =============================================================================
# DEBUG AND INFORMATION
# =============================================================================

func get_debug_info() -> String:
	var info = "=== %s DEBUG INFO ===\n" % npc_name.to_upper()
	info += "Archetype: %s\n" % SocialDNAManager.get_archetype_name(archetype)
	info += "Compatibility: %.2f (%s)\n" % [current_compatibility, SocialDNAManager.get_compatibility_description(current_compatibility)]
	info += "Trust Level: %.2f (%s)\n" % [current_trust_level, get_trust_name(current_trust_level)]
	
	# Show relationship summary
	if conversation_controller:
		var summary = conversation_controller.get_relationship_summary(self)
		info += "\nRelationship Summary:\n"
		info += "  Total Interactions: %d\n" % summary.total_interactions
		info += "  Success Rate: %.1f%%\n" % summary.success_rate
		info += "  Last Outcome: %s\n" % summary.get("last_outcome", "None")
	
	# Show archetype preferences
	info += "\nArchetype Preferences:\n"
	var preferences = SocialDNAManager.archetype_preferences[archetype]
	for social_type in preferences:
		var pref_value = preferences[social_type]
		var type_name = SocialDNAManager.get_social_type_name(social_type)
		var pref_desc = get_preference_description(pref_value)
		info += "  %s: %+.1f (%s)\n" % [type_name, pref_value, pref_desc]
	
	# Show conversation availability
	info += "\nConversation Availability:\n"
	if conversation_controller:
		for conv_type in ConversationController.ConversationType.values():
			var availability = conversation_controller.can_start_conversation(self, conv_type)
			var type_name = get_conversation_type_name(conv_type)
			if availability.can_start:
				info += "  ✓ %s: Available\n" % type_name
			else:
				info += "  🔒 %s: Need %s Trust (Have: %s)\n" % [type_name, availability.required_trust_name, availability.current_trust_name]
	
	info += "\nControls: Click (Quick) | Ctrl+Click (Topic) | Shift+Click (Deep)"
	
	return info

func get_preference_description(pref_value: float) -> String:
	if pref_value >= 1.5:
		return "LOVES"
	elif pref_value >= 0.5:
		return "LIKES"
	elif pref_value >= -0.5:
		return "NEUTRAL"
	elif pref_value >= -1.0:
		return "DISLIKES"
	else:
		return "HATES"

func get_npc_data() -> Dictionary:
	return {
		"name": npc_name,
		"archetype": archetype,
		"compatibility": current_compatibility,
		"trust_level": current_trust_level,
		"trust_name": get_trust_name(current_trust_level),
		"position": position,
		"available_conversations": conversation_controller.get_available_conversation_types(self) if conversation_controller else []
	}

# =============================================================================
# INPUT HANDLING FOR DEBUG
# =============================================================================

func _input(event):
	# Show debug info on key press when this NPC is selected
	if event.is_action_pressed("ui_accept") and has_focus():
		print(get_debug_info())

func has_focus() -> bool:
	# Simple focus check
	var mouse_pos = get_global_mouse_position()
	var npc_rect = Rect2(global_position - Vector2(30, 45), Vector2(60, 90))
	return npc_rect.has_point(mouse_pos)
