# =============================================================================
# ENHANCED SOCIAL NPC - Phase 2C: Information-Focused Interactions
# File: scripts/npcs/DialogueNPC.gd (REPLACE existing file)
# Adds information specializations, availability hints, and enhanced interaction feedback
# =============================================================================

extends Area2D
class_name SocialNPC

@export var npc_name: String = "Unknown"
@export var archetype: SocialDNAManager.NPCArchetype = SocialDNAManager.NPCArchetype.AUTHORITY

# Enhanced visual components
@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label
@onready var trust_indicator: Label = $TrustIndicator
@onready var information_indicator: Label = $InformationIndicator

var current_compatibility: float = 0.0
var current_trust_level: float = 0.0
var conversation_controller: ConversationController = null

# NEW: Information specialization data
var information_specialization: String = ""
var available_information_count: int = 0
var information_shared_count: int = 0

# Enhanced signals
signal npc_clicked(npc: SocialNPC)
signal conversation_requested(npc: SocialNPC, conversation_type: ConversationController.ConversationType)
signal trust_gate_blocked(npc: SocialNPC, required_trust: String, current_trust: String)

func _ready():
	setup_enhanced_visuals()
	input_event.connect(_on_input_event)
	SocialDNAManager.social_dna_changed.connect(_on_social_dna_changed)
	
	call_deferred("find_conversation_controller")
	update_compatibility()
	
	# Set information specialization
	set_information_specialization()

func find_conversation_controller():
	conversation_controller = get_node("/root/Main/ConversationController")
	if conversation_controller:
		conversation_controller.relationship_changed.connect(_on_relationship_changed)
		conversation_controller.information_gained.connect(_on_information_gained)
		update_trust_level()
		update_information_availability()
		print("[NPC %s] Connected to enhanced conversation controller" % npc_name)

func set_information_specialization():
	# Set specialization based on NPC name and archetype
	match npc_name:
		"Captain Stone":
			information_specialization = "Security Expert"
		"Dr. Wisdom":
			information_specialization = "Research Director"
		"Commander Steele":
			information_specialization = "Operations Chief"
		_:
			match archetype:
				SocialDNAManager.NPCArchetype.AUTHORITY:
					information_specialization = "Authority Figure"
				SocialDNAManager.NPCArchetype.INTELLECTUAL:
					information_specialization = "Knowledge Source"
				_:
					information_specialization = "Information Broker"

func setup_enhanced_visuals():
	# Create sprite if needed
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)
	
	# Enhanced main info label with information context
	if not label:
		label = Label.new()
		label.position = Vector2(-90, -160)
		label.size = Vector2(180, 80)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		add_child(label)
	
	# Enhanced trust indicator
	if not trust_indicator:
		trust_indicator = Label.new()
		trust_indicator.position = Vector2(-70, -85)
		trust_indicator.size = Vector2(140, 25)
		trust_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		trust_indicator.add_theme_font_size_override("font_size", 9)
		add_child(trust_indicator)
	
	# NEW: Information availability indicator
	if not information_indicator:
		information_indicator = Label.new()
		information_indicator.position = Vector2(-70, -60)
		information_indicator.size = Vector2(140, 20)
		information_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		information_indicator.add_theme_font_size_override("font_size", 8)
		add_child(information_indicator)
	
	# Enhanced archetype-based appearance with information specialization colors
	match archetype:
		SocialDNAManager.NPCArchetype.AUTHORITY:
			sprite.modulate = Color.RED
		SocialDNAManager.NPCArchetype.INTELLECTUAL:
			sprite.modulate = Color.BLUE
	
	# Create enhanced colored rectangle as sprite
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
	update_enhanced_display()

func update_trust_level():
	if conversation_controller:
		current_trust_level = conversation_controller.get_npc_trust_level(self)
		update_enhanced_display()

func update_information_availability():
	if not conversation_controller:
		available_information_count = 0
		information_shared_count = 0
		return
	
	# Get available information count (simulate the logic from ConversationData)
	available_information_count = get_simulated_available_information_count()
	
	# Get shared information count
	var shared_info = conversation_controller.get_information_from_npc(npc_name)
	information_shared_count = shared_info.size()
	
	update_enhanced_display()

func get_simulated_available_information_count() -> int:
	# Simulate information availability based on trust level
	var count = 0
	var trust = current_trust_level
	
	match npc_name:
		"Captain Stone":
			if trust >= 0.0: count += 1  # facility_layout
			if trust >= 1.0: count += 1  # patrol_schedules  
			if trust >= 2.0: count += 1  # security_codes
			if trust >= 2.5: count += 1  # weapon_cache
		"Dr. Wisdom":
			if trust >= 0.0: count += 1  # research_summary
			if trust >= 1.0: count += 1  # lab_access
			if trust >= 2.0: count += 1  # classified_projects
			if trust >= 2.5: count += 1  # prototype_location
		"Commander Steele":
			if trust >= 1.0: count += 1  # mission_brief
			if trust >= 1.5: count += 1  # comm_frequencies
			if trust >= 2.0: count += 1  # supply_caches
		_:
			if trust >= 0.0: count += 1
			if trust >= 1.0: count += 1
			if trust >= 2.0: count += 1
	
	return count

func update_enhanced_display():
	var compat_desc = SocialDNAManager.get_compatibility_description(current_compatibility)
	var compat_color = SocialDNAManager.get_compatibility_color(current_compatibility)
	
	# Get enhanced trust info
	var trust_name = get_trust_name(current_trust_level)
	var trust_color = get_trust_color(current_trust_level)
	
	# Enhanced main label with information specialization
	label.text = "%s\n[%s]\n%s\nCompatibility: %.1f (%s)" % [
		npc_name,
		information_specialization,
		SocialDNAManager.get_archetype_name(archetype).to_upper(),
		current_compatibility,
		compat_desc
	]
	
	# Enhanced trust indicator with conversation access
	var available_conversations = get_available_conversation_display()
	trust_indicator.text = "Trust: %s (%.1f)\n%s" % [trust_name, current_trust_level, available_conversations]
	trust_indicator.modulate = trust_color
	
	# NEW: Information availability indicator
	var info_display = get_information_availability_display()
	information_indicator.text = info_display
	information_indicator.modulate = get_information_availability_color()
	
	# Enhanced visual feedback through sprite modulation
	var base_color = Color.RED if archetype == SocialDNAManager.NPCArchetype.AUTHORITY else Color.BLUE
	var trust_influence = trust_color.lerp(Color.WHITE, 0.4)
	var info_influence = get_information_availability_color().lerp(Color.WHITE, 0.3)
	
	sprite.modulate = base_color.lerp(compat_color, 0.2).lerp(trust_influence, 0.2).lerp(info_influence, 0.1)

func get_available_conversation_display() -> String:
	if not conversation_controller:
		return "[CLICK] Quick Chat"
	
	var available_types = []
	
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
	
	if available_types.size() > 0:
		return "[CLICK] " + " | ".join(available_types)
	else:
		return "[CLICK] Build Trust First"

func get_information_availability_display() -> String:
	if available_information_count == 0:
		return "🔒 No Information Available"
	elif information_shared_count >= available_information_count:
		return "✅ All Information Shared (%d)" % information_shared_count
	else:
		var available_new = available_information_count - information_shared_count
		return "📋 %d Info Available | %d Shared" % [available_new, information_shared_count]

func get_information_availability_color() -> Color:
	if available_information_count == 0:
		return Color.GRAY  # No information available
	elif information_shared_count >= available_information_count:
		return Color.GOLD  # All information obtained
	elif available_information_count > information_shared_count:
		return Color.LIGHT_GREEN  # New information available
	else:
		return Color.CYAN  # Some information available

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

# =============================================================================
# ENHANCED INTERACTION HANDLING WITH INFORMATION CONTEXT
# =============================================================================

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			show_enhanced_conversation_menu()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			print(get_enhanced_debug_info())

func show_enhanced_conversation_menu():
	print("[NPC] %s: Opening enhanced conversation menu with information context" % npc_name)
	
	# Create enhanced popup menu
	var popup = PopupMenu.new()
	popup.size = Vector2(300, 140)  # Larger for information descriptions
	popup.position = global_position + Vector2(70, -70)
	
	# Get conversation types with information context
	var available_types = []
	var blocked_types = []
	
	if conversation_controller:
		for conv_type in ConversationController.ConversationType.values():
			var availability = conversation_controller.can_start_conversation(self, conv_type)
			if availability.can_start:
				available_types.append(conv_type)
			else:
				blocked_types.append([conv_type, availability])
	
	# Add available conversations with information descriptions
	for conv_type in available_types:
		var type_name = get_conversation_type_name(conv_type)
		var description = get_enhanced_conversation_description(conv_type)
		var info_potential = get_information_potential_for_conversation(conv_type)
		
		var menu_text = "%s - %s" % [type_name, description]
		if info_potential != "":
			menu_text += "\n💡 %s" % info_potential
		
		popup.add_item(menu_text)
		popup.set_item_metadata(popup.get_item_count() - 1, conv_type)
	
	# Add separator if we have both available and blocked
	if available_types.size() > 0 and blocked_types.size() > 0:
		popup.add_separator()
	
	# Add blocked conversations with information context
	for blocked_info in blocked_types:
		var conv_type = blocked_info[0]
		var availability = blocked_info[1]
		var type_name = get_conversation_type_name(conv_type)
		var required_trust = availability.required_trust_name
		var info_hint = get_blocked_information_hint(conv_type)
		
		var menu_text = "🔒 %s (Need: %s Trust)" % [type_name, required_trust]
		if info_hint != "":
			menu_text += "\n🔒 %s" % info_hint
		
		popup.add_item(menu_text)
		var item_index = popup.get_item_count() - 1
		popup.set_item_disabled(item_index, true)
		popup.set_item_metadata(item_index, null)
	
	# Connect and show
	popup.id_pressed.connect(_on_conversation_selected)
	get_tree().current_scene.add_child(popup)
	popup.popup()
	
	popup.popup_hide.connect(func(): popup.queue_free())

func get_enhanced_conversation_description(conv_type: ConversationController.ConversationType) -> String:
	match conv_type:
		ConversationController.ConversationType.QUICK_CHAT:
			return "Build rapport & assess information"
		ConversationController.ConversationType.TOPIC_DISCUSSION:
			return "Request specific information"
		ConversationController.ConversationType.DEEP_CONVERSATION:
			return "Access high-value intelligence"
		_:
			return "General conversation"

func get_information_potential_for_conversation(conv_type: ConversationController.ConversationType) -> String:
	# Return information hints based on NPC specialization and conversation type
	match conv_type:
		ConversationController.ConversationType.QUICK_CHAT:
			match npc_name:
				"Captain Stone":
					return "Learn about security measures"
				"Dr. Wisdom":
					return "Discover research projects"
				"Commander Steele":
					return "Understand current operations"
				_:
					return "General information gathering"
		
		ConversationController.ConversationType.TOPIC_DISCUSSION:
			match npc_name:
				"Captain Stone":
					if current_trust_level >= 2.0:
						return "May share security codes"
					elif current_trust_level >= 1.0:
						return "May share patrol schedules"
					else:
						return "Basic security information"
				"Dr. Wisdom":
					if current_trust_level >= 2.0:
						return "May share classified research"
					elif current_trust_level >= 1.0:
						return "May provide lab access"
					else:
						return "Research summaries"
				"Commander Steele":
					if current_trust_level >= 2.0:
						return "May reveal supply locations"
					elif current_trust_level >= 1.5:
						return "May share comm frequencies"
					else:
						return "Mission briefings"
				_:
					return "Specific information available"
		
		ConversationController.ConversationType.DEEP_CONVERSATION:
			match npc_name:
				"Captain Stone":
					return "Highest-level security intel"
				"Dr. Wisdom":
					return "Prototype locations & secrets"
				"Commander Steele":
					return "Complete operational data"
				_:
					return "Most valuable information"
		_:
			return ""

func get_blocked_information_hint(conv_type: ConversationController.ConversationType) -> String:
	# Show what information is locked behind trust gates
	match conv_type:
		ConversationController.ConversationType.TOPIC_DISCUSSION:
			match npc_name:
				"Captain Stone":
					return "Security codes & patrol data locked"
				"Dr. Wisdom":
					return "Lab access & research data locked"
				"Commander Steele":
					return "Mission intel & frequencies locked"
				_:
					return "Important information locked"
		
		ConversationController.ConversationType.DEEP_CONVERSATION:
			match npc_name:
				"Captain Stone":
					return "Weapon cache locations locked"
				"Dr. Wisdom":
					return "Prototype storage locations locked"
				"Commander Steele":
					return "Supply depot coordinates locked"
				_:
					return "High-value intelligence locked"
		_:
			return "Information requires more trust"

func _on_conversation_selected(id: int):
	var popup = get_tree().current_scene.get_children().filter(func(child): return child is PopupMenu).back()
	if popup:
		var conv_type = popup.get_item_metadata(id)
		if conv_type != null:
			start_enhanced_conversation(conv_type)

func start_enhanced_conversation(conversation_type: ConversationController.ConversationType = ConversationController.ConversationType.QUICK_CHAT):
	print("[NPC] %s: Starting enhanced %s conversation with information focus" % [npc_name, get_conversation_type_name(conversation_type)])
	
	# Emit enhanced signals
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

# =============================================================================
# ENHANCED EVENT HANDLERS WITH INFORMATION CONTEXT
# =============================================================================

func _on_social_dna_changed(_new_dna: Dictionary):
	var old_compatibility = current_compatibility
	update_compatibility()
	update_information_availability()  # Compatibility affects information success chances
	
	# Enhanced visual feedback for compatibility changes
	if abs(current_compatibility - old_compatibility) > 0.1:
		flash_enhanced_feedback(current_compatibility > old_compatibility)

func _on_relationship_changed(npc: SocialNPC, old_trust: float, new_trust: float):
	if npc == self:
		var old_trust_level = current_trust_level
		current_trust_level = new_trust
		update_enhanced_display()
		update_information_availability()  # Trust changes affect available information
		
		# Enhanced trust change feedback with information context
		if abs(new_trust - old_trust_level) > 0.05:
			show_enhanced_trust_change_feedback(old_trust, new_trust)

func _on_information_gained(info_type: ConversationController.InformationType, info_data: Dictionary):
	# Check if this information came from this NPC
	var source_npc = info_data.get("source_npc", "")
	if source_npc == npc_name:
		print("[NPC %s] Information shared: %s" % [npc_name, info_data.get("title", "Unknown")])
		
		# Update information availability
		update_information_availability()
		
		# Show information shared feedback
		show_information_shared_feedback(info_data)

func show_enhanced_trust_change_feedback(old_trust: float, new_trust: float):
	var change = new_trust - old_trust
	var change_text = ""
	var color = Color.WHITE
	
	if change > 0:
		change_text = "Trust +%.2f" % change
		color = Color.GREEN
	elif change < 0:
		change_text = "Trust %.2f" % change
		color = Color.ORANGE
	else:
		return
	
	# Check for trust level changes and information unlocks
	var old_trust_name = get_trust_name(old_trust)
	var new_trust_name = get_trust_name(new_trust)
	
	if old_trust_name != new_trust_name:
		change_text += "\n%s → %s" % [old_trust_name, new_trust_name]
		color = Color.YELLOW
		
		# Check if new information became available
		var old_info_count = get_simulated_available_information_count_at_trust(old_trust)
		var new_info_count = get_simulated_available_information_count_at_trust(new_trust)
		
		if new_info_count > old_info_count:
			change_text += "\n📋 New information unlocked!"
			color = Color.LIGHT_GREEN
	
	show_floating_enhanced_text(change_text, color)

func get_simulated_available_information_count_at_trust(trust: float) -> int:
	# Helper function to check information availability at specific trust level
	var count = 0
	
	match npc_name:
		"Captain Stone":
			if trust >= 0.0: count += 1
			if trust >= 1.0: count += 1
			if trust >= 2.0: count += 1
			if trust >= 2.5: count += 1
		"Dr. Wisdom":
			if trust >= 0.0: count += 1
			if trust >= 1.0: count += 1
			if trust >= 2.0: count += 1
			if trust >= 2.5: count += 1
		"Commander Steele":
			if trust >= 1.0: count += 1
			if trust >= 1.5: count += 1
			if trust >= 2.0: count += 1
		_:
			if trust >= 0.0: count += 1
			if trust >= 1.0: count += 1
			if trust >= 2.0: count += 1
	
	return count

func show_information_shared_feedback(info_data: Dictionary):
	var feedback_text = "📋 Information Shared!\n%s" % info_data.get("title", "Unknown")
	show_floating_enhanced_text(feedback_text, Color.GOLD)

func flash_enhanced_feedback(positive: bool):
	var flash_color = Color.GREEN if positive else Color.RED
	var original_modulate = sprite.modulate
	
	sprite.modulate = flash_color
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", original_modulate, 0.8)

func show_floating_enhanced_text(text: String, color: Color):
	var floating_label = Label.new()
	floating_label.text = text
	floating_label.modulate = color
	floating_label.position = Vector2(-40, -70)
	floating_label.add_theme_font_size_override("font_size", 9)
	floating_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floating_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(floating_label)
	
	# Enhanced animation with information context
	var tween = create_tween()
	tween.parallel().tween_property(floating_label, "position:y", floating_label.position.y - 35, 3.0)
	tween.parallel().tween_property(floating_label, "modulate:a", 0.0, 3.0)
	tween.tween_callback(floating_label.queue_free)

# =============================================================================
# ENHANCED DEBUG AND INFORMATION
# =============================================================================

func get_enhanced_debug_info() -> String:
	var info = "=== %s ENHANCED DEBUG INFO ===\n" % npc_name.to_upper()
	info += "Specialization: %s\n" % information_specialization
	info += "Archetype: %s\n" % SocialDNAManager.get_archetype_name(archetype)
	info += "Compatibility: %.2f (%s)\n" % [current_compatibility, SocialDNAManager.get_compatibility_description(current_compatibility)]
	info += "Trust Level: %.2f (%s)\n" % [current_trust_level, get_trust_name(current_trust_level)]
	
	# Enhanced information status
	info += "\nINFORMATION STATUS:\n"
	info += "  Available Information: %d items\n" % available_information_count
	info += "  Information Shared: %d items\n" % information_shared_count
	
	if conversation_controller:
		var shared_info = conversation_controller.get_information_from_npc(npc_name)
		if shared_info.size() > 0:
			info += "  Shared Information:\n"
			for item in shared_info:
				info += "    • %s\n" % item.get("title", "Unknown")
	
	# Show relationship summary
	if conversation_controller:
		var summary = conversation_controller.get_relationship_summary(self)
		if summary and summary.size() > 0:
			info += "\nRELATIONSHIP SUMMARY:\n"
			info += "  Total Interactions: %d\n" % summary.get("total_interactions", 0)
			info += "  Success Rate: %.1f%%\n" % summary.get("success_rate", 0.0)
			info += "  Last Outcome: %s\n" % summary.get("last_outcome", "None")
		else:
			info += "\nRELATIONSHIP SUMMARY: No data yet\n"
	
	# Enhanced archetype preferences with information context
	info += "\nARCHETYPE PREFERENCES:\n"
	var preferences = SocialDNAManager.archetype_preferences[archetype]
	for social_type in preferences:
		var pref_value = preferences[social_type]
		var type_name = SocialDNAManager.get_social_type_name(social_type)
		var pref_desc = get_preference_description(pref_value)
		var info_success_bonus = "%.0f%% info success" % (pref_value * 10) if pref_value > 0 else ""
		info += "  %s: %+.1f (%s) %s\n" % [type_name, pref_value, pref_desc, info_success_bonus]
	
	# Enhanced conversation availability with information hints
	info += "\nCONVERSATION & INFORMATION AVAILABILITY:\n"
	if conversation_controller:
		for conv_type in ConversationController.ConversationType.values():
			var availability = conversation_controller.can_start_conversation(self, conv_type)
			var type_name = get_conversation_type_name(conv_type)
			var info_potential = get_information_potential_for_conversation(conv_type)
			
			if availability and availability.get("can_start", false):
				info += "  ✅ %s: Available" % type_name
				if info_potential != "":
					info += " (💡 %s)" % info_potential
				info += "\n"
			else:
				var required_trust = availability.get("required_trust_name", "Unknown") if availability else "Unknown"
				var current_trust = availability.get("current_trust_name", "Unknown") if availability else "Unknown"
				var blocked_hint = get_blocked_information_hint(conv_type)
				info += "  🔒 %s: Blocked (Need: %s, Have: %s)" % [type_name, required_trust, current_trust]
				if blocked_hint != "":
					info += "\n     🔒 %s" % blocked_hint
				info += "\n"
	else:
		info += "  No conversation controller available\n"
	
	info += "\nCONTROLS: Left-click (Enhanced Menu) | Right-click (Debug)"
	
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

func get_enhanced_npc_data() -> Dictionary:
	var data = {
		"name": npc_name,
		"specialization": information_specialization,
		"archetype": archetype,
		"compatibility": current_compatibility,
		"trust_level": current_trust_level,
		"trust_name": get_trust_name(current_trust_level),
		"position": position,
		"available_conversations": conversation_controller.get_available_conversation_types(self) if conversation_controller else [],
		"available_information_count": available_information_count,
		"information_shared_count": information_shared_count
	}
	
	# Add information sharing history
	if conversation_controller:
		data.information_shared = conversation_controller.get_information_from_npc(npc_name)
	
	return data

# =============================================================================
# INPUT HANDLING FOR ENHANCED DEBUG
# =============================================================================

func _input(event):
	if event.is_action_pressed("ui_accept") and has_focus():
		print(get_enhanced_debug_info())
	elif event.is_action_pressed("ui_page_up") and has_focus():
		# Show information specialization details
		print_information_specialization_details()

func print_information_specialization_details():
	print("\n=== %s INFORMATION SPECIALIZATION ===\n" % npc_name.to_upper())
	print("Specialization: %s" % information_specialization)
	print("Available Information Types:")
	
	match npc_name:
		"Captain Stone":
			print("  🔐 Security Codes (Trust: 2.0+)")
			print("  🚨 Patrol Schedules (Trust: 1.0+)")
			print("  🗺️ Facility Layout (Trust: 0.0+)")
			print("  ⚔️ Weapon Cache Locations (Trust: 2.5+)")
		"Dr. Wisdom":
			print("  🧪 Research Data (Trust: 0.0+)")
			print("  🔬 Lab Access Codes (Trust: 1.0+)")
			print("  📚 Classified Projects (Trust: 2.0+)")
			print("  🛠️ Prototype Locations (Trust: 2.5+)")
		"Commander Steele":
			print("  📋 Mission Briefings (Trust: 1.0+)")
			print("  📡 Communication Codes (Trust: 1.5+)")
			print("  📦 Supply Cache Locations (Trust: 2.0+)")
		_:
			print("  📋 General Information Available")
	
	print("\nCurrent Status:")
	print("  Trust Level: %.2f (%s)" % [current_trust_level, get_trust_name(current_trust_level)])
	print("  Information Available: %d items" % available_information_count)
	print("  Information Already Shared: %d items" % information_shared_count)
	print("  Compatibility: %.2f (%s)" % [current_compatibility, SocialDNAManager.get_compatibility_description(current_compatibility)])
	print("=====================================\n")

func has_focus() -> bool:
	var mouse_pos = get_global_mouse_position()
	var npc_rect = Rect2(global_position - Vector2(30, 45), Vector2(60, 90))
	return npc_rect.has_point(mouse_pos)
