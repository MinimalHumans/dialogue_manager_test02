# =============================================================================
# 5. MAIN SCENE CONTROLLER (scripts/Main.gd)
# =============================================================================

# NOTE: Create new script file for this class  
extends Node2D

# UI will be instanced from scene file
@onready var ui_canvas: CanvasLayer = $UI

# Test NPCs
var npcs := []

func _ready():
	setup_ui()
	create_test_npcs()
	
	# Connect to NPC interactions
	for npc in npcs:
		npc.npc_clicked.connect(_on_npc_interaction)

func setup_ui():
	# Instance the SocialDNAPanel scene
	var ui_panel_scene = preload("res://scenes/ui/SocialDNAPanel.tscn")
	var ui_panel = ui_panel_scene.instantiate()
	ui_panel.position = Vector2(10, 10)
	ui_panel.size = Vector2(300, 500)
	ui_canvas.add_child(ui_panel)

func create_test_npcs():
	# Create Authority NPC
	var authority_npc_scene = preload("res://scenes/NPCTest.tscn")
	var authority_npc = authority_npc_scene.instantiate()
	authority_npc.npc_name = "Captain Stone"
	authority_npc.archetype = SocialDNAManager.NPCArchetype.AUTHORITY
	authority_npc.position = Vector2(500, 200)
	add_child(authority_npc)
	npcs.append(authority_npc)
	
	# Create Intellectual NPC  
	var intellectual_npc_scene = preload("res://scenes/NPCTest.tscn")
	var intellectual_npc = intellectual_npc_scene.instantiate()
	intellectual_npc.npc_name = "Dr. Wisdom"
	intellectual_npc.archetype = SocialDNAManager.NPCArchetype.INTELLECTUAL
	intellectual_npc.position = Vector2(700, 200)
	add_child(intellectual_npc)
	npcs.append(intellectual_npc)

func _on_npc_interaction(npc):
	print("Player interacted with %s (compatibility: %.2f)" % [npc.npc_name, npc.current_compatibility])
	# Future: Open dialogue system here
