# =============================================================================
# ENHANCED MAIN SCENE CONTROLLER - Phase 2B
# File: scripts/Main.gd (REPLACE existing file)
# Integrates trust gates, failure states, and enhanced relationship system
# =============================================================================

extends Node2D

# UI Components
@onready var ui_canvas: CanvasLayer = $UI

# System Controllers
var conversation_controller: ConversationController
var conversation_ui: ConversationUI

# NPCs
var npcs := []

func _ready():
	print("[MAIN] Starting Phase 2B - Enhanced Relationship & Trust System")
	
	# Initialize systems
	setup_conversation_system()
	setup_ui()
	create_test_npcs()
	
	# Connect to NPC interactions
	for npc in npcs:
		npc.npc_clicked.connect(_on_npc_clicked)
		npc.conversation_requested.connect(_on_conversation_requested)
		npc.trust_gate_blocked.connect(_on_trust_gate_blocked)
	
	# Connect to conversation controller events
	if conversation_controller:
		conversation_controller.trust_gate_encountered.connect(_on_trust_gate_encountered)
		conversation_controller.conversation_failed.connect(_on_conversation_failed)
	
	print("[MAIN] Phase 2B initialization complete!")
	print_usage_instructions()

func setup_conversation_system():
	# Create enhanced conversation controller
	conversation_controller = ConversationController.new()
	conversation_controller.name = "ConversationController"
	add_child(conversation_controller)
	
	print("[MAIN] Enhanced conversation controller initialized with trust gates and failure handling")

func setup_ui():
	# Instance the existing SocialDNAPanel scene
	var social_panel_scene = preload("res://scenes/ui/SocialDNAPanel.tscn")
	var social_panel = social_panel_scene.instantiate()
	social_panel.position = Vector2(10, 10)
	social_panel.size = Vector2(300, 450)  # Slightly taller for Phase 2B
	ui_canvas.add_child(social_panel)
	
	# Create enhanced conversation UI
	conversation_ui = create_enhanced_conversation_ui()
	ui_canvas.add_child(conversation_ui)
	
	# Connect conversation UI signals
	conversation_ui.conversation_ui_closed.connect(_on_conversation_ui_closed)
	
	print("[MAIN] Enhanced UI systems initialized")

func create_enhanced_conversation_ui() -> ConversationUI:
	# Create the enhanced conversation UI programmatically
	var ui = ConversationUI.new()
	ui.name = "ConversationUI"
	
	# Create UI structure
	var background = Panel.new()
	background.name = "BackgroundPanel"
	background.size = Vector2(700, 550)  # Taller for relationship info
	background.position = Vector2(1200, 300)  # User's preferred position
	
	# Create VBox container
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.add_theme_constant_override("separation", 8)
	
	# Enhanced NPC Info section
	var npc_info = VBoxContainer.new()
	npc_info.name = "NPCInfo"
	
	var npc_name_label = Label.new()
	npc_name_label.name = "NPCName"
	npc_name_label.add_theme_font_size_override("font_size", 18)
	npc_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	npc_info.add_child(npc_name_label)
	
	var npc_status_label = Label.new()
	npc_status_label.name = "NPCStatus"
	npc_status_label.add_theme_font_size_override("font_size", 12)
	npc_status_label.modulate = Color.LIGHT_GRAY
	npc_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	npc_info.add_child(npc_status_label)
	
	# New: Relationship status label
	var relationship_label = Label.new()
	relationship_label.name = "RelationshipStatus"
	relationship_label.add_theme_font_size_override("font_size", 11)
	relationship_label.modulate = Color.CYAN
	relationship_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	npc_info.add_child(relationship_label)
	
	vbox.add_child(npc_info)
	
	# Enhanced dialogue text area
	var dialogue_text = RichTextLabel.new()
	dialogue_text.name = "DialogueText"
	dialogue_text.custom_minimum_size = Vector2(680, 220)  # Taller for more text
	dialogue_text.bbcode_enabled = true
	dialogue_text.scroll_following = true
	dialogue_text.selection_enabled = true  # Allow text selection for debugging
	vbox.add_child(dialogue_text)
	
	# Choice container
	var choice_container = VBoxContainer.new()
	choice_container.name = "ChoiceContainer"
	choice_container.add_theme_constant_override("separation", 8)
	vbox.add_child(choice_container)
	
	# Enhanced close button
	var close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "Close Conversation"
	close_button.custom_minimum_size = Vector2(150, 35)
	close_button.visible = false
	vbox.add_child(close_button)
	
	# Assemble structure
	background.add_child(vbox)
	ui.add_child(background)
	
	# Apply enhanced conversation UI styling
	apply_enhanced_conversation_ui_styling(background)
	
	return ui

func apply_enhanced_conversation_ui_styling(background: Panel):
	# Enhanced dark theme for Phase 2B
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.08, 0.08, 0.12, 0.98)  # Darker, more professional
	style_box.border_width_left = 3
	style_box.border_width_right = 3
	style_box.border_width_top = 3
	style_box.border_width_bottom = 3
	style_box.border_color = Color(0.4, 0.6, 0.8, 1.0)  # Blue accent border
	style_box.corner_radius_top_left = 12
	style_box.corner_radius_top_right = 12
	style_box.corner_radius_bottom_left = 12
	style_box.corner_radius_bottom_right = 12
	
	# Add subtle shadow effect
	style_box.shadow_color = Color(0, 0, 0, 0.5)
	style_box.shadow_size = 8
	style_box.shadow_offset = Vector2(4, 4)
	
	background.add_theme_stylebox_override("panel", style_box)

func create_test_npcs():
	# Create Authority NPC (Captain Stone)
	var authority_npc_scene = preload("res://scenes/NPCTest.tscn")
	var authority_npc = authority_npc_scene.instantiate()
	authority_npc.npc_name = "Captain Stone"
	authority_npc.archetype = SocialDNAManager.NPCArchetype.AUTHORITY
	authority_npc.position = Vector2(500, 400)
	add_child(authority_npc)
	npcs.append(authority_npc)
	
	# Create Intellectual NPC (Dr. Wisdom)
	var intellectual_npc_scene = preload("res://scenes/NPCTest.tscn")
	var intellectual_npc = intellectual_npc_scene.instantiate()
	intellectual_npc.npc_name = "Dr. Wisdom"
	intellectual_npc.archetype = SocialDNAManager.NPCArchetype.INTELLECTUAL
	intellectual_npc.position = Vector2(700, 400)
	add_child(intellectual_npc)
	npcs.append(intellectual_npc)
	
	# New: Create a third NPC to test trust progression
	var authority_npc2_scene = preload("res://scenes/NPCTest.tscn")
	var authority_npc2 = authority_npc2_scene.instantiate()
	authority_npc2.npc_name = "Commander Steele"
	authority_npc2.archetype = SocialDNAManager.NPCArchetype.AUTHORITY
	authority_npc2.position = Vector2(900, 400)
	add_child(authority_npc2)
	npcs.append(authority_npc2)
	
	print("[MAIN] Created %d test NPCs with enhanced relationship tracking" % npcs.size())

# =============================================================================
# ENHANCED CONVERSATION EVENT HANDLERS
# =============================================================================

func _on_npc_clicked(npc: SocialNPC):
	print("[MAIN] NPC clicked: %s" % npc.npc_name)

func _on_conversation_requested(npc: SocialNPC, conversation_type: ConversationController.ConversationType):
	print("[MAIN] Conversation requested with %s: %s" % [npc.npc_name, get_conversation_type_name(conversation_type)])
	
	# Check if conversation is already active
	if conversation_controller.is_conversation_active():
		print("[MAIN] Conversation already active, ignoring request")
		return
	
	# Start the conversation UI
	conversation_ui.start_conversation_ui(npc, conversation_controller)
	
	# Start the conversation in the controller (this will handle trust gates automatically)
	conversation_controller.start_conversation(npc, conversation_type)

func _on_trust_gate_blocked(npc: SocialNPC, required_trust: String, current_trust: String):
	print("[MAIN] Trust gate blocked for %s - Need: %s, Have: %s" % [npc.npc_name, required_trust, current_trust])
	show_trust_gate_notification(npc, required_trust, current_trust)

func _on_trust_gate_encountered(npc: SocialNPC, required_trust: String, current_trust: String):
	print("[MAIN] Trust gate encountered in conversation controller")
	# The UI will handle displaying this, but we can add additional logic here if needed

func _on_conversation_failed(reason: String, retry_info: Dictionary):
	print("[MAIN] Conversation failed: %s" % reason)
	print("[MAIN] Retry info: %s" % retry_info)
	
	# Show failure notification
	show_conversation_failure_notification(reason, retry_info)

func show_trust_gate_notification(npc: SocialNPC, required_trust: String, current_trust: String):
	# Create a temporary notification above the NPC
	var notification = Label.new()
	notification.text = "🔒 Need %s Trust!\n(Have: %s)" % [required_trust, current_trust]
	notification.position = npc.position + Vector2(-60, -150)
	notification.size = Vector2(120, 50)
	notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification.add_theme_font_size_override("font_size", 10)
	notification.modulate = Color.ORANGE
	add_child(notification)
	
	# Animate and remove
	var tween = create_tween()
	tween.parallel().tween_property(notification, "position:y", notification.position.y - 30, 3.0)
	tween.parallel().tween_property(notification, "modulate:a", 0.0, 3.0)
	tween.tween_callback(notification.queue_free)

func show_conversation_failure_notification(reason: String, retry_info: Dictionary):
	# Create a screen-wide notification for conversation failure
	var notification_panel = Panel.new()
	notification_panel.size = Vector2(400, 120)
	notification_panel.position = Vector2(400, 100)
	
	var notification_label = Label.new()
	notification_label.text = "⚠️ Conversation Failed!\n%s\n\n💡 Try: %s" % [
		reason, 
		retry_info.get("retry_suggestion", "Different approach")
	]
	notification_label.anchors_preset = Control.PRESET_FULL_RECT
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notification_label.add_theme_font_size_override("font_size", 12)
	notification_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	# Style the notification
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.8, 0.3, 0.3, 0.9)
	style_box.border_color = Color(1.0, 0.5, 0.5, 1.0)
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	notification_panel.add_theme_stylebox_override("panel", style_box)
	
	notification_panel.add_child(notification_label)
	ui_canvas.add_child(notification_panel)
	
	# Auto-remove after delay
	var tween = create_tween()
	tween.tween_delay(4.0)
	tween.tween_property(notification_panel, "modulate:a", 0.0, 1.0)
	tween.tween_callback(notification_panel.queue_free)

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

func _on_conversation_ui_closed():
	print("[MAIN] Conversation UI closed")
	
	# End any active conversation
	if conversation_controller.is_conversation_active():
		conversation_controller.end_conversation({"outcome": ConversationController.ConversationOutcome.INTERRUPTED})

# =============================================================================
# ENHANCED DEBUG AND TESTING
# =============================================================================

func _input(event):
	# Enhanced debug keybindings
	if event.is_action_pressed("ui_select"):  # Space key
		print_enhanced_debug_info()
	elif event.is_action_pressed("ui_home"):  # Home key
		print_usage_instructions()
	elif event.is_action_pressed("ui_page_up"):  # Page Up - Show relationship summary
		print_relationship_summary()
	elif event.is_action_pressed("ui_page_down"):  # Page Down - Show trust gates status
		print_trust_gates_status()

func print_enhanced_debug_info():
	print("\n=== PHASE 2B ENHANCED DEBUG INFO ===")
	print("Social DNA Manager Status:")
	var percentages = SocialDNAManager.get_social_percentages()
	for social_type in SocialDNAManager.social_dna:
		var type_name = SocialDNAManager.get_social_type_name(social_type)
		var value = SocialDNAManager.social_dna[social_type]
		var percentage = percentages[social_type]
		print("  %s: %d (%.1f%%)" % [type_name, value, percentage])
	
	print("\nNPC Status with Trust Levels:")
	for npc in npcs:
		var compat = SocialDNAManager.calculate_compatibility(npc.archetype)
		var trust = conversation_controller.get_npc_trust_level(npc)
		var trust_name = conversation_controller.get_trust_level_name(trust)
		var summary = conversation_controller.get_relationship_summary(npc)
		
		print("  %s:" % npc.npc_name)
		print("    Compatibility: %.2f (%s)" % [compat, SocialDNAManager.get_compatibility_description(compat)])
		print("    Trust: %.2f (%s)" % [trust, trust_name])
		print("    Success Rate: %.1f%% (%d/%d interactions)" % [
			summary.success_rate, summary.successful_interactions, summary.total_interactions
		])
		
		# Show available conversation types
		var available = summary.available_conversations
		var available_names = []
		for conv_type in available:
			available_names.append(get_conversation_type_name(conv_type))
		print("    Available: [%s]" % ", ".join(available_names))
	
	print("\nConversation Controller Status:")
	print("  Active: %s" % conversation_controller.is_conversation_active())
	
	if conversation_controller.is_conversation_active():
		var info = conversation_controller.get_current_conversation_info()
		print("  Current NPC: %s" % info.get("npc", {}).get("npc_name", "Unknown"))
		print("  Turn: %d" % info.get("turn", 0))
		print("  Type: %s" % info.get("type", "Unknown"))
		print("  Outcome: %s" % info.get("outcome", "In Progress"))
	
	print("========================================\n")

func print_relationship_summary():
	print("\n=== RELATIONSHIP SUMMARY ===")
	for npc in npcs:
		var summary = conversation_controller.get_relationship_summary(npc)
		print("%s:" % npc.npc_name.to_upper())
		print("  Trust: %s (%.2f)" % [summary.trust_name, summary.trust_level])
		print("  Interactions: %d total, %d successful (%.1f%%)" % [
			summary.total_interactions, 
			summary.successful_interactions, 
			summary.success_rate
		])
		print("  Last Outcome: %s" % summary.last_outcome)
		
		var available_names = []
		for conv_type in summary.available_conversations:
			available_names.append(get_conversation_type_name(conv_type))
		print("  Available Conversations: %s" % ", ".join(available_names))
		print("")
	print("==============================\n")

func print_trust_gates_status():
	print("\n=== TRUST GATES STATUS ===")
	for npc in npcs:
		print("%s:" % npc.npc_name.to_upper())
		
		for conv_type in ConversationController.ConversationType.values():
			var availability = conversation_controller.can_start_conversation(npc, conv_type)
			var type_name = get_conversation_type_name(conv_type)
			
			if availability.can_start:
				print("  ✅ %s: Available" % type_name)
			else:
				print("  🔒 %s: Blocked (Need: %s, Have: %s)" % [
					type_name, 
					availability.required_trust_name, 
					availability.current_trust_name
				])
		print("")
	print("===========================\n")

func print_usage_instructions():
	print("\n=== PHASE 2B USAGE INSTRUCTIONS ===")
	print("ENHANCED CONVERSATION SYSTEM:")
	print("• Left-click NPCs: Quick Chat (no trust required)")
	print("• Ctrl+Left-click NPCs: Topic Discussion (Professional trust required)")
	print("• Shift+Left-click NPCs: Deep Conversation (Trusted trust required)")
	print("• Right-click NPCs: Show conversation menu and availability")
	print("")
	print("TRUST SYSTEM:")
	print("• Build trust through successful conversations")
	print("• Failed conversations damage trust")
	print("• Trust levels: Hostile → Stranger → Professional → Trusted → Close")
	print("• Higher trust unlocks deeper conversations")
	print("• NPCs remember your conversation history")
	print("")
	print("TRUST GATES:")
	print("• Topic Discussions require Professional trust (1.0+)")
	print("• Deep Conversations require Trusted trust (2.0+)")
	print("• Blocked conversations show [TRUST REQUIRED] messages")
	print("• Build trust through successful Quick Chats first")
	print("")
	print("FAILURE STATES:")
	print("• Very poor compatibility can end conversations early")
	print("• Failed conversations can be retried with different approaches")
	print("• Failure damages trust more than success builds it")
	print("• NPCs give recommendations for better social approaches")
	print("")
	print("ENHANCED UI:")
	print("• Conversation window shows trust levels and relationship history")
	print("• Success rates and interaction counts displayed")
	print("• Trust changes shown in real-time during conversations")
	print("• Visual trust indicators on NPCs (color-coded)")
	print("")
	print("ADVANCED FEATURES:")
	print("• Trust-aware NPC reactions (same choice, different response based on trust)")
	print("• Relationship history affects opening lines")
	print("• Social approach recommendations after failures")
	print("• Conversation retry system with improved success chances")
	print("")
	print("DEBUG KEYS:")
	print("• SPACE: Enhanced debug info with trust levels")
	print("• HOME: Show these instructions")
	print("• PAGE UP: Detailed relationship summary")
	print("• PAGE DOWN: Trust gates status for all NPCs")
	print("• ESC (in conversation): Close conversation UI")
	print("")
	print("TESTING SCENARIOS:")
	print("1. Try Topic/Deep conversations as Stranger → See trust gates")
	print("2. Build trust with Quick Chats → Watch conversations unlock")
	print("3. Use incompatible social approaches → Experience failures")
	print("4. Try different Social DNA builds → See how trust building changes")
	print("5. Have multiple conversations → Watch relationship history develop")
	print("===================================\n")

# =============================================================================
# SYSTEM INTEGRATION AND STATUS
# =============================================================================

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("[MAIN] Application closing - Phase 2B session complete")
		
		# Print final relationship summary
		print("\n=== FINAL SESSION SUMMARY ===")
		for npc in npcs:
			var summary = conversation_controller.get_relationship_summary(npc)
			print("%s: Trust %s (%.2f), %d interactions, %.1f%% success" % [
				npc.npc_name,
				summary.trust_name,
				summary.trust_level,
				summary.total_interactions,
				summary.success_rate
			])
		print("==============================")
		
		get_tree().quit()

func get_enhanced_system_status() -> Dictionary:
	return {
		"phase": "2B - Enhanced Relationship & Trust System",
		"conversation_controller_ready": is_instance_valid(conversation_controller),
		"conversation_ui_ready": is_instance_valid(conversation_ui),
		"active_conversation": conversation_controller.is_conversation_active() if conversation_controller else false,
		"npc_count": npcs.size(),
		"social_dna_total": SocialDNAManager.get_total_social_strength(),
		"trust_gates_active": true,
		"failure_states_active": true,
		"relationship_tracking": true
	}

# =============================================================================
# PHASE 2B SPECIFIC FEATURES
# =============================================================================

func simulate_trust_building_scenario():
	# Debug function to simulate trust building with an NPC
	if npcs.size() > 0:
		var npc = npcs[0]
		print("[MAIN] Simulating trust building with %s" % npc.npc_name)
		
		# Simulate successful interactions
		for i in range(3):
			conversation_controller.update_enhanced_relationship(
				{"social_type": SocialDNAManager.SocialType.DIRECT}, 
				"COMPATIBLE"
			)
		
		print("[MAIN] Trust building simulation complete")

func reset_all_relationships():
	# Debug function to reset all relationships
	print("[MAIN] Resetting all relationships...")
	if conversation_controller:
		conversation_controller.relationship_data.clear()
		
		# Update NPC displays
		for npc in npcs:
			if npc.has_method("update_trust_level"):
				npc.update_trust_level()
	
	print("[MAIN] All relationships reset to Stranger level")
