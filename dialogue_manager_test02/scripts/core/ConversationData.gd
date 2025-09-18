# =============================================================================
# ENHANCED CONVERSATION DATA - Phase 2B
# File: scripts/core/ConversationData.gd (REPLACE existing file)
# Adds trust-aware reactions and trust-gated conversation content
# =============================================================================

extends Node
class_name ConversationData

# =============================================================================
# ENHANCED CONVERSATION CONTENT GETTER
# =============================================================================

static func get_conversation(archetype: SocialDNAManager.NPCArchetype, 
							conv_type: ConversationController.ConversationType,
							trust_level: float, 
							compatibility: float) -> Dictionary:
	
	# Get base conversation structure
	var conversation = {}
	
	match conv_type:
		ConversationController.ConversationType.QUICK_CHAT:
			conversation = get_quick_chat_conversation(archetype, trust_level, compatibility)
		ConversationController.ConversationType.TOPIC_DISCUSSION:
			conversation = get_topic_conversation(archetype, trust_level, compatibility)
		ConversationController.ConversationType.DEEP_CONVERSATION:
			conversation = get_deep_conversation(archetype, trust_level, compatibility)
		_:
			conversation = get_quick_chat_conversation(archetype, trust_level, compatibility)
	
	# Add trust-aware opening lines
	conversation.opening_lines = get_trust_aware_opening_lines(archetype, trust_level, compatibility)
	
	return conversation

# =============================================================================
# TRUST-AWARE OPENING LINES
# =============================================================================

static func get_trust_aware_opening_lines(archetype: SocialDNAManager.NPCArchetype, 
										 trust_level: float,
										 compatibility: float) -> Array:
	
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

# =============================================================================
# TRUST-AWARE NPC REACTIONS
# =============================================================================

static func get_trust_aware_reaction_text(archetype: SocialDNAManager.NPCArchetype,
										 social_choice: SocialDNAManager.SocialType,
										 compatibility_result: String,
										 trust_level: float,
										 turn: int) -> String:
	
	# Get trust-modified reactions
	match archetype:
		SocialDNAManager.NPCArchetype.AUTHORITY:
			return get_authority_trust_reaction(social_choice, compatibility_result, trust_level, turn)
		SocialDNAManager.NPCArchetype.INTELLECTUAL:
			return get_intellectual_trust_reaction(social_choice, compatibility_result, trust_level, turn)
		_:
			return get_generic_reaction(compatibility_result)

static func get_authority_trust_reaction(social_choice: SocialDNAManager.SocialType,
										compatibility_result: String,
										trust_level: float,
										turn: int) -> String:
	
	# Trust level modifies how reactions are delivered
	var trust_modifier = ""
	if trust_level >= 2.0:
		trust_modifier = "trusted_"
	elif trust_level >= 1.0:
		trust_modifier = "professional_"
	elif trust_level < 0.0:
		trust_modifier = "hostile_"
	
	var reactions = {
		# VERY COMPATIBLE reactions with trust variants
		"VERY_COMPATIBLE": {
			SocialDNAManager.SocialType.AGGRESSIVE: {
				"": ["Exactly the kind of fire we need around here!", "That's the attitude that gets results!", "Now you're speaking my language!"],
				"professional_": ["I knew I could count on your intensity when it matters.", "Your aggressive approach is exactly what this situation needs.", "That's why I trust your judgment in difficult situations."],
				"trusted_": ["Perfect. Your killer instinct is why you're my right hand.", "That's the aggressive leadership I've come to rely on.", "Exactly what I expected from my most trusted operative."],
				"hostile_": ["Your aggression doesn't impress me anymore.", "I've seen this act before. It got old.", "Save the posturing for someone who still cares."]
			},
			SocialDNAManager.SocialType.DIRECT: {
				"": ["Straight to the point. I respect that.", "No wasted words. Excellent.", "Finally, someone who understands efficiency."],
				"professional_": ["Your directness is exactly why I work well with you.", "I appreciate that you don't waste my time with nonsense.", "That's the efficiency I've come to expect from you."],
				"trusted_": ["Perfect. No one cuts through confusion like you do.", "Your directness is one of your greatest strengths.", "That's exactly why I trust you with the important matters."],
				"hostile_": ["Your bluntness has lost its charm.", "Direct, but I don't care what you think anymore.", "Being direct doesn't make you right."]
			}
		},
		
		# COMPATIBLE reactions with trust variants  
		"COMPATIBLE": {
			SocialDNAManager.SocialType.AGGRESSIVE: {
				"": ["I can work with that approach.", "Good intensity, but pace yourself.", "That's the right energy, just controlled."],
				"professional_": ["Your controlled aggression shows you're learning.", "Good balance of force and restraint.", "That's the kind of measured intensity that gets results."],
				"trusted_": ["I trust your judgment on when to push hard.", "Your aggressive instincts are well-honed now.", "You know when to apply pressure. Good."],
				"hostile_": ["Your aggression is predictable and tiresome.", "I expected more subtlety by now.", "Same old aggressive response. How boring."]
			},
			SocialDNAManager.SocialType.DIRECT: {
				"": ["Clear and concise. Good.", "I appreciate the directness.", "That's how business should be done."],
				"professional_": ["Your direct communication style works well for us.", "I appreciate that you get straight to the point.", "That directness is becoming one of your strengths."],
				"trusted_": ["Your honesty is one of the things I value most about you.", "I can always count on you to tell me the truth.", "That directness has served us both well."],
				"hostile_": ["Your directness feels more like rudeness now.", "Being direct doesn't excuse being inconsiderate.", "I preferred when your directness came with respect."]
			}
		},
		
		# NEUTRAL reactions
		"NEUTRAL": {
			SocialDNAManager.SocialType.DIPLOMATIC: {
				"": ["A reasonable approach, I suppose.", "That's... measured.", "I can see the merit in that."],
				"professional_": ["Your diplomatic approach has its place.", "I can respect that perspective.", "That's a reasonable way to handle it."],
				"trusted_": ["Your diplomatic instincts are usually sound.", "I trust your judgment on the best approach.", "You typically know how to handle these situations."],
				"hostile_": ["Your diplomacy feels hollow now.", "I don't buy the reasonable act anymore.", "Diplomatic words can't fix what's broken between us."]
			}
		},
		
		# INCOMPATIBLE reactions
		"INCOMPATIBLE": {
			SocialDNAManager.SocialType.EMPATHETIC: {
				"": ["We're not running a support group here.", "Feelings don't solve problems.", "That's a luxury we can't afford."],
				"professional_": ["Your empathy, while admirable, isn't practical here.", "I understand your concern, but we need solutions.", "Compassion has its place, but not in this situation."],
				"trusted_": ["I know you care, but sometimes hard choices must be made.", "Your empathy is valued, but we need to be realistic.", "I respect your compassion, even when it complicates things."],
				"hostile_": ["Your fake empathy doesn't work on me anymore.", "Save the caring act for someone who believes it.", "Your empathy feels manipulative now."]
			},
			SocialDNAManager.SocialType.CHARMING: {
				"": ["This isn't a social club.", "Save the charm for someone else.", "I prefer substance over style."],
				"professional_": ["Your charm is noted, but let's focus on business.", "I appreciate the effort, but results matter more.", "Charm has its place, but not in serious matters."],
				"trusted_": ["You don't need to charm me - I already trust you.", "Your charm is unnecessary; I value your competence.", "I know who you really are beyond the charm."],
				"hostile_": ["Your charm is wasted on someone who sees through it.", "I remember when your charm was genuine.", "That smooth talk doesn't work on me anymore."]
			}
		},
		
		# VERY INCOMPATIBLE reactions  
		"VERY_INCOMPATIBLE": {
			SocialDNAManager.SocialType.CHARMING: {
				"": ["Your smooth talk doesn't impress me.", "I've heard enough empty flattery for one lifetime.", "Actions, not words, prove worth."],
				"professional_": ["Your charm feels inappropriate for the situation.", "I expected more professionalism from you.", "This isn't the time for charm; we need action."],
				"trusted_": ["I'm disappointed. I thought you understood me better.", "Your charm feels forced. What's really going on?", "I trusted you to be genuine with me."],
				"hostile_": ["Your disgusting charm makes my skin crawl.", "I can't stand your fake smile anymore.", "Your charm is the epitome of everything I despise about you."]
			},
			SocialDNAManager.SocialType.EMPATHETIC: {
				"": ["Weakness disguised as compassion.", "Sentiment has no place in serious matters.", "Your bleeding heart will get people killed."],
				"professional_": ["Your empathy is misplaced in this situation.", "I need clear thinking, not emotional responses.", "Compassion is admirable, but practicality is essential."],
				"trusted_": ["I understand your compassion, but sometimes we must make hard choices.", "Your empathy is one of your strengths, even when it conflicts with necessity.", "I know this is difficult for you, but we need to be practical."],
				"hostile_": ["Your fake empathy is nauseating.", "I'm sick of your bleeding-heart routine.", "Your empathy is just emotional manipulation."]
			}
		}
	}
	
	return get_random_trust_reaction(reactions, social_choice, compatibility_result, trust_modifier)

static func get_intellectual_trust_reaction(social_choice: SocialDNAManager.SocialType,
										   compatibility_result: String,
										   trust_level: float,
										   turn: int) -> String:
	
	var trust_modifier = ""
	if trust_level >= 2.0:
		trust_modifier = "trusted_"
	elif trust_level >= 1.0:
		trust_modifier = "professional_"
	elif trust_level < 0.0:
		trust_modifier = "hostile_"
	
	var reactions = {
		"VERY_COMPATIBLE": {
			SocialDNAManager.SocialType.DIPLOMATIC: {
				"": ["A wonderfully nuanced perspective!", "Such thoughtful consideration of all angles!", "You demonstrate remarkable intellectual sophistication!"],
				"professional_": ["Your diplomatic approach shows intellectual maturity.", "I appreciate your thoughtful analysis of the situation.", "Your nuanced thinking is exactly what this requires."],
				"trusted_": ["Your diplomatic wisdom continues to impress me.", "This is why I value our intellectual partnership.", "Your sophisticated approach is precisely what I hoped for."],
				"hostile_": ["Your diplomacy feels calculated and cold now.", "I don't trust your diplomatic manipulations anymore.", "Your nuanced approach seems designed to deceive."]
			},
			SocialDNAManager.SocialType.EMPATHETIC: {
				"": ["Your empathy shows true wisdom.", "Understanding others is the key to understanding truth.", "Emotional intelligence is still intelligence."],
				"professional_": ["Your empathetic insight adds valuable perspective.", "I appreciate your consideration of all stakeholders.", "Your emotional intelligence enhances our analysis."],
				"trusted_": ["Your empathy is one of your greatest intellectual gifts.", "This is why I trust your judgment on complex matters.", "Your compassionate wisdom guides us well."],
				"hostile_": ["Your empathy feels like intellectual weakness now.", "I don't believe in your caring act anymore.", "Your empathy has become a tool for manipulation."]
			}
		},
		
		"COMPATIBLE": {
			SocialDNAManager.SocialType.DIPLOMATIC: {
				"": ["A well-reasoned approach.", "I appreciate the thoughtfulness.", "That shows good judgment."],
				"professional_": ["Your diplomatic reasoning is sound.", "I can see the logic in your approach.", "That's a thoughtful way to handle this."],
				"trusted_": ["Your diplomatic instincts are well-developed.", "I trust your reasoned approach to these matters.", "Your thoughtfulness serves us both well."],
				"hostile_": ["Your diplomacy feels hollow and manipulative.", "I don't buy your reasonable facade anymore.", "Your diplomatic words can't hide your true nature."]
			},
			SocialDNAManager.SocialType.DIRECT: {
				"": ["Simple, but effective.", "Sometimes clarity is its own wisdom.", "Direct, but not crude. Good."],
				"professional_": ["Your direct approach has merit in this context.", "I appreciate the clarity of your position.", "That directness serves the discussion well."],
				"trusted_": ["Your directness cuts through unnecessary complexity.", "I value your honest, straightforward perspective.", "Your clear thinking is exactly what we need."],
				"hostile_": ["Your directness has become blunt and thoughtless.", "Being direct doesn't excuse being intellectually lazy.", "Your bluntness lacks the nuance I once respected."]
			}
		},
		
		"NEUTRAL": {
			SocialDNAManager.SocialType.CHARMING: {
				"": ["Charming, in its way.", "I suppose that has its place.", "An... interesting choice."],
				"professional_": ["Your charm is noted, though substance matters more.", "I understand the social utility of your approach.", "Charm has its place in intellectual discourse."],
				"trusted_": ["Your charm doesn't change our intellectual connection.", "I see beyond the charm to the real person.", "You don't need to charm me - I already value your mind."],
				"hostile_": ["Your charm feels intellectually dishonest now.", "I find your charming facade tedious.", "Your charm is just surface-level manipulation."]
			}
		},
		
		"INCOMPATIBLE": {
			SocialDNAManager.SocialType.AGGRESSIVE: {
				"": ["Such... intensity. Perhaps misplaced?", "Aggression rarely leads to enlightenment.", "Brute force is the tool of limited minds."],
				"professional_": ["Your aggressive approach lacks intellectual subtlety.", "I prefer reasoned discourse to forceful assertions.", "Intensity has its place, but not in thoughtful analysis."],
				"trusted_": ["I know you're passionate, but let's channel that productively.", "Your intensity shows you care, even if the approach is flawed.", "I understand your frustration, but aggression clouds judgment."],
				"hostile_": ["Your brutish aggression disgusts me intellectually.", "Your aggressive stupidity is exactly what I expected.", "Your crude approach confirms my worst assumptions about you."]
			}
		},
		
		"VERY_INCOMPATIBLE": {
			SocialDNAManager.SocialType.AGGRESSIVE: {
				"": ["Your crude approach appalls me.", "Violence is the last refuge of the incompetent.", "Such barbarism has no place in civilized discourse."],
				"professional_": ["Your aggressive stance undermines any intellectual merit.", "I cannot engage productively with such forceful approaches.", "Aggression and intellectual discourse are fundamentally incompatible."],
				"trusted_": ["I'm deeply disappointed in this aggressive turn.", "This isn't the thoughtful person I thought I knew.", "Your aggression betrays the intellectual bond I thought we had."],
				"hostile_": ["Your vile aggression confirms you're intellectually bankrupt.", "Your barbaric approach is the epitome of everything wrong with your thinking.", "Your crude aggression makes me sick to my intellectual core."]
			}
		}
	}
	
	return get_random_trust_reaction(reactions, social_choice, compatibility_result, trust_modifier)

static func get_random_trust_reaction(reactions: Dictionary, 
									 social_choice: SocialDNAManager.SocialType,
									 compatibility_result: String,
									 trust_modifier: String) -> String:
	
	if reactions.has(compatibility_result) and reactions[compatibility_result].has(social_choice):
		var choice_reactions = reactions[compatibility_result][social_choice]
		
		# Try trust-modified version first
		if choice_reactions.has(trust_modifier):
			var options = choice_reactions[trust_modifier]
			return options[randi() % options.size()]
		
		# Fall back to default
		if choice_reactions.has(""):
			var options = choice_reactions[""]
			return options[randi() % options.size()]
	
	return get_generic_reaction(compatibility_result)

static func get_generic_reaction(compatibility_result: String) -> String:
	match compatibility_result:
		"VERY_COMPATIBLE": return "Excellent point!"
		"COMPATIBLE": return "I can work with that."
		"NEUTRAL": return "Hmm, interesting."
		"INCOMPATIBLE": return "I'm not sure about that approach."
		"VERY_INCOMPATIBLE": return "That's completely wrong."
		_: return "I see."

# =============================================================================
# ENHANCED CONVERSATION STRUCTURES (Same as before, but with trust context)
# =============================================================================

static func get_quick_chat_conversation(archetype: SocialDNAManager.NPCArchetype, 
										trust_level: float, 
										compatibility: float) -> Dictionary:
	
	var conversation = {
		"type": ConversationController.ConversationType.QUICK_CHAT,
		"turns": []
	}
	
	# Turn 0: Initial player response (same options, but reactions will be trust-aware)
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
	
	# Turn 1: Follow-up responses (trust-aware reactions will make these feel different)
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

static func get_topic_conversation(archetype: SocialDNAManager.NPCArchetype,
								  trust_level: float,
								  compatibility: float) -> Dictionary:
	
	var conversation = {
		"type": ConversationController.ConversationType.TOPIC_DISCUSSION,
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

static func get_deep_conversation(archetype: SocialDNAManager.NPCArchetype,
								 trust_level: float, 
								 compatibility: float) -> Dictionary:
	
	var conversation = {
		"type": ConversationController.ConversationType.DEEP_CONVERSATION,
		"turns": []
	}
	
	# Deep conversations have more sophisticated options that change based on trust
	# Turn 0: Opening gambit
	conversation.turns.append({
		"turn": 0,
		"player_options": get_deep_conversation_opening_options(trust_level)
	})
	
	# Additional turns for deep conversations
	for turn in range(1, 5):
		conversation.turns.append(get_deep_conversation_turn_options(turn, trust_level))
	
	return conversation

static func get_deep_conversation_opening_options(trust_level: float) -> Array:
	if trust_level >= 3.0:  # Close relationship
		return [
			{
				"social_type": SocialDNAManager.SocialType.AGGRESSIVE,
				"text": "We've been through too much together to dance around this issue."
			},
			{
				"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
				"text": "Given our history, I think we can speak frankly about what's really happening."
			},
			{
				"social_type": SocialDNAManager.SocialType.CHARMING,
				"text": "You know I wouldn't come to you unless this was truly important."
			},
			{
				"social_type": SocialDNAManager.SocialType.DIRECT,
				"text": "I need your honest opinion about something that could affect us both."
			},
			{
				"social_type": SocialDNAManager.SocialType.EMPATHETIC,
				"text": "I'm worried about you, and I think there's more going on than you're letting on."
			}
		]
	else:  # Trusted level
		return [
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

static func get_deep_conversation_turn_options(turn_number: int, trust_level: float) -> Dictionary:
	# Deep conversations have more meaningful, trust-aware options
	return {
		"turn": turn_number,
		"player_options": [
			{
				"social_type": SocialDNAManager.SocialType.AGGRESSIVE,
				"text": "This changes everything. We need to act decisively."
			},
			{
				"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
				"text": "I think we can find a path forward that serves everyone's interests."
			},
			{
				"social_type": SocialDNAManager.SocialType.CHARMING,
				"text": "Your wisdom in these matters continues to impress me."
			},
			{
				"social_type": SocialDNAManager.SocialType.DIRECT,
				"text": "What's our next move?"
			},
			{
				"social_type": SocialDNAManager.SocialType.EMPATHETIC,
				"text": "I want to make sure we consider how this affects everyone involved."
			}
		]
	}
