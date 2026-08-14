
/obj/machinery/vending/security/marine/all_mech
	name = "\improper all mech parts"
	desc = "A marine all mech parts."
	product_ads = "EXTERMINATE!"
	icon_state = "solgov-marine"
	icon_deny = "solgov-marine-deny"
	light_mask = "solgov-marine-mask"
	icon_vend = "solgov-marine-vend"
	req_access = list()
	all_items_free = TRUE
	categories = list("Chassis", "Equipment", "Weapon ballistic", "Weapon energy", "Weapon", "Thrusters", "Medical", "Conversion kit", "Tracking", "Weapon bay", "Parts")
	product_categories = list(
		"Chassis" = list(
			/obj/item/mecha_parts/chassis,
		),
		"Equipment" = list(
			/obj/item/mecha_parts/mecha_equipment/wormhole_generator,
			/obj/item/mecha_parts/mecha_equipment/tesla_energy_relay,
			/obj/item/mecha_parts/mecha_equipment/teleporter,
			/obj/item/mecha_parts/mecha_equipment/salvage_saw,
			/obj/item/mecha_parts/mecha_equipment/repair_droid,
			/obj/item/mecha_parts/mecha_equipment/rcd,
			/obj/item/mecha_parts/mecha_equipment/mining_scanner,
			/obj/item/mecha_parts/mecha_equipment/hydraulic_clamp,
			/obj/item/mecha_parts/mecha_equipment/hydraulic_clamp/kill,
			/obj/item/mecha_parts/mecha_equipment/gravcatapult,
			/obj/item/mecha_parts/mecha_equipment/generator,
			/obj/item/mecha_parts/mecha_equipment/generator/nuclear,
			/obj/item/mecha_parts/mecha_equipment/extinguisher,
			/obj/item/mecha_parts/mecha_equipment/drill,
			/obj/item/mecha_parts/mecha_equipment/drill/diamonddrill,
			/obj/item/mecha_parts/mecha_equipment/cable_layer,
			/obj/item/mecha_parts/mecha_equipment/antiproj_armor_booster,
			/obj/item/mecha_parts/mecha_equipment/anticcw_armor_booster,
		),
		"Weapon ballistic" = list(
			/obj/item/mecha_parts/mecha_equipment/weapon/ballistic,
		),
		"Weapon energy" = list(
			/obj/item/mecha_parts/mecha_equipment/weapon/energy,
		),
		"Weapon" = list(
			/obj/item/mecha_parts/mecha_equipment/weapon/honker,
		),
		"Thrusters" = list(
			/obj/item/mecha_parts/mecha_equipment/thrusters,
		),
		"Medical" = list(
			/obj/item/mecha_parts/mecha_equipment/medical,
		),
		"Conversion kit" = list(
			/obj/item/mecha_parts/mecha_equipment/conversion_kit,
		),
		"Tracking" = list(
			/obj/item/mecha_parts/mecha_tracking,
		),
		"Parts" = list(
			/obj/item/mecha_parts/part,
		),
		"Weapon bay" = list(
			/obj/item/mecha_parts/weapon_bay,
		),
	)
	products = list(
		/obj/item/mecha_parts/chassis/ripley = 5,
		/obj/item/mecha_parts/chassis/phazon = 5,
		/obj/item/mecha_parts/chassis/odysseus = 5,
		/obj/item/mecha_parts/chassis/mp_gygax = 5,
		/obj/item/mecha_parts/chassis/honker = 5,
		/obj/item/mecha_parts/chassis/gygax = 5,
		/obj/item/mecha_parts/chassis/firefighter = 5,
		/obj/item/mecha_parts/chassis/durand = 5,

		/obj/item/mecha_parts/mecha_equipment/wormhole_generator = 5,
		/obj/item/mecha_parts/mecha_equipment/cable_layer = 5,
		/obj/item/mecha_parts/mecha_equipment/antiproj_armor_booster = 5,
		/obj/item/mecha_parts/mecha_equipment/anticcw_armor_booster = 5,

		/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/carbine = 5,
		/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/silenced = 5,
		/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/scattershot = 5,
		/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/railgun = 5,
		/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack = 5,
		/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/breaching = 5,
		/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/tank = 5,
		/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg = 5,
		/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg/mounted = 5,
		/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/launcher = 5,
		/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/launcher/banana_mortar = 5,
		/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/launcher/banana_mortar/bombanana = 5,
		/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/launcher/flashbang = 5,
		/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/launcher/flashbang/clusterbang = 5,
		/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/launcher/flashbang/tearstache = 5,
		/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/launcher/mousetrap_mortar = 5,
		/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/launcher/punching_glove = 5,

		/obj/item/mecha_parts/mecha_equipment/weapon/energy/carbine = 5,
		/obj/item/mecha_parts/mecha_equipment/weapon/energy/ion = 5,
		/obj/item/mecha_parts/mecha_equipment/weapon/energy/laser = 5,
		/obj/item/mecha_parts/mecha_equipment/weapon/energy/mecha_kineticgun = 5,
		/obj/item/mecha_parts/mecha_equipment/weapon/energy/plasma = 5,
		/obj/item/mecha_parts/mecha_equipment/weapon/energy/pulse = 5,
		/obj/item/mecha_parts/mecha_equipment/weapon/energy/taser = 5,
		/obj/item/mecha_parts/mecha_equipment/weapon/energy/tesla = 5,

		/obj/item/mecha_parts/mecha_equipment/weapon/honker = 5,

		/obj/item/mecha_parts/mecha_equipment/thrusters/gas = 5,
		/obj/item/mecha_parts/mecha_equipment/thrusters/ion = 5,

		/obj/item/mecha_parts/mecha_equipment/medical/mechmedbeam = 5,
		/obj/item/mecha_parts/mecha_equipment/medical/sleeper = 5,
		/obj/item/mecha_parts/mecha_equipment/medical/syringe_gun = 5,

		/obj/item/mecha_parts/mecha_equipment/conversion_kit/alt = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/aluminizer = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/ares = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/dark_gygax = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/dollhouse = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/duranddark = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/earth = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/executor = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/flames_red = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/gygaxblack = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/gygaxnt = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/gygaxwhite = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/hermes = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/inteq_gygax = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/leaper = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/medgax = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/mp_gygax = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/murdysseus = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/old = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/paladin = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/pobeda = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/proto = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/ripley = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/ripley_zairjah = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/sarathi = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/shire = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/titan = 5,
		/obj/item/mecha_parts/mecha_equipment/conversion_kit/zeus = 5,

		/obj/item/mecha_parts/mecha_tracking/ai_control = 5,

		/obj/item/mecha_parts/weapon_bay/concealed = 5,
		)

