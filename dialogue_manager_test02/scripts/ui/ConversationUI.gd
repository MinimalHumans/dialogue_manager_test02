# =============================================================================
# CONVERSATION UI - Phase 2A
# File: scripts/ui/ConversationUI.gd  
# Visual dialogue interface with NPC text and player choice buttons
# =============================================================================

extends Control
class_name ConversationUI

# UI Components
@onready var background_panel: Panel = $BackgroundPanel
@onready var npc_info: VBoxContainer = $BackgroundPanel/VBox/NPCInfo
@onready var npc_name_label: Label = $BackgroundPanel/VBox/NPCInfo/NPCName
@onready var npc_status_label: Label = $BackgroundPanel/VBox/NPCInfo/NPCStatus
@onready var dialogue_text: RichTextLabel = $BackgroundPanel/VBox/DialogueText
@onready var choice_container: VBoxContainer = $BackgroundPanel/VBox/ChoiceContainer
@onready var close_button: Button = $BackgroundPanel/VBox/CloseButton

# State
var current_npc: SocialNPC = null
var conversation_controller: ConversationController = null
var choice_buttons: Array[Button] = []

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
	background_panel.custom_minimum_size = Vector2(600, 400)
	
	# Style the dialogue text
	dialogue_text.bbcode_enabled = true
	dialogue_text.custom_minimum_size = Vector2(550, 150)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	# Center the UI on screen
	anchors_preset = Control.PRESET_CENTER
	position = Vector2(-300, -200)  # Half of panel size

# =============================================================================
# CONVERSATION FLOW HANDLERS
# =============================================================================

func start_conversation_ui(npc: SocialNPC, controller: ConversationController):
	current_npc = npc
	conversation_controller = controller
	
	# Connect to conversation events
	if conversation_controller:
		conversation_controller.conversation_started.connect(_on_conversation_started)
		conversation_controller.conversation_continued.connect(_on_conversation_continued)
		conversation_controller.conversation_ended.connect(_on_conversation_ended)
		conversation_controller.social_dna_updated.connect(_on_social_dna_updated)
		conversation_controller.relationship_changed.connect(_on_relationship_changed)
	
	# Update NPC info
	update_npc_info()
	
	# Show the UI
	visible = true
	print("[UI] Conversation UI opened with %s" % npc.npc_name)

func _on_conversation_started(npc: SocialNPC, opening_line: String):
	print("[UI] Conversation started: %s" % opening_line)
	
	# Display opening line
	dialogue_text.text = "[b]%s:[/b]\n%s" % [npc.npc_name, opening_line]
	
	# Clear any existing choice buttons
	clear_choice_buttons()

func _on_conversation_continued(npc_line: String, player_options: Array):
	print("[UI] Conversation continued - NPC: '%s', Options: %d" % [npc_line, player_options.size()])
	
	# Update dialogue text if there's an NPC line
	if npc_line != "":
		var current_text = dialogue_text.text
		dialogue_text.text = current_text + "\n\n[b]%s:[/b]\n%s" % [current_npc.npc_name, npc_line]
	
	# Create choice buttons if there are options
	if player_options.size() > 0:
		create_choice_buttons(player_options)
	else:
		# No options means this is the final reaction - show close button
		clear_choice_buttons()
		close_button.visible = true

func _on_conversation_ended(outcome: Dictionary):
	print("[UI] Conversation ended - Outcome: %s" % outcome.get("outcome", "unknown"))
	
	# Show final summary
	var summary_text = "\n\n[i][color=gray]--- Conversation Complete ---"
	summary_text += "\nOutcome: %s" % outcome.get("outcome", "unknown").capitalize()
	
	if outcome.has("turns_completed"):
		summary_text += "\nTurns: %d" % outcome.turns_completed
	
	if outcome.has("relationship_changes"):
		var change = outcome.relationship_changes
		if change != 0:
			summary_text += "\nRelationship: %s%.2f" % ["+" if change > 0 else "", change]
	
	summary_text += "[/color][/i]"
	
	dialogue_text.text += summary_text
	
	# Clear choices and show close button
	clear_choice_buttons()
	close_button.visible = true

# =============================================================================
# CHOICE BUTTON MANAGEMENT
# =============================================================================

func create_choice_buttons(options: Array):
	clear_choice_buttons()
	
	for i in range(options.size()):
		var option = options[i]
		var button = Button.new()
		
		# Set button text with formatting
		button.text = option.text
		button.custom_minimum_size = Vector2(550, 40)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD
		
		# Style based on social type for visual feedback
		style_choice_button(button, option.get("social_type", null))
		
		# Connect button signal
		var choice_index = i
		button.pressed.connect(func(): _on_choice_selected(choice_index))
		
		# Add to container
		choice_container.add_child(button)
		choice_buttons.append(button)
	
	# Hide close button when choices are available
	close_button.visible = false
	
	print("[UI] Created %d choice buttons" % options.size())

func style_choice_button(button: Button, social_type):
	if not social_type:
		return
		
	# Add subtle color coding based on social type
	var style_box = StyleBoxFlat.new()
	
	match social_type:
		SocialDNAManager.SocialType.AGGRESSIVE:
			style_box.bg_color = Color(0.8, 0.3, 0.3, 0.2)  # Light red tint
		SocialDNAManager.SocialType.DIPLOMATIC:
			style_box.bg_color = Color(0.3, 0.3, 0.8, 0.2)  # Light blue tint
		SocialDNAManager.SocialType.CHARMING:
			style_box.bg_color = Color(0.8, 0.3, 0.8, 0.2)  # Light purple tint
		SocialDNAManager.SocialType.DIRECT:
			style_box.bg_color = Color(0.8, 0.8, 0.3, 0.2)  # Light yellow tint
		SocialDNAManager.SocialType.EMPATHETIC:
			style_box.bg_color = Color(0.3, 0.8, 0.3, 0.2)  # Light green tint
	
	style_box.corner_radius_bottom_left = 5
	style_box.corner_radius_bottom_right = 5
	style_box.corner_radius_top_left = 5
	style_box.corner_radius_top_right = 5
	
	button.add_theme_stylebox_override("normal", style_box)

func clear_choice_buttons():
	for button in choice_buttons:
		if is_instance_valid(button):
			button.queue_free()
	
	choice_buttons.clear()

func _on_choice_selected(choice_index: int):
	print("[UI] Player selected choice %d" % choice_index)
	
	# Add player's choice to dialogue display
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
# INFO DISPLAY
# =============================================================================

func update_npc_info():
	if not current_npc:
		return
		
	npc_name_label.text = current_npc.npc_name
	
	# Get current status info
	var compatibility = SocialDNAManager.calculate_compatibility(current_npc.archetype)
	var trust_level = 0.0
	var trust_name = "Stranger"
	
	if conversation_controller:
		trust_level = conversation_controller.get_npc_trust_level(current_npc)
		trust_name = conversation_controller.get_trust_level_name(trust_level)
	
	var archetype_name = SocialDNAManager.get_archetype_name(current_npc.archetype)
	var compatibility_desc = SocialDNAManager.get_compatibility_description(compatibility)
	
	npc_status_label.text = "%s | Trust: %s (%.1f) | Compatibility: %s (%.2f)" % [
		archetype_name, trust_name, trust_level, compatibility_desc, compatibility
	]

# =============================================================================
# EVENT HANDLERS
# =============================================================================

func _on_social_dna_updated(changes: Dictionary):
	print("[UI] Social DNA updated")
	
	# Update NPC info to reflect new compatibility
	update_npc_info()
	
	# Show temporary feedback
	var change_text = ""
	for social_type in changes:
		if changes[social_type] > 1:  # Only show the main trait increase
			change_text = "+%d %s" % [changes[social_type], SocialDNAManager.get_social_type_name(social_type)]
			break
	
	if change_text != "":
		show_temporary_feedback(change_text, Color.CYAN)

func _on_relationship_changed(npc: SocialNPC, old_trust: float, new_trust: float):
	print("[UI] Relationship changed: %.2f → %.2f" % [old_trust, new_trust])
	
	# Update NPC info
	update_npc_info()
	
	# Show relationship change feedback
	var trust_change = new_trust - old_trust
	var change_text = "Relationship: %s%.2f" % ["+" if trust_change > 0 else "", trust_change]
	var color = Color.GREEN if trust_change > 0 else Color.ORANGE
	
	show_temporary_feedback(change_text, color)

func show_temporary_feedback(text: String, color: Color):
	# Create a temporary label for feedback
	var feedback_label = Label.new()
	feedback_label.text = text
	feedback_label.modulate = color
	feedback_label.add_theme_font_size_override("font_size", 14)
	feedback_label.position = Vector2(10, 10)
	
	add_child(feedback_label)
	
	# Fade out and remove
	var tween = create_tween()
	tween.tween_property(feedback_label, "modulate:a", 0.0, 2.0)
	tween.tween_callback(feedback_label.queue_free)

func _on_close_pressed():
	close_conversation_ui()

func close_conversation_ui():
	print("[UI] Closing conversation UI")
	
	# Disconnect signals
	if conversation_controller:
		if conversation_controller.conversation_started.is_connected(_on_conversation_started):
			conversation_controller.conversation_started.disconnect(_on_conversation_started)
		if conversation_controller.conversation_continued.is_connected(_on_conversation_continued):
			conversation_controller.conversation_continued.disconnect(_on_conversation_continued)  
		if conversation_controller.conversation_ended.is_connected(_on_conversation_ended):
			conversation_controller.conversation_ended.disconnect(_on_conversation_ended)
		if conversation_controller.social_dna_updated.is_connected(_on_social_dna_updated):
			conversation_controller.social_dna_updated.disconnect(_on_social_dna_updated)
		if conversation_controller.relationship_changed.is_connected(_on_relationship_changed):
			conversation_controller.relationship_changed.disconnect(_on_relationship_changed)
	
	# Clear state
	current_npc = null
	conversation_controller = null
	clear_choice_buttons()
	
	# Hide UI
	visible = false
	
	# Emit signal for main game to handle
	conversation_ui_closed.emit()

# =============================================================================
# INPUT HANDLING
# =============================================================================

func _input(event):
	if not visible:
		return
		
	# Close on Escape key
	if event.is_action_pressed("ui_cancel"):
		close_conversation_ui()
		get_viewport().set_input_as_handled()
