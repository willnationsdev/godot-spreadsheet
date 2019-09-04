tool
extends EditorImportPlugin

enum Delims {
	COMMA,
	SEMICOLON,
	TAB
}

func get_importer_name():
	return get_script().resource_path.get_basename()

func get_visible_name():
	return "Spreadsheet Importer"

func get_recognized_extensions():
	return ["csv", "tsv"]

func get_save_extension():
	return "tres"

func get_resource_type():
	return "Resource"

func get_preset_count():
	return 0

func get_preset_name(i):
	return ""

func get_import_options(i):
	return [
		{
			"name": "delimeter",
			"property_hint": PROPERTY_HINT_ENUM,
			"hint_string": "Comma,Semicolon,Tab",
			"default_value": Delims.COMMA
		}
	]

func import(source_file, save_path, options, platform_variants, gen_files):
	var file = File.new()
	if file.open(source_file, File.READ) != OK:
		return FAILED

	var mesh = Mesh.new()
	# Fill the Mesh with data read in 'file', left as exercise to the reader

	var filename = save_path + "." + get_save_extension()
	ResourceSaver.save(filename, mesh)
	return OK
