# =============================================================================
# 2. DATABASE MANAGER (AutoLoad: scripts/autoload/DatabaseManager.gd) 
# =============================================================================

# NOTE: Create new script file for this class
extends Node

var db: SQLite
var db_ready := false

func _ready():
	initialize_database()

func initialize_database():
	# Initialize SQLite (requires SQLite addon)
	db = SQLite.new()
	db.path = "user://social_dna.db"
	
	if db.open_db():
		create_tables()
		db_ready = true
		print("Database initialized successfully")
	else:
		print("ERROR: Cannot open database")

func create_tables():
	# Phase 1: Simple player data storage
	var create_player_table = """
	CREATE TABLE IF NOT EXISTS player_social_dna (
		id INTEGER PRIMARY KEY,
		aggressive INTEGER DEFAULT 10,
		diplomatic INTEGER DEFAULT 10,
		charming INTEGER DEFAULT 10,
		direct INTEGER DEFAULT 10,
		empathetic INTEGER DEFAULT 10,
		total_interactions INTEGER DEFAULT 0,
		last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);
	"""
	
	if not db.query(create_player_table):
		print("ERROR: Cannot create player_social_dna table")

func is_ready() -> bool:
	return db_ready

func save_social_dna(social_dna: Dictionary):
	if not db_ready:
		return
		
	var query = """
	INSERT OR REPLACE INTO player_social_dna 
	(id, aggressive, diplomatic, charming, direct, empathetic, last_updated)
	VALUES (1, ?, ?, ?, ?, ?, datetime('now'))
	"""
	
	var params = [
		social_dna[SocialDNAManager.SocialType.AGGRESSIVE],
		social_dna[SocialDNAManager.SocialType.DIPLOMATIC], 
		social_dna[SocialDNAManager.SocialType.CHARMING],
		social_dna[SocialDNAManager.SocialType.DIRECT],
		social_dna[SocialDNAManager.SocialType.EMPATHETIC]
	]
	
	db.query_with_bindings(query, params)

func load_social_dna() -> Dictionary:
	if not db_ready:
		return {}
		
	var query = "SELECT * FROM player_social_dna WHERE id = 1"
	db.query(query)
	
	if db.query_result.size() > 0:
		var row = db.query_result[0]
		return {
			SocialDNAManager.SocialType.AGGRESSIVE: int(row["aggressive"]),
			SocialDNAManager.SocialType.DIPLOMATIC: int(row["diplomatic"]),
			SocialDNAManager.SocialType.CHARMING: int(row["charming"]),
			SocialDNAManager.SocialType.DIRECT: int(row["direct"]),
			SocialDNAManager.SocialType.EMPATHETIC: int(row["empathetic"])
		}
	
	return {}
