# =============================================================================
# 1. CORE SOCIAL DNA MANAGER (AutoLoad: scripts/autoload/SocialDNAManager.gd)
# =============================================================================

extends Node

# Social DNA Types
enum SocialType {
	AGGRESSIVE,
	DIPLOMATIC, 
	CHARMING,
	DIRECT,
	EMPATHETIC
}

# NPC Archetypes
enum NPCArchetype {
	AUTHORITY,
	INTELLECTUAL
}

# Player's Social DNA - starts balanced for testing
var social_dna := {
	SocialType.AGGRESSIVE: 10,
	SocialType.DIPLOMATIC: 10,
	SocialType.CHARMING: 10,
	SocialType.DIRECT: 10,
	SocialType.EMPATHETIC: 10
}

# NPC Compatibility matrices - how each archetype responds to social approaches
var archetype_preferences := {
	NPCArchetype.AUTHORITY: {
		SocialType.DIRECT: 2.0,        # Strong positive
		SocialType.AGGRESSIVE: 1.0,    # Positive  
		SocialType.DIPLOMATIC: 0.0,    # Neutral
		SocialType.EMPATHETIC: -1.0,   # Negative
		SocialType.CHARMING: -2.0      # Strong negative
	},
	NPCArchetype.INTELLECTUAL: {
		SocialType.DIPLOMATIC: 2.0,    # Strong positive
		SocialType.EMPATHETIC: 1.0,    # Positive
		SocialType.DIRECT: 1.0,        # Positive
		SocialType.CHARMING: 0.0,      # Neutral
		SocialType.AGGRESSIVE: -2.0    # Strong negative
	}
}

# Signals for UI updates
signal social_dna_changed(new_dna: Dictionary)
signal compatibility_calculated(npc_archetype: NPCArchetype, compatibility: float)

func _ready():
	# Load saved data
	call_deferred("load_social_dna")

# =============================================================================
# CORE COMPATIBILITY CALCULATION
# =============================================================================

func calculate_compatibility(npc_archetype: NPCArchetype) -> float:
	var total_compatibility := 0.0
	var total_social_strength := get_total_social_strength()
	
	if total_social_strength == 0:
		return 0.0
	
	var preferences = archetype_preferences[npc_archetype]
	
	# Weight compatibility by player's strength in each social type
	for social_type in social_dna:
		var player_strength = social_dna[social_type]
		var npc_preference = preferences.get(social_type, 0.0)
		
		# Normalize by total social strength and apply preference
		var weight = float(player_strength) / float(total_social_strength)
		total_compatibility += weight * npc_preference
	
	compatibility_calculated.emit(npc_archetype, total_compatibility)
	return total_compatibility

# =============================================================================
# SOCIAL DNA MANAGEMENT
# =============================================================================

func increase_social_trait(trait_type: SocialType, amount: int = 1):
	var old_dna = social_dna.duplicate()
	
	# Increase the specific trait
	social_dna[trait_type] += amount
	
	# Small growth in all other traits (social development)
	for other_trait in social_dna:
		if other_trait != trait_type:
			social_dna[other_trait] += max(1, amount / 3)
	
	social_dna_changed.emit(social_dna.duplicate())
	save_social_dna()
	
	print("Social DNA Updated - %s increased by %d" % [get_social_type_name(trait_type), amount])

func get_total_social_strength() -> int:
	var total := 0
	for value in social_dna.values():
		total += value
	return total

func get_social_percentages() -> Dictionary:
	var total = get_total_social_strength()
	var percentages := {}
	
	for social_type in social_dna:
		percentages[social_type] = (float(social_dna[social_type]) / float(total)) * 100.0 if total > 0 else 0.0
	
	return percentages

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

func get_social_type_name(type: SocialType) -> String:
	match type:
		SocialType.AGGRESSIVE: return "Aggressive"
		SocialType.DIPLOMATIC: return "Diplomatic"
		SocialType.CHARMING: return "Charming"  
		SocialType.DIRECT: return "Direct"
		SocialType.EMPATHETIC: return "Empathetic"
		_: return "Unknown"

func get_archetype_name(archetype: NPCArchetype) -> String:
	match archetype:
		NPCArchetype.AUTHORITY: return "Authority"
		NPCArchetype.INTELLECTUAL: return "Intellectual"
		_: return "Unknown"

func get_compatibility_description(compatibility: float) -> String:
	if compatibility >= 1.5:
		return "Excellent"
	elif compatibility >= 0.8:
		return "Very Good"
	elif compatibility >= 0.3:
		return "Good"
	elif compatibility >= -0.3:
		return "Neutral"
	elif compatibility >= -0.8:
		return "Poor"
	else:
		return "Very Poor"

func get_compatibility_color(compatibility: float) -> Color:
	if compatibility >= 0.8:
		return Color.GREEN
	elif compatibility >= 0.3:
		return Color.YELLOW_GREEN
	elif compatibility >= -0.3:
		return Color.GRAY
	elif compatibility >= -0.8:
		return Color.ORANGE
	else:
		return Color.RED

# =============================================================================
# DATABASE INTEGRATION (Phase 1 - minimal)
# =============================================================================

func save_social_dna():
	if DatabaseManager.is_ready():
		DatabaseManager.save_social_dna(social_dna)

func load_social_dna():
	if DatabaseManager.is_ready():
		var loaded_dna = DatabaseManager.load_social_dna()
		if loaded_dna.size() > 0:
			social_dna = loaded_dna
			social_dna_changed.emit(social_dna.duplicate())
			print("Social DNA loaded from database")
