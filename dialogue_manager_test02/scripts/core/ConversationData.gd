# =============================================================================
# CONVERSATION DATA - Phase 2A
# File: scripts/core/ConversationData.gd
# Hardcoded conversation content with debug flags for testing
# =============================================================================

extends Node
class_name ConversationData

# =============================================================================
# CONVERSATION CONTENT GETTER
# =============================================================================

static func get_conversation(archetype: SocialDNAManager.NPCArchetype, 
							conv_type: ConversationController.ConversationType,
							trust_level: float, 
							compatibility: float) -> Dictionary:
	
	match conv_type:
		ConversationController.ConversationType.QUICK_CHAT:
			return get_quick_chat_conversation(archetype, trust_level, compatibility)
		ConversationController.ConversationType.TOPIC_DISCUSSION:
			return get_topic_conversation(archetype, trust_level, compatibility)
		ConversationController.ConversationType.DEEP_CONVERSATION:
			return get_deep_conversation(archetype, trust_level, compatibility)
		_:
			return get_quick_chat_conversation(archetype, trust_level, compatibility)

# =============================================================================
# QUICK CHAT CONVERSATIONS (1-2 exchanges)
# =============================================================================

static func get_quick_chat_conversation(archetype: SocialDNAManager.NPCArchetype, 
										trust_level: float, 
										compatibility: float) -> Dictionary:
	
	var conversation = {
		"type": ConversationController.ConversationType.QUICK_CHAT,
		"opening_lines": get_opening_lines(archetype, trust_level),
		"turns": []
	}
	
	# Turn 0: Initial player response
	conversation.turns.append({
		"turn": 0,
		"player_options": [
			{
				"social_type": SocialDNAManager.SocialType.AGGRESSIVE,
				"text": "Let's cut to the chase."
			},
			{
				"social_type": SocialDNAManager.SocialType.DIPLOMATIC, 
				"text": "I'd appreciate your perspective on something."
			},
			{
				"social_type": SocialDNAManager.SocialType.CHARMING,
				"text": "You seem like someone worth knowing."
			},
			{
				"social_type": SocialDNAManager.SocialType.DIRECT,
				"text": "What's on your mind?"
			},
			{
				"social_type": SocialDNAManager.SocialType.EMPATHETIC,
				"text": "How are you doing today?"
			}
		]
	})
	
	# Turn 1: Follow-up responses
	conversation.turns.append({
		"turn": 1,
		"player_options": [
			{
				"social_type": SocialDNAManager.SocialType.AGGRESSIVE,
				"text": "I'll remember this conversation."
			},
			{
				"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
				"text": "Thank you for your time."
			},
			{
				"social_type": SocialDNAManager.SocialType.CHARMING,
				"text": "This has been delightful."
			},
			{
				"social_type": SocialDNAManager.SocialType.DIRECT,
				"text": "Good to know."
			},
			{
				"social_type": SocialDNAManager.SocialType.EMPATHETIC,
				"text": "I hope things go well for you."
			}
		]
	})
	
	return conversation

# =============================================================================
# TOPIC CONVERSATIONS (3-5 exchanges) 
# =============================================================================

static func get_topic_conversation(archetype: SocialDNAManager.NPCArchetype,
								  trust_level: float,
								  compatibility: float) -> Dictionary:
	
	var conversation = {
		"type": ConversationController.ConversationType.TOPIC_DISCUSSION,
		"opening_lines": get_topic_opening_lines(archetype, trust_level),
		"turns": []
	}
	
	# Turn 0: Initial engagement
	conversation.turns.append({
		"turn": 0,
		"player_options": [
			{
				"social_type": SocialDNAManager.SocialType.AGGRESSIVE,
				"text": "I need information, and I need it now."
			},
			{
				"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
				"text": "I was hoping we could discuss something important."
			},
			{
				"social_type": SocialDNAManager.SocialType.CHARMING,
				"text": "I'm sure someone with your expertise could help me understand something."
			},
			{
				"social_type": SocialDNAManager.SocialType.DIRECT,
				"text": "I have some questions about what's happening around here."
			},
			{
				"social_type": SocialDNAManager.SocialType.EMPATHETIC,
				"text": "I'm concerned about some things I've been hearing. What's your take?"
			}
		]
	})
	
	# Turn 1: Deeper engagement
	conversation.turns.append({
		"turn": 1,
		"player_options": [
			{
				"social_type": SocialDNAManager.SocialType.AGGRESSIVE,
				"text": "That's not good enough. I need specifics."
			},
			{
				"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
				"text": "I see your point. Could you elaborate on that?"
			},
			{
				"social_type": SocialDNAManager.SocialType.CHARMING,
				"text": "Fascinating insight. You really understand the situation."
			},
			{
				"social_type": SocialDNAManager.SocialType.DIRECT,
				"text": "What would you do in my position?"
			},
			{
				"social_type": SocialDNAManager.SocialType.EMPATHETIC,
				"text": "This must be difficult for everyone involved."
			}
		]
	})
	
	# Turn 2: Resolution approach
	conversation.turns.append({
		"turn": 2,
		"player_options": [
			{
				"social_type": SocialDNAManager.SocialType.AGGRESSIVE,
				"text": "I'll handle this my way then."
			},
			{
				"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
				"text": "Perhaps we can find a solution that works for everyone."
			},
			{
				"social_type": SocialDNAManager.SocialType.CHARMING,
				"text": "I knew I could count on your wisdom."
			},
			{
				"social_type": SocialDNAManager.SocialType.DIRECT,
				"text": "I understand what needs to be done."
			},
			{
				"social_type": SocialDNAManager.SocialType.EMPATHETIC,
				"text": "Let me know if there's anything I can do to help."
			}
		]
	})
	
	return conversation

# =============================================================================
# DEEP CONVERSATIONS (5+ exchanges)
# =============================================================================

static func get_deep_conversation(archetype: SocialDNAManager.NPCArchetype,
								 trust_level: float, 
								 compatibility: float) -> Dictionary:
	
	var conversation = {
		"type": ConversationController.ConversationType.DEEP_CONVERSATION,
		"opening_lines": get_deep_opening_lines(archetype, trust_level),
		"turns": []
	}
	
	# Extended conversation with more nuanced options
	# Turn 0: Opening gambit
	conversation.turns.append({
		"turn": 0,
		"player_options": [
			{
				"social_type": SocialDNAManager.SocialType.AGGRESSIVE,
				"text": "We need to address the elephant in the room."
			},
			{
				"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
				"text": "I've been thinking about our situation, and I believe we should talk."
			},
			{
				"social_type": SocialDNAManager.SocialType.CHARMING,
				"text": "I value your opinion more than most. Can we speak candidly?"
			},
			{
				"social_type": SocialDNAManager.SocialType.DIRECT,
				"text": "I think it's time we had a serious conversation."
			},
			{
				"social_type": SocialDNAManager.SocialType.EMPATHETIC,
				"text": "I sense there's more going on here than meets the eye."
			}
		]
	})
	
	# Additional turns for deep conversations...
	for turn in range(1, 5):
		conversation.turns.append(get_generic_turn_options(turn))
	
	return conversation

static func get_generic_turn_options(turn_number: int) -> Dictionary:
	return {
		"turn": turn_number,
		"player_options": [
			{
				"social_type": SocialDNAManager.SocialType.AGGRESSIVE,
				"text": "This changes everything. We act now."
			},
			{
				"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
				"text": "I think we can find common ground here."
			},
			{
				"social_type": SocialDNAManager.SocialType.CHARMING,
				"text": "You always know exactly what to say."
			},
			{
				"social_type": SocialDNAManager.SocialType.DIRECT,
				"text": "What's our next move?"
			},
			{
				"social_type": SocialDNAManager.SocialType.EMPATHETIC,
				"text": "I want to make sure everyone's concerns are heard."
			}
		]
	}

# =============================================================================
# OPENING LINES BASED ON TRUST AND COMPATIBILITY
# =============================================================================

static func get_opening_lines(archetype: SocialDNAManager.NPCArchetype, trust_level: float) -> Array:
	match archetype:
		SocialDNAManager.NPCArchetype.AUTHORITY:
			return get_authority_opening_lines(trust_level)
		SocialDNAManager.NPCArchetype.INTELLECTUAL:
			return get_intellectual_opening_lines(trust_level)
		_:
			return [{"text": "Hello there.", "min_compatibility": -999, "max_compatibility": 999, "min_trust_level": -999}]

static func get_authority_opening_lines(trust_level: float) -> Array:
	var lines = []
	
	# High compatibility lines
	lines.append({
		"text": "Outstanding! I can see you understand how things work around here.",
		"min_compatibility": 1.5,
		"max_compatibility": 999,
		"min_trust_level": -999
	})
	
	lines.append({
		"text": "Good to meet someone competent for once.",
		"min_compatibility": 0.5,
		"max_compatibility": 1.5,
		"min_trust_level": -999
	})
	
	# Neutral lines
	lines.append({
		"text": "State your business.",
		"min_compatibility": -0.5,
		"max_compatibility": 0.5,
		"min_trust_level": -999
	})
	
	# Low compatibility lines
	lines.append({
		"text": "I don't have time for this nonsense.",
		"min_compatibility": -1.5,
		"max_compatibility": -0.5,
		"min_trust_level": -999
	})
	
	lines.append({
		"text": "Guards, who let this person in here?",
		"min_compatibility": -999,
		"max_compatibility": -1.5,
		"min_trust_level": -999
	})
	
	return lines

static func get_intellectual_opening_lines(trust_level: float) -> Array:
	var lines = []
	
	# High compatibility lines
	lines.append({
		"text": "Fascinating! I sense great depth in your approach to things.",
		"min_compatibility": 1.5,
		"max_compatibility": 999,
		"min_trust_level": -999
	})
	
	lines.append({
		"text": "An interesting perspective, I'm sure. Please, continue.",
		"min_compatibility": 0.5,
		"max_compatibility": 1.5,
		"min_trust_level": -999
	})
	
	# Neutral lines
	lines.append({
		"text": "How curious. What brings you to seek discourse?",
		"min_compatibility": -0.5,
		"max_compatibility": 0.5,
		"min_trust_level": -999
	})
	
	# Low compatibility lines
	lines.append({
		"text": "I doubt you'd appreciate the complexities involved in my work.",
		"min_compatibility": -1.5,
		"max_compatibility": -0.5,
		"min_trust_level": -999
	})
	
	lines.append({
		"text": "This conversation is beneath both of us, don't you think?",
		"min_compatibility": -999,
		"max_compatibility": -1.5,
		"min_trust_level": -999
	})
	
	return lines

static func get_topic_opening_lines(archetype: SocialDNAManager.NPCArchetype, trust_level: float) -> Array:
	# Different opening lines for topic conversations
	match archetype:
		SocialDNAManager.NPCArchetype.AUTHORITY:
			return [{
				"text": "You look like you have something important to discuss.",
				"min_compatibility": -999,
				"max_compatibility": 999,
				"min_trust_level": -999
			}]
		SocialDNAManager.NPCArchetype.INTELLECTUAL:
			return [{
				"text": "I can see the wheels turning in your mind. What puzzle are you working on?",
				"min_compatibility": -999,
				"max_compatibility": 999,
				"min_trust_level": -999
			}]
		_:
			return [{
				"text": "What can I help you with?",
				"min_compatibility": -999,
				"max_compatibility": 999,
				"min_trust_level": -999
			}]

static func get_deep_opening_lines(archetype: SocialDNAManager.NPCArchetype, trust_level: float) -> Array:
	match archetype:
		SocialDNAManager.NPCArchetype.AUTHORITY:
			return [{
				"text": "I can tell this is more than casual conversation. Speak freely.",
				"min_compatibility": -999,
				"max_compatibility": 999,
				"min_trust_level": 1.0
			}]
		SocialDNAManager.NPCArchetype.INTELLECTUAL:
			return [{
				"text": "Ah, I sense we're about to delve into something profound. I'm intrigued.",
				"min_compatibility": -999,
				"max_compatibility": 999,
				"min_trust_level": 1.0
			}]
		_:
			return [{
				"text": "This seems important. I'm listening.",
				"min_compatibility": -999,
				"max_compatibility": 999,
				"min_trust_level": 1.0
			}]

# =============================================================================
# NPC REACTION TEXTS
# =============================================================================

static func get_npc_reaction_text(archetype: SocialDNAManager.NPCArchetype,
								 social_choice: SocialDNAManager.SocialType,
								 compatibility_result: String,
								 turn: int) -> String:
	
	match archetype:
		SocialDNAManager.NPCArchetype.AUTHORITY:
			return get_authority_reaction(social_choice, compatibility_result, turn)
		SocialDNAManager.NPCArchetype.INTELLECTUAL:
			return get_intellectual_reaction(social_choice, compatibility_result, turn)
		_:
			return "I see."

static func get_authority_reaction(social_choice: SocialDNAManager.SocialType,
								  compatibility_result: String,
								  turn: int) -> String:
	
	var reactions = {
		"VERY_COMPATIBLE": {
			SocialDNAManager.SocialType.AGGRESSIVE: [
				"Exactly the kind of fire we need around here!",
				"That's the attitude that gets results!",
				"Now you're speaking my language!"
			],
			SocialDNAManager.SocialType.DIRECT: [
				"Straight to the point. I respect that.",
				"No wasted words. Excellent.",
				"Finally, someone who understands efficiency."
			]
		},
		"COMPATIBLE": {
			SocialDNAManager.SocialType.AGGRESSIVE: [
				"I can work with that approach.",
				"Good intensity, but pace yourself.",
				"That's the right energy, just controlled."
			],
			SocialDNAManager.SocialType.DIRECT: [
				"Clear and concise. Good.",
				"I appreciate the directness.",
				"That's how business should be done."
			]
		},
		"NEUTRAL": {
			SocialDNAManager.SocialType.DIPLOMATIC: [
				"A reasonable approach, I suppose.",
				"That's... measured.",
				"I can see the merit in that."
			]
		},
		"INCOMPATIBLE": {
			SocialDNAManager.SocialType.EMPATHETIC: [
				"We're not running a support group here.",
				"Feelings don't solve problems.",
				"That's a luxury we can't afford."
			],
			SocialDNAManager.SocialType.CHARMING: [
				"This isn't a social club.",
				"Save the charm for someone else.",
				"I prefer substance over style."
			]
		},
		"VERY_INCOMPATIBLE": {
			SocialDNAManager.SocialType.CHARMING: [
				"Your smooth talk doesn't impress me.",
				"I've heard enough empty flattery for one lifetime.",
				"Actions, not words, prove worth."
			],
			SocialDNAManager.SocialType.EMPATHETIC: [
				"Weakness disguised as compassion.",
				"Sentiment has no place in serious matters.",
				"Your bleeding heart will get people killed."
			]
		}
	}
	
	return get_random_reaction(reactions, social_choice, compatibility_result)

static func get_intellectual_reaction(social_choice: SocialDNAManager.SocialType,
									 compatibility_result: String,
									 turn: int) -> String:
	
	var reactions = {
		"VERY_COMPATIBLE": {
			SocialDNAManager.SocialType.DIPLOMATIC: [
				"A wonderfully nuanced perspective!",
				"Such thoughtful consideration of all angles!",
				"You demonstrate remarkable intellectual sophistication!"
			],
			SocialDNAManager.SocialType.EMPATHETIC: [
				"Your empathy shows true wisdom.",
				"Understanding others is the key to understanding truth.",
				"Emotional intelligence is still intelligence."
			]
		},
		"COMPATIBLE": {
			SocialDNAManager.SocialType.DIPLOMATIC: [
				"A well-reasoned approach.",
				"I appreciate the thoughtfulness.",
				"That shows good judgment."
			],
			SocialDNAManager.SocialType.DIRECT: [
				"Simple, but effective.",
				"Sometimes clarity is its own wisdom.",
				"Direct, but not crude. Good."
			]
		},
		"NEUTRAL": {
			SocialDNAManager.SocialType.CHARMING: [
				"Charming, in its way.",
				"I suppose that has its place.",
				"An... interesting choice."
			]
		},
		"INCOMPATIBLE": {
			SocialDNAManager.SocialType.AGGRESSIVE: [
				"Such... intensity. Perhaps misplaced?",
				"Aggression rarely leads to enlightenment.",
				"Brute force is the tool of limited minds."
			]
		},
		"VERY_INCOMPATIBLE": {
			SocialDNAManager.SocialType.AGGRESSIVE: [
				"Your crude approach appalls me.",
				"Violence is the last refuge of the incompetent.",
				"Such barbarism has no place in civilized discourse."
			]
		}
	}
	
	return get_random_reaction(reactions, social_choice, compatibility_result)

static func get_random_reaction(reactions: Dictionary, 
							   social_choice: SocialDNAManager.SocialType,
							   compatibility_result: String) -> String:
	
	if reactions.has(compatibility_result) and reactions[compatibility_result].has(social_choice):
		var options = reactions[compatibility_result][social_choice]
		return options[randi() % options.size()]
	
	# Fallback reactions
	match compatibility_result:
		"VERY_COMPATIBLE": return "Excellent point!"
		"COMPATIBLE": return "I can work with that."
		"NEUTRAL": return "Hmm, interesting."
		"INCOMPATIBLE": return "I'm not sure about that approach."
		"VERY_INCOMPATIBLE": return "That's completely wrong."
		_: return "I see."
