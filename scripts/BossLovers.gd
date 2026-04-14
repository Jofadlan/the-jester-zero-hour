class_name BossLovers
extends RefCounted

## The Lovers (VI) — Boss Act 2
## Filosofi: Pilihan moral, dualitas Jester-Knight
## Dua stage. Narrative phase di tengah stage 1 dan stage 2.

static func create() -> BossData:
	return BossData.new("THE LOVERS", [
		BossData.StageData.new(300),
		BossData.StageData.new(520, "discard_random_2"),
	])

static func create_narrative_phases() -> Array:
	return [
		# Stage 1 — setelah 2 hands
		NarrativePhase.new(0, 2,
			"Di tengah duel, bayangan itu berhenti.\n\n" +
			"\"Kau ingat bagaimana rasanya tidak penting?\"\n" +
			"\"Tidak ada yang melihatmu. Tidak ada yang peduli apakah kau hidup atau mati.\"\n\n" +
			"\"Itu adalah kebebasan. Mengapa kau melepaskannya?\"",
			[
				NarrativePhase.Choice.new(
					"\"Karena kebebasan itu bukan milikku — itu ketidakberdayaan.\"",
					-5   # corruption turun — Jester tetap lucid
				),
				NarrativePhase.Choice.new(
					"Diam. Mungkin ia benar. Mungkin ini semua sia-sia.",
					12   # corruption naik — mulai goyah
				),
			]
		),

		# Stage 2 — setelah 1 hand
		NarrativePhase.new(1, 1,
			"Stage kedua. Bayangan itu kini berbentuk lebih jelas —\n" +
			"separuh wajahnya adalah wajah pelawak, separuh lagi ksatria.\n\n" +
			"\"Kau tidak bisa menjadi keduanya selamanya.\"\n" +
			"\"Pilih. Jester yang tertawa saat dunia terbakar.\"\n" +
			"\"Atau Knight yang tangan darahnya menyelamatkan satu nyawa\n" +
			"dan menghancurkan seratus lainnya.\"",
			[
				NarrativePhase.Choice.new(
					"\"Aku tidak memilih. Aku adalah keduanya — dan itu cukup.\"",
					-8
				),
				NarrativePhase.Choice.new(
					"\"Mungkin... aku memang harus memilih satu.\" — Tapi kau tidak tahu mana.",
					15
				),
			]
		),
	]
