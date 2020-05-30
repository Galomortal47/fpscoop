extends clsnyctcp

var smoth = preload("res://scripts/smoothing.gd").new()

var data2 ={
	"x" : 0,
	"y" : 0,
	"z" : 0,
}
var players={
	"users" : [],
	"message" : []
}

var number_of_players = 4
export var id = 0
var player_path = preload("res://assets/Player.tscn")

var player_name

var min_id = 1000
var max_id = 9999
var ping = 0

var send_message = ""
var recive_message = []

var max_players = 100

func _ready():
#	players.resize(number_of_players)
	randomize()
	load_server_data()
#	recive_data = players
	connect_server()
#	players_generate()

func _physics_process(delta):
	disconect()
	get_player_data()
	players_generate()
	syncronize()
	send_and_recive_data()
#	if recive_data.has(id):
#		if not get_node("/root/singleton").port == str(recive_data[id].port):
#			get_node("/root/singleton").port = str(recive_data[id].port)
#			packet.disconnect_from_host()
#		print(recive_data[id].port)

func load_server_data():
	id = get_node("/root/singleton").username
	get_child(0).set_name(id)
	if get_node("/root/singleton").player_data.has(id):
		var player_data = get_node("/root/singleton").player_data[id]
		var pos2 = Vector3(player_data.x,player_data.y,player_data.z)
		get_child(0).set_translation(pos2)
		print("loaded_position_from_server")
	elif get_node("/root/singleton").player_data.has("id"):
		var player_data = get_node("/root/singleton").player_data
		var pos2 = Vector3(player_data.x,player_data.y,player_data.z)
		get_child(0).set_translation(pos2)
		print("loaded_position_from_server")
	else:
		print("new_position_being_generated")

func players_generate():
	var children = []
	children.resize(get_child_count())
	for a in range(0,get_child_count()):
		children[a] = get_child(a).get_name()
	if not recive_data == null:
		var interations
		if recive_data.keys().size() < max_players:
			interations = recive_data.keys().size()
		else:
			interations = max_players
		for j in range(0,interations):
			if not children.has(recive_data.keys()[j]):
				var new_player = player_path.instance()
				new_player.set_name(str(recive_data.keys()[j]))
				new_player.main = false
				warning(str("Player: ", recive_data.keys()[j] ," Has Connected"))
				randomize()
				var player_name2 = recive_data.keys()[j]
				var pos2 = Vector3(recive_data[player_name2].x,recive_data[player_name2].y,recive_data[player_name2].z)
#				print(pos2)
				new_player.set_translation(pos2)
				add_child(new_player)

# Called every frame. 'delta' is the elapsed time since the previous frame.

func disconect():
	var children = []
	children.resize(get_child_count())
	for a in range(0,get_child_count()):
		children[a] = get_child(a).get_name()
	for j in range(0,get_child_count()):
		if not recive_data == null:
			if not recive_data.keys().has(children[j]):
				if not children[j] == id:
					warning(str("Warning: ", str(children[j]) ," Has Disconnected"))
					get_node(children[j]).queue_free()

func warning(var text):
	get_parent().get_node("Chat").warning(text)

func get_player_data():
	players["operator"] = "Connected"
	players["Player"] = data2.duplicate()
	players["Player"].id = id
	players["Player"].x = three_digits(get_node(id).get_translation().x)
	players["Player"].y = three_digits(get_node(id).get_translation().y)
	players["Player"].z = three_digits(get_node(id).get_translation().z)
	if not get_node(id).dmg_com == {}:
		players["Player"].dmg_com = get_node(id).dmg_com
	if not get_node(id).spw_com == {}:
		players["Player"].spw_com = get_node(id).spw_com
	players["Player"].enm_dat = get_parent().get_node("SyncNpcs").enm_dat
	players["Player"].message = send_message
	players["Player"].rot_y = three_digits(get_node(id).get_node("MeshInstance").get_rotation().y)
	players["Player"].time = OS.get_system_time_msecs()
	players["Player"].host = false
	players["Player"].srv_n = get_node(id).room
#	print(players)
	json = players

func three_digits(var number):
	var multi = 1000.0
	var integer = int(number * multi)
	var x = float(integer / multi)
	return x


var id_aux = [0]

func syncronize():
	if not recive_data == null:
		if recive_data.keys().size() == 0:
			command_damage(players["Player"],0)
		var interations
		if recive_data.keys().size() < max_players:
			interations = recive_data.keys().size()
		else:
			interations = max_players
		for c in range(0,interations):
			var player_name2 = recive_data.keys()[c]
			recive_message.resize(recive_data.keys().size())
			recive_message[c] = recive_data[player_name2].message
			command_damage(recive_data[player_name2],c)
			if not id == str(player_name2):
				sync_player_pos_rot(player_name2)
			id_aux.resize(recive_data.keys().size())
			get_node(player_name2).time = recive_data[player_name2].time

func command_damage(var data,c):
	if data.has("dmg_com"):
		if data.dmg_com.has("id"):
			var data_id = data.dmg_com.id
			if not data_id == id_aux[c]:
				if has_node(data.dmg_com.tar):
					get_node(data.dmg_com.tar).health = data.dmg_com.health
					id_aux[c] = data_id

func sync_player_pos_rot(var player_name2):
#	print(recive_data.keys())
	var pos2 = Vector3(recive_data[player_name2].x,recive_data[player_name2].y,recive_data[player_name2].z)
	get_node(player_name2).set_translation(smoth.smoothing(pos2,get_node(player_name2).translation))
	get_node(player_name2).set_rotation(Vector3(0,smoth.smoothing(recive_data[player_name2].rot_y,get_node(player_name2).get_rotation().y),0))
