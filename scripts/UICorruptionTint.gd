## UICorruptionTint.gd
## Autoload singleton — UI accent color berubah mengikuti corruption secara diam-diam.
##
## CARA PAKAI:
##   1. Tambahkan ke Project > Project Settings > Autoload sebagai "UICorruptionTint"
##   2. Di CombatScene.gd atau UIManager, panggil:
##        UICorruptionTint.register(node, "theme_override_colors/font_color")
##      untuk setiap Label/Button yang ingin mengikuti warna accent.
##   3. Panggil UICorruptionTint.sync() setiap kali corruption berubah.
##      Atau biarkan _process() berjalan (auto-sync setiap frame).

extends Node

# ─────────────────────────────────────────────
#  KONSTANTA WARNA
#  Tidak pernah mencapai "merah murni" — selalu ada sisa kehangatan
#  agar tidak terasa seperti health-bar atau warning indicator.
# ─────────────────────────────────────────────

## Accent saat corruption = 0. Gold tua, seperti koin yang kusam.
const COLOR_PURE_JESTER   := Color(0.788, 0.573, 0.165, 1.0)   # #C99229

## Accent saat corruption = 50 (grey zone). Amber gelap, tembaga berdarah.
const COLOR_GREY_ZONE     := Color(0.698, 0.314, 0.122, 1.0)   # #B2501F

## Accent saat corruption = 100. Deep crimson, bukan merah terang —
## seperti darah yang sudah mengering di atas kertas.
const COLOR_PURE_JOKER    := Color(0.502, 0.086, 0.086, 1.0)   # #801616

## Warna sekunder untuk elemen "inactive" / placeholder
const COLOR_MUTED_JESTER  := Color(0.478, 0.431, 0.369, 1.0)   # #7A6E5E
const COLOR_MUTED_JOKER   := Color(0.380, 0.200, 0.180, 1.0)   # #61332E

## Kecepatan lerp. Nilai kecil = transisi sangat lambat (tidak kentara).
## 0.008 artinya butuh ~125 frame (±2 detik) untuk pindah penuh.
const LERP_SPEED := 0.008

# ─────────────────────────────────────────────
#  STATE INTERNAL
# ─────────────────────────────────────────────

## Nilai corruption yang *sedang ditampilkan* (0.0–1.0, float).
## Berbeda dari GameManager.corruption yang berupa int 0–100.
var _displayed_t: float = 0.0

## Target t berdasarkan GameManager.corruption saat ini.
var _target_t: float = 0.0

## Warna accent yang sedang aktif (lerp result).
var current_accent: Color = COLOR_PURE_JESTER
var current_muted:  Color = COLOR_MUTED_JESTER

## Registry: pasangan [node, property_name]
## Semua node terdaftar akan otomatis diupdate warnanya.
var _registered_nodes: Array = []

# ─────────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────────

func _process(_delta: float) -> void:
	_target_t = float(GameManager.corruption) / 100.0
	
	# Lerp perlahan ke target — sengaja tidak menggunakan delta agar
	# kecepatannya konsisten terlepas dari framerate.
	if not is_equal_approx(_displayed_t, _target_t):
		_displayed_t = lerp(_displayed_t, _target_t, LERP_SPEED)
		_recalculate_colors()
		_apply_to_registered()

# ─────────────────────────────────────────────
#  PUBLIC API
# ─────────────────────────────────────────────

## Daftarkan sebuah node agar warna accent-nya dikelola otomatis.
## property_name: string properti warna pada node, misalnya:
##   "theme_override_colors/font_color"
##   "theme_override_colors/font_pressed_color"
##   "theme_override_styles/normal:bg_color"  (tidak didukung langsung, lihat catatan)
##
## Contoh:
##   UICorruptionTint.register($UI/ScoreLabel, "theme_override_colors/font_color")
func register(node: Node, property_name: String, use_muted: bool = false) -> void:
	if not is_instance_valid(node):
		return
	# Cegah duplikat
	for entry in _registered_nodes:
		if entry[0] == node and entry[1] == property_name:
			return
	_registered_nodes.append([node, property_name, use_muted])

## Hapus node dari registry (misalnya saat node di-free).
func unregister(node: Node) -> void:
	_registered_nodes = _registered_nodes.filter(func(e): return e[0] != node)

## Panggil ini untuk force-sync langsung (tanpa menunggu lerp).
## Berguna saat scene baru load agar tidak terlihat "blink" dari gold ke merah.
func force_sync() -> void:
	_displayed_t = float(GameManager.corruption) / 100.0
	_recalculate_colors()
	_apply_to_registered()

## Ambil warna accent saat ini (untuk dipakai manual di luar registry).
func get_accent() -> Color:
	return current_accent

## Ambil warna muted saat ini.
func get_muted() -> Color:
	return current_muted

# ─────────────────────────────────────────────
#  LOGIKA WARNA INTERNAL
# ─────────────────────────────────────────────

func _recalculate_colors() -> void:
	var t := clampf(_displayed_t, 0.0, 1.0)
	
	# Kurva easing: warna berubah lambat di awal, mulai terasa di tengah.
	# Ini agar 20–30% corruption pertama hampir tidak kelihatan sama sekali.
	var eased_t := _ease_in_quad(t)
	
	if t <= 0.5:
		# Jester → Grey Zone (0.0–0.5 di-remap ke 0.0–1.0)
		var local_t := eased_t * 2.0
		current_accent = COLOR_PURE_JESTER.lerp(COLOR_GREY_ZONE, local_t)
		current_muted  = COLOR_MUTED_JESTER.lerp(COLOR_MUTED_JOKER, local_t * 0.6)
	else:
		# Grey Zone → Joker (0.5–1.0 di-remap ke 0.0–1.0)
		var local_t := (eased_t - 0.5) * 2.0
		current_accent = COLOR_GREY_ZONE.lerp(COLOR_PURE_JOKER, local_t)
		current_muted  = COLOR_MUTED_JESTER.lerp(COLOR_MUTED_JOKER, 0.6 + local_t * 0.4)

func _apply_to_registered() -> void:
	for entry in _registered_nodes:
		var node: Node = entry[0]
		var prop: String = entry[1]
		var use_muted: bool = entry[2]
		
		if not is_instance_valid(node):
			continue
		
		var target_color := current_muted if use_muted else current_accent
		
		# Gunakan set() untuk theme_override agar kompatibel dengan semua Control node
		if node.has_method("set"):
			node.set(prop, target_color)

# ─────────────────────────────────────────────
#  EASING
# ─────────────────────────────────────────────

## Ease-in quadratic: perubahan lambat di awal, makin cepat di akhir.
## Membuat 30 corruption pertama hampir tidak terasa.
func _ease_in_quad(t: float) -> float:
	return t * t
