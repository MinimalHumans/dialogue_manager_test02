# =============================================================================
# CONVERSATION CONTROLLER - Phase 2A
# File: scripts/core/ConversationController.gd
# Manages conversation state, flow, and progression
# =============================================================================

extends Node
class_name ConversationController

# Conversation types
enum ConversationType {
	QUICK_CHAT,      # 1-2 exchanges
	TOPIC_DISCUSSION, # 3-5 exchanges
	DEEP_CONVERSATION # 5+ exchanges
}

# Current conversation state
var current_npc: SocialNPC = null
var current_conversation_data: Dictionary = {}
var conversation_turn: int = 0
var conversation_active: bool = false
var relationship_data: Dictionary = {}

# Signals for UI updates
signal conversation_started(npc: SocialNPC, opening_line: String)
signal conversation_continued(npc_line: String, player_options: Array)
signal conversation_ended(outcome: Dictionary)
signal social_dna_updated(changes: Dictionary)
signal relationship_changed(npc: SocialNPC, old_trust: float, new_trust: float)

func _ready():
	# Initialize relationship tracking (hardcoded for Phase 2)
	relationship_data = {}

# =============================================================================
# MAIN CONVERSATION FLOW
# =============================================================================

func start_conversation(npc: SocialNPC, conversation_type: ConversationType = ConversationType.QUICK_CHAT):
	if conversation_active:
		print("[DEBUG] Conversation already active, ending previous")
		end_conversation({"outcome": "interrupted"})
	
	current_npc = npc
	conversation_turn = 0
	conversation_active = true
	
	# Get conversation data based on NPC archetype and relationship
	current_conversation_data = ConversationData.get_conversation(
		npc.archetype, 
		conversation_type,
		get_npc_trust_level(npc),
		SocialDNAManager.calculate_compatibility(npc.archetype)
	)
	
	# Get opening line based on compatibility and trust
	var opening_line = get_opening_line()
	
	print("[CONVERSATION] Started with %s - Turn %d" % [npc.npc_name, conversation_turn])
	conversation_started.emit(npc, opening_line)
	
	# Move to player response phase
	present_player_options()

func process_player_choice(choice_index: int):
	if not conversation_active or not current_conversation_data.has("turns"):
		print("[ERROR] No active conversation or invalid data")
		return
	
	var current_turn_data = current_conversation_data.turns[conversation_turn]
	
	if choice_index >= current_turn_data.player_options.size():
		print("[ERROR] Invalid choice index: %d" % choice_index)
		return
	
	var chosen_option = current_turn_data.player_options[choice_index]
	
	# Update Social DNA based on choice
	var social_type = chosen_option.social_type
	update_social_dna(social_type)
	
	# Calculate NPC reaction based on compatibility
	var compatibility = SocialDNAManager.calculate_compatibility(current_npc.archetype)
	var npc_reaction = get_npc_reaction(chosen_option, compatibility)
	
	# Update relationship based on reaction
	update_relationship(chosen_option, npc_reaction.compatibility_result)
	
	print("[CONVERSATION] Player chose: [%s] %s" % [
		SocialDNAManager.get_social_type_name(social_type).to_upper(), 
		chosen_option.text
	])
	print("[CONVERSATION] NPC reacts: %s" % npc_reaction.text)
	
	# Move to next turn or end conversation
	conversation_turn += 1
	
	if should_end_conversation(npc_reaction):
		# Show final NPC reaction before ending
		present_final_reaction(npc_reaction)
	else:
		present_next_turn(npc_reaction)

# =============================================================================
# CONVERSATION PROGRESSION
# =============================================================================

func get_opening_line() -> String:
	var compatibility = SocialDNAManager.calculate_compatibility(current_npc.archetype)
	var trust_level = get_npc_trust_level(current_npc)
	var compatibility_flag = get_compatibility_flag(compatibility)
	
	var opening_lines = current_conversation_data.get("opening_lines", [])
	
	for line_data in opening_lines:
		if line_data.min_compatibility <= compatibility and compatibility <= line_data.max_compatibility:
			if line_data.min_trust_level <= trust_level:
				return "[%s] %s" % [compatibility_flag, line_data.text]
	
	# Fallback
	return "[%s] Hello there." % compatibility_flag

func present_player_options():
	if conversation_turn >= current_conversation_data.turns.size():
		print("[DEBUG] No more turns available, ending conversation")
		end_conversation({"outcome": "completed"})
		return
	
	var turn_data = current_conversation_data.turns[conversation_turn]
	var formatted_options = []
	
	for i in range(turn_data.player_options.size()):
		var option = turn_data.player_options[i]
		var social_flag = "[%s]" % SocialDNAManager.get_social_type_name(option.social_type).to_upper()
		var trait_bonus = "+%d %s" % [3, SocialDNAManager.get_social_type_name(option.social_type)]
		
		formatted_options.append({
			"text": "%s %s (%s)" % [social_flag, option.text, trait_bonus],
			"social_type": option.social_type,
			"original_text": option.text
		})
	
	conversation_continued.emit("", formatted_options)  # Empty NPC line for options-only turn

func present_next_turn(npc_reaction: Dictionary):
	if conversation_turn >= current_conversation_data.turns.size():
		end_conversation_with_outcome(npc_reaction)
		return
	
	# Present NPC reaction, then player options for next turn
	var turn_data = current_conversation_data.turns[conversation_turn]
	var formatted_options = []
	
	for option in turn_data.player_options:
		var social_flag = "[%s]" % SocialDNAManager.get_social_type_name(option.social_type).to_upper()
		var trait_bonus = "+%d %s" % [3, SocialDNAManager.get_social_type_name(option.social_type)]
		
		formatted_options.append({
			"text": "%s %s (%s)" % [social_flag, option.text, trait_bonus],
			"social_type": option.social_type,
			"original_text": option.text
		})
	
	conversation_continued.emit(npc_reaction.text, formatted_options)

func present_final_reaction(npc_reaction: Dictionary):
	# Show the final NPC reaction without player options
	conversation_continued.emit(npc_reaction.text, [])
	
	# End the conversation after showing the reaction
	end_conversation_with_outcome(npc_reaction)

# =============================================================================
# NPC REACTION SYSTEM
# =============================================================================

func get_npc_reaction(chosen_option: Dictionary, compatibility: float) -> Dictionary:
	var archetype_preferences = SocialDNAManager.archetype_preferences[current_npc.archetype]
	var social_preference = archetype_preferences.get(chosen_option.social_type, 0.0)
	
	# Determine compatibility result
	var compatibility_result: String
	var reaction_modifier: String
	
	if social_preference >= 1.5:
		compatibility_result = "VERY_COMPATIBLE"
		reaction_modifier = "VERY COMPATIBLE"
	elif social_preference >= 0.5:
		compatibility_result = "COMPATIBLE" 
		reaction_modifier = "COMPATIBLE"
	elif social_preference >= -0.5:
		compatibility_result = "NEUTRAL"
		reaction_modifier = "NEUTRAL"
	elif social_preference >= -1.0:
		compatibility_result = "INCOMPATIBLE"
		reaction_modifier = "INCOMPATIBLE"
	else:
		compatibility_result = "VERY_INCOMPATIBLE"
		reaction_modifier = "VERY INCOMPATIBLE"
	
	# Get reaction text based on archetype and compatibility
	var reaction_text = ConversationData.get_npc_reaction_text(
		current_npc.archetype,
		chosen_option.social_type,
		compatibility_result,
		conversation_turn
	)
	
	return {
		"text": "[%s] %s" % [reaction_modifier, reaction_text],
		"compatibility_result": compatibility_result,
		"social_preference": social_preference,
		"relationship_change": calculate_relationship_change(compatibility_result)
	}

func calculate_relationship_change(compatibility_result: String) -> float:
	match compatibility_result:
		"VERY_COMPATIBLE": return 0.3
		"COMPATIBLE": return 0.1
		"NEUTRAL": return 0.0
		"INCOMPATIBLE": return -0.1
		"VERY_INCOMPATIBLE": return -0.2
		_: return 0.0

# =============================================================================
# CONVERSATION ENDING
# =============================================================================

func should_end_conversation(npc_reaction: Dictionary) -> bool:
	# End if we've reached the max turns for this conversation type
	var max_turns = get_max_turns_for_type(current_conversation_data.get("type", ConversationType.QUICK_CHAT))
	
	if conversation_turn >= max_turns:
		return true
	
	# End if compatibility becomes very poor
	if npc_reaction.compatibility_result == "VERY_INCOMPATIBLE":
		return true
	
	# Check if we have more turns available
	return conversation_turn >= current_conversation_data.turns.size()

func get_max_turns_for_type(conv_type: ConversationType) -> int:
	match conv_type:
		ConversationType.QUICK_CHAT: return 2
		ConversationType.TOPIC_DISCUSSION: return 5  
		ConversationType.DEEP_CONVERSATION: return 8
		_: return 2

func end_conversation_with_outcome(final_reaction: Dictionary):
	var outcome = {
		"outcome": "completed",
		"final_reaction": final_reaction,
		"turns_completed": conversation_turn,
		"final_trust": get_npc_trust_level(current_npc),
		"social_dna_changes": {},  # Will be populated by social DNA updates
		"relationship_changes": final_reaction.relationship_change
	}
	
	end_conversation(outcome)

func end_conversation(outcome: Dictionary):
	if not conversation_active:
		return
		
	print("[CONVERSATION] Ended with %s - Outcome: %s" % [
		current_npc.npc_name if current_npc else "Unknown", 
		outcome.get("outcome", "unknown")
	])
	
	conversation_active = false
	current_npc = null
	current_conversation_data = {}
	conversation_turn = 0
	
	conversation_ended.emit(outcome)

# =============================================================================
# SOCIAL DNA & RELATIONSHIP MANAGEMENT
# =============================================================================

func update_social_dna(chosen_social_type: SocialDNAManager.SocialType):
	var changes = {}
	
	# +3 to chosen trait, +1 to others
	for social_type in SocialDNAManager.social_dna:
		if social_type == chosen_social_type:
			changes[social_type] = 3
		else:
			changes[social_type] = 1
	
	# Apply changes
	for social_type in changes:
		SocialDNAManager.social_dna[social_type] += changes[social_type]
	
	SocialDNAManager.social_dna_changed.emit(SocialDNAManager.social_dna.duplicate())
	social_dna_updated.emit(changes)
	
	print("[SOCIAL DNA] Updated: +%d %s, +1 to others" % [
		3, 
		SocialDNAManager.get_social_type_name(chosen_social_type)
	])

func update_relationship(chosen_option: Dictionary, compatibility_result: String):
	if not current_npc:
		return
		
	var npc_id = current_npc.npc_name  # Use name as ID for Phase 2
	var old_trust = get_npc_trust_level(current_npc)
	
	# Initialize relationship data if not exists
	if not relationship_data.has(npc_id):
		relationship_data[npc_id] = {
			"trust_level": 0.0,
			"total_interactions": 0,
			"successful_interactions": 0,
			"last_conversation_outcome": ""
		}
	
	var relationship = relationship_data[npc_id]
	relationship.total_interactions += 1
	
	# Update trust based on compatibility result
	var trust_change = calculate_relationship_change(compatibility_result)
	relationship.trust_level += trust_change
	relationship.trust_level = clamp(relationship.trust_level, -2.0, 3.0)  # Trust range: -2 to +3
	
	if trust_change > 0:
		relationship.successful_interactions += 1
	
	relationship.last_conversation_outcome = compatibility_result
	
	var new_trust = relationship.trust_level
	
	if abs(new_trust - old_trust) > 0.05:  # Only emit if meaningful change
		relationship_changed.emit(current_npc, old_trust, new_trust)
		print("[RELATIONSHIP] %s: %.2f → %.2f (%s)" % [
			npc_id, old_trust, new_trust, 
			"+" + str(trust_change) if trust_change > 0 else str(trust_change)
		])

func get_npc_trust_level(npc: SocialNPC) -> float:
	if not npc:
		return 0.0
	
	var npc_id = npc.npc_name
	if relationship_data.has(npc_id):
		return relationship_data[npc_id].trust_level
	
	return 0.0  # Stranger level

func get_trust_level_name(trust: float) -> String:
	if trust >= 2.0:
		return "Close"
	elif trust >= 1.0:
		return "Trusted"
	elif trust >= 0.5:
		return "Professional"
	elif trust >= -0.5:
		return "Stranger"
	else:
		return "Hostile"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

func get_compatibility_flag(compatibility: float) -> String:
	if compatibility >= 1.5:
		return "VERY COMPATIBLE"
	elif compatibility >= 0.8:
		return "COMPATIBLE"
	elif compatibility >= -0.3:
		return "NEUTRAL"
	elif compatibility >= -0.8:
		return "INCOMPATIBLE" 
	else:
		return "VERY INCOMPATIBLE"

func is_conversation_active() -> bool:
	return conversation_active

func get_current_conversation_info() -> Dictionary:
	if not conversation_active:
		return {}
	
	return {
		"npc": current_npc,
		"turn": conversation_turn,
		"type": current_conversation_data.get("type", "unknown"),
		"trust_level": get_npc_trust_level(current_npc)
	}
