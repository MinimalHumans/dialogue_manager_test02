# =============================================================================
# ENHANCED CONVERSATION DATA - Phase 2C: Goal-Driven Information System
# File: scripts/core/ConversationData.gd (REPLACE existing file)
# Adds meaningful objectives, information rewards, and NPC-specific knowledge assets
# =============================================================================

extends Node
class_name ConversationData

# =============================================================================
# NPC INFORMATION ASSETS SYSTEM
# =============================================================================

const NPC_INFORMATION_ASSETS = {
	"Captain Stone": {
		"facility_layout": {
			"trust_required": 0.0,
			"compatibility_bonus": 0.0,
			"info_type": "location",
			"title": "Basic Facility Layout",
			"description": "General building layout and public areas",
			"value": "basic_facility_map"
		},
		"patrol_schedules": {
			"trust_required": 1.0,
			"compatibility_bonus": 0.3,
			"info_type": "security",
			"title": "Guard Patrol Schedules",
			"description": "Security rotation times and patrol routes",
			"value": "guard_patrol_data"
		},
		"security_codes": {
			"trust_required": 2.0,
			"compatibility_bonus": 0.5,
			"info_type": "access",
			"title": "Research Lab Access Code",
			"description": "Alpha-level security clearance codes",
			"value": "research_lab_code_alpha77delta"
		},
		"weapon_cache": {
			"trust_required": 2.5,
			"compatibility_bonus": 0.8,
			"info_type": "location",
			"title": "Emergency Armory Location", 
			"description": "Hidden weapons cache in sub-basement",
			"value": "armory_sublevel_b3"
		},
		"personnel_files": {
			"trust_required": 1.5,
			"compatibility_bonus": 0.2,
			"info_type": "intelligence",
			"title": "Personnel Background Files",
			"description": "Confidential staff records and clearance levels",
			"value": "staff_security_profiles"
		}
	},
	"Dr. Wisdom": {
		"research_summary": {
			"trust_required": 0.0,
			"compatibility_bonus": 0.0,
			"info_type": "knowledge",
			"title": "Published Research Summary",
			"description": "Overview of current public research projects",
			"value": "public_research_data"
		},
		"lab_access": {
			"trust_required": 1.0,
			"compatibility_bonus": 0.4,
			"info_type": "access",
			"title": "Laboratory Access Codes",
			"description": "Entry codes for research laboratory",
			"value": "lab_access_beta44gamma"
		},
		"classified_projects": {
			"trust_required": 2.0,
			"compatibility_bonus": 0.6,
			"info_type": "knowledge",
			"title": "Classified Research Data",
			"description": "Top-secret experimental data and results",
			"value": "project_blackbird_data"
		},
		"prototype_location": {
			"trust_required": 2.5,
			"compatibility_bonus": 0.7,
			"info_type": "location",
			"title": "Prototype Storage Location",
			"description": "Location of experimental technology prototypes",
			"value": "prototype_vault_sublevel_a2"
		}
	},
	"Commander Steele": {
		"mission_brief": {
			"trust_required": 1.0,
			"compatibility_bonus": 0.3,
			"info_type": "intelligence",
			"title": "Current Mission Briefing",
			"description": "Overview of ongoing military operations",
			"value": "operation_steel_rain_brief"
		},
		"comm_frequencies": {
			"trust_required": 1.5,
			"compatibility_bonus": 0.4,
			"info_type": "access",
			"title": "Encrypted Communication Codes",
			"description": "Secure radio frequencies and encryption keys",
			"value": "tactical_comm_freq_2847"
		},
		"supply_caches": {
			"trust_required": 2.0,
			"compatibility_bonus": 0.6,
			"info_type": "location",
			"title": "Supply Cache Locations",
			"description": "Hidden resource and equipment stashes",
			"value": "supply_depot_coordinates"
		},
		"transport_schedule": {
			"trust_required": 1.2,
			"compatibility_bonus": 0.3,
			"info_type": "intelligence",
			"title": "Transport Schedules",
			"description": "Vehicle and aircraft movement timetables",
			"value": "transport_logistics_alpha"
		}
	}
}

# Conversation objectives based on information sought
const CONVERSATION_OBJECTIVES = {
	"seek_security_access": {
		"title": "Obtain Security Access",
		"description": "Get access codes or security information",
		"target_info_types": ["access", "security"],
		"difficulty": "medium"
	},
	"gather_intelligence": {
		"title": "Gather Intelligence",
		"description": "Collect information about people, places, or operations", 
		"target_info_types": ["intelligence", "location"],
		"difficulty": "medium"
	},
	"acquire_research_data": {
		"title": "Acquire Research Data",
		"description": "Obtain scientific or technical information",
		"target_info_types": ["knowledge", "access"],
		"difficulty": "hard"
	}
}

# =============================================================================
# ENHANCED CONVERSATION CONTENT GETTER
# =============================================================================

static func get_conversation(archetype: SocialDNAManager.NPCArchetype, 
							conv_type: ConversationController.ConversationType,
							trust_level: float, 
							compatibility: float,
							npc_name: String = "",
							objective: String = "") -> Dictionary:
	
	# Get base conversation structure with enhanced content
	var conversation = {}
	
	match conv_type:
		ConversationController.ConversationType.QUICK_CHAT:
			conversation = get_goal_oriented_quick_chat(archetype, npc_name, trust_level, compatibility)
		ConversationController.ConversationType.TOPIC_DISCUSSION:
			conversation = get_goal_oriented_topic_discussion(archetype, npc_name, trust_level, compatibility, objective)
		ConversationController.ConversationType.DEEP_CONVERSATION:
			conversation = get_goal_oriented_deep_conversation(archetype, npc_name, trust_level, compatibility, objective)
		_:
			conversation = get_goal_oriented_quick_chat(archetype, npc_name, trust_level, compatibility)
	
	# Add trust-aware opening lines
	conversation.opening_lines = get_trust_aware_opening_lines(archetype, trust_level, compatibility, npc_name)
	
	# Add available information for this NPC
	conversation.available_information = get_available_information_for_npc(npc_name, trust_level, compatibility)
	
	return conversation

# =============================================================================
# GOAL-ORIENTED CONVERSATION STRUCTURES
# =============================================================================

static func get_goal_oriented_quick_chat(archetype: SocialDNAManager.NPCArchetype,
										npc_name: String,
										trust_level: float,
										compatibility: float) -> Dictionary:
	
	var conversation = {
		"type": ConversationController.ConversationType.QUICK_CHAT,
		"objective": "Build rapport and assess information availability",
		"turns": []
	}
	
	# Turn 0: Relationship building with information hints
	var turn_0_options = []
	
	match npc_name:
		"Captain Stone":
			turn_0_options = [
				{
					"social_type": SocialDNAManager.SocialType.AGGRESSIVE,
					"text": "I need to know who I can count on around here.",
					"information_hint": "Asserts authority to gauge Stone's respect"
				},
				{
					"social_type": SocialDNAManager.SocialType.DIRECT,
					"text": "What's the security situation in this facility?",
					"information_hint": "Direct inquiry about Stone's area of expertise"
				},
				{
					"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
					"text": "I'd appreciate any guidance you could offer.",
					"information_hint": "Respectful approach that acknowledges Stone's authority"
				},
				{
					"social_type": SocialDNAManager.SocialType.EMPATHETIC,
					"text": "This job must put a lot of responsibility on your shoulders.",
					"information_hint": "Shows understanding of Stone's burden"
				},
				{
					"social_type": SocialDNAManager.SocialType.CHARMING,
					"text": "I've heard you run a tight ship around here.",
					"information_hint": "Flattery approach - risky with Authority types"
				}
			]
		
		"Dr. Wisdom":
			turn_0_options = [
				{
					"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
					"text": "Your research reputation precedes you, Doctor.",
					"information_hint": "Acknowledges intellectual status respectfully"
				},
				{
					"social_type": SocialDNAManager.SocialType.EMPATHETIC,
					"text": "The complexity of your work must be fascinating.",
					"information_hint": "Shows genuine interest in their expertise"
				},
				{
					"social_type": SocialDNAManager.SocialType.DIRECT,
					"text": "What kind of research are you working on?",
					"information_hint": "Straightforward inquiry about research"
				},
				{
					"social_type": SocialDNAManager.SocialType.AGGRESSIVE,
					"text": "I need to understand what's happening in your lab.",
					"information_hint": "Aggressive approach - risky with Intellectual types"
				},
				{
					"social_type": SocialDNAManager.SocialType.CHARMING,
					"text": "I'd love to learn more about your fascinating work.",
					"information_hint": "Flattery with intellectual focus"
				}
			]
		
		_:  # Generic options for other NPCs
			turn_0_options = [
				{
					"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
					"text": "I was hoping we could talk.",
					"information_hint": "Standard diplomatic opener"
				},
				{
					"social_type": SocialDNAManager.SocialType.DIRECT,
					"text": "What's your role around here?",
					"information_hint": "Direct inquiry about their position"
				}
			]
	
	conversation.turns.append({
		"turn": 0,
		"player_options": turn_0_options,
		"context": "Initial rapport building - hints at information availability"
	})
	
	# Turn 1: Follow-up based on compatibility
	conversation.turns.append({
		"turn": 1,
		"player_options": get_quick_chat_followup_options(npc_name, trust_level),
		"context": "Gauge willingness to share information in future conversations"
	})
	
	return conversation

static func get_goal_oriented_topic_discussion(archetype: SocialDNAManager.NPCArchetype,
											  npc_name: String,
											  trust_level: float,
											  compatibility: float,
											  objective: String = "") -> Dictionary:
	
	var conversation = {
		"type": ConversationController.ConversationType.TOPIC_DISCUSSION,
		"objective": "Request specific information based on relationship level",
		"turns": []
	}
	
	# Determine available information for this trust level
	var available_info = get_available_information_for_npc(npc_name, trust_level, compatibility)
	var primary_target = get_primary_information_target(available_info, trust_level)
	
	conversation.primary_information_target = primary_target
	
	# Turn 0: Make information request
	match npc_name:
		"Captain Stone":
			conversation.turns.append(get_captain_stone_topic_turns(trust_level, primary_target))
		"Dr. Wisdom":
			conversation.turns.append(get_dr_wisdom_topic_turns(trust_level, primary_target))
		"Commander Steele":
			conversation.turns.append(get_commander_steele_topic_turns(trust_level, primary_target))
		_:
			conversation.turns.append(get_generic_topic_turns(trust_level))
	
	return conversation

static func get_goal_oriented_deep_conversation(archetype: SocialDNAManager.NPCArchetype,
											   npc_name: String,
											   trust_level: float,
											   compatibility: float,
											   objective: String = "") -> Dictionary:
	
	var conversation = {
		"type": ConversationController.ConversationType.DEEP_CONVERSATION,
		"objective": "Access high-value information through established trust",
		"turns": []
	}
	
	# Deep conversations focus on the most valuable information
	var available_info = get_available_information_for_npc(npc_name, trust_level, compatibility)
	var high_value_targets = get_high_value_information_targets(available_info)
	
	conversation.high_value_targets = high_value_targets
	
	# Create multi-turn conversation for valuable information
	match npc_name:
		"Captain Stone":
			conversation.turns = get_captain_stone_deep_turns(trust_level, high_value_targets)
		"Dr. Wisdom":
			conversation.turns = get_dr_wisdom_deep_turns(trust_level, high_value_targets)
		"Commander Steele":
			conversation.turns = get_commander_steele_deep_turns(trust_level, high_value_targets)
		_:
			conversation.turns = get_generic_deep_turns(trust_level)
	
	return conversation

# =============================================================================
# CAPTAIN STONE SPECIFIC CONVERSATIONS
# =============================================================================

static func get_captain_stone_topic_turns(trust_level: float, primary_target: Dictionary) -> Dictionary:
	var turn = {
		"turn": 0,
		"context": "Requesting information from Security Chief",
		"primary_target": primary_target,
		"player_options": []
	}
	
	if primary_target.has("patrol_schedules"):
		turn.player_options = [
			{
				"social_type": SocialDNAManager.SocialType.DIRECT,
				"text": "I need to know the security patrol patterns.",
				"information_request": "patrol_schedules",
				"success_chance": 0.8,
				"risk_level": "medium"
			},
			{
				"social_type": SocialDNAManager.SocialType.AGGRESSIVE,
				"text": "The security around here is sloppy. Show me the patrol routes.",
				"information_request": "patrol_schedules",
				"success_chance": 0.6,
				"risk_level": "high"
			},
			{
				"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
				"text": "For coordination purposes, could you share the patrol schedules?",
				"information_request": "patrol_schedules",
				"success_chance": 0.7,
				"risk_level": "low"
			}
		]
	elif primary_target.has("security_codes"):
		turn.player_options = [
			{
				"social_type": SocialDNAManager.SocialType.DIRECT,
				"text": "I need access to the research lab. What's the code?",
				"information_request": "security_codes",
				"success_chance": 0.7,
				"risk_level": "high"
			},
			{
				"social_type": SocialDNAManager.SocialType.AGGRESSIVE,
				"text": "I have clearance for that lab. Give me the access code.",
				"information_request": "security_codes", 
				"success_chance": 0.5,
				"risk_level": "very_high"
			},
			{
				"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
				"text": "I'm working with Dr. Wisdom. Could you provide lab access?",
				"information_request": "security_codes",
				"success_chance": 0.8,
				"risk_level": "medium"
			}
		]
	else:
		# Fallback for basic information
		turn.player_options = [
			{
				"social_type": SocialDNAManager.SocialType.DIRECT,
				"text": "Can you tell me about this facility's layout?",
				"information_request": "facility_layout",
				"success_chance": 0.9,
				"risk_level": "low"
			}
		]
	
	return turn

static func get_captain_stone_deep_turns(trust_level: float, high_value_targets: Array) -> Array:
	var turns = []
	
	# Turn 0: High-stakes information request
	turns.append({
		"turn": 0,
		"context": "High-value information request from trusted ally",
		"player_options": [
			{
				"social_type": SocialDNAManager.SocialType.DIRECT,
				"text": "I need to know about the emergency protocols. Lives might depend on it.",
				"information_request": "weapon_cache",
				"success_chance": 0.8,
				"risk_level": "high"
			},
			{
				"social_type": SocialDNAManager.SocialType.AGGRESSIVE,
				"text": "The situation is critical. I need access to emergency resources.",
				"information_request": "weapon_cache",
				"success_chance": 0.7,
				"risk_level": "very_high"
			},
			{
				"social_type": SocialDNAManager.SocialType.EMPATHETIC,
				"text": "I know you're concerned about security. Help me help everyone.",
				"information_request": "weapon_cache",
				"success_chance": 0.6,
				"risk_level": "medium"
			}
		]
	})
	
	# Turn 1: Follow-through based on response
	turns.append({
		"turn": 1,
		"context": "Reinforcing the request or changing approach",
		"player_options": [
			{
				"social_type": SocialDNAManager.SocialType.DIRECT,
				"text": "I understand the risks. I won't abuse this information.",
				"information_request": "confirmation",
				"success_chance": 0.9,
				"risk_level": "low"
			},
			{
				"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
				"text": "Perhaps there's another way I can prove my reliability?",
				"information_request": "alternative",
				"success_chance": 0.7,
				"risk_level": "low"
			}
		]
	})
	
	return turns

# =============================================================================
# INFORMATION AVAILABILITY SYSTEM
# =============================================================================

static func get_available_information_for_npc(npc_name: String, trust_level: float, compatibility: float) -> Dictionary:
	if not NPC_INFORMATION_ASSETS.has(npc_name):
		return {}
	
	var npc_assets = NPC_INFORMATION_ASSETS[npc_name]
	var available = {}
	
	for info_key in npc_assets:
		var info_asset = npc_assets[info_key]
		var required_trust = info_asset.trust_required
		var compatibility_bonus = info_asset.get("compatibility_bonus", 0.0)
		
		# Check if information is available based on trust + compatibility bonus
		var effective_trust = trust_level + (compatibility * compatibility_bonus)
		
		if effective_trust >= required_trust:
			# Create a new dictionary instead of referencing the read-only constant
			available[info_key] = {
				"trust_required": info_asset.trust_required,
				"compatibility_bonus": info_asset.get("compatibility_bonus", 0.0),
				"info_type": info_asset.info_type,
				"title": info_asset.title,
				"description": info_asset.description,
				"value": info_asset.value,
				"effective_trust": effective_trust,
				"unlock_margin": effective_trust - required_trust
			}
	
	return available

static func get_primary_information_target(available_info: Dictionary, trust_level: float) -> Dictionary:
	# Find the highest-value information that's just within reach
	var best_target = {}
	var highest_value = -1.0
	
	for info_key in available_info:
		var info = available_info[info_key]
		var value_score = info.trust_required + info.get("compatibility_bonus", 0.0)
		
		if value_score > highest_value:
			highest_value = value_score
			best_target[info_key] = info
	
	return best_target

static func get_high_value_information_targets(available_info: Dictionary) -> Array:
	var high_value = []
	
	for info_key in available_info:
		var info = available_info[info_key]
		if info.trust_required >= 2.0:  # High-trust information
			high_value.append({info_key: info})
	
	return high_value

# =============================================================================
# NPC-SPECIFIC RESPONSE CONTENT
# =============================================================================

static func get_trust_aware_reaction_text(archetype: SocialDNAManager.NPCArchetype,
										 social_choice: SocialDNAManager.SocialType,
										 compatibility_result: String,
										 trust_level: float,
										 turn: int,
										 npc_name: String = "",
										 information_context: Dictionary = {}) -> String:
	
	# Enhanced reactions that consider information requests
	match npc_name:
		"Captain Stone":
			return get_captain_stone_information_reaction(social_choice, compatibility_result, trust_level, information_context)
		"Dr. Wisdom":
			return get_dr_wisdom_information_reaction(social_choice, compatibility_result, trust_level, information_context)
		"Commander Steele":
			return get_commander_steele_information_reaction(social_choice, compatibility_result, trust_level, information_context)
		_:
			# Fall back to original system
			return get_original_trust_aware_reaction_text(archetype, social_choice, compatibility_result, trust_level, turn)

static func get_captain_stone_information_reaction(social_choice: SocialDNAManager.SocialType,
												  compatibility_result: String,
												  trust_level: float,
												  info_context: Dictionary) -> String:
	
	var information_request = info_context.get("information_request", "")
	var success_chance = info_context.get("success_chance", 0.5)
	
	# Information-specific reactions
	match information_request:
		"security_codes":
			match compatibility_result:
				"VERY_COMPATIBLE", "COMPATIBLE":
					if trust_level >= 2.0:
						return "Alpha-7-7-Delta. That code gets you into the research lab. Don't make me regret this."
					else:
						return "You're not ready for that level of clearance. Build my trust first."
				"NEUTRAL":
					return "Security codes aren't given out lightly. Prove you're reliable first."
				"INCOMPATIBLE", "VERY_INCOMPATIBLE":
					return "I don't share classified information with people I can't rely on."
				_:
					return "Security access is restricted information."
		
		"patrol_schedules":
			match compatibility_result:
				"VERY_COMPATIBLE", "COMPATIBLE":
					if trust_level >= 1.0:
						return "Guards rotate every 4 hours. Alpha shift starts at 0600, Bravo at 1000. Use this wisely."
					else:
						return "I need to see you're trustworthy before sharing operational details."
				"NEUTRAL":
					return "That's operational information. I'll consider sharing it if you prove yourself."
				"INCOMPATIBLE", "VERY_INCOMPATIBLE":
					return "Security protocols are none of your business."
				_:
					return "Patrol information is classified."
		
		"facility_layout":
			match compatibility_result:
				"VERY_COMPATIBLE", "COMPATIBLE":
					return "The facility has 5 levels. Research is on 3, command on 4, secure storage below. Simple enough."
				"NEUTRAL":
					return "Basic layout: Admin on 1, operations on 2, research above. That's all you need to know."
				"INCOMPATIBLE", "VERY_INCOMPATIBLE":
					return "Find your own way around. I'm not a tour guide."
				_:
					return "Basic facility information is available through proper channels."
		
		"weapon_cache":
			match compatibility_result:
				"VERY_COMPATIBLE", "COMPATIBLE":
					if trust_level >= 2.5:
						return "Emergency armory is in sub-basement level B3, behind the maintenance access. Keep this between us."
					else:
						return "Weapon cache locations are for senior personnel only. You're not there yet."
				"NEUTRAL":
					return "Emergency weapons are classified above your clearance level."
				"INCOMPATIBLE", "VERY_INCOMPATIBLE":
					return "I'm not telling you where the weapons are stored."
				_:
					return "Weapons storage is highly restricted information."
		
		"personnel_files":
			match compatibility_result:
				"VERY_COMPATIBLE", "COMPATIBLE":
					if trust_level >= 1.5:
						return "I can share some background information on key personnel. What do you need to know?"
					else:
						return "Personnel files are confidential. Build more trust with me first."
				"NEUTRAL":
					return "Staff information is available through proper HR channels."
				"INCOMPATIBLE", "VERY_INCOMPATIBLE":
					return "Personnel records are none of your concern."
				_:
					return "Personnel information requires proper authorization."
		
		_:
			# Default Captain Stone personality reactions
			return get_default_captain_stone_reaction(social_choice, compatibility_result, trust_level)

static func get_dr_wisdom_information_reaction(social_choice: SocialDNAManager.SocialType,
											  compatibility_result: String,
											  trust_level: float,
											  info_context: Dictionary) -> String:
	
	var information_request = info_context.get("information_request", "")
	
	match information_request:
		"classified_projects":
			match compatibility_result:
				"VERY_COMPATIBLE", "COMPATIBLE":
					if trust_level >= 2.0:
						return "Project Blackbird involves quantum field manipulation. The implications are... significant. I trust you understand the discretion required."
					else:
						return "Such information requires a deeper level of trust between us. Perhaps in time."
				"NEUTRAL":
					return "I appreciate your interest, but classified research must remain classified for now."
				"INCOMPATIBLE", "VERY_INCOMPATIBLE":
					return "I'm afraid such sensitive information is not appropriate to discuss."
				_:
					return "Classified research requires appropriate clearance."
		
		"lab_access":
			match compatibility_result:
				"VERY_COMPATIBLE", "COMPATIBLE":
					if trust_level >= 1.0:
						return "The lab code is Beta-44-Gamma. Please respect the delicate equipment within."
					else:
						return "Laboratory access requires a certain level of mutual trust and respect."
				"NEUTRAL":
					return "I'll need to verify your clearance before providing access codes."
				"INCOMPATIBLE", "VERY_INCOMPATIBLE":
					return "I cannot grant access to unauthorized personnel."
				_:
					return "Laboratory access is restricted."
		
		"research_summary":
			match compatibility_result:
				"VERY_COMPATIBLE", "COMPATIBLE":
					return "Our current research focuses on advanced materials and energy applications. Quite fascinating work."
				"NEUTRAL":
					return "We're conducting various research projects within standard academic protocols."
				"INCOMPATIBLE", "VERY_INCOMPATIBLE":
					return "I don't believe you'd understand the complexities of our research."
				_:
					return "Research information is available through proper channels."
		
		"prototype_location":
			match compatibility_result:
				"VERY_COMPATIBLE", "COMPATIBLE":
					if trust_level >= 2.5:
						return "The prototype vault is located in sublevel A2. Exercise extreme caution with the experimental technology."
					else:
						return "Prototype locations are highly classified. I need absolute trust before sharing such sensitive information."
				"NEUTRAL":
					return "Prototype storage information is above your current clearance level."
				"INCOMPATIBLE", "VERY_INCOMPATIBLE":
					return "I cannot discuss prototype locations with unauthorized individuals."
				_:
					return "Prototype information is highly restricted."
		
		_:
			return get_default_dr_wisdom_reaction(social_choice, compatibility_result, trust_level)

# =============================================================================
# UTILITY FUNCTIONS FOR QUICK CHAT
# =============================================================================

static func get_quick_chat_followup_options(npc_name: String, trust_level: float) -> Array:
	match npc_name:
		"Captain Stone":
			return [
				{
					"social_type": SocialDNAManager.SocialType.DIRECT,
					"text": "I'd like to discuss security matters with you sometime.",
					"information_hint": "Sets up future information requests"
				},
				{
					"social_type": SocialDNAManager.SocialType.AGGRESSIVE,
					"text": "I'll be back when I need real information.",
					"information_hint": "Assertive but potentially risky"
				},
				{
					"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
					"text": "Thank you for your time. I hope we can work together.",
					"information_hint": "Safe relationship building"
				}
			]
		"Dr. Wisdom":
			return [
				{
					"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
					"text": "I'd value the opportunity to learn more about your research.",
					"information_hint": "Respectful interest in their expertise"
				},
				{
					"social_type": SocialDNAManager.SocialType.EMPATHETIC,
					"text": "Your work must be very rewarding despite the challenges.",
					"information_hint": "Shows understanding of their dedication"
				},
				{
					"social_type": SocialDNAManager.SocialType.DIRECT,
					"text": "I may need to consult with you on technical matters.",
					"information_hint": "Direct statement of future needs"
				}
			]
		_:
			return [
				{
					"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
					"text": "Thank you for the conversation.",
					"information_hint": "Polite conclusion"
				}
			]

# =============================================================================
# DEFAULT REACTIONS (FALLBACK)
# =============================================================================

static func get_default_captain_stone_reaction(social_choice: SocialDNAManager.SocialType,
											  compatibility_result: String,
											  trust_level: float) -> String:
	match compatibility_result:
		"VERY_COMPATIBLE":
			return "Now that's the kind of direct thinking I respect. You understand how things work."
		"COMPATIBLE":
			return "I can work with someone who gets straight to the point."
		"NEUTRAL":
			return "I suppose that's a reasonable approach."
		"INCOMPATIBLE":
			return "That's not how we handle things around here."
		"VERY_INCOMPATIBLE":
			return "I don't have time for that kind of nonsense."
		_:
			return "Understood."

static func get_default_dr_wisdom_reaction(social_choice: SocialDNAManager.SocialType,
										  compatibility_result: String,
										  trust_level: float) -> String:
	match compatibility_result:
		"VERY_COMPATIBLE":
			return "A most thoughtful and nuanced perspective. I appreciate intellectual discourse."
		"COMPATIBLE":
			return "Your approach shows consideration and wisdom."
		"NEUTRAL":
			return "An interesting point of view, certainly."
		"INCOMPATIBLE":
			return "Perhaps a more thoughtful approach would be beneficial."
		"VERY_INCOMPATIBLE":
			return "I'm afraid such crude thinking is beneath productive discourse."
		_:
			return "Indeed."

# Keep the original function as fallback
static func get_original_trust_aware_reaction_text(archetype: SocialDNAManager.NPCArchetype,
												  social_choice: SocialDNAManager.SocialType,
												  compatibility_result: String,
												  trust_level: float,
												  turn: int) -> String:
	# [Original implementation - keeping for compatibility]
	match compatibility_result:
		"VERY_COMPATIBLE": return "Excellent approach!"
		"COMPATIBLE": return "I can work with that."
		"NEUTRAL": return "Interesting perspective."
		"INCOMPATIBLE": return "Not quite what I was expecting."
		"VERY_INCOMPATIBLE": return "That approach doesn't work with me."
		_: return "I see."

# =============================================================================
# GENERIC CONVERSATION HELPERS (for other NPCs)
# =============================================================================

static func get_generic_topic_turns(trust_level: float) -> Dictionary:
	return {
		"turn": 0,
		"context": "Generic information request",
		"player_options": [
			{
				"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
				"text": "I was hoping you could help me with something.",
				"information_request": "general_help",
				"success_chance": 0.7,
				"risk_level": "low"
			}
		]
	}

static func get_generic_deep_turns(trust_level: float) -> Array:
	return [
		{
			"turn": 0,
			"context": "Generic deep conversation",
			"player_options": [
				{
					"social_type": SocialDNAManager.SocialType.EMPATHETIC,
					"text": "I trust you, and I hope you trust me too.",
					"information_request": "trust_confirmation",
					"success_chance": 0.8,
					"risk_level": "low"
				}
			]
		}
	]

# =============================================================================
# MISSING IMPLEMENTATION FUNCTIONS
# =============================================================================

static func get_trust_aware_opening_lines(archetype: SocialDNAManager.NPCArchetype, 
										 trust_level: float,
										 compatibility: float,
										 npc_name: String = "") -> Array:
	
	var lines = []
	
	match archetype:
		SocialDNAManager.NPCArchetype.AUTHORITY:
			lines = get_authority_trust_lines(trust_level, compatibility)
		SocialDNAManager.NPCArchetype.INTELLECTUAL:
			lines = get_intellectual_trust_lines(trust_level, compatibility)
		_:
			lines = get_generic_trust_lines(trust_level, compatibility)
	
	return lines

static func get_authority_trust_lines(trust_level: float, compatibility: float) -> Array:
	var lines = []
	
	# Trust level affects opening lines more than compatibility
	if trust_level >= 3.0:  # Close
		lines.append({
			"text": "My most trusted ally. What do you need?",
			"min_compatibility": -999, "max_compatibility": 999, "min_trust_level": 3.0
		})
	elif trust_level >= 2.0:  # Trusted
		if compatibility >= 0.8:
			lines.append({
				"text": "I've come to rely on your judgment. What's the situation?",
				"min_compatibility": 0.8, "max_compatibility": 999, "min_trust_level": 2.0
			})
		else:
			lines.append({
				"text": "You've earned my trust, even if we don't always see eye to eye. What do you need?",
				"min_compatibility": -999, "max_compatibility": 0.8, "min_trust_level": 2.0
			})
	elif trust_level >= 1.0:  # Professional
		if compatibility >= 0.5:
			lines.append({
				"text": "Good to see a competent professional. What can I do for you?",
				"min_compatibility": 0.5, "max_compatibility": 999, "min_trust_level": 1.0
			})
		else:
			lines.append({
				"text": "You're proving yourself useful, despite our differences. What's the matter?",
				"min_compatibility": -999, "max_compatibility": 0.5, "min_trust_level": 1.0
			})
	elif trust_level >= 0.0:  # Stranger
		lines.append_array(get_basic_authority_lines(compatibility))
	else:  # Hostile
		lines.append({
			"text": "I thought I made it clear you weren't welcome here. Make this quick.",
			"min_compatibility": -999, "max_compatibility": 999, "min_trust_level": -999
		})
	
	return lines

static func get_intellectual_trust_lines(trust_level: float, compatibility: float) -> Array:
	var lines = []
	
	if trust_level >= 3.0:  # Close
		lines.append({
			"text": "My dear colleague! I always have time for our stimulating discussions.",
			"min_compatibility": -999, "max_compatibility": 999, "min_trust_level": 3.0
		})
	elif trust_level >= 2.0:  # Trusted
		if compatibility >= 0.8:
			lines.append({
				"text": "Ah, a kindred spirit approaches! What intellectual puzzle shall we tackle today?",
				"min_compatibility": 0.8, "max_compatibility": 999, "min_trust_level": 2.0
			})
		else:
			lines.append({
				"text": "Despite our different approaches, I've grown to appreciate your perspective. What's on your mind?",
				"min_compatibility": -999, "max_compatibility": 0.8, "min_trust_level": 2.0
			})
	elif trust_level >= 1.0:  # Professional
		if compatibility >= 0.5:
			lines.append({
				"text": "A fellow seeker of knowledge! How can I assist your inquiries?",
				"min_compatibility": 0.5, "max_compatibility": 999, "min_trust_level": 1.0
			})
		else:
			lines.append({
				"text": "You're beginning to show promise, despite your unconventional methods. What brings you here?",
				"min_compatibility": -999, "max_compatibility": 0.5, "min_trust_level": 1.0
			})
	elif trust_level >= 0.0:  # Stranger
		lines.append_array(get_basic_intellectual_lines(compatibility))
	else:  # Hostile
		lines.append({
			"text": "Your presence continues to be... intellectually disappointing. What do you want?",
			"min_compatibility": -999, "max_compatibility": 999, "min_trust_level": -999
		})
	
	return lines

static func get_basic_authority_lines(compatibility: float) -> Array:
	# Original compatibility-based lines for Stranger level
	var text = ""
	if compatibility >= 1.5:
		text = "Outstanding! I can see you understand how things work around here."
	elif compatibility >= 0.5:
		text = "Good to meet someone competent for once."
	elif compatibility >= -0.5:
		text = "State your business."
	elif compatibility >= -1.5:
		text = "I don't have time for this nonsense."
	else:
		text = "Guards, who let this person in here?"
	
	return [{
		"text": text,
		"min_compatibility": -999, 
		"max_compatibility": 999, 
		"min_trust_level": 0.0
	}]

static func get_basic_intellectual_lines(compatibility: float) -> Array:
	var text = ""
	if compatibility >= 1.5:
		text = "Fascinating! I sense great depth in your approach to things."
	elif compatibility >= 0.5:
		text = "An interesting perspective, I'm sure. Please, continue."
	elif compatibility >= -0.5:
		text = "How curious. What brings you to seek discourse?"
	elif compatibility >= -1.5:
		text = "I doubt you'd appreciate the complexities involved in my work."
	else:
		text = "This conversation is beneath both of us, don't you think?"
	
	return [{
		"text": text,
		"min_compatibility": -999, 
		"max_compatibility": 999, 
		"min_trust_level": 0.0
	}]

static func get_generic_trust_lines(trust_level: float, compatibility: float) -> Array:
	return [{
		"text": "Hello there. What can I help you with?" if trust_level >= 0.0 else "What do you want?",
		"min_compatibility": -999, "max_compatibility": 999, "min_trust_level": -999
	}]

static func get_dr_wisdom_topic_turns(trust_level: float, primary_target: Dictionary) -> Dictionary:
	var turn = {
		"turn": 0,
		"context": "Requesting information from Research Director",
		"primary_target": primary_target,
		"player_options": []
	}
	
	if primary_target.has("classified_projects"):
		turn.player_options = [
			{
				"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
				"text": "I'd like to discuss your classified research projects.",
				"information_request": "classified_projects",
				"success_chance": 0.8,
				"risk_level": "medium"
			},
			{
				"social_type": SocialDNAManager.SocialType.EMPATHETIC,
				"text": "I understand the sensitivity, but I need to know about your secret projects.",
				"information_request": "classified_projects",
				"success_chance": 0.7,
				"risk_level": "low"
			},
			{
				"social_type": SocialDNAManager.SocialType.DIRECT,
				"text": "What classified research are you working on?",
				"information_request": "classified_projects",
				"success_chance": 0.6,
				"risk_level": "medium"
			}
		]
	elif primary_target.has("lab_access"):
		turn.player_options = [
			{
				"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
				"text": "I need access to your laboratory for research purposes.",
				"information_request": "lab_access",
				"success_chance": 0.8,
				"risk_level": "low"
			},
			{
				"social_type": SocialDNAManager.SocialType.DIRECT,
				"text": "Can you provide me with the lab access codes?",
				"information_request": "lab_access",
				"success_chance": 0.7,
				"risk_level": "medium"
			}
		]
	else:
		# Fallback for basic information
		turn.player_options = [
			{
				"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
				"text": "Could you tell me about your current research?",
				"information_request": "research_summary",
				"success_chance": 0.9,
				"risk_level": "low"
			}
		]
	
	return turn

static func get_commander_steele_topic_turns(trust_level: float, primary_target: Dictionary) -> Dictionary:
	var turn = {
		"turn": 0,
		"context": "Requesting information from Operations Chief",
		"primary_target": primary_target,
		"player_options": []
	}
	
	if primary_target.has("supply_caches"):
		turn.player_options = [
			{
				"social_type": SocialDNAManager.SocialType.AGGRESSIVE,
				"text": "I need the locations of your supply caches.",
				"information_request": "supply_caches",
				"success_chance": 0.7,
				"risk_level": "high"
			},
			{
				"social_type": SocialDNAManager.SocialType.DIRECT,
				"text": "Can you share the supply depot coordinates?",
				"information_request": "supply_caches",
				"success_chance": 0.8,
				"risk_level": "medium"
			}
		]
	elif primary_target.has("comm_frequencies"):
		turn.player_options = [
			{
				"social_type": SocialDNAManager.SocialType.DIRECT,
				"text": "I need the encrypted communication frequencies.",
				"information_request": "comm_frequencies",
				"success_chance": 0.7,
				"risk_level": "medium"
			}
		]
	else:
		# Fallback for basic information
		turn.player_options = [
			{
				"social_type": SocialDNAManager.SocialType.DIRECT,
				"text": "Can you brief me on current operations?",
				"information_request": "mission_brief",
				"success_chance": 0.8,
				"risk_level": "low"
			}
		]
	
	return turn

static func get_dr_wisdom_deep_turns(trust_level: float, high_value_targets: Array) -> Array:
	var turns = []
	
	# Turn 0: High-stakes research information request
	turns.append({
		"turn": 0,
		"context": "High-value research information from trusted colleague",
		"player_options": [
			{
				"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
				"text": "I need access to your most sensitive research data.",
				"information_request": "prototype_location",
				"success_chance": 0.8,
				"risk_level": "medium"
			},
			{
				"social_type": SocialDNAManager.SocialType.EMPATHETIC,
				"text": "I understand this is sensitive, but lives may depend on this information.",
				"information_request": "prototype_location",
				"success_chance": 0.7,
				"risk_level": "low"
			}
		]
	})
	
	# Turn 1: Follow-through
	turns.append({
		"turn": 1,
		"context": "Reinforcing the research request",
		"player_options": [
			{
				"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
				"text": "I give you my word this information will be used responsibly.",
				"information_request": "confirmation",
				"success_chance": 0.9,
				"risk_level": "low"
			}
		]
	})
	
	return turns

static func get_commander_steele_deep_turns(trust_level: float, high_value_targets: Array) -> Array:
	var turns = []
	
	# Turn 0: High-stakes operational information request
	turns.append({
		"turn": 0,
		"context": "High-value operational information from trusted ally",
		"player_options": [
			{
				"social_type": SocialDNAManager.SocialType.AGGRESSIVE,
				"text": "I need complete operational intelligence. No holding back.",
				"information_request": "supply_caches",
				"success_chance": 0.7,
				"risk_level": "high"
			},
			{
				"social_type": SocialDNAManager.SocialType.DIRECT,
				"text": "The mission requires full operational data. Can you provide it?",
				"information_request": "supply_caches",
				"success_chance": 0.8,
				"risk_level": "medium"
			}
		]
	})
	
	return turns

static func get_commander_steele_information_reaction(social_choice: SocialDNAManager.SocialType,
												   compatibility_result: String,
												   trust_level: float,
												   info_context: Dictionary) -> String:
	
	var information_request = info_context.get("information_request", "")
	
	match information_request:
		"supply_caches":
			match compatibility_result:
				"VERY_COMPATIBLE", "COMPATIBLE":
					if trust_level >= 2.0:
						return "Grid coordinates 47.2N, 122.3W. Supply depot Alpha has enough for two weeks. Keep this information secure."
					else:
						return "You're not cleared for supply logistics yet. Prove your operational worth first."
				"NEUTRAL":
					return "Supply information is classified. I'll consider sharing it if you demonstrate tactical competence."
				"INCOMPATIBLE", "VERY_INCOMPATIBLE":
					return "Supply locations are on a need-to-know basis. You don't need to know."
				_:
					return "Supply logistics are restricted information."
		
		"comm_frequencies":
			match compatibility_result:
				"VERY_COMPATIBLE", "COMPATIBLE":
					if trust_level >= 1.5:
						return "Frequency 2847.5 MHz, encryption key Delta-Nine. Monitor channel 3 for updates."
					else:
						return "Communication protocols require higher clearance. Build operational trust first."
				"NEUTRAL":
					return "Encrypted communications are sensitive. I need assurance of your operational security."
				"INCOMPATIBLE", "VERY_INCOMPATIBLE":
					return "Communication frequencies are classified military intelligence."
				_:
					return "Communication protocols are classified."
		
		"mission_brief":
			match compatibility_result:
				"VERY_COMPATIBLE", "COMPATIBLE":
					return "Operation Steel Rain is a three-phase tactical deployment. Current status is Phase 2 preparation."
				"NEUTRAL":
					return "Mission briefings are available to cleared personnel on an operational need-to-know basis."
				"INCOMPATIBLE", "VERY_INCOMPATIBLE":
					return "Mission details are classified above your clearance level."
				_:
					return "Mission information is restricted."
		
		_:
			return get_default_commander_steele_reaction(social_choice, compatibility_result, trust_level)

static func get_default_commander_steele_reaction(social_choice: SocialDNAManager.SocialType,
												compatibility_result: String,
												trust_level: float) -> String:
	match compatibility_result:
		"VERY_COMPATIBLE":
			return "Solid tactical thinking. You understand operational priorities."
		"COMPATIBLE":
			return "Acceptable approach for military operations."
		"NEUTRAL":
			return "Standard operational response."
		"INCOMPATIBLE":
			return "That approach lacks tactical discipline."
		"VERY_INCOMPATIBLE":
			return "Completely inappropriate for military operations."
		_:
			return "Acknowledged."
