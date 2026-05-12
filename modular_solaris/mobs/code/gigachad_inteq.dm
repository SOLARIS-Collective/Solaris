/mob/living/simple_animal/hostile/gigachad_inteq
	name = "InteQ Agent"
	real_name = "InteQ Agent"
	icon = 'modular_solaris/_storage_icons/icons/mobs/gigachad_inteq.dmi'
	desc = "An experiment had gone out of control.."
	icon_state = "gigachad_inteq"
	icon_living = "gigachad_inteq"
	icon_dead = "syndicate_dead"
	icon_gib = "syndicate_gib"
	maxHealth = 1200
	health = 1200
	response_harm_continuous = "harmlessly punches"
	response_harm_simple = "harmlessly punch"
	harm_intent_damage = 0
	obj_damage = 100
	melee_damage_lower = 50
	melee_damage_upper = 60
	attack_verb_continuous = "smashes his sledgehammer into"
	attack_verb_simple = "smashes sledgehammer into"
	speed = 0.8
	environment_smash = ENVIRONMENT_SMASH_WALLS
	attack_sound = 'modular_solaris/_storage_sounds/sound/weapons/sledge.ogg'
	status_flags = 0
	mob_size = MOB_SIZE_LARGE
	del_on_death = TRUE
	force_threshold = 10
	speak_chance = 90
	AIStatus = AI_ON
	speak = list("БЕГАЮЩИЕ ГВОЗДИ!!!", "БЕГИ, СУКА, БЕГИ!!!", "КАК ОРЕХ ЩА РАСКОЛЮ!!!", "СТОЙ, СУКА!!!")
	loot = list(/obj/item/storage/belt/military/assault,
				/obj/item/clothing/head/helmet/swat,
				/obj/item/clothing/shoes/combat/coldres,
				/obj/effect/gibspawner/generic,
				/obj/effect/gibspawner/generic/animal,
				/obj/effect/gibspawner/human/bodypartless,
				/obj/effect/gibspawner/human)

/mob/living/simple_animal/hostile/gigachad_inteq
	name = "InteQ Uncle Stepan"
	real_name = "Дядя Стёпа"

/mob/living/simple_animal/hostile/gigachad_inteq/space
	name = "InteQ Space Agent"
	maxHealth = 1400
	health = 1400
	atmos_requirements = IMMUNE_ATMOS_REQS
	minbodytemp = 0
	maxbodytemp = 1000
	melee_damage_lower = 30
	melee_damage_upper = 20
	attack_verb_continuous = "smashes his hands into"
	attack_verb_simple = "smashes hands into"
	icon_state = "gigachad_inteq_space"
	icon_living = "gigachad_inteq_space"
	attack_sound = 'sound/weapons/smash.ogg'
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	faction = list(FACTION_INTEQ, FACTION_PLAYER_INTEQ)

/mob/living/simple_animal/hostile/gigachad_inteq/shooter
	name = "InteQ Machinegunner"
	icon_state = "gigachad_machinegun"
	icon_living = "gigachad_machinegun"
	maxHealth = 600
	health = 600
	ranged = 1
	rapid = 5
	projectilesound = 'modular_solaris/_storage_sounds/sound/weapons/shot.ogg'
	speak = list("БЕГАЮЩАЯ МИШЕНЬ И БЕСПЛАТНО!!!", "БЕГИ, СУКА, БЕГИ!!!", "КАК АРБУЗ МАГНУМОМ ЛОПНУ!!!")
	casingtype = /obj/item/ammo_casing/a762_40 // а должно быть 7.62х38
	retreat_distance = 5
	minimum_distance = 5
	faction = list(FACTION_INTEQ, FACTION_PLAYER_INTEQ)

/mob/living/simple_animal/hostile/gigachad_inteq/shooter/sniper
	name = "InteQ Buffed sniper"
	icon_state = "gigachad_sniper"
	icon_living = "gigachad_sniper"
	casingtype = /obj/item/ammo_casing/p50/cheap
	rapid = 1
	maxHealth = 350
	health = 350
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	projectilesound = "sound/weapons/noscope.ogg"
	ranged_cooldown = 150
	check_friendly_fire = 1
	speak = list("ДА ЁБ ТВОЮ МАТЬ! ОПЯТЬ КЛИН!!!", "А ЭТО ЧЁ? ПРОБИВНЫЕ? ЭТО НАМ НАДО!!!", "МАГАЗИН ГДЕ? БЛЯ! ГДЕ МАГАЗИН МОЙ!!!")

/obj/item/ammo_casing/p50/cheap
	name = "cheap .50 bullet casing"
	desc = "A cheap .50 bullet casing."
	projectile_type = /obj/projectile/bullet/p50/cheap

/obj/projectile/bullet/p50/cheap
	name ="cheap .50 bullet"
	icon_state = "gauss"
	damage = 40
	knockdown = 80
	dismemberment = 40
	armour_penetration = 30
	// zone_accuracy_factor = 70 // хз че это
	wound_bonus = 10
	bare_wound_bonus = 5
