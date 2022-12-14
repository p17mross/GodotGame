tool
extends EditorPlugin

# A class member to hold the dock during the plugin life cycle.
var inspector_plugin: EditorInspectorPlugin

# Called when plugin is loaded
func _enter_tree():
	# Get inspector plugin
	inspector_plugin = preload("res://addons/PuzzleEditorPlugin/PuzzleEditorInspectorPlugin.gd").new()
	print("Adding inspector plugin ", inspector_plugin)
	# Load inspector plugin
	add_inspector_plugin(inspector_plugin)

# Called when plugin is unloaded
func _exit_tree():
	print("Removing inspector plugin ", inspector_plugin)
	# Unload inspector plugin
	remove_inspector_plugin(inspector_plugin)
