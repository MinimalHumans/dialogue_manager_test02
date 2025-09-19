# =============================================================================
# COMPLETE CONVERSATION CONTROLLER - Phase 2C: Information System
# File: scripts/core/ConversationController.gd (COMPLETE REPLACEMENT)
# All fixes integrated - ready to use
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
	INTERRUPTED,
	INFORMATION_GAINED  # New: Successful information acquisition
}

# Information gained tracking
enum InformationType {
	ACCESS,        # Codes, keys, passwords
	SECURITY,      # Patrol routes, security info
	LOCATION,      # Maps, hidden places, coordinates
	INTELLIGENCE,  # People info, plans, operations
	KNOWLEDGE      # Research, technical data, secrets
}

# Trust level thresholds (unchanged)
const TRUST_THRESHOLDS = {
	"HOSTILE": -1.0,
	"STRANGER": 0.0,
	"PROFESSIONAL": 1.0,
	"TRUSTED": 2.0,
	"CLOSE": 3.0
}

# Conversation requirements (unchanged)
const CONVERSATION_REQUIREMENTS = {
	ConversationType.QUICK_CHAT: 0.0,        
	ConversationType.TOPIC_DISCUSSION: 1.0,  
	ConversationType.DEEP_CONVERSATION: 2.0  
}

# NEW: Information tracking system
var player_information_inventory: Dictionary = {
	InformationType.ACCESS: [],
	InformationType.SECURITY: [],
	InformationType.LOCATION: [],
	InformationType.INTELLIGENCE: [],
	InformationType.KNOWLEDGE: []
}

# Enhanced conversation state
var current_npc: SocialNPC = null
var current_conversation_data: Dictionary = {}
var conversation_turn: int = 0
var conversation_active: bool = false
var relationship_data: Dictionary = {}
var conversation_outcome: ConversationOutcome = ConversationOutcome.SUCCESS

# NEW: Information request tracking
var current_information_request: Dictionary = {}
var conversation_objective: String = ""

# Enhanced signals
signal conversation_started(npc: SocialNPC, opening_line: String)
signal conversation_continued(npc_line: String, player_options: Array)
signal conversation_ended(outcome: Dictionary)
signal conversation_failed(reason: String, retry_info: Dictionary)
signal trust_gate_encountered(npc: SocialNPC, required_trust: String, current_trust: String)
signal social_dna_updated(changes: Dictionary)
signal relationship_changed(npc: SocialNPC, old_trust: float, new_trust: float)

# NEW: Information-specific signals
signal information_gained(info_type: InformationType, info_data: Dictionary)
signal information_request_failed(reason: String, npc_name: String)
signal objective_completed(objective: String, reward: Dictionary)

func _ready():
	relationship_data = {}
	player_information_inventory = {
		InformationType.ACCESS: [],
		InformationType.SECURITY: [],
		InformationType.LOCATION: [],
		InformationType.INTELLIGENCE: [],
		InformationType.KNOWLEDGE: []
	}
	print("[CONVERSATION CONTROLLER] Phase 2C Enhanced system ready with information tracking")

# =============================================================================
# ENHANCED CONVERSATION FLOW WITH INFORMATION OBJECTIVES
# =============================================================================

func start_conversation(npc: SocialNPC, conversation_type: ConversationType = ConversationType.QUICK_CHAT, objective: String = ""):
	if conversation_active:
		print("[DEBUG] Conversation already active, ending previous")
		end_conversation({"outcome": ConversationOutcome.INTERRUPTED})
	
	current_npc = npc
	conversation_turn = 0
	conversation_active = true
	conversation_outcome = ConversationOutcome.SUCCESS
	conversation_objective = objective
	current_information_request = {}
	
	# Check trust requirements
	var current_trust = get_npc_trust_level(npc)
	var required_trust = CONVERSATION_REQUIREMENTS[conversation_type]
	
	if current_trust < required_trust:
		handle_trust_gate_blocked(conversation_type, current_trust, required_trust)
		return
	
	# Get enhanced conversation data with information context
	current_conversation_data = ConversationData.get_conversation(
		npc.archetype, 
		conversation_type,
		current_trust,
		SocialDNAManager.calculate_compatibility(npc.archetype),
		npc.npc_name,
		objective
	)
	
	# Get opening line with information context
	var opening_line = get_enhanced_opening_line_with_objective()
	
	print("[CONVERSATION] Started with %s - %s [Trust: %.1f]" % [
		npc.npc_name, 
		get_conversation_type_name(conversation_type), 
		current_trust
	])
	
	if objective != "":
		print("[OBJECTIVE] %s" % objective)
	
	conversation_started.emit(npc, opening_line)
	present_player_options()

func get_enhanced_opening_line_with_objective() -> String:
	if not current_npc:
		return "Hello there."
	
	var compatibility = SocialDNAManager.calculate_compatibility(current_npc.archetype)
	var trust_level = get_npc_trust_level(current_npc)
	
	# Get available information for context
	var available_info = current_conversation_data.get("available_information", {})
	var info_context = get_information_context_string(available_info)
	
	var opening_lines = current_conversation_data.get("opening_lines", [])
	
	# Enhanced opening with information availability hints
	for line_data in opening_lines:
		if line_data.min_compatibility <= compatibility and compatibility <= line_data.max_compatibility:
			if line_data.min_trust_level <= trust_level:
				var base_line = line_data.text
				var flags = "[%s%s]" % [
					get_compatibility_flag(compatibility),
					get_trust_flag(trust_level)
				]
				
				# Add information availability hint if relevant
				if info_context != "":
					return "%s %s\n\n💡 %s" % [flags, base_line, info_context]
				else:
					return "%s %s" % [flags, base_line]
	
	# Fallback
	return "[%s%s] Hello there." % [get_compatibility_flag(compatibility), get_trust_flag(trust_level)]

func get_information_context_string(available_info: Dictionary) -> String:
	if available_info.size() == 0:
		return ""
	
	var context_hints = []
	for info_key in available_info:
		var info_data = available_info[info_key]
		var title = info_data.get("title", "information")
		context_hints.append(title)
	
	if context_hints.size() == 1:
		return "I might be able to help with: %s" % context_hints[0]
	elif context_hints.size() <= 3:
		return "I might be able to help with: %s" % ", ".join(context_hints)
	else:
		return "I have access to various types of information you might need"

# =============================================================================
# ENHANCED CONVERSATION PROCESSING WITH INFORMATION REQUESTS
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
	
	# Handle information requests
	var information_request = chosen_option.get("information_request", "")
	if information_request != "":
		process_information_request(chosen_option, information_request)
		return
	
	# Standard conversation processing
	process_standard_choice(chosen_option)

func process_information_request(chosen_option: Dictionary, information_request: String):
	print("[INFO REQUEST] Player requesting: %s" % information_request)
	
	# Store the current request
	current_information_request = {
		"request": information_request,
		"social_approach": chosen_option.social_type,
		"success_chance": chosen_option.get("success_chance", 0.5),
		"risk_level": chosen_option.get("risk_level", "medium")
	}
	
	# Calculate success based on compatibility, trust, and approach
	var success_result = calculate_information_request_success(chosen_option, information_request)
	
	# Update Social DNA
	update_social_dna(chosen_option.social_type)
	
	# Generate NPC reaction with information context
	var npc_reaction = get_information_request_reaction(chosen_option, information_request, success_result)
	
	# Process the result
	if success_result.success:
		handle_successful_information_request(information_request, npc_reaction, success_result)
	else:
		handle_failed_information_request(information_request, npc_reaction, success_result)

func calculate_information_request_success(chosen_option: Dictionary, information_request: String) -> Dictionary:
	if not current_npc:
		return {"success": false, "reason": "No NPC available", "trust_sufficient": false}
	
	var compatibility = SocialDNAManager.calculate_compatibility(current_npc.archetype)
	var trust_level = get_npc_trust_level(current_npc)
	var base_success_chance = chosen_option.get("success_chance", 0.5)
	
	# Get information requirements
	var available_info = current_conversation_data.get("available_information", {})
	if not available_info.has(information_request):
		return {"success": false, "reason": "Information not available", "trust_sufficient": false}
	
	var info_data = available_info[information_request]
	var required_trust = info_data.trust_required
	var compatibility_bonus = info_data.get("compatibility_bonus", 0.0)
	
	# Check trust requirements
	var effective_trust = trust_level + (compatibility * compatibility_bonus)
	if effective_trust < required_trust:
		return {
			"success": false, 
			"reason": "Insufficient trust", 
			"trust_sufficient": false,
			"required_trust": required_trust,
			"effective_trust": effective_trust
		}
	
	# Calculate final success chance
	var compatibility_modifier = 0.0
	if compatibility >= 0.8:
		compatibility_modifier = 0.2
	elif compatibility >= 0.3:
		compatibility_modifier = 0.1
	elif compatibility <= -0.3:
		compatibility_modifier = -0.1
	elif compatibility <= -0.8:
		compatibility_modifier = -0.2
	
	var final_success_chance = base_success_chance + compatibility_modifier
	final_success_chance = clamp(final_success_chance, 0.1, 0.95)
	
	var success = randf() < final_success_chance
	
	return {
		"success": success,
		"reason": "Compatible approach" if success else "Poor approach",
		"trust_sufficient": true,
		"final_chance": final_success_chance,
		"compatibility_modifier": compatibility_modifier,
		"info_data": info_data
	}

func handle_successful_information_request(information_request: String, npc_reaction: Dictionary, success_result: Dictionary):
	print("[SUCCESS] Information acquired: %s" % information_request)
	
	conversation_outcome = ConversationOutcome.INFORMATION_GAINED
	
	# Add information to player's inventory
	var info_data = success_result.info_data
	var npc_name = current_npc.npc_name if current_npc else "Unknown NPC"
	var trust_level = get_npc_trust_level(current_npc)
	
	var info_item = {
		"id": info_data.value,
		"title": info_data.title,
		"description": info_data.description,
		"source_npc": npc_name,
		"acquired_at": Time.get_unix_time_from_system(),
		"trust_level_when_acquired": trust_level
	}
	
	# Categorize information
	var info_type = get_information_type_from_string(info_data.info_type)
	player_information_inventory[info_type].append(info_item)
	
	# Update relationship positively
	update_enhanced_relationship_for_information(current_information_request, "SUCCESS")
	
	# Show success reaction and end conversation
	present_final_reaction(npc_reaction)
	
	# Emit information gained signal
	information_gained.emit(info_type, info_item)
	
	print("[INVENTORY] Added to %s: %s" % [info_data.info_type, info_data.title])

func handle_failed_information_request(information_request: String, npc_reaction: Dictionary, success_result: Dictionary):
	print("[FAILED] Information request failed: %s" % success_result.reason)
	
	if not success_result.trust_sufficient:
		# Trust gate failure
		conversation_outcome = ConversationOutcome.TRUST_GATE_BLOCKED
		handle_information_trust_gate(information_request, success_result)
	else:
		# Compatibility/approach failure
		conversation_outcome = ConversationOutcome.FAILURE
		update_enhanced_relationship_for_information(current_information_request, "FAILURE")
		
		# Show failure reaction
		present_final_reaction(npc_reaction)
		
		# Emit failure signal with retry info
		var retry_info = get_information_retry_suggestions(information_request, success_result)
		var npc_name = current_npc.npc_name if current_npc else "Unknown NPC"
		information_request_failed.emit(success_result.reason, npc_name)
		conversation_failed.emit("Failed to obtain information: " + success_result.reason, retry_info)

func get_information_request_reaction(chosen_option: Dictionary, information_request: String, success_result: Dictionary) -> Dictionary:
	if not current_npc:
		return {
			"text": "No response available.",
			"compatibility_result": "NEUTRAL",
			"relationship_change": 0.0,
			"information_success": false
		}
	
	var social_type = chosen_option.social_type
	var compatibility = SocialDNAManager.calculate_compatibility(current_npc.archetype)
	var trust_level = get_npc_trust_level(current_npc)
	
	# Determine compatibility result for reaction system
	var compatibility_result: String
	if success_result.success:
		compatibility_result = "VERY_COMPATIBLE" if compatibility >= 0.8 else "COMPATIBLE"
	else:
		if not success_result.trust_sufficient:
			compatibility_result = "TRUST_INSUFFICIENT"
		else:
			compatibility_result = "INCOMPATIBLE" if compatibility >= -0.3 else "VERY_INCOMPATIBLE"
	
	# Get NPC reaction text with information context
	var information_context = {
		"information_request": information_request,
		"success_chance": chosen_option.get("success_chance", 0.5),
		"success_result": success_result
	}
	
	var reaction_text = ConversationData.get_trust_aware_reaction_text(
		current_npc.archetype,
		social_type,
		compatibility_result,
		trust_level,
		conversation_turn,
		current_npc.npc_name,
		information_context
	)
	
	var relationship_change = 0.0
	if success_result.success:
		relationship_change = 0.2  # Information sharing builds trust
	else:
		if success_result.trust_sufficient:
			relationship_change = -0.1  # Poor approach damages trust slightly
		else:
			relationship_change = 0.0  # Trust gate doesn't damage relationship
	
	return {
		"text": reaction_text,
		"compatibility_result": compatibility_result,
		"relationship_change": relationship_change,
		"information_success": success_result.success
	}

func handle_information_trust_gate(information_request: String, success_result: Dictionary):
	var required_trust_name = get_trust_level_name(success_result.required_trust)
	var current_trust_name = get_trust_level_name(success_result.effective_trust)
	
	print("[TRUST GATE] Information blocked - Need: %s, Have: %s" % [required_trust_name, current_trust_name])
	
	# Create trust gate message for information
	var gate_message = get_information_trust_gate_message(information_request, required_trust_name)
	
	conversation_started.emit(current_npc, gate_message)
	
	var gate_outcome = {
		"outcome": ConversationOutcome.TRUST_GATE_BLOCKED,
		"required_trust": required_trust_name,
		"current_trust": current_trust_name,
		"information_blocked": information_request,
		"suggestion": "Build trust through successful conversations, then try again."
	}
	
	conversation_ended.emit(gate_outcome)
	conversation_active = false

func get_information_trust_gate_message(information_request: String, required_trust_name: String) -> String:
	if not current_npc:
		return "[TRUST REQUIRED: %s] I need to trust you more before sharing that information." % required_trust_name
	
	match current_npc.npc_name:
		"Captain Stone":
			match information_request:
				"security_codes":
					return "[TRUST REQUIRED: %s] Security codes aren't shared with just anyone. Prove you're reliable first." % required_trust_name
				"patrol_schedules":
					return "[TRUST REQUIRED: %s] Operational details are sensitive information. Build my trust first." % required_trust_name
				"weapon_cache":
					return "[TRUST REQUIRED: %s] Emergency resources are for trusted allies only. You're not there yet." % required_trust_name
				_:
					return "[TRUST REQUIRED: %s] That information is classified. Earn my trust first." % required_trust_name
		
		"Dr. Wisdom":
			match information_request:
				"classified_projects":
					return "[TRUST REQUIRED: %s] Classified research requires the highest level of discretion. We need a stronger professional relationship." % required_trust_name
				"lab_access":
					return "[TRUST REQUIRED: %s] Laboratory access requires professional trust. Perhaps we should work together more first." % required_trust_name
				_:
					return "[TRUST REQUIRED: %s] Such sensitive information requires a deeper level of professional trust." % required_trust_name
		
		_:
			return "[TRUST REQUIRED: %s] I need to trust you more before sharing that information." % required_trust_name

func get_information_retry_suggestions(information_request: String, success_result: Dictionary) -> Dictionary:
	var suggestions = []
	
	if not current_npc:
		suggestions.append("Try a different approach")
		return {"can_retry": true, "retry_suggestions": suggestions, "information_blocked": information_request}
	
	var compatibility = SocialDNAManager.calculate_compatibility(current_npc.archetype)
	
	# Get NPC preferences
	var preferences = SocialDNAManager.archetype_preferences[current_npc.archetype]
	var preferred_approaches = []
	
	for social_type in preferences:
		if preferences[social_type] >= 1.0:
			preferred_approaches.append(SocialDNAManager.get_social_type_name(social_type))
	
	suggestions.append("Try using approaches this NPC prefers: %s" % ", ".join(preferred_approaches))
	
	if compatibility < 0.0:
		suggestions.append("Improve compatibility by building your Social DNA in preferred traits")
	
	suggestions.append("Build more trust through successful Quick Chats first")
	
	return {
		"can_retry": true,
		"retry_suggestions": suggestions,
		"recommended_social_types": preferred_approaches,
		"information_blocked": information_request
	}

# =============================================================================
# ENHANCED RELATIONSHIP MANAGEMENT FOR INFORMATION SHARING
# =============================================================================

func update_enhanced_relationship_for_information(information_request: Dictionary, result: String):
	if not current_npc:
		return
		
	var npc_id = current_npc.npc_name
	var old_trust = get_npc_trust_level(current_npc)
	
	if not relationship_data.has(npc_id):
		initialize_relationship(npc_id)
	
	var relationship = relationship_data[npc_id]
	relationship.total_interactions += 1
	
	# Enhanced trust changes for information sharing
	var trust_change = 0.0
	match result:
		"SUCCESS":
			trust_change = 0.2  # Successful information sharing builds significant trust
			relationship.successful_interactions += 1
			relationship.last_conversation_outcome = "INFORMATION_GAINED"
			
			# Track successful information requests
			if not relationship.has("information_shared"):
				relationship.information_shared = []
			relationship.information_shared.append({
				"request": information_request.request,
				"timestamp": Time.get_unix_time_from_system()
			})
		
		"FAILURE":
			trust_change = -0.1  # Failed information requests slightly damage trust
			relationship.last_conversation_outcome = "INFORMATION_FAILED"
		
		"TRUST_GATE":
			trust_change = 0.0  # Trust gates don't damage relationships
			relationship.last_conversation_outcome = "TRUST_INSUFFICIENT"
	
	relationship.trust_level += trust_change
	relationship.trust_level = clamp(relationship.trust_level, -2.0, 3.0)
	
	var new_trust = relationship.trust_level
	
	if abs(new_trust - old_trust) > 0.05:
		relationship_changed.emit(current_npc, old_trust, new_trust)
		print("[RELATIONSHIP] %s: %.2f → %.2f (Information: %s)" % [
			npc_id, old_trust, new_trust, result
		])

# =============================================================================
# INFORMATION INVENTORY MANAGEMENT
# =============================================================================

func get_information_type_from_string(type_string: String) -> InformationType:
	match type_string.to_lower():
		"access":
			return InformationType.ACCESS
		"security":
			return InformationType.SECURITY
		"location":
			return InformationType.LOCATION
		"intelligence":
			return InformationType.INTELLIGENCE
		"knowledge":
			return InformationType.KNOWLEDGE
		_:
			return InformationType.INTELLIGENCE  # Default fallback

func get_player_information_inventory() -> Dictionary:
	return player_information_inventory.duplicate(true)

func get_information_count_by_type(info_type: InformationType) -> int:
	return player_information_inventory[info_type].size()

func get_total_information_count() -> int:
	var total = 0
	for info_type in player_information_inventory:
		total += player_information_inventory[info_type].size()
	return total

func has_information(information_id: String) -> bool:
	for info_type in player_information_inventory:
		for info_item in player_information_inventory[info_type]:
			if info_item.id == information_id:
				return true
	return false

func get_information_by_id(information_id: String) -> Dictionary:
	for info_type in player_information_inventory:
		for info_item in player_information_inventory[info_type]:
			if info_item.id == information_id:
				return info_item
	return {}

func get_information_from_npc(npc_name: String) -> Array:
	var npc_info = []
	for info_type in player_information_inventory:
		for info_item in player_information_inventory[info_type]:
			if info_item.source_npc == npc_name:
				npc_info.append(info_item)
	return npc_info

func get_information_type_name(info_type: InformationType) -> String:
	match info_type:
		InformationType.ACCESS: return "ACCESS CODES"
		InformationType.SECURITY: return "SECURITY INFO"
		InformationType.LOCATION: return "LOCATIONS"
		InformationType.INTELLIGENCE: return "INTELLIGENCE"
		InformationType.KNOWLEDGE: return "RESEARCH DATA"
		_: return "UNKNOWN"

# =============================================================================
# ENHANCED STANDARD CHOICE PROCESSING (for non-information conversations)
# =============================================================================

func process_standard_choice(chosen_option: Dictionary):
	if not current_npc:
		print("[ERROR] No current NPC for standard choice processing")
		return
	
	# Standard processing for conversations without information requests
	var social_type = chosen_option.social_type
	update_social_dna(social_type)
	
	var compatibility = SocialDNAManager.calculate_compatibility(current_npc.archetype)
	var npc_reaction = get_enhanced_npc_reaction(chosen_option, compatibility)
	
	# Check for conversation failure
	if check_conversation_failure(npc_reaction, compatibility):
		handle_conversation_failure(npc_reaction)
		return
	
	# Update relationship
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
# UTILITY FUNCTIONS AND COMPATIBILITY METHODS
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

func get_trust_flag(trust_level: float) -> String:
	var trust_name = get_trust_level_name(trust_level)
	if trust_name != "Stranger":
		return " | " + trust_name.to_upper()
	return ""

func get_enhanced_npc_reaction(chosen_option: Dictionary, compatibility: float) -> Dictionary:
	if not current_npc:
		return {
			"text": "No response available.",
			"compatibility_result": "NEUTRAL",
			"social_preference": 0.0,
			"trust_modifier": "",
			"relationship_change": 0.0
		}
	
	var archetype_preferences = SocialDNAManager.archetype_preferences[current_npc.archetype]
	var social_preference = archetype_preferences.get(chosen_option.social_type, 0.0)
	var trust_level = get_npc_trust_level(current_npc)
	
	# Trust affects how reactions are delivered
	var trust_modifier = get_trust_reaction_modifier(trust_level)
	
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
	
	# Get reaction text with trust context
	var reaction_text = ConversationData.get_trust_aware_reaction_text(
		current_npc.archetype,
		chosen_option.social_type,
		compatibility_result,
		trust_level,
		conversation_turn,
		current_npc.npc_name
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
	if not current_npc:
		return false
	
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
	if not current_npc:
		return "[CONVERSATION FAILED] I don't think we're understanding each other. Let's try this again later."
	
	match current_npc.archetype:
		SocialDNAManager.NPCArchetype.AUTHORITY:
			return "[CONVERSATION FAILED] I don't have time for this incompetence. Come back when you understand how to communicate properly."
		SocialDNAManager.NPCArchetype.INTELLECTUAL:
			return "[CONVERSATION FAILED] This discourse has devolved beyond any productive purpose. Perhaps reflection would serve you better than conversation."
		_:
			return "[CONVERSATION FAILED] I don't think we're understanding each other. Let's try this again later."

func apply_failure_consequences():
	if not current_npc:
		return
	
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
	if not current_npc:
		return ["Direct", "Diplomatic"]  # Generic fallback suggestions
	
	# Suggest social types that work well with this NPC archetype
	var preferences = SocialDNAManager.archetype_preferences[current_npc.archetype]
	var recommended = []
	
	for social_type in preferences:
		if preferences[social_type] >= 1.0:  # Positive preference
			recommended.append(SocialDNAManager.get_social_type_name(social_type))
	
	return recommended

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

# =============================================================================
# TRUST GATE AND RELATIONSHIP MANAGEMENT
# =============================================================================

func handle_trust_gate_blocked(conversation_type: ConversationType, current_trust: float, required_trust: float):
	var required_trust_name = get_trust_level_name(required_trust)
	var current_trust_name = get_trust_level_name(current_trust)
	
	print("[TRUST GATE] %s conversation blocked - Need: %s, Have: %s" % [
		get_conversation_type_name(conversation_type),
		required_trust_name,
		current_trust_name
	])
	
	var gate_message = get_trust_gate_message(conversation_type, required_trust_name)
	
	conversation_active = false
	trust_gate_encountered.emit(current_npc, required_trust_name, current_trust_name)
	
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

func initialize_relationship(npc_id: String):
	relationship_data[npc_id] = {
		"trust_level": 0.0,  # Stranger level
		"total_interactions": 0,
		"successful_interactions": 0,
		"failed_interactions": 0,
		"last_conversation_outcome": "",
		"social_history": {},
		"conversations_unlocked": ["QUICK_CHAT"],
		"first_met": Time.get_unix_time_from_system(),
		"information_shared": []  # Track information sharing history
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
# CONVERSATION FLOW MANAGEMENT
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
		
		# Enhanced option display with information hints
		var option_text = "%s %s (%s)" % [social_flag, option.text, trait_bonus]
		
		# Add information request indicators
		if option.has("information_request"):
			var risk_indicator = get_risk_indicator(option.get("risk_level", "medium"))
			option_text += " %s" % risk_indicator
		elif option.has("information_hint"):
			option_text += " 💡"
		
		formatted_options.append({
			"text": option_text,
			"social_type": option.social_type,
			"original_text": option.text,
			"information_request": option.get("information_request", ""),
			"information_hint": option.get("information_hint", "")
		})
	
	conversation_continued.emit("", formatted_options)

func get_risk_indicator(risk_level: String) -> String:
	match risk_level:
		"low": return "🟢"
		"medium": return "🟡"
		"high": return "🟠"
		"very_high": return "🔴"
		_: return "⚪"

func present_final_reaction(npc_reaction: Dictionary):
	conversation_continued.emit(npc_reaction.text, [])
	end_conversation_with_outcome(npc_reaction)

func should_end_conversation(npc_reaction: Dictionary) -> bool:
	var max_turns = get_max_turns_for_type(current_conversation_data.get("type", ConversationType.QUICK_CHAT))
	
	if conversation_turn >= max_turns:
		return true
	
	if npc_reaction.compatibility_result == "VERY_INCOMPATIBLE":
		return true
	
	if current_information_request.size() > 0:
		return true  # Information requests end the conversation
	
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
		"final_trust": get_npc_trust_level(current_npc) if current_npc else 0.0,
		"trust_name": get_trust_level_name(get_npc_trust_level(current_npc)) if current_npc else "Unknown",
		"social_dna_changes": {},
		"relationship_changes": final_reaction.get("relationship_change", 0.0)
	}
	
	# Add information-specific outcome data
	if current_information_request.size() > 0:
		outcome.information_request = current_information_request
	
	if conversation_outcome == ConversationOutcome.INFORMATION_GAINED:
		outcome.information_gained = true
	
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
	current_information_request = {}
	conversation_objective = ""
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

# =============================================================================
# UTILITY AND STATUS FUNCTIONS
# =============================================================================

func is_conversation_active() -> bool:
	return conversation_active

func get_conversation_type_name(conv_type: ConversationType) -> String:
	match conv_type:
		ConversationType.QUICK_CHAT: return "QUICK"
		ConversationType.TOPIC_DISCUSSION: return "TOPIC"
		ConversationType.DEEP_CONVERSATION: return "DEEP"
		_: return "UNKNOWN"

func get_current_conversation_info() -> Dictionary:
	if not conversation_active:
		return {}
	
	var info = {
		"npc": current_npc,
		"turn": conversation_turn,
		"type": current_conversation_data.get("type", "unknown"),
		"trust_level": get_npc_trust_level(current_npc) if current_npc else 0.0,
		"outcome": conversation_outcome,
		"objective": conversation_objective
	}
	
	if current_information_request.size() > 0:
		info.information_request = current_information_request
	
	return info

func get_debug_information_summary() -> String:
	var summary = "=== PLAYER INFORMATION INVENTORY ===\n"
	
	var total_info = get_total_information_count()
	summary += "Total Information Items: %d\n\n" % total_info
	
	for info_type in InformationType.values():
		var type_name = get_information_type_name(info_type)
		var items = player_information_inventory[info_type]
		summary += "%s (%d items):\n" % [type_name, items.size()]
		
		for item in items:
			summary += "  • %s (from %s)\n" % [item.title, item.source_npc]
		summary += "\n"
	
	return summary
