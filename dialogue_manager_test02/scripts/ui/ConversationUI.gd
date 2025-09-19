# =============================================================================
# ENHANCED CONVERSATION UI - Phase 2C: Information Objectives & Rewards
# File: scripts/ui/ConversationUI.gd (REPLACE existing file)
# Adds information objectives display, success feedback, and inventory integration
# =============================================================================

extends Control
class_name ConversationUI

# UI Components (existing)
@onready var background_panel: Panel = $BackgroundPanel
@onready var npc_info: VBoxContainer = $BackgroundPanel/VBox/NPCInfo
@onready var npc_name_label: Label = $BackgroundPanel/VBox/NPCInfo/NPCName
@onready var npc_status_label: Label = $BackgroundPanel/VBox/NPCInfo/NPCStatus
@onready var relationship_label: Label = $BackgroundPanel/VBox/NPCInfo/RelationshipStatus
@onready var dialogue_text: RichTextLabel = $BackgroundPanel/VBox/DialogueText
@onready var choice_container: VBoxContainer = $BackgroundPanel/VBox/ChoiceContainer
@onready var close_button: Button = $BackgroundPanel/VBox/CloseButton

# NEW: Information system UI components
var objective_panel: Panel
var objective_label: Label
var information_feedback_label: Label
var available_info_label: Label

# State (existing + new)
var current_npc: SocialNPC = null
var conversation_controller: ConversationController = null
var choice_buttons: Array[Button] = []
var is_trust_gate_mode: bool = false
var is_failure_mode: bool = false

# NEW: Information state
var current_objective: String = ""
var available_information: Dictionary = {}
var information_gained_this_conversation: Array = []

signal conversation_ui_closed()

func _ready():
	visible = false
	close_button.pressed.connect(_on_close_pressed)
	setup_enhanced_ui_styling()

func setup_enhanced_ui_styling():
	# Enhanced background panel (taller for information display)
	background_panel.custom_minimum_size = Vector2(700, 650)  # Taller for objectives
	
	# Create information objective panel
	create_information_objective_panel()
	
	# Style the dialogue text
	dialogue_text.bbcode_enabled = true
	dialogue_text.custom_minimum_size = Vector2(680, 180)  # Slightly shorter to make room
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	# Center the UI on screen
	anchors_preset = Control.PRESET_CENTER
	position = Vector2(-350, -325)  # Adjusted for larger size

func create_information_objective_panel():
	# Create objective panel at the top
	objective_panel = Panel.new()
	objective_panel.name = "ObjectivePanel"
	objective_panel.custom_minimum_size = Vector2(680, 80)
	
	# Style the objective panel
	var objective_style = StyleBoxFlat.new()
	objective_style.bg_color = Color(0.1, 0.2, 0.4, 0.8)  # Dark blue tint
	objective_style.border_width_left = 2
	objective_style.border_width_right = 2
	objective_style.border_width_top = 2
	objective_style.border_width_bottom = 2
	objective_style.border_color = Color(0.3, 0.5, 0.9, 1.0)
	objective_style.corner_radius_top_left = 8
	objective_style.corner_radius_top_right = 8
	objective_style.corner_radius_bottom_left = 8
	objective_style.corner_radius_bottom_right = 8
	objective_panel.add_theme_stylebox_override("panel", objective_style)
	
	# Create objective content
	var objective_vbox = VBoxContainer.new()
	objective_vbox.anchors_preset = Control.PRESET_FULL_RECT
	objective_vbox.add_theme_constant_override("separation", 4)
	
	# Objective title and description
	objective_label = Label.new()
	objective_label.name = "ObjectiveLabel"
	objective_label.add_theme_font_size_override("font_size", 12)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	objective_vbox.add_child(objective_label)
	
	# Available information display
	available_info_label = Label.new()
	available_info_label.name = "AvailableInfoLabel"
	available_info_label.add_theme_font_size_override("font_size", 10)
	available_info_label.modulate = Color.LIGHT_GRAY
	available_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	available_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	objective_vbox.add_child(available_info_label)
	
	objective_panel.add_child(objective_vbox)
	
	# Insert at the beginning of the VBox (before NPC info)
	var main_vbox = background_panel.get_node("VBox")
	main_vbox.add_child(objective_panel)
	main_vbox.move_child(objective_panel, 0)

# =============================================================================
# ENHANCED CONVERSATION FLOW WITH INFORMATION OBJECTIVES
# =============================================================================

func start_conversation_ui(npc: SocialNPC, controller: ConversationController):
	current_npc = npc
	conversation_controller = controller
	is_trust_gate_mode = false
	is_failure_mode = false
	information_gained_this_conversation = []
	
	# Connect to all conversation events
	if conversation_controller:
		_connect_conversation_signals()
	
	# Update all UI components
	update_npc_info()
	update_objective_display()
	
	# Show the UI
	visible = true
	print("[UI] Enhanced Information-focused UI opened with %s" % npc.npc_name)

func _connect_conversation_signals():
	# Disconnect any existing connections first
	_disconnect_conversation_signals()
	
	# Connect to conversation events
	conversation_controller.conversation_started.connect(_on_conversation_started)
	conversation_controller.conversation_continued.connect(_on_conversation_continued)
	conversation_controller.conversation_ended.connect(_on_conversation_ended)
	conversation_controller.conversation_failed.connect(_on_conversation_failed)
	conversation_controller.trust_gate_encountered.connect(_on_trust_gate_encountered)
	conversation_controller.social_dna_updated.connect(_on_social_dna_updated)
	conversation_controller.relationship_changed.connect(_on_relationship_changed)
	
	# NEW: Information-specific signals
	conversation_controller.information_gained.connect(_on_information_gained)
	conversation_controller.information_request_failed.connect(_on_information_request_failed)
	conversation_controller.objective_completed.connect(_on_objective_completed)

func _disconnect_conversation_signals():
	if not conversation_controller:
		return
		
	# Safely disconnect existing signals
	if conversation_controller.conversation_started.is_connected(_on_conversation_started):
		conversation_controller.conversation_started.disconnect(_on_conversation_started)
	if conversation_controller.conversation_continued.is_connected(_on_conversation_continued):
		conversation_controller.conversation_continued.disconnect(_on_conversation_continued)
	if conversation_controller.conversation_ended.is_connected(_on_conversation_ended):
		conversation_controller.conversation_ended.disconnect(_on_conversation_ended)
	if conversation_controller.conversation_failed.is_connected(_on_conversation_failed):
		conversation_controller.conversation_failed.disconnect(_on_conversation_failed)
	if conversation_controller.trust_gate_encountered.is_connected(_on_trust_gate_encountered):
		conversation_controller.trust_gate_encountered.disconnect(_on_trust_gate_encountered)
	if conversation_controller.social_dna_updated.is_connected(_on_social_dna_updated):
		conversation_controller.social_dna_updated.disconnect(_on_social_dna_updated)
	if conversation_controller.relationship_changed.is_connected(_on_relationship_changed):
		conversation_controller.relationship_changed.disconnect(_on_relationship_changed)
	
	# NEW: Information signals
	if conversation_controller.information_gained.is_connected(_on_information_gained):
		conversation_controller.information_gained.disconnect(_on_information_gained)
	if conversation_controller.information_request_failed.is_connected(_on_information_request_failed):
		conversation_controller.information_request_failed.disconnect(_on_information_request_failed)
	if conversation_controller.objective_completed.is_connected(_on_objective_completed):
		conversation_controller.objective_completed.disconnect(_on_objective_completed)

func update_objective_display():
	if not current_npc or not conversation_controller:
		objective_label.text = "🎯 OBJECTIVE: Build rapport"
		available_info_label.text = ""
		return
	
	# Get available information for this NPC
	var trust_level = conversation_controller.get_npc_trust_level(current_npc)
	var compatibility = SocialDNAManager.calculate_compatibility(current_npc.archetype)
	
	# This would come from ConversationData, but we'll simulate it here
	available_information = get_simulated_available_info(trust_level, compatibility)
	
	# Set objective based on available information
	if available_information.size() > 0:
		var info_names = []
		for info_key in available_information:
			var info_data = available_information[info_key]
			info_names.append(info_data.get("title", info_key))
		
		objective_label.text = "🎯 OBJECTIVE: Obtain valuable information"
		
		if info_names.size() <= 3:
			available_info_label.text = "💡 Available: %s" % ", ".join(info_names)
		else:
			available_info_label.text = "💡 Multiple information sources available"
	else:
		objective_label.text = "🎯 OBJECTIVE: Build trust to unlock information"
		available_info_label.text = "🔒 No information available at current trust level"
	
	# Color coding based on availability
	if available_information.size() > 0:
		objective_label.modulate = Color.LIGHT_GREEN
		available_info_label.modulate = Color.CYAN
	else:
		objective_label.modulate = Color.ORANGE
		available_info_label.modulate = Color.GRAY

func get_simulated_available_info(trust_level: float, compatibility: float) -> Dictionary:
	# Simulate the information that would be available
	# This mirrors the logic from ConversationData
	var available = {}
	
	match current_npc.npc_name:
		"Captain Stone":
			if trust_level >= 0.0:
				available["facility_layout"] = {"title": "Facility Layout", "info_type": "location"}
			if trust_level >= 1.0:
				available["patrol_schedules"] = {"title": "Patrol Schedules", "info_type": "security"}
			if trust_level >= 2.0:
				available["security_codes"] = {"title": "Security Codes", "info_type": "access"}
			if trust_level >= 2.5:
				available["weapon_cache"] = {"title": "Weapon Cache Location", "info_type": "location"}
		
		"Dr. Wisdom":
			if trust_level >= 0.0:
				available["research_summary"] = {"title": "Research Summary", "info_type": "knowledge"}
			if trust_level >= 1.0:
				available["lab_access"] = {"title": "Lab Access Codes", "info_type": "access"}
			if trust_level >= 2.0:
				available["classified_projects"] = {"title": "Classified Research", "info_type": "knowledge"}
			if trust_level >= 2.5:
				available["prototype_location"] = {"title": "Prototype Storage", "info_type": "location"}
		
		"Commander Steele":
			if trust_level >= 1.0:
				available["mission_brief"] = {"title": "Mission Briefing", "info_type": "intelligence"}
			if trust_level >= 1.5:
				available["comm_frequencies"] = {"title": "Communication Codes", "info_type": "access"}
			if trust_level >= 2.0:
				available["supply_caches"] = {"title": "Supply Locations", "info_type": "location"}
	
	return available

# =============================================================================
# ENHANCED EVENT HANDLERS WITH INFORMATION FEEDBACK
# =============================================================================

func _on_conversation_started(npc: SocialNPC, opening_line: String):
	print("[UI] Conversation started: %s" % opening_line)
	
	# Enhanced opening display with information context
	dialogue_text.text = "[b][color=lightgreen]%s:[/color][/b]\n%s" % [npc.npc_name, opening_line]
	
	clear_choice_buttons()

func _on_conversation_continued(npc_line: String, player_options: Array):
	print("[UI] Conversation continued - NPC: '%s', Options: %d" % [npc_line, player_options.size()])
	
	# Update dialogue text if there's an NPC line
	if npc_line != "":
		var current_text = dialogue_text.text
		dialogue_text.text = current_text + "\n\n[b][color=lightgreen]%s:[/color][/b]\n%s" % [current_npc.npc_name, npc_line]
	
	# Create enhanced choice buttons with information indicators
	if player_options.size() > 0:
		create_enhanced_choice_buttons(player_options)
	else:
		clear_choice_buttons()
		close_button.visible = true

func _on_conversation_ended(outcome: Dictionary):
	print("[UI] Conversation ended - Outcome: %s" % outcome.get("outcome", "unknown"))
	
	# Enhanced ending summary with information results
	var summary_text = "\n\n[i][color=gray]--- Conversation Complete ---"
	
	var outcome_value = outcome.get("outcome", "unknown")
	var outcome_color = get_enhanced_outcome_color(outcome_value)
	summary_text += "\n[color=%s]Outcome: %s[/color]" % [outcome_color, str(outcome_value).capitalize()]
	
	# Information-specific feedback
	if outcome_value == ConversationController.ConversationOutcome.INFORMATION_GAINED:
		summary_text += "\n[b][color=lightgreen]✅ Information Successfully Obtained![/color][/b]"
		
		# Show what information was gained
		if information_gained_this_conversation.size() > 0:
			summary_text += "\n[color=cyan]New Information:[/color]"
			for info_item in information_gained_this_conversation:
				summary_text += "\n  📋 %s" % info_item.get("title", "Unknown")
	elif outcome_value == ConversationController.ConversationOutcome.TRUST_GATE_BLOCKED:
		summary_text += "\n[color=orange]🔒 Information Blocked - Need %s Trust[/color]" % outcome.get("required_trust", "Higher")
		summary_text += "\n[color=yellow]💡 %s[/color]" % outcome.get("suggestion", "Build trust first")
	elif outcome_value == ConversationController.ConversationOutcome.FAILURE:
		summary_text += "\n[color=red]❌ Information Request Failed[/color]"
		if outcome.has("information_request"):
			summary_text += "\n[color=orange]Failed to obtain: %s[/color]" % outcome.information_request.get("request", "information")
	
	# Standard outcome information
	if outcome.has("turns_completed"):
		summary_text += "\nTurns: %d" % outcome.turns_completed
	
	if outcome.has("final_trust") and outcome.has("trust_name"):
		summary_text += "\nFinal Trust: %s (%.1f)" % [outcome.trust_name, outcome.final_trust]
	
	if outcome.has("relationship_changes"):
		var change = outcome.relationship_changes
		if change != 0:
			var change_color = "lightgreen" if change > 0 else "orange"
			summary_text += "\n[color=%s]Trust Change: %s%.2f[/color]" % [
				change_color, 
				"+" if change > 0 else "", 
				change
			]
	
	summary_text += "[/color][/i]"
	
	dialogue_text.text += summary_text
	
	# Update objective display to reflect results
	update_post_conversation_objective()
	
	clear_choice_buttons()
	close_button.visible = true

func update_post_conversation_objective():
	if information_gained_this_conversation.size() > 0:
		objective_label.text = "🎉 OBJECTIVE COMPLETED: Information Obtained!"
		objective_label.modulate = Color.GOLD
		
		var info_names = []
		for info in information_gained_this_conversation:
			info_names.append(info.get("title", "Unknown"))
		
		available_info_label.text = "✅ Gained: %s" % ", ".join(info_names)
		available_info_label.modulate = Color.LIGHT_GREEN
	else:
		objective_label.text = "🎯 OBJECTIVE: Information not obtained this time"
		objective_label.modulate = Color.ORANGE
		available_info_label.text = "💡 Try different approaches or build more trust"
		available_info_label.modulate = Color.YELLOW

# =============================================================================
# NEW: INFORMATION-SPECIFIC EVENT HANDLERS
# =============================================================================

func _on_information_gained(info_type: ConversationController.InformationType, info_data: Dictionary):
	print("[UI] Information gained: %s - %s" % [info_type, info_data.get("title", "Unknown")])
	
	# Store for display in summary
	information_gained_this_conversation.append(info_data)
	
	# Show immediate feedback
	var feedback_text = "\n\n[b][color=gold]🎉 INFORMATION ACQUIRED! 🎉[/color][/b]"
	feedback_text += "\n[color=lightgreen]📋 %s[/color]" % info_data.get("title", "Unknown Information")
	feedback_text += "\n[color=cyan]%s[/color]" % info_data.get("description", "")
	
	dialogue_text.text += feedback_text
	
	# Update objective display immediately
	objective_label.text = "🎉 OBJECTIVE COMPLETED!"
	objective_label.modulate = Color.GOLD
	
	# Play success animation
	animate_success_feedback()

func _on_information_request_failed(reason: String, npc_name: String):
	print("[UI] Information request failed: %s" % reason)
	
	# Show failure feedback
	var feedback_text = "\n\n[b][color=red]❌ INFORMATION REQUEST FAILED[/color][/b]"
	feedback_text += "\n[color=orange]Reason: %s[/color]" % reason
	
	dialogue_text.text += feedback_text
	
	# Update objective display
	objective_label.text = "❌ OBJECTIVE FAILED"
	objective_label.modulate = Color.RED

func _on_objective_completed(objective: String, reward: Dictionary):
	print("[UI] Objective completed: %s" % objective)
	
	# This could be used for complex multi-part objectives
	objective_label.text = "🎉 %s COMPLETED!" % objective.to_upper()
	objective_label.modulate = Color.GOLD

func animate_success_feedback():
	# Simple success animation
	var original_modulate = objective_panel.modulate
	var tween = create_tween()
	tween.tween_property(objective_panel, "modulate", Color.GOLD, 0.3)
	tween.tween_property(objective_panel, "modulate", original_modulate, 0.7)

# =============================================================================
# ENHANCED CHOICE BUTTON MANAGEMENT WITH INFORMATION INDICATORS
# =============================================================================

func create_enhanced_choice_buttons(options: Array):
	clear_choice_buttons()
	
	for i in range(options.size()):
		var option = options[i]
		var button = Button.new()
		
		# Enhanced button text with information indicators
		var button_text = option.text
		
		# Add information request indicators
		if option.has("information_request") and option.information_request != "":
			button_text += " 📋"  # Information request indicator
			
			# Add risk indicator
			var risk_level = get_option_risk_level(option)
			button_text += get_risk_indicator(risk_level)
		elif option.has("information_hint") and option.information_hint != "":
			button_text += " 💡"  # Information hint indicator
		
		button.text = button_text
		button.custom_minimum_size = Vector2(670, 55)  # Slightly taller for better text
		button.autowrap_mode = TextServer.AUTOWRAP_WORD
		
		# Enhanced styling with information context
		style_enhanced_choice_button(button, option.get("social_type", null), option)
		
		# Connect button signal
		var choice_index = i
		button.pressed.connect(func(): _on_choice_selected(choice_index))
		
		# Add tooltip for information requests
		if option.has("information_request") and option.information_request != "":
			button.tooltip_text = "Information Request: %s" % option.information_request
		elif option.has("information_hint") and option.information_hint != "":
			button.tooltip_text = option.information_hint
		
		choice_container.add_child(button)
		choice_buttons.append(button)
	
	close_button.visible = false
	print("[UI] Created %d enhanced choice buttons with information indicators" % options.size())

func get_option_risk_level(option: Dictionary) -> String:
	# Try to infer risk level from option data or use default
	return option.get("risk_level", "medium")

func get_risk_indicator(risk_level: String) -> String:
	match risk_level:
		"low": return " 🟢"
		"medium": return " 🟡" 
		"high": return " 🟠"
		"very_high": return " 🔴"
		_: return " ⚪"

func style_enhanced_choice_button(button: Button, social_type, option: Dictionary):
	if not social_type:
		return
	
	var style_box = StyleBoxFlat.new()
	var base_color = Color(0.2, 0.2, 0.2, 0.3)  # Default base
	
	# Social type colors
	match social_type:
		SocialDNAManager.SocialType.AGGRESSIVE:
			base_color = Color(0.8, 0.2, 0.2, 0.3)
		SocialDNAManager.SocialType.DIPLOMATIC:
			base_color = Color(0.2, 0.3, 0.8, 0.3)
		SocialDNAManager.SocialType.CHARMING:
			base_color = Color(0.8, 0.2, 0.8, 0.3)
		SocialDNAManager.SocialType.DIRECT:
			base_color = Color(0.8, 0.8, 0.2, 0.3)
		SocialDNAManager.SocialType.EMPATHETIC:
			base_color = Color(0.2, 0.8, 0.3, 0.3)
	
	# Enhance color for information requests
	if option.has("information_request") and option.information_request != "":
		base_color = base_color.lerp(Color.CYAN, 0.3)  # Add cyan tint for info requests
		
		# Add border for information requests
		style_box.border_width_left = 2
		style_box.border_width_right = 2
		style_box.border_width_top = 2
		style_box.border_width_bottom = 2
		style_box.border_color = Color.CYAN
	
	style_box.bg_color = base_color
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	
	button.add_theme_stylebox_override("normal", style_box)
	
	# Hover effect
	var hover_style = style_box.duplicate()
	hover_style.bg_color = Color(hover_style.bg_color.r, hover_style.bg_color.g, hover_style.bg_color.b, 0.5)
	button.add_theme_stylebox_override("hover", hover_style)

func _on_choice_selected(choice_index: int):
	print("[UI] Player selected choice %d" % choice_index)
	
	# Enhanced choice display with information context
	if choice_index < choice_buttons.size():
		var button = choice_buttons[choice_index]
		var current_text = dialogue_text.text
		
		# Show player's choice with enhanced formatting
		var choice_text = button.text
		
		# Remove indicators from display
		choice_text = choice_text.replace(" 📋", "").replace(" 💡", "")
		choice_text = choice_text.replace(" 🟢", "").replace(" 🟡", "").replace(" 🟠", "").replace(" 🔴", "").replace(" ⚪", "")
		
		dialogue_text.text = current_text + "\n\n[b][color=lightblue]You:[/color][/b]\n%s" % choice_text
	
	clear_choice_buttons()
	
	# Send choice to conversation controller
	if conversation_controller:
		conversation_controller.process_player_choice(choice_index)

# =============================================================================
# ENHANCED INFO DISPLAY WITH INFORMATION CONTEXT
# =============================================================================

func update_npc_info():
	if not current_npc:
		return
		
	npc_name_label.text = current_npc.npc_name
	
	# Get enhanced status info
	var compatibility = SocialDNAManager.calculate_compatibility(current_npc.archetype)
	var trust_level = 0.0
	var trust_name = "Stranger"
	var relationship_summary = {}
	
	if conversation_controller:
		trust_level = conversation_controller.get_npc_trust_level(current_npc)
		trust_name = conversation_controller.get_trust_level_name(trust_level)
		relationship_summary = conversation_controller.get_relationship_summary(current_npc)
	
	var archetype_name = SocialDNAManager.get_archetype_name(current_npc.archetype)
	var compatibility_desc = SocialDNAManager.get_compatibility_description(compatibility)
	
	# Enhanced status display with information specialization
	var specialization = get_npc_information_specialization(current_npc.npc_name)
	npc_status_label.text = "%s | %s | Compatibility: %s (%.2f)" % [
		archetype_name, specialization, compatibility_desc, compatibility
	]
	
	# Enhanced relationship display with information history
	if relationship_summary.size() > 0:
		var success_rate = relationship_summary.get("success_rate", 0.0)
		var total_interactions = relationship_summary.get("total_interactions", 0)
		
		# Get information sharing history
		var info_shared_count = get_information_shared_count()
		
		relationship_label.text = "Trust: %s (%.1f) | Interactions: %d | Success: %.1f%% | Info Shared: %d" % [
			trust_name, trust_level, total_interactions, success_rate, info_shared_count
		]
		
		relationship_label.modulate = get_trust_display_color(trust_level)
	else:
		relationship_label.text = "Trust: %s (%.1f) | First Meeting | No Information Shared" % [trust_name, trust_level]
		relationship_label.modulate = Color.GRAY

func get_npc_information_specialization(npc_name: String) -> String:
	match npc_name:
		"Captain Stone":
			return "Security Expert"
		"Dr. Wisdom":
			return "Research Director"
		"Commander Steele":
			return "Operations Chief"
		_:
			return "Information Source"

func get_information_shared_count() -> int:
	# This would come from the conversation controller's information tracking
	if conversation_controller:
		var npc_info = conversation_controller.get_information_from_npc(current_npc.npc_name)
		return npc_info.size()
	return 0

func get_enhanced_outcome_color(outcome) -> String:
	match outcome:
		ConversationController.ConversationOutcome.INFORMATION_GAINED:
			return "gold"
		ConversationController.ConversationOutcome.SUCCESS:
			return "lightgreen"
		ConversationController.ConversationOutcome.PARTIAL_SUCCESS:
			return "yellow"
		ConversationController.ConversationOutcome.FAILURE:
			return "red"
		ConversationController.ConversationOutcome.TRUST_GATE_BLOCKED:
			return "orange"
		ConversationController.ConversationOutcome.INTERRUPTED:
			return "gray"
		_:
			return "white"

func get_trust_display_color(trust_level: float) -> Color:
	if trust_level >= 3.0:
		return Color.GOLD
	elif trust_level >= 2.0:
		return Color.GREEN
	elif trust_level >= 1.0:
		return Color.CYAN
	elif trust_level >= 0.0:
		return Color.GRAY
	else:
		return Color.RED

# =============================================================================
# EXISTING EVENT HANDLERS (Enhanced for information context)
# =============================================================================

func _on_conversation_failed(reason: String, retry_info: Dictionary):
	print("[UI] Conversation failed: %s" % reason)
	is_failure_mode = true
	
	# Enhanced failure information with information context
	var failure_text = "\n\n[b][color=red]--- CONVERSATION FAILED ---[/color][/b]"
	failure_text += "\n[color=orange]%s[/color]" % reason
	
	# Information-specific failure details
	if retry_info.has("information_blocked"):
		failure_text += "\n[color=yellow]Information Blocked: %s[/color]" % retry_info.information_blocked
	
	if retry_info.get("can_retry", false):
		failure_text += "\n\n[color=yellow]Retry Available:[/color]"
		var suggestions = retry_info.get("retry_suggestions", [])
		for suggestion in suggestions:
			failure_text += "\n• %s" % suggestion
	
	dialogue_text.text += failure_text
	
	# Update objective display
	objective_label.text = "❌ OBJECTIVE FAILED"
	objective_label.modulate = Color.RED
	
	create_retry_button()

func _on_trust_gate_encountered(npc: SocialNPC, required_trust: String, current_trust: String):
	print("[UI] Trust gate encountered - Need: %s, Have: %s" % [required_trust, current_trust])
	is_trust_gate_mode = true
	
	update_trust_gate_display_with_information_context(required_trust, current_trust)

func update_trust_gate_display_with_information_context(required_trust: String, current_trust: String):
	# Enhanced trust gate information
	var gate_text = "\n\n[b][color=orange]--- TRUST REQUIRED FOR INFORMATION ---[/color][/b]"
	gate_text += "\n[color=red]Required:[/color] %s Trust" % required_trust
	gate_text += "\n[color=gray]Current:[/color] %s Trust" % current_trust
	gate_text += "\n\n[color=yellow]💡 Build trust to unlock valuable information:[/color]"
	gate_text += "\n• Start with Quick Chats to build familiarity"
	gate_text += "\n• Use social approaches this NPC prefers"
	gate_text += "\n• Complete conversations successfully"
	gate_text += "\n• Higher trust = more valuable information"
	
	# Show what information is locked
	if available_information.size() > 0:
		gate_text += "\n\n[color=cyan]🔒 Information Available at Higher Trust:[/color]"
		for info_key in available_information:
			var info_data = available_information[info_key]
			gate_text += "\n  📋 %s" % info_data.get("title", info_key)
	
	dialogue_text.text += gate_text
	
	# Update objective display
	objective_label.text = "🔒 TRUST REQUIRED FOR INFORMATION"
	objective_label.modulate = Color.ORANGE
	available_info_label.text = "Build trust: %s → %s" % [current_trust, required_trust]
	available_info_label.modulate = Color.YELLOW
	
	clear_choice_buttons()
	close_button.visible = true

func create_retry_button():
	clear_choice_buttons()
	
	var retry_button = Button.new()
	retry_button.text = "🔄 Try Different Approach for Information"
	retry_button.custom_minimum_size = Vector2(250, 40)
	
	# Enhanced retry button styling
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.6, 0.8, 0.3)
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2  
	style_box.border_width_bottom = 2
	style_box.border_color = Color.CYAN
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	retry_button.add_theme_stylebox_override("normal", style_box)
	
	retry_button.pressed.connect(_on_retry_pressed)
	
	choice_container.add_child(retry_button)
	choice_buttons.append(retry_button)

func _on_retry_pressed():
	print("[UI] Player requested information retry")
	close_conversation_ui()

# =============================================================================
# ENHANCED EXISTING EVENT HANDLERS
# =============================================================================

func _on_social_dna_updated(changes: Dictionary):
	print("[UI] Social DNA updated")
	update_npc_info()
	update_objective_display()  # Update objective as compatibility may have changed
	
	var change_text = ""
	for social_type in changes:
		if changes[social_type] > 1:
			change_text = "+%d %s" % [changes[social_type], SocialDNAManager.get_social_type_name(social_type)]
			break
	
	if change_text != "":
		show_temporary_feedback(change_text, Color.CYAN, Vector2(10, 10))

func _on_relationship_changed(npc: SocialNPC, old_trust: float, new_trust: float):
	if npc != current_npc:
		return
		
	print("[UI] Relationship changed: %.2f → %.2f" % [old_trust, new_trust])
	
	update_npc_info()
	update_objective_display()  # Trust changes affect available information
	
	var trust_change = new_trust - old_trust
	var change_text = "Trust: %s%.2f" % ["+" if trust_change > 0 else "", trust_change]
	var color = Color.GREEN if trust_change > 0 else Color.ORANGE
	
	if conversation_controller:
		var old_trust_name = conversation_controller.get_trust_level_name(old_trust)
		var new_trust_name = conversation_controller.get_trust_level_name(new_trust)
		
		if old_trust_name != new_trust_name:
			change_text += "\n%s → %s" % [old_trust_name, new_trust_name]
			color = Color.YELLOW
			
			# Special notification for information unlocks
			change_text += "\n🔓 New information may be available!"
	
	show_temporary_feedback(change_text, color, Vector2(200, 10))

func show_temporary_feedback(text: String, color: Color, offset: Vector2 = Vector2.ZERO):
	var feedback_label = Label.new()
	feedback_label.text = text
	feedback_label.modulate = color
	feedback_label.add_theme_font_size_override("font_size", 14)
	feedback_label.position = Vector2(10, 10) + offset
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	add_child(feedback_label)
	
	var tween = create_tween()
	tween.parallel().tween_property(feedback_label, "position:y", feedback_label.position.y - 20, 2.5)
	tween.parallel().tween_property(feedback_label, "modulate:a", 0.0, 2.5)
	tween.tween_callback(feedback_label.queue_free)

# =============================================================================
# UI CLOSING AND CLEANUP
# =============================================================================

func _on_close_pressed():
	close_conversation_ui()

func close_conversation_ui():
	print("[UI] Closing enhanced information-focused conversation UI")
	
	_disconnect_conversation_signals()
	
	# Clear state
	current_npc = null
	conversation_controller = null
	clear_choice_buttons()
	is_trust_gate_mode = false
	is_failure_mode = false
	current_objective = ""
	available_information = {}
	information_gained_this_conversation = []
	
	# Hide UI
	visible = false
	
	conversation_ui_closed.emit()

func clear_choice_buttons():
	for button in choice_buttons:
		if is_instance_valid(button):
			button.queue_free()
	
	choice_buttons.clear()

# =============================================================================
# INPUT HANDLING
# =============================================================================

func _input(event):
	if not visible:
		return
		
	if event.is_action_pressed("ui_cancel"):
		close_conversation_ui()
		get_viewport().set_input_as_handled()
	
	# Debug: Show information inventory on F2
	if event.is_action_pressed("ui_page_up") and visible:
		print_information_debug_info()

func print_information_debug_info():
	print("\n=== INFORMATION DEBUG ===")
	print("Current Objective: %s" % current_objective)
	print("Available Information: %d items" % available_information.size())
	for info_key in available_information:
		print("  • %s: %s" % [info_key, available_information[info_key].get("title", "Unknown")])
	print("Information Gained This Conversation: %d" % information_gained_this_conversation.size())
	
	if conversation_controller:
		print("\nPlayer Information Inventory:")
		var inventory = conversation_controller.get_player_information_inventory()
		for info_type in inventory:
			print("  %s: %d items" % [conversation_controller.get_information_type_name(info_type), inventory[info_type].size()])
	
	print("==========================\n")
