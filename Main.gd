extends Node



# Load nodes to variables so they can be referenced to easier in the script if the resource path changes
onready var node_graph = $GUI/VBoxContainer/PanelContainer3/Background/Graph
onready var node_button_process = $GUI/VBoxContainer/PanelContainer/PanelContainer2/GridContainer/ButtonProcess
onready var node_text_input = $GUI/VBoxContainer/PanelContainer/PanelContainer/TextInput
onready var node_delimiter_box = $GUI/VBoxContainer/PanelContainer/PanelContainer2/GridContainer/DelimBox
onready var node_list_x_labels = $GUI/VBoxContainer/PanelContainer2/VBoxContainer/HBoxContainer3/ListXLabels
onready var node_list_y_labels = $GUI/VBoxContainer/PanelContainer2/VBoxContainer/HBoxContainer3/ListYLabels
onready var node_label_line_width_value = $GUI/VBoxContainer/PanelContainer2/VBoxContainer/HBoxContainer4/LabelLineWidthValue
onready var node_label_line_color_value = $GUI/VBoxContainer/PanelContainer2/VBoxContainer/HBoxContainer4/LabelLineColorValue
onready var node_label_cursor = $GUI/VBoxContainer/PanelContainer2/VBoxContainer/HBoxContainer5/PanelContainer/LabelCursor
onready var node_label_x_range = $GUI/VBoxContainer/PanelContainer2/VBoxContainer/HBoxContainer5/PanelContainer2/LabelXRangeValue
onready var node_label_y_range = $GUI/VBoxContainer/PanelContainer2/VBoxContainer/HBoxContainer5/PanelContainer3/LabelYRangeValue

var input_text: String
var delim: String
var labels = []
var x = []
var y = []
var data = []

# contains the data of plots that have been drawn
var plots = []
# contains the colors of plots that have been drawn
var colors = []

# default plot width and color
var plot_width: int
var plot_color = Color.black

# default graph/plot scale
var graph_scale = Vector2(0,0)
var limit_x = Vector2(0,0)
var limit_y = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	# select TAB delimiter by default
	node_delimiter_box.select(0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _input(event):
	if event is InputEventMouseMotion and graph_scale.length() > 0:
		var coordinates = event.position
		coordinates = convert_program_coordinates_to_data_coordinates(coordinates)
		#print(coordinates)
		var cursor_str = "(" + str(stepify(coordinates.x,0.0001)) + ", " + str(stepify(coordinates.y,0.0001)) + ")"
		#print(cursor_str)
		node_label_cursor.text = cursor_str


func _on_Button_pressed():
	# process strings from text in the text box
	process_text()
	
	
func process_text():
	
	# get delimiter selection	
	var delim_selection = node_delimiter_box.get_selected_items()
	if delim_selection[0] == 0:
		delim = "\t"
	elif delim_selection[0] == 1:
		delim = ","
	elif delim_selection[0] == 2:
		delim = "."
	else:
		delim = ""
		

	# split the text into several strings by line breaks (\n)
	input_text = node_text_input.text
	var strings = input_text.rsplit("\n", true, 0)
	
	
	var data_start_row = 0
	var metadata_passed = false
	var row = 0
	# for each line, split the string into substrings and save to data
	for line in strings:
		
		var line_elements = line.rsplit(delim, true, 0)
		#print(line_elements[0])
		if line_elements[0] == "time":
			metadata_passed = true
			labels = line_elements
			data_start_row = row+1
			
		if row >= data_start_row and data_start_row != 0:
			if line_elements[0].empty():
				break
			else:
				data.push_back(line_elements)
			
		row += 1
		


	# after text is processed, we can process data and display the results
	process_data(data,labels)
	

# Scale plots to fit in their reserved space
func update_graph_scale(selected_x,selected_y):
	var x_minimum = null
	var x_maximum = null
	var y_minimum = null
	var y_maximum = null
	
	for row in data:
		var x_current = row[selected_x].to_float()
		var y_current = row[selected_y].to_float()
		print(y_current)
		
		if x_minimum == null or x_maximum == null or y_minimum == null or y_maximum == null:
			x_minimum = x_current
			x_maximum = x_current
			y_minimum = y_current
			y_maximum = y_current
		
		if x_current > x_maximum:
			x_maximum = x_current
		elif x_current < x_minimum:
			x_minimum = x_current
			
		
		if y_current > y_maximum or y_maximum == null:
			y_maximum = y_current
		elif y_current < y_minimum or y_minimum == null:
			y_minimum = y_current
	
	

	
	#if x_minimum <  limit_x[0]:
	#	limit_x[0] = x_minimum
	#if x_maximum > limit_x[1]:
	#	limit_x[1] = x_maximum
	#if y_minimum <  limit_y[0]:
	#	limit_y[0] = y_minimum
	#if y_maximum > limit_y[1]:
	#	limit_y[1] = y_maximum
	limit_x = Vector2(x_minimum, x_maximum)
	limit_y = Vector2(y_minimum, y_maximum)
	
	print(limit_x)
	graph_scale.x = node_graph.get_parent().rect_size.x/(limit_x[1]-limit_x[0])
	graph_scale.y = node_graph.get_parent().rect_size.y/(limit_y[1]-limit_y[0])
	
	update_plots()
	
	#graph_offset.x = x_minimum
	#graph_offset.y = y_minimum
	
func update_plots():
	# first remove all drawn plots
	clear_graph()
	
	# then redraw them with new scaling
	draw_plots()

# clears all drawn plots
func clear_graph():
	# remove all drawn plots
	for child in node_graph.get_children():
		child.queue_free()
		
# clears all plots from memory
func clear_plots():
	plots = []
	colors = []

# divide data under labels etc
func process_data(data,labels):
	
	$GUI/VBoxContainer/PanelContainer2/VBoxContainer/HBoxContainer/LabelRowNumber.text = str(data.size())
	$GUI/VBoxContainer/PanelContainer2/VBoxContainer/HBoxContainer/LabelColumnNumber.text = str(labels.size())
	
	var labels_string = ""
	for label in labels:
		labels_string += label + ", "
	labels_string = labels_string.trim_suffix(", ")
	
	$GUI/VBoxContainer/PanelContainer2/VBoxContainer/HBoxContainer2/LabelDataLabelNames.text = labels_string
	
	for label in labels:
		node_list_x_labels.add_item(label)
		node_list_y_labels.add_item(label)
		
	node_list_x_labels.select(0)
	node_list_y_labels.select(1)
	
	$GUI/VBoxContainer/PanelContainer2/VBoxContainer/HBoxContainer4/ButtonPlot.disabled = false
	$GUI/VBoxContainer/PanelContainer2/VBoxContainer/HBoxContainer4/ButtonReset.disabled = false

# create a new 2D line from the data
func save_plot_data(selected_x,selected_y):
	
	var new_plot = [] # will contain this plot without scaling (true values)
	
	for row in data:
		var data_point = Vector2(row[selected_x].to_float(), row[selected_y].to_float())
		#data_point = data_point - Vector2(limit_x[0],limit_y[0])
		#print("limit x: " + var2str(limit_x))
		new_plot.push_back(data_point)

	# save true plots
	plots.push_back(new_plot)
	colors.push_back(node_label_line_color_value.color)
	

func draw_plots():
	
	
	
	# draw x and y axes
	var x_axis = PoolVector2Array()
	var y_axis = PoolVector2Array()
	var x_axis_line = Line2D.new()
	var y_axis_line = Line2D.new()
	x_axis.push_back(convert_data_coordinates_to_graph_coordinates(Vector2(limit_x[0],0)))
	x_axis.push_back(convert_data_coordinates_to_graph_coordinates(Vector2(limit_x[1],0)))
	y_axis.push_back(convert_data_coordinates_to_graph_coordinates(Vector2(0,limit_y[0])))
	y_axis.push_back(convert_data_coordinates_to_graph_coordinates(Vector2(0,limit_y[1])))
	x_axis_line.default_color = Color.black
	x_axis_line.width = 4
	x_axis_line.points = x_axis
	y_axis_line.default_color = Color.black
	y_axis_line.width = 4
	y_axis_line.points = y_axis
	node_graph.add_child(x_axis_line)
	node_graph.add_child(y_axis_line)
	
	var i = 0
	for plot in plots:
		var points = PoolVector2Array() # will contain this plot with scaling
		for data_point in plot:
			#var data_point_scaled = data_point - Vector2(limit_x[0],limit_y[0])
			print("limit x: " + var2str(limit_x))
			#var data_point_scaled = Vector2(data_point.x*graph_scale.x - node_graph.get_parent().rect_position.x, data_point.y*graph_scale.y + node_graph.get_parent().rect_size.y/2 - node_graph.get_parent().rect_position.y)
			var data_point_scaled = convert_data_coordinates_to_graph_coordinates(data_point)
			points.push_back(data_point_scaled)
		
		plot_color = colors[i]
		
		var line = Line2D.new()
		line.default_color = plot_color
		line.width = plot_width
		line.points = points
		node_graph.add_child(line)
		
		
		
		i = i+1
		

# Convert data coordinates (read from text box) to program coordinates (coordinates of the application window)
func convert_data_coordinates_to_program_coordinates(vector):
	var coordinates = vector
	# in parentheses, the coordinate data is offset by subtracting the lower limit of the value
	# the coordinate is then defined by setting minimum at rect.position.x
	coordinates.x = (coordinates.x-limit_x[0])*graph_scale.x + node_graph.get_parent().rect_position.x
	# y is set to minimum at rect.position.y + rect.size.y
	coordinates.y = (-coordinates.y+limit_y[0])*graph_scale.y - node_graph.get_parent().rect_position.y + 600
	return coordinates
	
# Convert program coordinates (coordinates of the application window) to data coordinates (read from text box)
func convert_program_coordinates_to_data_coordinates(vector):
	var coordinates = vector
	coordinates.x = (coordinates.x - node_graph.get_parent().rect_position.x) / graph_scale.x  + limit_x[0]
	coordinates.y = -( coordinates.y - 600 + node_graph.get_parent().rect_position.y )/graph_scale.y + limit_y[0]
	return coordinates

# Convert program coordinates (coordinates of the application window) to graph coordinates (coordinates in the LCS of the graph)
func convert_program_coordinates_to_graph_coordinates(vector):
	var coordinates = vector
	var global_position = node_graph.get_global_position()
	coordinates.x = coordinates.x - global_position.x
	coordinates.y = coordinates.y - global_position.y
	return coordinates

# Convert data coordinates (read from text box) to graph coordinates (coordinates in the LCS of the graph)	
func convert_data_coordinates_to_graph_coordinates(vector):
	return convert_program_coordinates_to_graph_coordinates(convert_data_coordinates_to_program_coordinates(vector))

# Define what happens when the user presses "Plot" on the GUI
func _on_ButtonPlot_pressed():
	var selected_x = node_list_x_labels.get_selected_items()[0]
	var selected_y = node_list_y_labels.get_selected_items()[0]
	
	plot_width = node_label_line_width_value.text.to_float()
	plot_color = node_label_line_color_value.color
	

	save_plot_data(selected_x,selected_y)
	update_graph_scale(selected_x,selected_y)
	
	update_range_labels()
	
# Set the labels of data range shown to the user on the GUI
func update_range_labels():
	node_label_x_range.text = "[" + str(limit_x[0]) + ", " + str(limit_x[1]) + "]"
	node_label_y_range.text = "[" + str(limit_y[0]) + ", " + str(limit_y[1]) + "]"

# 
func _on_ButtonReset_pressed():
	clear_graph()
	clear_plots()
	
	graph_scale = Vector2(0,0)
	limit_x = Vector2(0,0)
	limit_y = Vector2(0,0)
	draw_plots()
	
	update_range_labels()
