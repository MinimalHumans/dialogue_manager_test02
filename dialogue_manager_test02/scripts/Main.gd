# =============================================================================
# ENHANCED MAIN SCENE CONTROLLER - Phase 2C: Information System Integration
# File: scripts/Main.gd (REPLACE existing file)
# Integrates goal-driven conversations, information tracking, and reward systems
# =============================================================================

extends Node2D

# UI Components
@onready var ui_canvas: CanvasLayer = $UI

# System Controllers
var conversation_controller: ConversationController
var conversation_ui: ConversationUI

# NEW: Information system UI
var information_panel: Panel
var information_inventory_label: Label

# NPCs
var npcs := []

func _ready():
	print("[MAIN] Starting Phase 2C - Goal-Driven Information System")
	
	# Initialize enhanced systems
	setup_enhanced_conversation_system()
	setup_enhanced_ui()
	create_enhanced_test_npcs()
	
	# Connect to NPC interactions
	for npc in npcs:
		npc.npc_clicked.connect(_on_npc_clicked)
		npc.conversation_requested.connect(_on_conversation_requested)
		npc.trust_gate_blocked.connect(_on_trust_gate_blocked)
	
	# Connect to conversation controller events (enhanced)
	if conversation_controller:
		conversation_controller.trust_gate_encountered.connect(_on_trust_gate_encountered)
		conversation_controller.conversation_failed.connect(_on_conversation_failed)
		
		# NEW: Information system signals
		conversation_controller.information_gained.connect(_on_information_gained)
		conversation_controller.information_request_failed.connect(_on_information_request_failed)
		conversation_controller.objective_completed.connect(_on_objective_completed)
	
	print("[MAIN] Phase 2C initialization complete with information tracking!")
	print_enhanced_usage_instructions()

func setup_enhanced_conversation_system():
	# Create enhanced conversation controller with information system
	conversation_controller = ConversationController.new()
	conversation_controller.name = "ConversationController"
	add_child(conversation_controller)
	
	print("[MAIN] Enhanced conversation controller initialized with information tracking and reward system")

func setup_enhanced_ui():
	# Instance the existing SocialDNAPanel scene
	var social_panel_scene = preload("res://scenes/ui/SocialDNAPanel.tscn")
	var social_panel = social_panel_scene.instantiate()
	social_panel.position = Vector2(10, 10)
	social_panel.size = Vector2(300, 450)
	ui_canvas.add_child(social_panel)
	
	# Create enhanced conversation UI
	conversation_ui = create_enhanced_conversation_ui()
	ui_canvas.add_child(conversation_ui)
	
	# NEW: Create information inventory panel
	create_information_inventory_panel()
	
	# Connect conversation UI signals
	conversation_ui.conversation_ui_closed.connect(_on_conversation_ui_closed)
	
	print("[MAIN] Enhanced UI systems initialized with information tracking")

func create_information_inventory_panel():
	# Create information inventory display
	information_panel = Panel.new()
	information_panel.name = "InformationPanel"
	information_panel.size = Vector2(350, 300)
	information_panel.position = Vector2(1550, 10)  # Top right
	
	# Style the information panel
	var info_style = StyleBoxFlat.new()
	info_style.bg_color = Color(0.08, 0.12, 0.08, 0.95)  # Dark green tint
	info_style.border_width_left = 3
	info_style.border_width_right = 3
	info_style.border_width_top = 3
	info_style.border_width_bottom = 3
	info_style.border_color = Color(0.4, 0.8, 0.4, 1.0)  # Green accent border
	info_style.corner_radius_top_left = 12
	info_style.corner_radius_top_right = 12
	info_style.corner_radius_bottom_left = 12
	info_style.corner_radius_bottom_right = 12
	information_panel.add_theme_stylebox_override("panel", info_style)
	
	# Create information content
	var info_vbox = VBoxContainer.new()
	info_vbox.anchors_preset = Control.PRESET_FULL_RECT
	info_vbox.add_theme_constant_override("separation", 8)
	
	# Title label
	var title_label = Label.new()
	title_label.text = "INFORMATION INVENTORY"
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.modulate = Color.LIGHT_GREEN
	info_vbox.add_child(title_label)
	
	# Inventory content
	information_inventory_label = Label.new()
	information_inventory_label.name = "InventoryLabel"
	information_inventory_label.add_theme_font_size_override("font_size", 10)
	information_inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	information_inventory_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	info_vbox.add_child(information_inventory_label)
	
	information_panel.add_child(info_vbox)
	ui_canvas.add_child(information_panel)
	
	# Initialize display
	update_information_inventory_display()

func update_information_inventory_display():
	if not conversation_controller:
		information_inventory_label.text = "No information system available"
		return
	
	var inventory = conversation_controller.get_player_information_inventory()
	var total_count = conversation_controller.get_total_information_count()
	
	var display_text = "Total Items: %d\n\n" % total_count
	
	for info_type in ConversationController.InformationType.values():
		var type_name = conversation_controller.get_information_type_name(info_type)
		var items = inventory[info_type]
		
		display_text += "[color=cyan]%s (%d):[/color]\n" % [type_name, items.size()]
		
		if items.size() == 0:
			display_text += "  [color=gray]None acquired[/color]\n"
		else:
			for item in items:
				var title = item.get("title", "Unknown")
				var source = item.get("source_npc", "Unknown")
				display_text += "  • %s\n    [color=gray](from %s)[/color]\n" % [title, source]
		display_text += "\n"
	
	# Set as rich text
	information_inventory_label.text = display_text

func create_enhanced_conversation_ui() -> ConversationUI:
	# Create the enhanced conversation UI programmatically
	var ui = ConversationUI.new()
	ui.name = "ConversationUI"
	
	# Create enhanced UI structure (same as before but larger for information display)
	var background = Panel.new()
	background.name = "BackgroundPanel"
	background.size = Vector2(700, 650)  # Taller for objectives
	background.position = Vector2(1200, 250)  # Adjusted position
	
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
	
	var relationship_label = Label.new()
	relationship_label.name = "RelationshipStatus"
	relationship_label.add_theme_font_size_override("font_size", 11)
	relationship_label.modulate = Color.CYAN
	relationship_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	npc_info.add_child(relationship_label)
	
	vbox.add_child(npc_info)
	
	# Enhanced dialogue text area (slightly smaller to make room for objectives)
	var dialogue_text = RichTextLabel.new()
	dialogue_text.name = "DialogueText"
	dialogue_text.custom_minimum_size = Vector2(680, 180)
	dialogue_text.bbcode_enabled = true
	dialogue_text.scroll_following = true
	dialogue_text.selection_enabled = true
	vbox.add_child(dialogue_text)
	
	# Choice container
	var choice_container = VBoxContainer.new()
	choice_container.name = "ChoiceContainer"
	choice_container.add_theme_constant_override("separation", 8)
	vbox.add_child(choice_container)
	
	# Close button
	var close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "Close Conversation"
	close_button.custom_minimum_size = Vector2(150, 35)
	close_button.visible = false
	vbox.add_child(close_button)
	
	# Assemble structure
	background.add_child(vbox)
	ui.add_child(background)
	
	# Apply enhanced styling
	apply_enhanced_conversation_ui_styling(background)
	
	return ui

func apply_enhanced_conversation_ui_styling(background: Panel):
	# Enhanced styling for information-focused conversations
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.08, 0.08, 0.12, 0.98)
	style_box.border_width_left = 3
	style_box.border_width_right = 3
	style_box.border_width_top = 3
	style_box.border_width_bottom = 3
	style_box.border_color = Color(0.4, 0.6, 0.8, 1.0)
	style_box.corner_radius_top_left = 12
	style_box.corner_radius_top_right = 12
	style_box.corner_radius_bottom_left = 12
	style_box.corner_radius_bottom_right = 12
	
	# Enhanced shadow for information importance
	style_box.shadow_color = Color(0, 0, 0, 0.6)
	style_box.shadow_size = 10
	style_box.shadow_offset = Vector2(5, 5)
	
	background.add_theme_stylebox_override("panel", style_box)

func create_enhanced_test_npcs():
	# Create Captain Stone (Authority NPC) - Security Expert
	var authority_npc_scene = preload("res://scenes/NPCTest.tscn")
	var captain_stone = authority_npc_scene.instantiate()
	captain_stone.npc_name = "Captain Stone"
	captain_stone.archetype = SocialDNAManager.NPCArchetype.AUTHORITY
	captain_stone.position = Vector2(500, 400)
	add_child(captain_stone)
	npcs.append(captain_stone)
	
	# Create Dr. Wisdom (Intellectual NPC) - Research Director  
	var intellectual_npc_scene = preload("res://scenes/NPCTest.tscn")
	var dr_wisdom = intellectual_npc_scene.instantiate()
	dr_wisdom.npc_name = "Dr. Wisdom"
	dr_wisdom.archetype = SocialDNAManager.NPCArchetype.INTELLECTUAL
	dr_wisdom.position = Vector2(700, 400)
	add_child(dr_wisdom)
	npcs.append(dr_wisdom)
	
	# Create Commander Steele (Authority NPC) - Operations Chief
	var commander_npc_scene = preload("res://scenes/NPCTest.tscn")
	var commander_steele = commander_npc_scene.instantiate()
	commander_steele.npc_name = "Commander Steele"
	commander_steele.archetype = SocialDNAManager.NPCArchetype.AUTHORITY
	commander_steele.position = Vector2(900, 400)
	add_child(commander_steele)
	npcs.append(commander_steele)
	
	print("[MAIN] Created %d enhanced NPCs with specialized information assets:" % npcs.size())
	print("  • Captain Stone: Security codes, patrol routes, weapon cache locations")
	print("  • Dr. Wisdom: Research data, lab access, prototype locations")
	print("  • Commander Steele: Mission intel, comm codes, supply locations")

# =============================================================================
# ENHANCED CONVERSATION EVENT HANDLERS WITH INFORMATION SYSTEM
# =============================================================================

func _on_npc_clicked(npc: SocialNPC):
	print("[MAIN] NPC clicked: %s (%s)" % [npc.npc_name, get_npc_specialization(npc.npc_name)])

func get_npc_specialization(npc_name: String) -> String:
	match npc_name:
		"Captain Stone": return "Security Expert"
		"Dr. Wisdom": return "Research Director" 
		"Commander Steele": return "Operations Chief"
		_: return "Information Source"

func _on_conversation_requested(npc: SocialNPC, conversation_type: ConversationController.ConversationType):
	print("[MAIN] Information-focused conversation requested with %s: %s" % [npc.npc_name, get_conversation_type_name(conversation_type)])
	
	# Check if conversation is already active
	if conversation_controller.is_conversation_active():
		print("[MAIN] Conversation already active, ignoring request")
		return
	
	# Determine conversation objective based on NPC and available information
	var objective = determine_conversation_objective(npc, conversation_type)
	
	# Start the enhanced conversation UI
	conversation_ui.start_conversation_ui(npc, conversation_controller)
	
	# Start the conversation with objective context
	conversation_controller.start_conversation(npc, conversation_type, objective)

func determine_conversation_objective(npc: SocialNPC, conversation_type: ConversationController.ConversationType) -> String:
	# Determine what information the player might be seeking
	var trust_level = conversation_controller.get_npc_trust_level(npc)
	
	match conversation_type:
		ConversationController.ConversationType.QUICK_CHAT:
			return "Build rapport and assess information availability"
		
		ConversationController.ConversationType.TOPIC_DISCUSSION:
			match npc.npc_name:
				"Captain Stone":
					if trust_level >= 2.0:
						return "Obtain security access codes"
					elif trust_level >= 1.0:
						return "Request patrol schedule information"
					else:
						return "Learn about facility security"
				"Dr. Wisdom":
					if trust_level >= 2.0:
						return "Access classified research data"
					elif trust_level >= 1.0:
						return "Request laboratory access"
					else:
						return "Discuss current research projects"
				"Commander Steele":
					if trust_level >= 2.0:
						return "Obtain supply cache locations"
					elif trust_level >= 1.0:
						return "Request mission briefing"
					else:
						return "Understand current operations"
				_:
					return "Gather useful information"
		
		ConversationController.ConversationType.DEEP_CONVERSATION:
			match npc.npc_name:
				"Captain Stone":
					return "Access highest-level security information"
				"Dr. Wisdom":
					return "Obtain prototype locations and classified data"
				"Commander Steele":
					return "Get complete operational intelligence"
				_:
					return "Access most valuable information"
		_:
			return "General conversation"

# =============================================================================
# NEW: INFORMATION SYSTEM EVENT HANDLERS
# =============================================================================

func _on_information_gained(info_type: ConversationController.InformationType, info_data: Dictionary):
	print("[MAIN] 🎉 INFORMATION ACQUIRED! 🎉")
	print("  Type: %s" % conversation_controller.get_information_type_name(info_type))
	print("  Title: %s" % info_data.get("title", "Unknown"))
	print("  Description: %s" % info_data.get("description", "No description"))
	print("  Source: %s" % info_data.get("source_npc", "Unknown"))
	print("  Value ID: %s" % info_data.get("id", "Unknown"))
	
	# Update information inventory display
	update_information_inventory_display()
	
	# Show success notification
	show_information_gained_notification(info_data)
	
	# Check for special information combinations or achievements
	check_information_achievements(info_type, info_data)

func _on_information_request_failed(reason: String, npc_name: String):
	print("[MAIN] ❌ Information request failed with %s: %s" % [npc_name, reason])
	
	# Show failure notification
	show_information_failure_notification(npc_name, reason)

func _on_objective_completed(objective: String, reward: Dictionary):
	print("[MAIN] 🏆 OBJECTIVE COMPLETED: %s" % objective)
	print("  Reward: %s" % str(reward))
	
	# Show objective completion notification
	show_objective_completion_notification(objective, reward)

func show_information_gained_notification(info_data: Dictionary):
	# Create a prominent success notification
	var notification_panel = Panel.new()
	notification_panel.size = Vector2(450, 120)
	notification_panel.position = Vector2(400, 50)
	
	var notification_label = Label.new()
	notification_label.text = "🎉 INFORMATION ACQUIRED! 🎉\n\n📋 %s\n%s" % [
		info_data.get("title", "Unknown Information"),
		info_data.get("description", "")
	]
	notification_label.anchors_preset = Control.PRESET_FULL_RECT
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notification_label.add_theme_font_size_override("font_size", 12)
	notification_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	# Style the success notification
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.8, 0.2, 0.95)  # Bright green
	style_box.border_color = Color(1.0, 1.0, 0.5, 1.0)  # Gold border
	style_box.border_width_left = 3
	style_box.border_width_right = 3
	style_box.border_width_top = 3
	style_box.border_width_bottom = 3
	style_box.corner_radius_top_left = 12
	style_box.corner_radius_top_right = 12
	style_box.corner_radius_bottom_left = 12
	style_box.corner_radius_bottom_right = 12
	
	# Add glow effect
	style_box.shadow_color = Color(0.2, 0.8, 0.2, 0.8)
	style_box.shadow_size = 15
	style_box.shadow_offset = Vector2(0, 0)
	
	notification_panel.add_theme_stylebox_override("panel", style_box)
	notification_panel.add_child(notification_label)
	ui_canvas.add_child(notification_panel)
	
	# Animate and remove
	var tween = create_tween()
	tween.parallel().tween_property(notification_panel, "position:y", notification_panel.position.y - 20, 4.0)
	tween.parallel().tween_property(notification_panel, "modulate:a", 0.0, 4.0)
	tween.tween_callback(notification_panel.queue_free)

func show_information_failure_notification(npc_name: String, reason: String):
	# Create failure notification
	var notification_panel = Panel.new()
	notification_panel.size = Vector2(400, 100)
	notification_panel.position = Vector2(400, 100)
	
	var notification_label = Label.new()
	notification_label.text = "❌ Information Request Failed\n\n%s refused: %s" % [npc_name, reason]
	notification_label.anchors_preset = Control.PRESET_FULL_RECT
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notification_label.add_theme_font_size_override("font_size", 11)
	notification_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	# Style the failure notification
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
	
	# Auto-remove
	var tween = create_tween()
	tween.tween_interval(3.0)  # Fixed: tween_interval instead of tween_delay
	tween.tween_property(notification_panel, "modulate:a", 0.0, 1.0)
	tween.tween_callback(notification_panel.queue_free)

func show_objective_completion_notification(objective: String, reward: Dictionary):
	# Create objective completion notification
	var notification_panel = Panel.new()
	notification_panel.size = Vector2(500, 80)
	notification_panel.position = Vector2(400, 150)
	
	var notification_label = Label.new()
	notification_label.text = "🏆 OBJECTIVE COMPLETED!\n%s" % objective
	notification_label.anchors_preset = Control.PRESET_FULL_RECT
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notification_label.add_theme_font_size_override("font_size", 14)
	
	# Style with gold theme
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.8, 0.6, 0.2, 0.95)  # Gold
	style_box.border_color = Color(1.0, 0.8, 0.3, 1.0)
	style_box.border_width_left = 3
	style_box.border_width_right = 3
	style_box.border_width_top = 3
	style_box.border_width_bottom = 3
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	notification_panel.add_theme_stylebox_override("panel", style_box)
	
	notification_panel.add_child(notification_label)
	ui_canvas.add_child(notification_panel)
	
	# Animate
	var tween = create_tween()
	tween.tween_interval(3.0)  # Fixed: tween_interval instead of tween_delay
	tween.tween_property(notification_panel, "modulate:a", 0.0, 1.0)
	tween.tween_callback(notification_panel.queue_free)

func check_information_achievements(info_type: ConversationController.InformationType, info_data: Dictionary):
	# Check for interesting information combinations or achievements
	var total_info = conversation_controller.get_total_information_count()
	
	# Achievement: First Information
	if total_info == 1:
		show_achievement_notification("📋 First Information Acquired!", "You've obtained your first piece of valuable information!")
	
	# Achievement: Security Expert
	var security_count = conversation_controller.get_information_count_by_type(ConversationController.InformationType.ACCESS) + conversation_controller.get_information_count_by_type(ConversationController.InformationType.SECURITY)
	if security_count >= 3:
		show_achievement_notification("🔐 Security Expert!", "You've mastered the art of acquiring security information!")
	
	# Achievement: Research Partner
	var research_count = conversation_controller.get_information_count_by_type(ConversationController.InformationType.KNOWLEDGE)
	if research_count >= 2:
		show_achievement_notification("🧪 Research Partner!", "Dr. Wisdom trusts you with classified research!")
	
	# Achievement: Intelligence Operative
	var intel_count = conversation_controller.get_information_count_by_type(ConversationController.InformationType.INTELLIGENCE)
	if intel_count >= 2:
		show_achievement_notification("🎯 Intelligence Operative!", "You've become skilled at gathering operational intelligence!")
	
	# Special combinations
	if conversation_controller.has_information("research_lab_code_alpha77delta") and conversation_controller.has_information("lab_access_beta44gamma"):
		show_achievement_notification("🔬 Lab Access Master!", "You have access to both research facilities!")

func show_achievement_notification(title: String, description: String):
	# Create achievement notification
	var notification_panel = Panel.new()
	notification_panel.size = Vector2(400, 100)
	notification_panel.position = Vector2(750, 200)
	
	var notification_label = Label.new()
	notification_label.text = "%s\n%s" % [title, description]
	notification_label.anchors_preset = Control.PRESET_FULL_RECT
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notification_label.add_theme_font_size_override("font_size", 11)
	notification_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	# Style with purple achievement theme
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.5, 0.3, 0.8, 0.95)  # Purple
	style_box.border_color = Color(0.7, 0.5, 1.0, 1.0)
	style_box.border_width_left = 3
	style_box.border_width_right = 3
	style_box.border_width_top = 3
	style_box.border_width_bottom = 3
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	
	# Add glow effect
	style_box.shadow_color = Color(0.5, 0.3, 0.8, 0.6)
	style_box.shadow_size = 12
	style_box.shadow_offset = Vector2(0, 0)
	
	notification_panel.add_theme_stylebox_override("panel", style_box)
	notification_panel.add_child(notification_label)
	ui_canvas.add_child(notification_panel)
	
	# Animate with bounce effect
	var tween = create_tween()
	tween.parallel().tween_property(notification_panel, "scale", Vector2(1.1, 1.1), 0.3)
	tween.parallel().tween_property(notification_panel, "position:y", notification_panel.position.y - 10, 0.3)
	tween.parallel().tween_property(notification_panel, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_interval(2.5)  # Fixed: tween_interval instead of tween_delay
	tween.tween_property(notification_panel, "modulate:a", 0.0, 1.0)
	tween.tween_callback(notification_panel.queue_free)

# =============================================================================
# EXISTING EVENT HANDLERS (Enhanced for information context)
# =============================================================================

func _on_trust_gate_blocked(npc: SocialNPC, required_trust: String, current_trust: String):
	print("[MAIN] Information trust gate blocked for %s - Need: %s, Have: %s" % [npc.npc_name, required_trust, current_trust])
	show_enhanced_trust_gate_notification(npc, required_trust, current_trust)

func show_enhanced_trust_gate_notification(npc: SocialNPC, required_trust: String, current_trust: String):
	# Create enhanced trust gate notification with information context
	var notification = Label.new()
	var info_hint = get_information_hint_for_npc(npc.npc_name)
	notification.text = "🔒 Information Locked!\nNeed %s Trust (Have: %s)\n\n💡 %s" % [
		required_trust, current_trust, info_hint
	]
	notification.position = npc.position + Vector2(-80, -180)
	notification.size = Vector2(160, 80)
	notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification.add_theme_font_size_override("font_size", 9)
	notification.modulate = Color.ORANGE
	notification.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(notification)
	
	# Enhanced animation
	var tween = create_tween()
	tween.parallel().tween_property(notification, "position:y", notification.position.y - 40, 4.0)
	tween.parallel().tween_property(notification, "modulate:a", 0.0, 4.0)
	tween.tween_callback(notification.queue_free)

func get_information_hint_for_npc(npc_name: String) -> String:
	match npc_name:
		"Captain Stone":
			return "Build trust for security codes & patrol info"
		"Dr. Wisdom":
			return "Build trust for research data & lab access"
		"Commander Steele":
			return "Build trust for mission intel & supplies"
		_:
			return "Build trust for valuable information"

func _on_trust_gate_encountered(npc: SocialNPC, required_trust: String, current_trust: String):
	print("[MAIN] Information trust gate encountered in conversation")
	# The UI will handle the detailed display

func _on_conversation_failed(reason: String, retry_info: Dictionary):
	print("[MAIN] Information-focused conversation failed: %s" % reason)
	
	# Show enhanced failure notification
	var failure_text = "Information Request Failed: %s" % reason
	if retry_info.has("information_blocked"):
		failure_text += "\nBlocked: %s" % retry_info.information_blocked
	
	show_conversation_failure_notification(failure_text, retry_info)

func show_conversation_failure_notification(reason: String, retry_info: Dictionary):
	# Enhanced failure notification with information context
	var notification_panel = Panel.new()
	notification_panel.size = Vector2(450, 140)
	notification_panel.position = Vector2(400, 100)
	
	var notification_text = "⚠️ Information Request Failed!\n%s" % reason
	
	var suggestions = retry_info.get("retry_suggestions", [])
	if suggestions.size() > 0:
		notification_text += "\n\n💡 Try:\n"
		for suggestion in suggestions.slice(0, 2):  # Show first 2 suggestions
			notification_text += "• %s\n" % suggestion
	
	var notification_label = Label.new()
	notification_label.text = notification_text
	notification_label.anchors_preset = Control.PRESET_FULL_RECT
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notification_label.add_theme_font_size_override("font_size", 10)
	notification_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	# Style the failure notification
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
	tween.tween_interval(5.0)  # Fixed: tween_interval instead of tween_delay
	tween.tween_property(notification_panel, "modulate:a", 0.0, 1.0)
	tween.tween_callback(notification_panel.queue_free)

func _on_conversation_ui_closed():
	print("[MAIN] Enhanced information conversation UI closed")
	
	# End any active conversation
	if conversation_controller.is_conversation_active():
		conversation_controller.end_conversation({"outcome": ConversationController.ConversationOutcome.INTERRUPTED})
	
	# Update information display in case new info was gained
	update_information_inventory_display()

# =============================================================================
# ENHANCED DEBUG AND TESTING WITH INFORMATION SYSTEM
# =============================================================================

func _input(event):
	# Enhanced debug keybindings for information system
	if event.is_action_pressed("ui_select"):  # Space key
		print_enhanced_debug_info_with_information()
	elif event.is_action_pressed("ui_home"):  # Home key
		print_enhanced_usage_instructions()
	elif event.is_action_pressed("ui_page_up"):  # Page Up - Show relationship and information summary
		print_enhanced_relationship_and_information_summary()
	elif event.is_action_pressed("ui_page_down"):  # Page Down - Show information inventory
		print_information_inventory_details()
	elif event.is_action_pressed("ui_end"):  # End key - Grant test information
		grant_test_information()

func print_enhanced_debug_info_with_information():
	print("\n=== PHASE 2C ENHANCED DEBUG INFO WITH INFORMATION SYSTEM ===")
	
	# Social DNA status
	print("Social DNA Manager Status:")
	var percentages = SocialDNAManager.get_social_percentages()
	for social_type in SocialDNAManager.social_dna:
		var type_name = SocialDNAManager.get_social_type_name(social_type)
		var value = SocialDNAManager.social_dna[social_type]
		var percentage = percentages[social_type]
		print("  %s: %d (%.1f%%)" % [type_name, value, percentage])
	
	# Information inventory summary
	if conversation_controller:
		var total_info = conversation_controller.get_total_information_count()
		print("\nInformation Inventory Summary:")
		print("  Total Information Items: %d" % total_info)
		
		var inventory = conversation_controller.get_player_information_inventory()
		for info_type in inventory:
			var type_name = conversation_controller.get_information_type_name(info_type)
			var count = inventory[info_type].size()
			print("  %s: %d items" % [type_name, count])
	
	# Enhanced NPC status with information context
	print("\nNPC Status with Trust & Information Access:")
	for npc in npcs:
		var compat = SocialDNAManager.calculate_compatibility(npc.archetype)
		var trust = conversation_controller.get_npc_trust_level(npc)
		var trust_name = conversation_controller.get_trust_level_name(trust)
		var summary = conversation_controller.get_relationship_summary(npc)
		var info_shared = conversation_controller.get_information_from_npc(npc.npc_name).size()
		var specialization = get_npc_specialization(npc.npc_name)
		
		print("  %s (%s):" % [npc.npc_name, specialization])
		print("    Compatibility: %.2f (%s)" % [compat, SocialDNAManager.get_compatibility_description(compat)])
		print("    Trust: %.2f (%s)" % [trust, trust_name])
		print("    Success Rate: %.1f%% (%d/%d interactions)" % [
			summary.success_rate, summary.successful_interactions, summary.total_interactions
		])
		print("    Information Shared: %d items" % info_shared)
		
		# Show available conversation types
		var available = summary.available_conversations
		var available_names = []
		for conv_type in available:
			available_names.append(get_conversation_type_name(conv_type))
		print("    Available: [%s]" % ", ".join(available_names))
	
	print("==========================================\n")

func print_enhanced_relationship_and_information_summary():
	print("\n=== ENHANCED RELATIONSHIP & INFORMATION SUMMARY ===")
	
	for npc in npcs:
		var summary = conversation_controller.get_relationship_summary(npc)
		var info_from_npc = conversation_controller.get_information_from_npc(npc.npc_name)
		
		print("%s (%s):" % [npc.npc_name.to_upper(), get_npc_specialization(npc.npc_name)])
		print("  Trust: %s (%.2f)" % [summary.trust_name, summary.trust_level])
		print("  Interactions: %d total, %d successful (%.1f%%)" % [
			summary.total_interactions, 
			summary.successful_interactions, 
			summary.success_rate
		])
		print("  Last Outcome: %s" % summary.last_outcome)
		
		# Information sharing history
		print("  Information Shared (%d items):" % info_from_npc.size())
		if info_from_npc.size() == 0:
			print("    None yet")
		else:
			for info_item in info_from_npc:
				print("    📋 %s" % info_item.get("title", "Unknown"))
		
		# Available conversations
		var available_names = []
		for conv_type in summary.available_conversations:
			available_names.append(get_conversation_type_name(conv_type))
		print("  Available Conversations: %s" % ", ".join(available_names))
		print("")
	
	print("========================================\n")

func print_information_inventory_details():
	if not conversation_controller:
		print("No conversation controller available")
		return
	
	print("\n=== DETAILED INFORMATION INVENTORY ===")
	
	var inventory = conversation_controller.get_player_information_inventory()
	var total_count = conversation_controller.get_total_information_count()
	
	print("Total Information Items: %d" % total_count)
	print("")
	
	for info_type in inventory:
		var type_name = conversation_controller.get_information_type_name(info_type)
		var items = inventory[info_type]
		
		print("%s (%d items):" % [type_name, items.size()])
		if items.size() == 0:
			print("  No items in this category")
		else:
			for item in items:
				print("  📋 %s" % item.get("title", "Unknown"))
				print("      Source: %s" % item.get("source_npc", "Unknown"))
				print("      ID: %s" % item.get("id", "Unknown"))
				print("      Description: %s" % item.get("description", "No description"))
				var acquired_time = Time.get_datetime_dict_from_unix_time(item.get("acquired_at", 0))
				print("      Acquired: %02d:%02d" % [acquired_time.hour, acquired_time.minute])
				print("")
		print("")
	
	print("=====================================\n")

func grant_test_information():
	# Debug function to grant test information for testing
	print("[DEBUG] Granting test information...")
	
	if not conversation_controller:
		print("No conversation controller available")
		return
	
	# Simulate information gain from each NPC
	var test_info = [
		{
			"type": ConversationController.InformationType.ACCESS,
			"data": {
				"id": "test_security_code_123",
				"title": "Test Security Code",
				"description": "Debug access code for testing",
				"source_npc": "Captain Stone",
				"acquired_at": Time.get_unix_time_from_system(),
				"trust_level_when_acquired": 2.0
			}
		},
		{
			"type": ConversationController.InformationType.KNOWLEDGE,
			"data": {
				"id": "test_research_data_456",
				"title": "Test Research Data",
				"description": "Debug research information for testing",
				"source_npc": "Dr. Wisdom", 
				"acquired_at": Time.get_unix_time_from_system(),
				"trust_level_when_acquired": 2.0
			}
		}
	]
	
	for info in test_info:
		conversation_controller.information_gained.emit(info.type, info.data)
	
	print("[DEBUG] Test information granted!")

func print_enhanced_usage_instructions():
	print("\n=== PHASE 2C ENHANCED USAGE INSTRUCTIONS ===")
	print("GOAL-DRIVEN INFORMATION SYSTEM:")
	print("• Left-click NPCs: Opens conversation selection menu")
	print("• Each NPC specializes in different types of information:")
	print("  - Captain Stone: Security codes, patrol routes, weapon caches")
	print("  - Dr. Wisdom: Research data, lab access, prototype locations")
	print("  - Commander Steele: Mission intel, comm codes, supply locations")
	print("• Right-click NPCs: Show debug info including information assets")
	print("")
	print("INFORMATION ACQUISITION:")
	print("• Conversations have clear objectives and rewards")
	print("• Higher trust levels unlock more valuable information")
	print("• Compatible social approaches increase success chances")
	print("• Failed information requests provide specific retry suggestions")
	print("• Information inventory tracks all acquired intel")
	print("")
	print("CONVERSATION TYPES & INFORMATION:")
	print("• Quick Chats: Build rapport, hints about available information")
	print("• Topic Discussions: Request specific information based on trust")
	print("• Deep Conversations: Access highest-value intelligence")
	print("• Trust gates clearly show what information is locked and why")
	print("")
	print("VISUAL FEEDBACK ENHANCEMENTS:")
	print("• 📋 Icon: Information request available")
	print("• 💡 Icon: Information hint or suggestion")
	print("• 🟢🟡🟠🔴 Icons: Success/risk indicators for information requests")
	print("• Information inventory panel (top right) tracks all acquired intel")
	print("• Success notifications show exactly what information was gained")
	print("")
	print("ENHANCED DEBUG KEYS:")
	print("• SPACE: Enhanced debug info with information system status")
	print("• HOME: Show these enhanced instructions")
	print("• PAGE UP: Detailed relationship summary with information history")
	print("• PAGE DOWN: Complete information inventory details")
	print("• END: Grant test information for debugging")
	print("• ESC (in conversation): Close conversation UI")
	print("")
	print("TESTING SCENARIOS:")
	print("1. Build trust with Captain Stone → Request security codes")
	print("2. Use compatible approaches → See higher information success rates")
	print("3. Try information requests below trust threshold → See trust gates")
	print("4. Fail information requests → Get specific retry suggestions")
	print("5. Acquire multiple information types → Unlock achievements")
	print("6. Check information inventory → See persistent intel collection")
	print("===================================================\n")

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
# SYSTEM INTEGRATION AND STATUS
# =============================================================================

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("[MAIN] Application closing - Phase 2C session complete")
		
		# Print final session summary with information
		print("\n=== FINAL SESSION SUMMARY WITH INFORMATION ===")
		
		if conversation_controller:
			var total_info = conversation_controller.get_total_information_count()
			print("Total Information Acquired: %d items" % total_info)
			
			if total_info > 0:
				var inventory = conversation_controller.get_player_information_inventory()
				for info_type in inventory:
					var type_name = conversation_controller.get_information_type_name(info_type)
					var count = inventory[info_type].size()
					print("  %s: %d" % [type_name, count])
			print("")
		
		# NPC relationship summary
		for npc in npcs:
			var summary = conversation_controller.get_relationship_summary(npc)
			var info_count = conversation_controller.get_information_from_npc(npc.npc_name).size()
			print("%s: Trust %s (%.2f), %d interactions, %.1f%% success, %d info shared" % [
				npc.npc_name,
				summary.trust_name,
				summary.trust_level,
				summary.total_interactions,
				summary.success_rate,
				info_count
			])
		print("===========================================")
		
		get_tree().quit()

func get_enhanced_system_status() -> Dictionary:
	var status = {
		"phase": "2C - Goal-Driven Information System",
		"conversation_controller_ready": is_instance_valid(conversation_controller),
		"conversation_ui_ready": is_instance_valid(conversation_ui),
		"information_panel_ready": is_instance_valid(information_panel),
		"active_conversation": conversation_controller.is_conversation_active() if conversation_controller else false,
		"npc_count": npcs.size(),
		"social_dna_total": SocialDNAManager.get_total_social_strength(),
		"trust_gates_active": true,
		"failure_states_active": true,
		"relationship_tracking": true,
		"information_tracking": true,
		"objective_system": true
	}
	
	if conversation_controller:
		status.total_information_count = conversation_controller.get_total_information_count()
		status.information_inventory = conversation_controller.get_player_information_inventory()
	
	return status
