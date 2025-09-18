# =============================================================================
# 4. SOCIAL DNA UI PANEL (scripts/ui/SocialDNAPanel.gd)
# =============================================================================

# NOTE: Create new script file for this class
extends Panel
class_name SocialDNAPanel

@onready var stats_label: Label = $VBox/StatsLabel
@onready var test_buttons: VBoxContainer = $VBox/TestButtons

var test_profiles := {
	"Balanced": {
		SocialDNAManager.SocialType.AGGRESSIVE: 10,
		SocialDNAManager.SocialType.DIPLOMATIC: 10,
		SocialDNAManager.SocialType.CHARMING: 10,
		SocialDNAManager.SocialType.DIRECT: 10,
		SocialDNAManager.SocialType.EMPATHETIC: 10
	},
	"Authority Build": {
		SocialDNAManager.SocialType.AGGRESSIVE: 25,
		SocialDNAManager.SocialType.DIPLOMATIC: 5,
		SocialDNAManager.SocialType.CHARMING: 5,
		SocialDNAManager.SocialType.DIRECT: 30,
		SocialDNAManager.SocialType.EMPATHETIC: 8
	},
	"Intellectual Build": {
		SocialDNAManager.SocialType.AGGRESSIVE: 3,
		SocialDNAManager.SocialType.DIPLOMATIC: 30,
		SocialDNAManager.SocialType.CHARMING: 8,
		SocialDNAManager.SocialType.DIRECT: 15,
		SocialDNAManager.SocialType.EMPATHETIC: 25
	}
}

func _ready():
	setup_ui()
	update_display()
	SocialDNAManager.social_dna_changed.connect(_on_social_dna_changed)

func setup_ui():
	# Create test profile buttons
	for profile_name in test_profiles:
		var button = Button.new()
		button.text = "Apply " + profile_name
		button.pressed.connect(func(): apply_test_profile(profile_name))
		test_buttons.add_child(button)
	
	# Add trait increase buttons for testing
	var trait_section = VBoxContainer.new()
	var trait_label = Label.new()
	trait_label.text = "Increase Social Traits:"
	trait_section.add_child(trait_label)
	
	for social_type in SocialDNAManager.SocialType.values():
		var button = Button.new()
		var trait_name = SocialDNAManager.get_social_type_name(social_type)
		button.text = "+" + trait_name
		button.pressed.connect(func(): SocialDNAManager.increase_social_trait(social_type, 3))
		trait_section.add_child(button)
	
	test_buttons.add_child(trait_section)

func update_display():
	var text = "SOCIAL DNA PROFILE\n\n"
	
	# Show current values and percentages
	var percentages = SocialDNAManager.get_social_percentages()
	for social_type in SocialDNAManager.social_dna:
		var name = SocialDNAManager.get_social_type_name(social_type)
		var value = SocialDNAManager.social_dna[social_type]
		var percentage = percentages[social_type]
		text += "%s: %d (%.1f%%)\n" % [name, value, percentage]
	
	text += "\nTotal: %d\n\n" % SocialDNAManager.get_total_social_strength()
	
	# Show compatibility with all archetypes
	text += "NPC COMPATIBILITY:\n"
	for archetype in SocialDNAManager.NPCArchetype.values():
		var compat = SocialDNAManager.calculate_compatibility(archetype)
		var archetype_name = SocialDNAManager.get_archetype_name(archetype)
		var description = SocialDNAManager.get_compatibility_description(compat)
		text += "%s: %.2f (%s)\n" % [archetype_name, compat, description]
	
	stats_label.text = text

func apply_test_profile(profile_name: String):
	if test_profiles.has(profile_name):
		SocialDNAManager.social_dna = test_profiles[profile_name].duplicate()
		SocialDNAManager.social_dna_changed.emit(SocialDNAManager.social_dna.duplicate())
		SocialDNAManager.save_social_dna()
		print("Applied test profile: " + profile_name)

func _on_social_dna_changed(_new_dna: Dictionary):
	update_display()
