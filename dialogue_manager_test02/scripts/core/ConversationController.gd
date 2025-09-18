# =============================================================================
# ENHANCED CONVERSATION CONTROLLER - Phase 2B
# File: scripts/core/ConversationController.gd (REPLACE existing file)
# Adds trust gates, failure states, and enhanced relationship tracking
# =============================================================================

extends Node
class_name ConversationController

# Conversation types
enum ConversationType {
	QUICK_CHAT,      # 1-2 exchanges, no trust required
	TOPIC_DISCUSSION, # 3-5 exchanges, requires Professional trust
	DEEP_CONVERSATION # 5+ exchanges, requires Trusted trust
}

# Conversation outcomes
enum ConversationOutcome {
	SUCCESS,
	PARTIAL_SUCCESS,
	FAILURE,
	TRUST_GATE_BLOCKED,
	INTERRUPTED
}

# Trust level thresholds
const TRUST_THRESHOLDS = {
	"HOSTILE": -1.0,
	"STRANGER": 0.0,
	"PROFESSIONAL": 1.0,
	"TRUSTED": 2.0,
	"CLOSE": 3.0
}

# Conversation requirements
const CONVERSATION_REQUIREMENTS = {
	ConversationType.QUICK_CHAT: 0.0,        # No trust required
	ConversationType.TOPIC_DISCUSSION: 1.0,  # Professional trust required
	ConversationType.DEEP_CONVERSATION: 2.0  # Trusted trust required
}

# Current conversation state
var current_npc: SocialNPC = null
var current_conversation_data: Dictionary = {}
var conversation_turn: int = 0
var conversation_active: bool = false
var relationship_data: Dictionary = {}
var conversation_outcome: ConversationOutcome = ConversationOutcome.SUCCESS

# Signals for UI updates
signal conversation_started(npc: SocialNPC, opening_line: String)
signal conversation_continued(npc_line: String, player_options: Array)
signal conversation_ended(outcome: Dictionary)
signal conversation_failed(reason: String, retry_info: Dictionary)
signal trust_gate_encountered(npc: SocialNPC, required_trust: String, current_trust: String)
signal social_dna_updated(changes: Dictionary)
signal relationship_changed(npc: SocialNPC, old_trust: float, new_trust: float)

func _ready():
	# Initialize relationship tracking
	relationship_data = {}
	print("[CONVERSATION CONTROLLER] Phase 2B Enhanced system ready")

# =============================================================================
# ENHANCED CONVERSATION FLOW WITH TRUST GATES
# =============================================================================

func start_conversation(npc: SocialNPC, conversation_type: ConversationType = ConversationType.QUICK_CHAT):
	if conversation_active:
		print("[DEBUG] Conversation already active, ending previous")
		end_conversation({"outcome": ConversationOutcome.INTERRUPTED})
	
	current_npc = npc
	conversation_turn = 0
	conversation_active = true
	conversation_outcome = ConversationOutcome.SUCCESS
	
	# Check trust requirements
	var current_trust = get_npc_trust_level(npc)
	var required_trust = CONVERSATION_REQUIREMENTS[conversation_type]
	
	if current_trust < required_trust:
		handle_trust_gate_blocked(conversation_type, current_trust, required_trust)
		return
	
	# Get conversation data based on NPC archetype, relationship, and trust
	current_conversation_data = ConversationData.get_conversation(
		npc.archetype, 
		conversation_type,
		current_trust,
		SocialDNAManager.calculate_compatibility(npc.archetype)
	)
	
	# Get opening line based on compatibility, trust, and history
	var opening_line = get_enhanced_opening_line()
	
	print("[CONVERSATION] Started with %s - Turn %d [%s] Trust: %.1f" % [
		npc.npc_name, conversation_turn, get_conversation_type_name(conversation_type), current_trust
	])
	conversation_started.emit(npc, opening_line)
	
	# Move to player response phase
	present_player_options()

func handle_trust_gate_blocked(conversation_type: ConversationType, current_trust: float, required_trust: float):
	var required_trust_name = get_trust_level_name(required_trust)
	var current_trust_name = get_trust_level_name(current_trust)
	
	print("[TRUST GATE] %s conversation blocked - Need: %s, Have: %s" % [
		get_conversation_type_name(conversation_type),
		required_trust_name,
		current_trust_name
	])
	
	# Show trust gate message
	var gate_message = get_trust_gate_message(conversation_type, required_trust_name)
	
	conversation_active = false
	trust_gate_encountered.emit(current_npc, required_trust_name, current_trust_name)
	
	# Emit as a special "conversation" that immediately ends with gate info
	conversation_started.emit(current_npc, gate_message)
	
	var gate_outcome = {
		"outcome": ConversationOutcome.TRUST_GATE_BLOCKED,
		"required_trust": required_trust_name,
		"current_trust": current_trust_name,
		"conversation_type": get_conversation_type_name(conversation_type),
		"suggestion": get_trust_building_suggestion()
	}
	
	conversation_ended.emit(gate_outcome)

func get_trust_gate_message(conversation_type: ConversationType, required_trust_name: String) -> String:
	var messages = {
		ConversationType.TOPIC_DISCUSSION: "[TRUST REQUIRED: %s] I'm not ready to discuss important matters with you yet. Perhaps we could start with something simpler?" % required_trust_name,
		ConversationType.DEEP_CONVERSATION: "[TRUST REQUIRED: %s] That kind of conversation requires a deeper level of trust between us. We'll need to know each other better first." % required_trust_name
	}
	
	return messages.get(conversation_type, "[TRUST REQUIRED: %s] I need to trust you more before we can have that conversation." % required_trust_name)

func get_trust_building_suggestion() -> String:
	return "Try building trust through successful Quick Chats and Topic Discussions."

# =============================================================================
# ENHANCED CONVERSATION PROCESSING WITH FAILURE DETECTION
# =============================================================================

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
	var npc_reaction = get_enhanced_npc_reaction(chosen_option, compatibility)
	
	# Check for conversation failure
	if check_conversation_failure(npc_reaction, compatibility):
		handle_conversation_failure(npc_reaction)
		return
	
	# Update relationship based on reaction
	update_enhanced_relationship(chosen_option, npc_reaction.compatibility_result)
	
	print("[CONVERSATION] Player chose: [%s] %s" % [
		SocialDNAManager.get_social_type_name(social_type).to_upper(), 
		chosen_option.text
	])
	print("[CONVERSATION] NPC reacts: %s" % npc_reaction.text)
	
	# Move to next turn or end conversation
	conversation_turn += 1
	
	if should_end_conversation(npc_reaction):
		present_final_reaction(npc_reaction)
	else:
		present_next_turn(npc_reaction)

# =============================================================================
# FAILURE STATE HANDLING
# =============================================================================

func check_conversation_failure(npc_reaction: Dictionary, compatibility: float) -> bool:
	# Failure conditions:
	# 1. Very poor compatibility with multiple bad reactions
	# 2. Trust level drops too low during conversation
	# 3. Consecutive incompatible choices
	
	if npc_reaction.compatibility_result == "VERY_INCOMPATIBLE":
		# Check if this is a pattern of bad choices
		var recent_failures = get_recent_interaction_failures()
		if recent_failures >= 2:  # Third strike
			return true
	
	# Check if trust would drop to hostile levels
	var current_trust = get_npc_trust_level(current_npc)
	var trust_change = npc_reaction.get("relationship_change", 0.0)
	if current_trust + trust_change <= TRUST_THRESHOLDS.HOSTILE:
		return true
	
	return false

func get_recent_interaction_failures() -> int:
	# Count recent failures in this conversation
	# This is a simplified version - could track across conversation history
	var failures = 0
	# For now, just return 0 to allow testing of other failure conditions
	return failures

func handle_conversation_failure(npc_reaction: Dictionary):
	print("[CONVERSATION FAILURE] Conversation failed due to poor compatibility")
	
	conversation_outcome = ConversationOutcome.FAILURE
	
	# Apply failure consequences
	apply_failure_consequences()
	
	# Create failure message
	var failure_message = get_failure_message(npc_reaction)
	
	# Show failure reaction
	present_final_reaction({
		"text": failure_message,
		"compatibility_result": "FAILURE",
		"relationship_change": -0.3  # Penalty for failure
	})
	
	# Emit failure signal with retry information
	var retry_info = {
		"can_retry": true,
		"retry_suggestion": "Try a different social approach or improve your compatibility first.",
		"recommended_social_types": get_recommended_social_types(),
		"cooldown_turns": 0  # Could implement cooldown later
	}
	
	conversation_failed.emit("Poor social compatibility led to conversation breakdown.", retry_info)

func get_failure_message(npc_reaction: Dictionary) -> String:
	match current_npc.archetype:
		SocialDNAManager.NPCArchetype.AUTHORITY:
			return "[CONVERSATION FAILED] I don't have time for this incompetence. Come back when you understand how to communicate properly."
		SocialDNAManager.NPCArchetype.INTELLECTUAL:
			return "[CONVERSATION FAILED] This discourse has devolved beyond any productive purpose. Perhaps reflection would serve you better than conversation."
		_:
			return "[CONVERSATION FAILED] I don't think we're understanding each other. Let's try this again later."

func apply_failure_consequences():
	# Apply trust penalty for failed conversation
	var npc_id = current_npc.npc_name
	if not relationship_data.has(npc_id):
		initialize_relationship(npc_id)
	
	var relationship = relationship_data[npc_id]
	relationship.failed_interactions += 1
	relationship.trust_level -= 0.3  # Failure penalty
	relationship.trust_level = clamp(relationship.trust_level, -2.0, 3.0)
	relationship.last_conversation_outcome = "FAILURE"

func get_recommended_social_types() -> Array:
	# Suggest social types that work well with this NPC archetype
	var preferences = SocialDNAManager.archetype_preferences[current_npc.archetype]
	var recommended = []
	
	for social_type in preferences:
		if preferences[social_type] >= 1.0:  # Positive preference
			recommended.append(SocialDNAManager.get_social_type_name(social_type))
	
	return recommended

# =============================================================================
# ENHANCED NPC REACTIONS WITH TRUST CONTEXT
# =============================================================================

func get_enhanced_npc_reaction(chosen_option: Dictionary, compatibility: float) -> Dictionary:
	var archetype_preferences = SocialDNAManager.archetype_preferences[current_npc.archetype]
	var social_preference = archetype_preferences.get(chosen_option.social_type, 0.0)
	var trust_level = get_npc_trust_level(current_npc)
	
	# Trust affects how reactions are delivered
	var trust_modifier = get_trust_reaction_modifier(trust_level)
	
	# Determine compatibility result (same as before)
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
	
	# Get reaction text with trust context
	var reaction_text = ConversationData.get_trust_aware_reaction_text(
		current_npc.archetype,
		chosen_option.social_type,
		compatibility_result,
		trust_level,
		conversation_turn
	)
	
	return {
		"text": "[%s%s] %s" % [reaction_modifier, trust_modifier, reaction_text],
		"compatibility_result": compatibility_result,
		"social_preference": social_preference,
		"trust_modifier": trust_modifier,
		"relationship_change": calculate_trust_aware_relationship_change(compatibility_result, trust_level)
	}

func get_trust_reaction_modifier(trust_level: float) -> String:
	if trust_level >= TRUST_THRESHOLDS.TRUSTED:
		return " | TRUSTED"
	elif trust_level >= TRUST_THRESHOLDS.PROFESSIONAL:
		return " | PROFESSIONAL"
	elif trust_level <= TRUST_THRESHOLDS.HOSTILE:
		return " | HOSTILE"
	else:
		return ""

func calculate_trust_aware_relationship_change(compatibility_result: String, trust_level: float) -> float:
	var base_change = 0.0
	
	match compatibility_result:
		"VERY_COMPATIBLE": base_change = 0.3
		"COMPATIBLE": base_change = 0.1
		"NEUTRAL": base_change = 0.0
		"INCOMPATIBLE": base_change = -0.1
		"VERY_INCOMPATIBLE": base_change = -0.2
	
	# Trust amplifies positive changes and dampens negative ones at higher levels
	if trust_level >= TRUST_THRESHOLDS.PROFESSIONAL:
		if base_change > 0:
			base_change *= 1.2  # 20% bonus for positive interactions when trusted
		else:
			base_change *= 0.8  # 20% reduction in penalties when trusted
	
	return base_change

# =============================================================================
# ENHANCED OPENING LINES WITH RELATIONSHIP HISTORY
# =============================================================================

func get_enhanced_opening_line() -> String:
	var compatibility = SocialDNAManager.calculate_compatibility(current_npc.archetype)
	var trust_level = get_npc_trust_level(current_npc)
	var relationship_history = get_relationship_history_context()
	
	var opening_lines = current_conversation_data.get("opening_lines", [])
	
	# First try to find trust-aware opening lines
	for line_data in opening_lines:
		if line_data.min_compatibility <= compatibility and compatibility <= line_data.max_compatibility:
			if line_data.min_trust_level <= trust_level:
				var base_line = line_data.text
				
				# Add relationship context if available
				if relationship_history != "":
					return "[%s%s] %s %s" % [
						get_compatibility_flag(compatibility),
						get_trust_flag(trust_level),
						base_line,
						relationship_history
					]
				else:
					return "[%s%s] %s" % [
						get_compatibility_flag(compatibility),
						get_trust_flag(trust_level),
						base_line
					]
	
	# Fallback
	return "[%s%s] Hello there." % [get_compatibility_flag(compatibility), get_trust_flag(trust_level)]

func get_relationship_history_context() -> String:
	var npc_id = current_npc.npc_name
	if not relationship_data.has(npc_id):
		return ""
	
	var relationship = relationship_data[npc_id]
	var last_outcome = relationship.get("last_conversation_outcome", "")
	
	match last_outcome:
		"SUCCESS":
			return "Good to see you again."
		"PARTIAL_SUCCESS":
			return "I hope our conversation goes better this time."
		"FAILURE":
			return "Let's see if you've learned anything since last time."
		_:
			return ""

func get_trust_flag(trust_level: float) -> String:
	var trust_name = get_trust_level_name(trust_level)
	if trust_name != "Stranger":
		return " | " + trust_name.to_upper()
	return ""

# =============================================================================
# ENHANCED RELATIONSHIP MANAGEMENT
# =============================================================================

func update_enhanced_relationship(chosen_option: Dictionary, compatibility_result: String):
	if not current_npc:
		return
		
	var npc_id = current_npc.npc_name
	var old_trust = get_npc_trust_level(current_npc)
	
	# Initialize relationship data if not exists
	if not relationship_data.has(npc_id):
		initialize_relationship(npc_id)
	
	var relationship = relationship_data[npc_id]
	relationship.total_interactions += 1
	
	# Update trust based on compatibility result
	var trust_change = calculate_trust_aware_relationship_change(compatibility_result, old_trust)
	relationship.trust_level += trust_change
	relationship.trust_level = clamp(relationship.trust_level, -2.0, 3.0)
	
	# Track success/failure
	if compatibility_result in ["VERY_COMPATIBLE", "COMPATIBLE"]:
		relationship.successful_interactions += 1
		relationship.last_conversation_outcome = "SUCCESS"
	elif compatibility_result == "NEUTRAL":
		relationship.last_conversation_outcome = "PARTIAL_SUCCESS"
	else:
		relationship.last_conversation_outcome = "FAILURE"
	
	# Track social approaches used
	if not relationship.has("social_history"):
		relationship.social_history = {}
	
	var social_type_name = SocialDNAManager.get_social_type_name(chosen_option.social_type)
	if not relationship.social_history.has(social_type_name):
		relationship.social_history[social_type_name] = 0
	relationship.social_history[social_type_name] += 1
	
	var new_trust = relationship.trust_level
	
	if abs(new_trust - old_trust) > 0.05:
		relationship_changed.emit(current_npc, old_trust, new_trust)
		print("[RELATIONSHIP] %s: %.2f → %.2f (%s) [%s]" % [
			npc_id, old_trust, new_trust, 
			"+" + str(trust_change) if trust_change > 0 else str(trust_change),
			get_trust_level_name(new_trust)
		])

func initialize_relationship(npc_id: String):
	relationship_data[npc_id] = {
		"trust_level": 0.0,  # Stranger level
		"total_interactions": 0,
		"successful_interactions": 0,
		"failed_interactions": 0,
		"last_conversation_outcome": "",
		"social_history": {},
		"conversations_unlocked": ["QUICK_CHAT"],
		"first_met": Time.get_unix_time_from_system()
	}

func get_npc_trust_level(npc: SocialNPC) -> float:
	if not npc:
		return 0.0
	
	var npc_id = npc.npc_name
	if relationship_data.has(npc_id):
		return relationship_data[npc_id].trust_level
	
	return 0.0  # Stranger level

func get_trust_level_name(trust: float) -> String:
	if trust >= TRUST_THRESHOLDS.CLOSE:
		return "Close"
	elif trust >= TRUST_THRESHOLDS.TRUSTED:
		return "Trusted"
	elif trust >= TRUST_THRESHOLDS.PROFESSIONAL:
		return "Professional"
	elif trust >= TRUST_THRESHOLDS.STRANGER:
		return "Stranger"
	else:
		return "Hostile"

# =============================================================================
# CONVERSATION AVAILABILITY CHECKING
# =============================================================================

func can_start_conversation(npc: SocialNPC, conversation_type: ConversationType) -> Dictionary:
	var current_trust = get_npc_trust_level(npc)
	var required_trust = CONVERSATION_REQUIREMENTS[conversation_type]
	
	var result = {
		"can_start": current_trust >= required_trust,
		"current_trust": current_trust,
		"current_trust_name": get_trust_level_name(current_trust),
		"required_trust": required_trust,
		"required_trust_name": get_trust_level_name(required_trust),
		"conversation_type": conversation_type
	}
	
	if not result.can_start:
		result.blocker_reason = "Trust level too low"
		result.suggestion = "Build trust through simpler conversations first"
	
	return result

func get_available_conversation_types(npc: SocialNPC) -> Array:
	var available = []
	var current_trust = get_npc_trust_level(npc)
	
	for conv_type in ConversationType.values():
		var required_trust = CONVERSATION_REQUIREMENTS[conv_type]
		if current_trust >= required_trust:
			available.append(conv_type)
	
	return available

# =============================================================================
# UTILITY FUNCTIONS (Enhanced)
# =============================================================================

func get_conversation_type_name(conv_type: ConversationType) -> String:
	match conv_type:
		ConversationType.QUICK_CHAT: return "QUICK"
		ConversationType.TOPIC_DISCUSSION: return "TOPIC"
		ConversationType.DEEP_CONVERSATION: return "DEEP"
		_: return "UNKNOWN"

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

func get_relationship_summary(npc: SocialNPC) -> Dictionary:
	var npc_id = npc.npc_name
	if not relationship_data.has(npc_id):
		return {"trust_level": 0.0, "trust_name": "Stranger", "total_interactions": 0}
	
	var relationship = relationship_data[npc_id]
	return {
		"trust_level": relationship.trust_level,
		"trust_name": get_trust_level_name(relationship.trust_level),
		"total_interactions": relationship.total_interactions,
		"successful_interactions": relationship.successful_interactions,
		"success_rate": float(relationship.successful_interactions) / max(1, relationship.total_interactions) * 100.0,
		"last_outcome": relationship.get("last_conversation_outcome", "None"),
		"available_conversations": get_available_conversation_types(npc)
	}

# =============================================================================
# EXISTING METHODS (Updated signatures but same core logic)
# =============================================================================

func present_player_options():
	if conversation_turn >= current_conversation_data.turns.size():
		print("[DEBUG] No more turns available, ending conversation")
		end_conversation({"outcome": conversation_outcome})
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
	
	conversation_continued.emit("", formatted_options)

func present_next_turn(npc_reaction: Dictionary):
	if conversation_turn >= current_conversation_data.turns.size():
		end_conversation_with_outcome(npc_reaction)
		return
	
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
	conversation_continued.emit(npc_reaction.text, [])
	end_conversation_with_outcome(npc_reaction)

func should_end_conversation(npc_reaction: Dictionary) -> bool:
	var max_turns = get_max_turns_for_type(current_conversation_data.get("type", ConversationType.QUICK_CHAT))
	
	if conversation_turn >= max_turns:
		return true
	
	if npc_reaction.compatibility_result == "VERY_INCOMPATIBLE":
		return true
	
	return conversation_turn >= current_conversation_data.turns.size()

func get_max_turns_for_type(conv_type: ConversationType) -> int:
	match conv_type:
		ConversationType.QUICK_CHAT: return 2
		ConversationType.TOPIC_DISCUSSION: return 5  
		ConversationType.DEEP_CONVERSATION: return 8
		_: return 2

func end_conversation_with_outcome(final_reaction: Dictionary):
	var outcome = {
		"outcome": conversation_outcome,
		"final_reaction": final_reaction,
		"turns_completed": conversation_turn,
		"final_trust": get_npc_trust_level(current_npc),
		"trust_name": get_trust_level_name(get_npc_trust_level(current_npc)),
		"social_dna_changes": {},
		"relationship_changes": final_reaction.get("relationship_change", 0.0)
	}
	
	end_conversation(outcome)

func end_conversation(outcome: Dictionary):
	if not conversation_active:
		return
		
	print("[CONVERSATION] Ended with %s - Outcome: %s" % [
		current_npc.npc_name if current_npc else "Unknown", 
		str(outcome.get("outcome", "unknown"))
	])
	
	conversation_active = false
	current_npc = null
	current_conversation_data = {}
	conversation_turn = 0
	
	conversation_ended.emit(outcome)

func update_social_dna(chosen_social_type: SocialDNAManager.SocialType):
	var changes = {}
	
	for social_type in SocialDNAManager.social_dna:
		if social_type == chosen_social_type:
			changes[social_type] = 3
		else:
			changes[social_type] = 1
	
	for social_type in changes:
		SocialDNAManager.social_dna[social_type] += changes[social_type]
	
	SocialDNAManager.social_dna_changed.emit(SocialDNAManager.social_dna.duplicate())
	social_dna_updated.emit(changes)
	
	print("[SOCIAL DNA] Updated: +%d %s, +1 to others" % [
		3, 
		SocialDNAManager.get_social_type_name(chosen_social_type)
	])

func is_conversation_active() -> bool:
	return conversation_active

func get_current_conversation_info() -> Dictionary:
	if not conversation_active:
		return {}
	
	return {
		"npc": current_npc,
		"turn": conversation_turn,
		"type": current_conversation_data.get("type", "unknown"),
		"trust_level": get_npc_trust_level(current_npc),
		"outcome": conversation_outcome
	}
