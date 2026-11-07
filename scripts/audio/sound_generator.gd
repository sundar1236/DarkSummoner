class_name SoundGenerator
extends RefCounted

# Generates procedural 16-bit PCM AudioStreamWAV for mobile game audio.
# All sound effects, ambience loops, and music tracks are synthesised directly,
# ensuring high performance, zero external asset dependencies, and guaranteed playback.

const SAMPLE_RATE: int = 22050

static func create_pcm_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	
	var byte_array := PackedByteArray()
	byte_array.resize(samples.size() * 2)
	
	for i in range(samples.size()):
		var clamped: float = clampf(samples[i], -1.0, 1.0)
		var val_16: int = int(clamped * 32767.0)
		if val_16 < -32768:
			val_16 = -32768
		elif val_16 > 32767:
			val_16 = 32767
		byte_array.encode_s16(i * 2, val_16)
		
	stream.data = byte_array
	return stream

# 1. UI Click
static func gen_ui_click() -> AudioStreamWAV:
	var duration: float = 0.05
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0 - (float(i) / float(count))
		var freq: float = 800.0 - (t * 4000.0)
		var s: float = sin(t * freq * TAU) * env * 0.4
		samples[i] = s
	return create_pcm_stream(samples)

# 2. UI Error / Invalid Placement
static func gen_ui_error() -> AudioStreamWAV:
	var duration: float = 0.15
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0 - (float(i) / float(count))
		var freq: float = 150.0
		var s: float = (1.0 if sin(t * freq * TAU) > 0.0 else -1.0) * env * 0.35
		samples[i] = s
	return create_pcm_stream(samples)

# 3. Item Pickup
static func gen_item_pickup() -> AudioStreamWAV:
	var duration: float = 0.08
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0 - (float(i) / float(count))
		var freq: float = 400.0 + (t * 800.0)
		var s: float = sin(t * freq * TAU) * env * 0.4
		samples[i] = s
	return create_pcm_stream(samples)

# 4. Item Place
static func gen_item_place() -> AudioStreamWAV:
	var duration: float = 0.1
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0 - (float(i) / float(count))
		var freq: float = 600.0 - (t * 2000.0)
		var s: float = sin(t * maxf(freq, 100.0) * TAU) * env * 0.5
		samples[i] = s
	return create_pcm_stream(samples)

# 5. Item Rotate
static func gen_item_rotate() -> AudioStreamWAV:
	var duration: float = 0.07
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0 - (float(i) / float(count))
		var freq: float = 520.0 + sin(t * 120.0) * 150.0
		var s: float = sin(t * freq * TAU) * env * 0.4
		samples[i] = s
	return create_pcm_stream(samples)

# 6. Item Merge
static func gen_item_merge() -> AudioStreamWAV:
	var duration: float = 0.35
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0 - (float(i) / float(count))
		var freq1: float = 440.0 + (t * 600.0)
		var freq2: float = 660.0 + (t * 900.0)
		var s: float = (sin(t * freq1 * TAU) * 0.5 + sin(t * freq2 * TAU) * 0.5) * env * 0.6
		samples[i] = s
	return create_pcm_stream(samples)

# 7. Shop Buy
static func gen_shop_buy() -> AudioStreamWAV:
	var duration: float = 0.25
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0 - (float(i) / float(count))
		var freq: float = 784.0 if t < 0.12 else 1046.0
		var s: float = sin(t * freq * TAU) * env * 0.45
		samples[i] = s
	return create_pcm_stream(samples)

# 8. Player Attack (slash/whoosh)
static func gen_player_attack() -> AudioStreamWAV:
	var duration: float = 0.12
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = sin((float(i) / float(count)) * PI)
		var noise: float = (randf() * 2.0 - 1.0) * 0.35
		var tone: float = sin(t * (350.0 - t * 1500.0) * TAU) * 0.45
		samples[i] = (noise + tone) * env * 0.6
	return create_pcm_stream(samples)

# 9. Enemy Hit
static func gen_enemy_hit() -> AudioStreamWAV:
	var duration: float = 0.1
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0 - (float(i) / float(count))
		var noise: float = (randf() * 2.0 - 1.0) * 0.5
		var low: float = sin(t * 120.0 * TAU) * 0.5
		samples[i] = (noise + low) * env * 0.5
	return create_pcm_stream(samples)

# 10. Critical Hit
static func gen_crit_hit() -> AudioStreamWAV:
	var duration: float = 0.2
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0 - (float(i) / float(count))
		var freq: float = 1200.0 - (t * 3000.0)
		var s: float = sin(t * maxf(freq, 200.0) * TAU) * 0.6 + (randf() * 2.0 - 1.0) * 0.3
		samples[i] = s * env * 0.7
	return create_pcm_stream(samples)

# 11. Enemy Death
static func gen_enemy_death() -> AudioStreamWAV:
	var duration: float = 0.25
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0 - (float(i) / float(count))
		var freq: float = 220.0 - (t * 500.0)
		var s: float = sin(t * maxf(freq, 40.0) * TAU) * 0.6 + (randf() * 2.0 - 1.0) * 0.2
		samples[i] = s * env * 0.6
	return create_pcm_stream(samples)

# 12. Dodge
static func gen_dodge() -> AudioStreamWAV:
	var duration: float = 0.16
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = sin((float(i) / float(count)) * PI)
		var noise: float = (randf() * 2.0 - 1.0) * 0.5
		var s: float = sin(t * 300.0 * TAU) * 0.4
		samples[i] = (noise + s) * env * 0.5
	return create_pcm_stream(samples)

# 13. Skill Activation
static func gen_skill() -> AudioStreamWAV:
	var duration: float = 0.3
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0 - (float(i) / float(count))
		var freq: float = 300.0 + (t * 900.0)
		var s: float = sin(t * freq * TAU) * 0.5 + sin(t * (freq * 1.5) * TAU) * 0.3
		samples[i] = s * env * 0.65
	return create_pcm_stream(samples)

# 14. Potion Heal
static func gen_potion() -> AudioStreamWAV:
	var duration: float = 0.35
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0 - (float(i) / float(count))
		var freq: float = 523.25 + sin(t * 40.0) * 150.0
		var s: float = sin(t * freq * TAU) * env * 0.5
		samples[i] = s
	return create_pcm_stream(samples)

# 15. Boss Intro / Roar
static func gen_boss_intro() -> AudioStreamWAV:
	var duration: float = 0.8
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = sin((float(i) / float(count)) * PI)
		var freq: float = 80.0 + sin(t * 15.0) * 30.0
		var sub: float = sin(t * freq * TAU) * 0.7
		var grit: float = (randf() * 2.0 - 1.0) * 0.4
		samples[i] = (sub + grit) * env * 0.8
	return create_pcm_stream(samples)

# 16. Boss Warning (Telegraph cue)
static func gen_boss_warning() -> AudioStreamWAV:
	var duration: float = 0.22
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0 - (float(i) / float(count))
		var freq: float = 880.0 + (sin(t * 60.0) * 200.0)
		var s: float = (1.0 if sin(t * freq * TAU) > 0.0 else -1.0) * 0.3
		samples[i] = s * env * 0.5
	return create_pcm_stream(samples)

# 17. Boss Hit
static func gen_boss_hit() -> AudioStreamWAV:
	var duration: float = 0.18
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0 - (float(i) / float(count))
		var low: float = sin(t * 70.0 * TAU) * 0.6
		var noise: float = (randf() * 2.0 - 1.0) * 0.4
		samples[i] = (low + noise) * env * 0.7
	return create_pcm_stream(samples)

# 18. Boss Defeat
static func gen_boss_defeat() -> AudioStreamWAV:
	var duration: float = 0.9
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0 - (float(i) / float(count))
		var freq: float = maxf(160.0 - t * 140.0, 30.0)
		var rumble: float = sin(t * freq * TAU) * 0.6 + (randf() * 2.0 - 1.0) * 0.4
		samples[i] = rumble * env * 0.8
	return create_pcm_stream(samples)

# 19. Level Win
static func gen_level_win() -> AudioStreamWAV:
	var duration: float = 0.45
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0 - (float(i) / float(count))
		var freq: float = 523.25
		if t > 0.15: freq = 659.25
		if t > 0.30: freq = 783.99
		var s: float = sin(t * freq * TAU) * env * 0.55
		samples[i] = s
	return create_pcm_stream(samples)

# 20. Upgrade / Progression Buy
static func gen_upgrade() -> AudioStreamWAV:
	var duration: float = 0.35
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0 - (float(i) / float(count))
		var freq: float = 330.0 + (t * 880.0)
		var s: float = sin(t * freq * TAU) * 0.5 + sin(t * (freq * 2.0) * TAU) * 0.3
		samples[i] = s * env * 0.6
	return create_pcm_stream(samples)

# 21. Projectile Launch
static func gen_proj_launch() -> AudioStreamWAV:
	var duration: float = 0.1
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0 - (float(i) / float(count))
		var freq: float = 600.0 - (t * 2000.0)
		var s: float = sin(t * maxf(freq, 100.0) * TAU) * env * 0.45
		samples[i] = s
	return create_pcm_stream(samples)

# 22. Pet Attack
static func gen_pet_attack() -> AudioStreamWAV:
	var duration: float = 0.1
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0 - (float(i) / float(count))
		var freq: float = 700.0 + sin(t * 100.0) * 300.0
		var s: float = sin(t * freq * TAU) * env * 0.4
		samples[i] = s
	return create_pcm_stream(samples)

# 23. Footstep (soft rhythmic dungeon step)
static func gen_footstep() -> AudioStreamWAV:
	var duration: float = 0.06
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0 - (float(i) / float(count))
		var noise: float = (randf() * 2.0 - 1.0) * 0.2
		var thud: float = sin(t * 80.0 * TAU) * 0.35
		samples[i] = (noise + thud) * env * 0.3
	return create_pcm_stream(samples)

# 24. Lightning Zap / Chain Arcs
static func gen_lightning_zap() -> AudioStreamWAV:
	var duration: float = 0.18
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0 - (float(i) / float(count))
		var noise: float = (randf() * 2.0 - 1.0) * 0.6
		var zap: float = sin(t * (1800.0 - t * 4000.0) * TAU) * 0.4
		samples[i] = (noise * 0.7 + zap * 0.3) * env * 0.55
	return create_pcm_stream(samples)

# 25. Soul Summon Chime
static func gen_summon_chime() -> AudioStreamWAV:
	var duration: float = 0.4
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0 - (float(i) / float(count))
		var chime: float = sin(t * 880.0 * TAU) * 0.4 + sin(t * 1320.0 * TAU) * 0.3
		samples[i] = chime * env * 0.5
	return create_pcm_stream(samples)

# 23. Dark Fantasy Ambience Loop
static func gen_dark_ambience() -> AudioStreamWAV:
	var duration: float = 4.0
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var drone1: float = sin(t * 55.0 * TAU) * 0.35 # A1 note drone
		var drone2: float = sin(t * 82.41 * TAU) * 0.25 # E2 note
		var pulse: float = (1.0 + sin(t * 0.5 * TAU)) * 0.5
		var whisper: float = (randf() * 2.0 - 1.0) * 0.04
		samples[i] = (drone1 + drone2 * pulse + whisper) * 0.5
	var stream: AudioStreamWAV = create_pcm_stream(samples)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	return stream

# 24. Combat Music Loop
static func gen_combat_music() -> AudioStreamWAV:
	var duration: float = 8.0 # 8-second repeating rhythmic loop
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var bpm: float = 130.0
	var beat_sec: float = 60.0 / bpm
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var beat_pos: float = fmod(t, beat_sec)
		var beat_idx: int = int(t / beat_sec)
		
		# Kick / bass hit on beats
		var kick_env: float = exp(-beat_pos * 18.0)
		var kick: float = sin(beat_pos * maxf(120.0 - beat_pos * 400.0, 45.0) * TAU) * kick_env * 0.6
		
		# Hi-hat / pulse on offbeats
		var offbeat_pos: float = fmod(t + beat_sec * 0.5, beat_sec)
		var hat_env: float = exp(-offbeat_pos * 35.0)
		var hat: float = (randf() * 2.0 - 1.0) * hat_env * 0.15
		
		# Synth melody arpeggio in D minor (D3, F3, A3, C4)
		var notes := [146.83, 174.61, 220.00, 261.63, 220.00, 174.61, 146.83, 130.81]
		var note_idx: int = int(t / (beat_sec * 0.5)) % notes.size()
		var note_pos: float = fmod(t, beat_sec * 0.5)
		var synth_env: float = exp(-note_pos * 8.0)
		var synth: float = sin(note_pos * notes[note_idx] * TAU) * synth_env * 0.35
		
		samples[i] = kick + hat + synth
	var stream: AudioStreamWAV = create_pcm_stream(samples)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	return stream

# 25. Boss Music Loop (Intense, aggressive tempo)
static func gen_boss_music() -> AudioStreamWAV:
	var duration: float = 6.0
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var bpm: float = 145.0
	var beat_sec: float = 60.0 / bpm
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var beat_pos: float = fmod(t, beat_sec)
		var kick_env: float = exp(-beat_pos * 20.0)
		var kick: float = sin(beat_pos * maxf(140.0 - beat_pos * 500.0, 50.0) * TAU) * kick_env * 0.7
		
		# Heavy dark pulse
		var bar_pos: float = fmod(t, beat_sec * 4.0)
		var sub: float = sin(bar_pos * 65.41 * TAU) * 0.3 # C2 heavy drone
		
		# Intense bell / sting
		var eighth_pos: float = fmod(t, beat_sec * 0.25)
		var arp_notes := [130.81, 155.56, 196.00, 246.94] # C minor chord
		var arp_idx: int = int(t / (beat_sec * 0.25)) % arp_notes.size()
		var arp_env: float = exp(-eighth_pos * 12.0)
		var arp: float = sin(eighth_pos * arp_notes[arp_idx] * TAU) * arp_env * 0.4
		
		samples[i] = kick + sub + arp
	var stream: AudioStreamWAV = create_pcm_stream(samples)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	return stream

# 26. Gothic Horror Menu & Intro Music (Tense, dark, ominous horror)
static func gen_horror_menu_music() -> AudioStreamWAV:
	var duration: float = 12.0 # 12-second seamless horror loop
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		
		# 1. Distant Tolling Funeral Bell (C2 - 65.41 Hz with bell inharmonic overtones)
		var bell_cycle: float = fmod(t, 4.0)
		var bell_env: float = exp(-bell_cycle * 2.2)
		var bell_tone: float = sin(bell_cycle * 65.41 * TAU) * 0.45
		var bell_ov1: float = sin(bell_cycle * 176.6 * TAU) * 0.25 # Minor 3rd partial
		var bell_ov2: float = sin(bell_cycle * 353.2 * TAU) * 0.15 # 5th partial
		var bell: float = (bell_tone + bell_ov1 + bell_ov2) * bell_env * 0.55
		
		# 2. Contrabass Low Bowed Drone (32.7 Hz C1 + 49.0 Hz G1)
		var drone: float = (sin(t * 32.7 * TAU) * 0.4 + sin(t * 48.99 * TAU) * 0.25) * 0.4
		
		# 3. Creeping Spectral Strings / Tritone tension (Eb2, F#2, G2)
		var chord_phase: float = fmod(t, 6.0)
		var chord_env: float = sin((chord_phase / 6.0) * PI)
		var tritone: float = sin(t * 92.5 * TAU) * 0.15 + sin(t * 98.0 * TAU) * 0.15
		
		# 4. Eerie Music Box chime in high octave (C5, Eb5, G5, Ab5, B4)
		var chime_step: float = fmod(t, 0.75)
		var notes := [523.25, 622.25, 783.99, 830.61, 493.88, 622.25, 523.25, 392.00]
		var chime_idx: int = int(t / 0.75) % notes.size()
		var chime_env: float = exp(-chime_step * 5.5)
		var chime: float = sin(chime_step * notes[chime_idx] * TAU) * chime_env * 0.22
		
		# 5. Cold Abyssal Wind & Ghostly Whispers
		var wind: float = (randf() * 2.0 - 1.0) * (0.04 + sin(t * 0.4) * 0.02)
		
		samples[i] = clampf(bell + drone + (tritone * chord_env) + chime + wind, -1.0, 1.0) * 0.8
		
	var stream: AudioStreamWAV = create_pcm_stream(samples)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	return stream

# 27. Crisp Punchy Player Weapon Slash & Projectile Launch
static func gen_shoot_slash() -> AudioStreamWAV:
	var duration: float = 0.14
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = exp(-t * 22.0)
		var metallic_snap: float = sin(t * (2400.0 - t * 12000.0) * TAU) * 0.4
		var whoosh: float = (randf() * 2.0 - 1.0) * sin((t / duration) * PI) * 0.45
		var bass_thump: float = sin(t * 120.0 * TAU) * exp(-t * 30.0) * 0.35
		samples[i] = (metallic_snap + whoosh + bass_thump) * env * 0.75
	return create_pcm_stream(samples)

# 28. Player Electric Lightning Shoot
static func gen_shoot_lightning() -> AudioStreamWAV:
	var duration: float = 0.18
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = exp(-t * 18.0)
		var crackle: float = (randf() * 2.0 - 1.0) * 0.55
		var zap: float = sin(t * (3200.0 - t * 14000.0) * TAU) * 0.45
		var sub: float = sin(t * 85.0 * TAU) * exp(-t * 25.0) * 0.4
		samples[i] = (crackle + zap + sub) * env * 0.7
	return create_pcm_stream(samples)

# 29. Player Soul Missile Shoot
static func gen_shoot_soul() -> AudioStreamWAV:
	var duration: float = 0.22
	var count: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = sin((t / duration) * PI) * exp(-t * 8.0)
		var sweep: float = sin(t * (600.0 + sin(t * 40.0) * 120.0) * TAU) * 0.45
		var whisper: float = (randf() * 2.0 - 1.0) * 0.25
		samples[i] = (sweep + whisper) * env * 0.65
	return create_pcm_stream(samples)
