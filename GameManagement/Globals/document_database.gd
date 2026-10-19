extends Node
class_name DocumentDatabase

@export var documents_folder: String = "res://Assets/Documents/Resources/"
@export var recursive: bool = false #look into sub folders? idk if will be needed

var by_id: Dictionary = {}
var all: Array = [DocumentInfo]                

func _ready() -> void:
	reload()

func reload() -> void:
	by_id.clear()
	all.clear()

	var paths: Array[String] = []
	get_resource_paths(documents_folder, paths, recursive)
	for path in paths:
		var res = load(path)
		if res == null:
			push_warning("Failed to load resource: %s" % path)
			continue
		
		#Only keep if it is DocumentInfo
		if res is DocumentInfo:
			register_document(res, path)
		#Ignore unrelated resources in the folder

func get_document(id: int) -> DocumentInfo:
	return by_id.get(id)

func has_document(id: String) -> bool:
	return by_id.has(id)

func print_all_documents_title():
	for document in all:
		print(document.title)

func register_document(doc: DocumentInfo, path: String):
	if doc.document_id < 0:
		push_warning("Document has negative document_id: %s" % path)
		return

	if by_id.has(doc.document_id):
		#var existing: DocumentInfo = by_id[doc.document_id]
		push_warning("Duplicate document_id '%s'. Keeping first, ignoring: %s" % [doc.document_id, path])
		return

	by_id[doc.document_id] = doc
	all.append(doc)

func get_resource_paths(folder: String, out_paths: Array[String], is_recursive: bool):
	var dir := DirAccess.open(folder)
	if dir == null:
		push_warning("Document folder not found: %s" % folder)
		return
	dir.list_dir_begin()
	while true:
		var path_name := dir.get_next()
		if path_name == "": #Base case
			break

		if path_name.begins_with("."): #Ignore these documents
			continue

		var full_path := folder.path_join(path_name)

		if dir.current_is_dir(): #If finds a folder, recurse into it
			if is_recursive:
				get_resource_paths(full_path, out_paths, is_recursive)
		else:
			# Only load .tres
			if full_path.ends_with(".tres") or full_path.ends_with(".tres.remap"): #when exported, all .tres have .remap added to the end
				var load_path = full_path.replace(".remap", "")
				out_paths.append(load_path)

	dir.list_dir_end()
