# =============================================================================
# ENHANCED CONVERSATION UI - Phase 2B
# File: scripts/ui/ConversationUI.gd (REPLACE existing file)
# Adds trust gate handling, failure states, and enhanced relationship display
# =============================================================================

extends Control
class_name ConversationUI

# UI Components
@onready var background_panel: Panel = $BackgroundPanel
@onready var npc_info: VBoxContainer = $BackgroundPanel/VBox/NPCInfo
@onready var npc_name_label: Label = $BackgroundPanel/VBox/NPCInfo/NPCName
@onready var npc_status_label: Label = $BackgroundPanel/VBox/NPCInfo/NPCStatus
@onready var relationship_label: Label = $BackgroundPanel/VBox/NPCInfo/RelationshipStatus
@onready var dialogue_text: RichTextLabel = $BackgroundPanel/VBox/DialogueText
@onready var choice_container: VBoxContainer = $BackgroundPanel/VBox/ChoiceContainer
@onready var close_button: Button = $BackgroundPanel/VBox/CloseButton

# State
var current_npc: SocialNPC = null
var conversation_controller: ConversationController = null
var choice_buttons: Array[Button] = []
var is_trust_gate_mode: bool = false
var is_failure_mode: bool = false

signal conversation_ui_closed()

func _ready():
	# Initially hidden
	visible = false
	
	# Connect close button
	close_button.pressed.connect(_on_close_pressed)
	
	# Setup UI styling
	setup_ui_styling()

func setup_ui_styling():
	# Set up the background panel to be prominent
	background_panel.custom_minimum_size = Vector2(700, 550)  # Slightly taller for relationship info
	
	# Style the dialogue text
	dialogue_text.bbcode_enabled = true
	dialogue_text.custom_minimum_size = Vector2(680, 200)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	# Add relationship status label if it doesn't exist
	if not relationship_label:
		relationship_label = Label.new()
		relationship_label.name = "RelationshipStatus"
		relationship_label.add_theme_font_size_override("font_size", 10)
		relationship_label.modulate = Color.CYAN
		npc_info.add_child(relationship_label)
		npc_info.move_child(relationship_label, 2)  # After status label
	
	# Center the UI on screen
	anchors_preset = Control.PRESET_CENTER
	position = Vector2(-350, -275)  # Adjusted for larger size

# =============================================================================
# ENHANCED CONVERSATION FLOW HANDLERS
# =============================================================================

func start_conversation_ui(npc: SocialNPC, controller: ConversationController):
	current_npc = npc
	conversation_controller = controller
	is_trust_gate_mode = false
	is_failure_mode = false
	
	# Connect to conversation events
	if conversation_controller:
		conversation_controller.conversation_started.connect(_on_conversation_started)
		conversation_controller.conversation_continued.connect(_on_conversation_continued)
		conversation_controller.conversation_ended.connect(_on_conversation_ended)
		conversation_controller.conversation_failed.connect(_on_conversation_failed)
		conversation_controller.trust_gate_encountered.connect(_on_trust_gate_encountered)
		conversation_controller.social_dna_updated.connect(_on_social_dna_updated)
		conversation_controller.relationship_changed.connect(_on_relationship_changed)
	
	# Update NPC info
	update_npc_info()
	
	# Show the UI
	visible = true
	print("[UI] Enhanced Conversation UI opened with %s" % npc.npc_name)

func _on_conversation_started(npc: SocialNPC, opening_line: String):
	print("[UI] Conversation started: %s" % opening_line)
	
	# Display opening line with enhanced formatting
	dialogue_text.text = "[b][color=lightgreen]%s:[/color][/b]\n%s" % [npc.npc_name, opening_line]
	
	# Clear any existing choice buttons
	clear_choice_buttons()

func _on_conversation_continued(npc_line: String, player_options: Array):
	print("[UI] Conversation continued - NPC: '%s', Options: %d" % [npc_line, player_options.size()])
	
	# Update dialogue text if there's an NPC line
	if npc_line != "":
		var current_text = dialogue_text.text
		dialogue_text.text = current_text + "\n\n[b][color=lightgreen]%s:[/color][/b]\n%s" % [current_npc.npc_name, npc_line]
	
	# Create choice buttons if there are options
	if player_options.size() > 0:
		create_choice_buttons(player_options)
	else:
		# No options means this is the final reaction - show close button
		clear_choice_buttons()
		close_button.visible = true

func _on_conversation_ended(outcome: Dictionary):
	print("[UI] Conversation ended - Outcome: %s" % outcome.get("outcome", "unknown"))
	
	# Show final summary with enhanced formatting
	var summary_text = "\n\n[i][color=gray]--- Conversation Complete ---"
	
	# Format outcome based on type
	var outcome_value = outcome.get("outcome", "unknown")
	var outcome_color = get_outcome_color(outcome_value)
	summary_text += "\n[color=%s]Outcome: %s[/color]" % [outcome_color, str(outcome_value).capitalize()]
	
	if outcome.has("turns_completed"):
		summary_text += "\nTurns: %d" % outcome.turns_completed
	
	# Enhanced relationship feedback
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
	
	# Trust gate specific information
	if outcome_value == ConversationController.ConversationOutcome.TRUST_GATE_BLOCKED:
		summary_text += "\n[color=orange]Required: %s Trust[/color]" % outcome.get("required_trust", "Unknown")
		summary_text += "\n[color=yellow]Suggestion: %s[/color]" % outcome.get("suggestion", "Build trust first")
	
	summary_text += "[/color][/i]"
	
	dialogue_text.text += summary_text
	
	# Clear choices and show close button
	clear_choice_buttons()
	close_button.visible = true

func _on_conversation_failed(reason: String, retry_info: Dictionary):
	print("[UI] Conversation failed: %s" % reason)
	is_failure_mode = true
	
	# Show failure information
	var failure_text = "\n\n[b][color=red]--- CONVERSATION FAILED ---[/color][/b]"
	failure_text += "\n[color=orange]%s[/color]" % reason
	
	if retry_info.get("can_retry", false):
		failure_text += "\n\n[color=yellow]Retry Available:[/color]"
		failure_text += "\n%s" % retry_info.get("retry_suggestion", "Try again with a different approach.")
		
		var recommended = retry_info.get("recommended_social_types", [])
		if recommended.size() > 0:
			failure_text += "\n\n[color=cyan]Recommended approaches:[/color]"
			for social_type in recommended:
				failure_text += "\n• %s" % social_type
	
	dialogue_text.text += failure_text
	
	# Show retry button instead of close button
	create_retry_button()

func _on_trust_gate_encountered(npc: SocialNPC, required_trust: String, current_trust: String):
	print("[UI] Trust gate encountered - Need: %s, Have: %s" % [required_trust, current_trust])
	is_trust_gate_mode = true
	
	# Update display to show trust gate information
	update_trust_gate_display(required_trust, current_trust)

func update_trust_gate_display(required_trust: String, current_trust: String):
	# Add trust gate information to the dialogue
	var gate_text = "\n\n[b][color=orange]--- TRUST REQUIRED ---[/color][/b]"
	gate_text += "\n[color=red]Required:[/color] %s Trust" % required_trust
	gate_text += "\n[color=gray]Current:[/color] %s Trust" % current_trust
	gate_text += "\n\n[color=yellow]💡 Build trust through successful conversations:[/color]"
	gate_text += "\n• Start with Quick Chats to build familiarity"
	gate_text += "\n• Use social approaches this NPC prefers"
	gate_text += "\n• Complete conversations successfully"
	
	dialogue_text.text += gate_text
	
	# Show close button
	clear_choice_buttons()
	close_button.visible = true

func get_outcome_color(outcome) -> String:
	match outcome:
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

# =============================================================================
# ENHANCED CHOICE BUTTON MANAGEMENT
# =============================================================================

func create_choice_buttons(options: Array):
	clear_choice_buttons()
	
	for i in range(options.size()):
		var option = options[i]
		var button = Button.new()
		
		# Set button text with enhanced formatting
		button.text = option.text
		button.custom_minimum_size = Vector2(670, 50)  # Taller buttons for better text
		button.autowrap_mode = TextServer.AUTOWRAP_WORD
		
		# Enhanced styling based on social type
		style_enhanced_choice_button(button, option.get("social_type", null))
		
		# Connect button signal
		var choice_index = i
		button.pressed.connect(func(): _on_choice_selected(choice_index))
		
		# Add to container
		choice_container.add_child(button)
		choice_buttons.append(button)
	
	# Hide close button when choices are available
	close_button.visible = false
	
	print("[UI] Created %d choice buttons" % options.size())

func style_enhanced_choice_button(button: Button, social_type):
	if not social_type:
		return
	
	# Enhanced color coding with better visual feedback
	var style_box = StyleBoxFlat.new()
	var border_style = StyleBoxFlat.new()
	
	match social_type:
		SocialDNAManager.SocialType.AGGRESSIVE:
			style_box.bg_color = Color(0.8, 0.2, 0.2, 0.3)  # Red tint
			border_style.border_color = Color(0.9, 0.3, 0.3, 0.8)
		SocialDNAManager.SocialType.DIPLOMATIC:
			style_box.bg_color = Color(0.2, 0.3, 0.8, 0.3)  # Blue tint
			border_style.border_color = Color(0.3, 0.4, 0.9, 0.8)
		SocialDNAManager.SocialType.CHARMING:
			style_box.bg_color = Color(0.8, 0.2, 0.8, 0.3)  # Purple tint
			border_style.border_color = Color(0.9, 0.3, 0.9, 0.8)
		SocialDNAManager.SocialType.DIRECT:
			style_box.bg_color = Color(0.8, 0.8, 0.2, 0.3)  # Yellow tint
			border_style.border_color = Color(0.9, 0.9, 0.3, 0.8)
		SocialDNAManager.SocialType.EMPATHETIC:
			style_box.bg_color = Color(0.2, 0.8, 0.3, 0.3)  # Green tint
			border_style.border_color = Color(0.3, 0.9, 0.4, 0.8)
	
	# Enhanced styling
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	
	button.add_theme_stylebox_override("normal", style_box)
	
	# Add hover effect
	var hover_style = style_box.duplicate()
	hover_style.bg_color = Color(hover_style.bg_color.r, hover_style.bg_color.g, hover_style.bg_color.b, 0.5)
	button.add_theme_stylebox_override("hover", hover_style)

func create_retry_button():
	clear_choice_buttons()
	
	var retry_button = Button.new()
	retry_button.text = "🔄 Try Different Approach"
	retry_button.custom_minimum_size = Vector2(200, 40)
	
	# Style retry button
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.6, 0.8, 0.3)
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	retry_button.add_theme_stylebox_override("normal", style_box)
	
	# Connect retry functionality
	retry_button.pressed.connect(_on_retry_pressed)
	
	choice_container.add_child(retry_button)
	choice_buttons.append(retry_button)

func _on_retry_pressed():
	print("[UI] Player requested conversation retry")
	close_conversation_ui()
	# The player can click the NPC again to retry

func clear_choice_buttons():
	for button in choice_buttons:
		if is_instance_valid(button):
			button.queue_free()
	
	choice_buttons.clear()

func _on_choice_selected(choice_index: int):
	print("[UI] Player selected choice %d" % choice_index)
	
	# Add player's choice to dialogue display with enhanced formatting
	if choice_index < choice_buttons.size():
		var button = choice_buttons[choice_index]
		var current_text = dialogue_text.text
		dialogue_text.text = current_text + "\n\n[b][color=lightblue]You:[/color][/b]\n%s" % button.text
	
	# Clear choices immediately to prevent double-clicking
	clear_choice_buttons()
	
	# Send choice to conversation controller
	if conversation_controller:
		conversation_controller.process_player_choice(choice_index)

# =============================================================================
# ENHANCED INFO DISPLAY
# =============================================================================

func update_npc_info():
	if not current_npc:
		return
		
	npc_name_label.text = current_npc.npc_name
	
	# Get current status info
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
	
	# Enhanced status display
	npc_status_label.text = "%s | Compatibility: %s (%.2f)" % [
		archetype_name, compatibility_desc, compatibility
	]
	
	# Enhanced relationship display
	if relationship_summary.size() > 0:
		var success_rate = relationship_summary.get("success_rate", 0.0)
		var total_interactions = relationship_summary.get("total_interactions", 0)
		var last_outcome = relationship_summary.get("last_outcome", "None")
		
		relationship_label.text = "Trust: %s (%.1f) | Interactions: %d | Success: %.1f%% | Last: %s" % [
			trust_name, trust_level, total_interactions, success_rate, last_outcome
		]
		
		# Color-code based on trust level
		relationship_label.modulate = get_trust_display_color(trust_level)
	else:
		relationship_label.text = "Trust: %s (%.1f) | First Meeting" % [trust_name, trust_level]
		relationship_label.modulate = Color.GRAY

func get_trust_display_color(trust_level: float) -> Color:
	if trust_level >= 3.0:
		return Color.GOLD  # Close
	elif trust_level >= 2.0:
		return Color.GREEN  # Trusted
	elif trust_level >= 1.0:
		return Color.CYAN  # Professional
	elif trust_level >= 0.0:
		return Color.GRAY  # Stranger
	else:
		return Color.RED  # Hostile

# =============================================================================
# ENHANCED EVENT HANDLERS
# =============================================================================

func _on_social_dna_updated(changes: Dictionary):
	print("[UI] Social DNA updated")
	
	# Update NPC info to reflect new compatibility
	update_npc_info()
	
	# Show enhanced feedback
	var change_text = ""
	for social_type in changes:
		if changes[social_type] > 1:  # Only show the main trait increase
			change_text = "+%d %s" % [changes[social_type], SocialDNAManager.get_social_type_name(social_type)]
			break
	
	if change_text != "":
		show_temporary_feedback(change_text, Color.CYAN, Vector2(10, 10))

func _on_relationship_changed(npc: SocialNPC, old_trust: float, new_trust: float):
	if npc != current_npc:
		return
		
	print("[UI] Relationship changed: %.2f → %.2f" % [old_trust, new_trust])
	
	# Update NPC info
	update_npc_info()
	
	# Show enhanced relationship change feedback
	var trust_change = new_trust - old_trust
	var change_text = "Trust: %s%.2f" % ["+" if trust_change > 0 else "", trust_change]
	var color = Color.GREEN if trust_change > 0 else Color.ORANGE
	
	# Check for trust level changes
	if conversation_controller:
		var old_trust_name = conversation_controller.get_trust_level_name(old_trust)
		var new_trust_name = conversation_controller.get_trust_level_name(new_trust)
		
		if old_trust_name != new_trust_name:
			change_text += "\n%s → %s" % [old_trust_name, new_trust_name]
			color = Color.YELLOW
	
	show_temporary_feedback(change_text, color, Vector2(200, 10))

func show_temporary_feedback(text: String, color: Color, offset: Vector2 = Vector2.ZERO):
	# Create a temporary label for feedback
	var feedback_label = Label.new()
	feedback_label.text = text
	feedback_label.modulate = color
	feedback_label.add_theme_font_size_override("font_size", 14)
	feedback_label.position = Vector2(10, 10) + offset
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	add_child(feedback_label)
	
	# Enhanced fade out animation
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
	print("[UI] Closing enhanced conversation UI")
	
	# Disconnect signals
	if conversation_controller:
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
	
	# Clear state
	current_npc = null
	conversation_controller = null
	clear_choice_buttons()
	is_trust_gate_mode = false
	is_failure_mode = false
	
	# Hide UI
	visible = false
	
	# Emit signal for main game to handle
	conversation_ui_closed.emit()

# =============================================================================
# ENHANCED INPUT HANDLING
# =============================================================================

func _input(event):
	if not visible:
		return
		
	# Close on Escape key
	if event.is_action_pressed("ui_cancel"):
		close_conversation_ui()
		get_viewport().set_input_as_handled()
	
	# Debug: Show conversation state on F1
	if event.is_action_pressed("ui_home") and visible:
		print_conversation_debug_info()

func print_conversation_debug_info():
	print("\n=== CONVERSATION UI DEBUG ===")
	print("Current NPC: %s" % (current_npc.npc_name if current_npc else "None"))
	print("Trust Gate Mode: %s" % is_trust_gate_mode)
	print("Failure Mode: %s" % is_failure_mode)
	print("Choice Buttons: %d" % choice_buttons.size())
	
	if conversation_controller and current_npc:
		var relationship = conversation_controller.get_relationship_summary(current_npc)
		print("Relationship Summary:")
		for key in relationship:
			print("  %s: %s" % [key, relationship[key]])
	
	print("================================\n")
