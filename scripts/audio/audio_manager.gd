extends Node

# Autoload AudioManager for Abyssal Altar
# Manages Audio Buses (Master, Music, SFX, Ambience), voice pooling, volume controls, and sound effects.

var sfx_streams: Dictionary = {}
var music_streams: Dictionary = {}
var ambience_stream: AudioStreamWAV

var sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE: int = 14
var next_sfx_player: int = 0

var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer

var current_music_track: String = ""
var is_muted: bool = false
var master_vol: float = 0.8
var music_vol: float = 0.7
var sfx_vol: float = 0.8
var ambience_vol: float = 0.6

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_players()
	_init_sound_effects()
	apply_volumes()

func _setup_audio_players() -> void:
	# Dedicated music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = &"Music"
	add_child(music_player)
	
	# Dedicated ambience player
	ambience_player = AudioStreamPlayer.new()
	ambience_player.bus = &"Ambience"
	add_child(ambience_player)
	
	# Pre-allocated pool of SFX players
	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		sfx_players.append(p)

func _init_sound_effects() -> void:
	# Synthesize all SFX via SoundGenerator
	sfx_streams["ui_click"] = SoundGenerator.gen_ui_click()
	sfx_streams["ui_error"] = SoundGenerator.gen_ui_error()
	sfx_streams["item_pickup"] = SoundGenerator.gen_item_pickup()
	sfx_streams["item_place"] = SoundGenerator.gen_item_place()
	sfx_streams["item_rotate"] = SoundGenerator.gen_item_rotate()
	sfx_streams["item_merge"] = SoundGenerator.gen_item_merge()
	sfx_streams["shop_buy"] = SoundGenerator.gen_shop_buy()
	sfx_streams["player_attack"] = SoundGenerator.gen_player_attack()
	sfx_streams["enemy_hit"] = SoundGenerator.gen_enemy_hit()
	sfx_streams["crit_hit"] = SoundGenerator.gen_crit_hit()
	sfx_streams["enemy_death"] = SoundGenerator.gen_enemy_death()
	sfx_streams["dodge"] = SoundGenerator.gen_dodge()
	sfx_streams["skill"] = SoundGenerator.gen_skill()
	sfx_streams["potion"] = SoundGenerator.gen_potion()
	sfx_streams["boss_intro"] = SoundGenerator.gen_boss_intro()
	sfx_streams["boss_warning"] = SoundGenerator.gen_boss_warning()
	sfx_streams["boss_hit"] = SoundGenerator.gen_boss_hit()
	sfx_streams["boss_defeat"] = SoundGenerator.gen_boss_defeat()
	sfx_streams["level_win"] = SoundGenerator.gen_level_win()
	sfx_streams["upgrade"] = SoundGenerator.gen_upgrade()
	sfx_streams["proj_launch"] = SoundGenerator.gen_proj_launch()
	sfx_streams["pet_attack"] = SoundGenerator.gen_pet_attack()
	sfx_streams["footstep"] = SoundGenerator.gen_footstep()
	sfx_streams["lightning_zap"] = SoundGenerator.gen_lightning_zap()
	sfx_streams["summon_chime"] = SoundGenerator.gen_summon_chime()
	sfx_streams["shoot_slash"] = SoundGenerator.gen_shoot_slash()
	sfx_streams["shoot_lightning"] = SoundGenerator.gen_shoot_lightning()
	sfx_streams["shoot_soul"] = SoundGenerator.gen_shoot_soul()
	
	# Music and Ambience
	ambience_stream = SoundGenerator.gen_dark_ambience()
	ambience_player.stream = ambience_stream
	
	music_streams["combat"] = SoundGenerator.gen_combat_music()
	music_streams["boss"] = SoundGenerator.gen_boss_music()
	music_streams["horror_menu"] = SoundGenerator.gen_horror_menu_music()

func play_sfx(sound_name: String, pitch_range: float = 0.05) -> void:
	if is_muted or not sfx_streams.has(sound_name):
		return
	
	var stream: AudioStreamWAV = sfx_streams[sound_name]
	var p: AudioStreamPlayer = sfx_players[next_sfx_player]
	next_sfx_player = (next_sfx_player + 1) % SFX_POOL_SIZE
	
	p.stream = stream
	if pitch_range > 0.0:
		p.pitch_scale = randf_range(1.0 - pitch_range, 1.0 + pitch_range)
	else:
		p.pitch_scale = 1.0
	p.play()

func play_music(track: String) -> void:
	if current_music_track == track and music_player.playing:
		return
	current_music_track = track
	
	if track == "none" or not music_streams.has(track):
		music_player.stop()
		return
	
	music_player.stream = music_streams[track]
	music_player.play()

func play_ambience(enabled: bool = true) -> void:
	if not is_instance_valid(ambience_player):
		return
	if enabled and not ambience_player.playing and not is_muted:
		ambience_player.play()
	elif not enabled and is_instance_valid(ambience_player):
		ambience_player.stop()

func set_muted(muted: bool) -> void:
	is_muted = muted
	AudioServer.set_bus_mute(0, is_muted)
	if is_muted:
		if is_instance_valid(ambience_player): ambience_player.stop()
		if is_instance_valid(music_player): music_player.stop()
	else:
		if current_music_track != "" and current_music_track != "none":
			play_music(current_music_track)
		play_ambience(true)

func set_master_volume(linear: float) -> void:
	master_vol = clampf(linear, 0.0, 1.0)
	_set_bus_volume(0, master_vol)

func set_music_volume(linear: float) -> void:
	music_vol = clampf(linear, 0.0, 1.0)
	var bus_idx := AudioServer.get_bus_index(&"Music")
	if bus_idx >= 0:
		_set_bus_volume(bus_idx, music_vol)

func set_sfx_volume(linear: float) -> void:
	sfx_vol = clampf(linear, 0.0, 1.0)
	var bus_idx := AudioServer.get_bus_index(&"SFX")
	if bus_idx >= 0:
		_set_bus_volume(bus_idx, sfx_vol)

func set_ambience_volume(linear: float) -> void:
	ambience_vol = clampf(linear, 0.0, 1.0)
	var bus_idx := AudioServer.get_bus_index(&"Ambience")
	if bus_idx >= 0:
		_set_bus_volume(bus_idx, ambience_vol)

func _set_bus_volume(bus_idx: int, linear: float) -> void:
	if linear <= 0.001:
		AudioServer.set_bus_volume_db(bus_idx, -80.0)
	else:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear))

func apply_volumes() -> void:
	set_muted(is_muted)
	set_master_volume(master_vol)
	set_music_volume(music_vol)
	set_sfx_volume(sfx_vol)
	set_ambience_volume(ambience_vol)
