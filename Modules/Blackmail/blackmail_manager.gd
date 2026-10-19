extends Node

# path to bm database (blackmail record resources should already be linked to the database within this resource)
const BM_DATABASE_TEMPLATE_PATH = "res://Modules/Blackmail/Data/bm_database.tres"
const BM_DATABASE_SAVE_PATH = "user://bm_database.tres"

var database: BlackmailDatabase

func _ready() -> void:
	database = load_data()

func load_data() -> BlackmailDatabase:
	# try loading from save path
	if ResourceLoader.exists(BM_DATABASE_SAVE_PATH):
		#print("Loading BM Database from save")
		var db = ResourceLoader.load(BM_DATABASE_SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as BlackmailDatabase
		return db
	# try to make new save from template
	#print("Trying to make BM Database from template")
	var temp = ResourceLoader.load(BM_DATABASE_TEMPLATE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as BlackmailDatabase
	var newDB = temp.duplicate(true)
	for record in newDB.bm_records:
		record.resource_path = ""
	return newDB
	
func save_data():
	#for record in database.bm_records:
		#print(record.person_name, " is_deleted: ", record.blackmail_deleted)
	ResourceSaver.save(database, BM_DATABASE_SAVE_PATH)
