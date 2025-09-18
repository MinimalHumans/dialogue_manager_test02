# =============================================================================
# MAIN SCENE CONTROLLER - Phase 2A Updated
# File: scripts/Main.gd (replace existing file)
# Integrates conversation system with existing Social DNA system
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
	print("[MAIN] Starting Phase 2A - Multi-Turn Conversation System")
	
	# Initialize systems
	setup_conversation_system()
	setup_ui()
	create_test_npcs()
	
	# Connect to NPC interactions
	for npc in npcs:
		npc.npc_clicked.connect(_on_npc_clicked)
		npc.conversation_requested.connect(_on_conversation_requested)
	
	print("[MAIN] Phase 2A initialization complete!")
	print_usage_instructions()

func setup_conversation_system():
	# Create conversation controller
	conversation_controller = ConversationController.new()
	conversation_controller.name = "ConversationController"
	add_child(conversation_controller)
	
	print("[MAIN] Conversation controller initialized")

func setup_ui():
	# Instance the existing SocialDNAPanel scene
	var social_panel_scene = preload("res://scenes/ui/SocialDNAPanel.tscn")
	var social_panel = social_panel_scene.instantiate()
	social_panel.position = Vector2(10, 10)
	social_panel.size = Vector2(300, 400)
	ui_canvas.add_child(social_panel)
	
	# Create conversation UI scene structure and instantiate
	conversation_ui = create_conversation_ui()
	ui_canvas.add_child(conversation_ui)
	
	# Connect conversation UI signals
	conversation_ui.conversation_ui_closed.connect(_on_conversation_ui_closed)
	
	print("[MAIN] UI systems initialized")

func create_conversation_ui() -> ConversationUI:
	# Create the conversation UI programmatically since we don't have a scene file yet
	var ui = ConversationUI.new()
	ui.name = "ConversationUI"
	
	# Create UI structure
	var background = Panel.new()
	background.name = "BackgroundPanel"
	background.size = Vector2(700, 500)
	background.position = Vector2(1200, 300)  # Updated position
	
	# Create VBox container
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.add_theme_constant_override("separation", 10)
	
	# NPC Info section
	var npc_info = VBoxContainer.new()
	npc_info.name = "NPCInfo"
	
	var npc_name_label = Label.new()
	npc_name_label.name = "NPCName"
	npc_name_label.add_theme_font_size_override("font_size", 16)
	npc_info.add_child(npc_name_label)
	
	var npc_status_label = Label.new()
	npc_status_label.name = "NPCStatus"
	npc_status_label.add_theme_font_size_override("font_size", 12)
	npc_status_label.modulate = Color.GRAY
	npc_info.add_child(npc_status_label)
	
	vbox.add_child(npc_info)
	
	# Dialogue text area
	var dialogue_text = RichTextLabel.new()
	dialogue_text.name = "DialogueText"
	dialogue_text.custom_minimum_size = Vector2(680, 200)
	dialogue_text.bbcode_enabled = true
	dialogue_text.scroll_following = true
	vbox.add_child(dialogue_text)
	
	# Choice container
	var choice_container = VBoxContainer.new()
	choice_container.name = "ChoiceContainer"
	choice_container.add_theme_constant_override("separation", 5)
	vbox.add_child(choice_container)
	
	# Close button
	var close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "Close Conversation"
	close_button.custom_minimum_size = Vector2(150, 30)
	close_button.visible = false
	vbox.add_child(close_button)
	
	# Assemble structure
	background.add_child(vbox)
	ui.add_child(background)
	
	# Apply dark theme styling
	apply_conversation_ui_styling(background)
	
	return ui

func apply_conversation_ui_styling(background: Panel):
	# Create dark theme for conversation UI
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.3, 0.3, 0.3, 1.0)
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	
	background.add_theme_stylebox_override("panel", style_box)

func create_test_npcs():
	# Create Authority NPC (Captain Stone)
	var authority_npc_scene = preload("res://scenes/NPCTest.tscn")
	var authority_npc = authority_npc_scene.instantiate()
	authority_npc.npc_name = "Captain Stone"
	authority_npc.archetype = SocialDNAManager.NPCArchetype.AUTHORITY
	authority_npc.position = Vector2(500, 300)
	add_child(authority_npc)
	npcs.append(authority_npc)
	
	# Create Intellectual NPC (Dr. Wisdom)
	var intellectual_npc_scene = preload("res://scenes/NPCTest.tscn")
	var intellectual_npc = intellectual_npc_scene.instantiate()
	intellectual_npc.npc_name = "Dr. Wisdom"
	intellectual_npc.archetype = SocialDNAManager.NPCArchetype.INTELLECTUAL
	intellectual_npc.position = Vector2(700, 300)
	add_child(intellectual_npc)
	npcs.append(intellectual_npc)
	
	print("[MAIN] Created %d test NPCs" % npcs.size())

# =============================================================================
# CONVERSATION EVENT HANDLERS
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
	
	# Start the conversation in the controller
	conversation_controller.start_conversation(npc, conversation_type)

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
		conversation_controller.end_conversation({"outcome": "player_closed"})

# =============================================================================
# DEBUG AND TESTING
# =============================================================================

func _input(event):
	# Debug keybindings
	if event.is_action_pressed("ui_select"):  # Space key
		print_debug_info()
	elif event.is_action_pressed("ui_home"):  # Home key
		print_usage_instructions()

func print_debug_info():
	print("\n=== PHASE 2A DEBUG INFO ===")
	print("Social DNA Manager Status:")
	var percentages = SocialDNAManager.get_social_percentages()
	for social_type in SocialDNAManager.social_dna:
		var type_name = SocialDNAManager.get_social_type_name(social_type)
		var value = SocialDNAManager.social_dna[social_type]
		var percentage = percentages[social_type]
		print("  %s: %d (%.1f%%)" % [type_name, value, percentage])
	
	print("\nNPC Status:")
	for npc in npcs:
		var compat = SocialDNAManager.calculate_compatibility(npc.archetype)
		print("  %s: %.2f compatibility (%s)" % [
			npc.npc_name, 
			compat, 
			SocialDNAManager.get_compatibility_description(compat)
		])
	
	print("\nConversation Controller:")
	print("  Active: %s" % conversation_controller.is_conversation_active())
	
	if conversation_controller.is_conversation_active():
		var info = conversation_controller.get_current_conversation_info()
		print("  Current NPC: %s" % info.get("npc", {}).get("npc_name", "Unknown"))
		print("  Turn: %d" % info.get("turn", 0))
		print("  Type: %s" % info.get("type", "Unknown"))
	
	print("========================\n")

func print_usage_instructions():
	print("\n=== PHASE 2A USAGE INSTRUCTIONS ===")
	print("CONVERSATION SYSTEM:")
	print("• Left-click NPCs: Start Quick Chat (1-2 exchanges)")
	print("• Right-click NPCs: Start Topic Discussion (3-5 exchanges)")
	print("• Deep Conversations: Available but need UI implementation")
	print("")
	print("CONVERSATION UI:")
	print("• Shows NPC info, compatibility, and trust levels")
	print("• Player choices show [SOCIAL_TYPE] flags and trait bonuses")
	print("• NPC reactions show [COMPATIBILITY] flags")
	print("• Real-time Social DNA updates during conversation")
	print("• Relationship tracking (trust levels)")
	print("")
	print("DEBUG FLAGS IN CONVERSATIONS:")
	print("• Player Options: [AGGRESSIVE], [DIPLOMATIC], [CHARMING], [DIRECT], [EMPATHETIC]")
	print("• NPC Reactions: [VERY COMPATIBLE], [COMPATIBLE], [NEUTRAL], [INCOMPATIBLE], [VERY INCOMPATIBLE]")
	print("• Social DNA Updates: +3 chosen trait, +1 others")
	print("• Relationship Changes: Shown as trust level changes")
	print("")
	print("SOCIAL DNA PANEL (Left Side):")
	print("• Shows current Social DNA stats and percentages")
	print("• Test profile buttons to try different builds")
	print("• Individual trait increase buttons")
	print("• Real-time compatibility with all NPCs")
	print("")
	print("TESTING TIPS:")
	print("• Try different Social DNA builds and see how NPCs react differently")
	print("• Watch console output for detailed conversation flow")
	print("• Use different conversation types to see varied content")
	print("• Notice how relationship/trust changes over multiple conversations")
	print("")
	print("DEBUG KEYS:")
	print("• SPACE: Print debug info")
	print("• HOME: Show these instructions")
	print("• ESC (in conversation): Close conversation UI")
	print("===================================\n")

# =============================================================================
# SYSTEM INTEGRATION
# =============================================================================

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("[MAIN] Application closing - Phase 2A session complete")
		get_tree().quit()

func get_system_status() -> Dictionary:
	return {
		"phase": "2A - Multi-Turn Conversations",
		"conversation_controller_ready": is_instance_valid(conversation_controller),
		"conversation_ui_ready": is_instance_valid(conversation_ui),
		"active_conversation": conversation_controller.is_conversation_active() if conversation_controller else false,
		"npc_count": npcs.size(),
		"social_dna_total": SocialDNAManager.get_total_social_strength()
	}
