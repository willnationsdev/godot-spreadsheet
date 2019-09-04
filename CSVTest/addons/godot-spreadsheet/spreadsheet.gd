# author: willnationsdev
# description: A spreadsheet class that provides a type-safe wrapper for a CSV or TSV document.
# license: MIT
# 
# Assuming sample data:
#
# data.csv:
# id,name,health,attack,defense
# 1,goomba,1,1,0
# 2,koopa,1,2,1
# 3,koopa_king,3,5,0
# 
# row.gd
# extends Resource
# var id
# var name
# var health
# var attack
# var defense
# func _get_key() -> String:
#     return name
# 
# var s = Spreadsheet.new()
# s.row_script = load("row.gd")
# s.load("res://data.csv")
# print(s.koopa_king.health) # prints 3
# print(s.get_row(2).attack) # prints 2

tool
extends Resource
class_name Spreadsheet

##### CLASSES #####

##### SIGNALS #####

##### CONSTANTS #####

##### EXPORTS #####

export var row_script: Script = null

##### PROPERTIES #####

# Array of records. Records are instances of the row script, if non-null. Otherwise Dictionaries.
var _data := []
# Map of row keys to data indexes.
# For Objects, it's the return of obj._get_key().
# For Dictionaries, it's the first key.
# Can be overridden by implementing one's own `_get_key()` method.
var _keys := {}
# A map of column names to row indexes, based on the first row of data.
var _titles := {}

##### NOTIFICATIONS #####

##### OVERRIDES #####

func _get_property_list() -> Array:
	var ret := []
	for a_row in _data:
		var key = _get_key(a_row)
		if key:
			ret.append(_pinfo_resource(key))
	return ret

func _get(p_name: String):
	var slices := _get_slices(p_name)
	if not slices:
		return null
	
	var group := slices.group as String
	var name := slices.name as String
	
	if not _keys.has(group):
		return null
	
	return _data[_keys[group]].get(name)

func _set(p_name: String, p_value) -> bool:
	var slices := _get_slices(p_name)
	if not slices:
		return false
	
	var group := slices.group as String
	var name := slices.name as String
	
	if not _keys.has(group):
		return false
	
	_data[_keys[group]][name] = p_value
	return true

##### VIRTUALS #####

func _get_key(p_row) -> String:
	if not p_row:
		return ""
	if typeof(p_row) == TYPE_OBJECT:
		if p_row.has_method("_get_key"):
			return p_row._get_key()
		else:
			push_error("Spreadsheet row resource must implement the virtual method `_get_key() -> String`.")
			return ""
	elif typeof(p_row) == TYPE_DICTIONARY:
		return p_row.keys()[0]
	return ""

##### PUBLIC METHODS #####

func get_row(p_idx: int):
	return _data[p_idx]

func load(p_path: String, p_delim: String = ",") -> int:
	
	var f := File.new()
	var err := f.open(p_path, File.READ)
	if err != OK:
		return err
	
	_data.clear()
	_keys.clear()
	_titles.clear()
	
	var line := f.get_csv_line(p_delim)
	var titles_array := line
	
	_titles.clear()
	for a_idx in len(line):
		_titles[line[a_idx]] = a_idx
	
	while line:
		line = f.get_csv_line(p_delim)
		
		var inst
		if row_script:
			inst = row_script.new()
		else:
			inst = {}
		
		for a_idx in len(line):
			var a_term := line[a_idx]
			var a_value = str2var(a_term)
			var a_title := titles_array[a_idx]
			
			inst[a_title] = a_value
			_keys[_get_key(inst)] = len(_data)
			_data.append(inst)
	
	f.close()
	
	return OK

func save(p_path: String, p_delim := ",") -> int:
	
	var f := File.new()
	var err := f.open(p_path, File.WRITE)
	if err != OK:
		return err
	
	f.store_csv_line(_titles.keys(), p_delim)
	
	for a_row in _data:
		if typeof(a_row) == TYPE_DICTIONARY:
			var arr := PoolStringArray()
			for a_key in a_row:
				arr.append(var2str(a_row[a_key]))
			f.store_csv_line(arr, p_delim)
		elif typeof(a_row) == TYPE_OBJECT:
			var arr := PoolStringArray()
			for a_prop in a_row.get_property_list():
				var a_name := a_prop.name as String
				arr.append(var2str(a_row[a_name]))
			f.store_csv_line(arr, p_delim)
	
	f.close()
	
	return OK

##### PRIVATE METHODS

#func _get_key(p_row) -> String:

func _pinfo_resource(p_name: String) -> Dictionary:
	return {
		"name": p_name,
		"type": TYPE_OBJECT,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "Resource"
	}

func _get_slices(p_name: String) -> Dictionary:
	var slices := p_name.split("/")
	if not len(slices) >= 2:
		return {}
	return {
		"group": slices[0],
		"name": slices[1]
	}

##### CONNECTIONS #####

##### SETTERS AND GETTERS #####

#
#class SpreadsheetRow:
#	extends Resource
#	var row: Object = null
#	var idx := -1
#
#	func _get_property_list() -> Array:
#		return [] if not row else row.get_property_list()
#
#	func _set(p_property: String, p_value) -> bool:
#		if not row:
#			return false
#		var props := row.get_property_list() as Array
#		for a_prop in props:
#			var name := (a_prop as Dictionary).name as String
#			if name == p_property:
#				row.set(p_property, p_value)
#				return true
#		return false
#
#	func _get(p_property: String):
#		if not row:
#			return null
#		var props = row.get_property_list()
#		for a_prop in props:
#			var name := (a_prop as Dictionary).name as String
#			if name == p_property:
#				return row.get(p_property)
#		return null
#
#export var row_script: Script = null
#export var uses_titles := true setget set_uses_titles
#export var uses_keys := true setget set_uses_keys
#
#var _data := []
#var _keys := {}
#var _titles := {}
#
#func _get(p_property: String):
#	var slices := p_property.split("/")
#	if not len(slices) == 2:
#		return null
#
#	var group := slices[0]
#	var name := slices[1]
#
#	if uses_keys:
#		if not _keys.has(group):
#			return null
#
#		var row = _data[_keys[group]]
#		if uses_titles:
#			return row.get(_titles[name])
#		else:
#			if not name.is_valid_integer():
#				return null
#			return row.get(int(name))
#	else:
#		if not group.is_valid_integer():
#			return null
#
#		var row = _data[int(group)]
#		if name.is_valid_integer():
#			return row[int(name)]
#		else:
#			return row.get(name)
#
#	return null
#
#func _set(p_property: String, p_value) -> bool:
#	var slices := p_property.split("/") as PoolStringArray
#	if not len(slices) == 2:
#		return false
#
#	var group := slices[0]
#	var name := slices[1]
#
#	if uses_keys:
#		if not _keys.has(group):
#			return false
#
#		var row = _data[_keys[group]]
#		if uses_titles:
#			return row.get(_titles[name])
#		else:
#			if not name.is_valid_integer():
#				return false
#			return row.get(int(name))
#	else:
#		if not group.is_valid_integer():
#			return false
#
#		var row = _data[int(group)]
#		if name.is_valid_integer():
#			return row[int(name)]
#		else:
#			return row.get(name)
#
#	return false
#
#
#
#
#"""
#
#
#func _pinfo_dictionary(p_name) -> Dictionary:
#	return {
#		"name": p_name,
#		"type": TYPE_DICTIONARY
#	}
#
#func _pinfo_array(p_name) -> Dictionary:
#	return {
#		"name": p_name,
#		"type": TYPE_ARRAY
#	}
#
#func _get_key(p_row) -> String:
#	match typeof(p_row):
#		TYPE_OBJECT:
#			if not p_row is Resource:
#				return ""
#			var props = p_row.get_property_list()
#			if not len(props):
#				return ""
#			return props[0].name as String
#		TYPE_DICTIONARY:
#			var keys = p_row.keys()
#			if not len(keys):
#				return ""
#			return str(keys[0])
#		TYPE_ARRAY:
#			if not len(p_row):
#				return ""
#			return str(p_row[0])
#	return ""
#
#func _get_property_list() -> Array:
#	var ret := []
#
#	var name := ""
#	var type := TYPE_NIL
#	var hint := PROPERTY_HINT_NONE
#	var hint_string := ""
#	var usage := PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
#
#	var group := ""
#
#	for a_idx in len(data):
#		var row := data[a_idx]
#
#		group = _get_key(row) if uses_keys else
#
#	if uses_keys:
#		for a_key in keys:
#			group = a_key as String
#
#			if row_script:
#				type = TYPE_OBJECT
#				hint = PROPERTY_HINT_RESOURCE_TYPE
#				hint_string = "Resource"
#			else:
#				type = TYPE_DICTIONARY
#
#
#
#	if uses_keys:
#		if uses_titles:
#			for a_key in keys:
#				var key := a_key as String
#				var type := TYPE_NIL
#				var hint := PROPERTY_HINT_NONE
#				var hint_string := ""
#
#				if row_script:
#					type = TYPE_OBJECT
#					hint = PROPERTY_HINT_RESOURCE_TYPE
#					hint_string = "Resource"
#				else:
#					type = TYPE_DICTIONARY
#
#				ret.append({
#					"name": key,
#					"type": type,
#					"hint": hint,
#					"hint_string": hint_string
#				})
#		else:
#			for a_key in keys:
#				var key := a_key as String
#				ret.append({
#					"name": key,
#					"type": TYPE_ARRAY
#				})
#	else:
#		if uses_titles:
#			for a_idx in len(data):
#				var row := data[a_idx] as Array
#				ret.append({
#					"name": a_idx,
#					"type": TYPE_DICTIONARY,
#				})
#		else:
#			pass
#
#	return ret
#
#func _set(p_property: String, p_value) -> bool:
#	if not row:
#		return false
#	var props := row.get_property_list() as Array
#	for a_prop in props:
#		var name := (a_prop as Dictionary).name as String
#		if name == p_property:
#			row.set(p_property, p_value)
#			return true
#	return false
#
#func _get(p_property: String):
#	if not row:
#		return null
#	var props = row.get_property_list()
#	for a_prop in props:
#		var name := (a_prop as Dictionary).name as String
#		if name == p_property:
#			return row.get(p_property)
#	return null
