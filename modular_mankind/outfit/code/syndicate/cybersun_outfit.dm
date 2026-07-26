//MARK: Captain

/datum/outfit/job/cel/syndicate/captain/cybersun
	name = "Syndi Cybersun - Captain"

	id = /obj/item/card/id/cel/syndicate/captain/cybersun
	uniform = /obj/item/clothing/under/cybersun/officer
	suit = /obj/item/clothing/suit/armor/cybersun
	head = /obj/item/clothing/head/cybersun
	gloves = /obj/item/clothing/gloves/combat

//MARK: Command

/datum/outfit/job/cel/syndicate/cmo/cybersun
	name = "Syndi Cybersun - Medical Director"

	id = /obj/item/card/id/cel/syndicate/command_cmo/cybersun
	uniform = /obj/item/clothing/under/cybersun/doctor
	head = /obj/item/clothing/head/cybersun/cmo

/datum/outfit/job/cel/syndicate/head_of_personnel/cybersun
	name = "Syndi Cybersun - Intelligence Officer"
	id_assignment = "Intelligence Officer"

	id = /obj/item/card/id/cel/syndicate/command_hop/cybersun
	ears = /obj/item/radio/headset/syndicate/alt
	uniform = /obj/item/clothing/under/cybersun/officer
	suit = /obj/item/clothing/suit/cybersun
	head = /obj/item/clothing/head/cybersun
	gloves = /obj/item/clothing/gloves/combat
	glasses = /obj/item/clothing/glasses/sunglasses

/datum/outfit/job/cel/syndicate/science/director
	name = "Syndi Cybersun - Research and Development Team Leader"
	id_assignment = "Research and Development Team Leader"
	jobtype = /datum/job/rd
	job_icon = "headofpersonnel"

	id = /obj/item/card/id/cel/syndicate/command_rd/cybersun
	ears = /obj/item/radio/headset/syndicate/alt
	uniform = /obj/item/clothing/under/cybersun/officer
	suit = /obj/item/clothing/suit/cybersun
	shoes = /obj/item/clothing/shoes/jackboots
	head = /obj/item/clothing/head/HoS
	gloves = /obj/item/clothing/gloves/combat
	glasses = /obj/item/clothing/glasses/sunglasses

//MARK: Crew

/datum/outfit/job/cel/syndicate/doctor/cybersun
	name = "Syndi Cybersun - Medical Doctor"

	id = /obj/item/card/id/cel/syndicate/crew/doctor/cybersun
	head = /obj/item/clothing/head/soft/cybersun/medical
	uniform = /obj/item/clothing/under/cybersun/medic
	accessory = /obj/item/clothing/accessory/armband/medblue
	shoes = /obj/item/clothing/shoes/combat

/datum/outfit/job/cel/syndicate/paramedic/cybersun
	name = "Syndi Cybersun - Field Medic (Cybersun Industries)"
	id_assignment = "Field Medic"

	id = /obj/item/card/id/cel/syndicate/crew/doctor/paramedic/cybersun
	uniform = /obj/item/clothing/under/cybersun/medic
	head = /obj/item/clothing/head/soft/cybersun/medical
	shoes = /obj/item/clothing/shoes/combat
	suit = /obj/item/clothing/suit/armor/vest/cybersun/trauma

/datum/outfit/job/cel/syndicate/science/cybersun
	name = "Syndi Cybersun - Scientist"
	jobtype = /datum/job/scientist
	job_icon = "scientist"

	id = /obj/item/card/id/cel/syndicate/crew/scientist/cybersun
	uniform = /obj/item/clothing/under/cybersun/coverall
	suit = /obj/item/clothing/suit/toggle/labcoat
	head = /obj/item/clothing/head/soft/cybersun

	backpack = /obj/item/storage/backpack/duffelbag/syndie
	satchel = /obj/item/storage/backpack/satchel/tox
	courierbag = /obj/item/storage/backpack/messenger/tox

/datum/outfit/job/cel/syndicate/miner/cybersun
	name = "Syndi Cybersun - Field Agent"
	id_assignment = "Field Agent"

	id = /obj/item/card/id/cel/syndicate/crew/miner/cybersun
	uniform = /obj/item/clothing/under/cybersun
	accessory = /obj/item/clothing/accessory/armband/cargo
	head = /obj/item/clothing/head/soft/cybersun
	r_pocket = /obj/item/radio

/datum/outfit/job/cel/syndicate/engineer/cybersun
	name = "Syndi Cybersun - Engineer"

	id = /obj/item/card/id/cel/syndicate/crew/engineer/cybersun
	uniform = /obj/item/clothing/under/cybersun
	shoes = /obj/item/clothing/shoes/workboots
	r_pocket = /obj/item/radio
	head = /obj/item/clothing/head/soft/cybersun
	accessory = /obj/item/clothing/accessory/armband/engine

//MARK: Assistant

/datum/outfit/job/cel/syndicate/assistant/cybersun
	name = "Syndi Cybersun - Junior Agent"

	id = /obj/item/card/id/cel/syndicate/assistant/cybersun
	uniform = /obj/item/clothing/under/cybersun
	head = /obj/item/clothing/head/soft/cybersun

//MARK: Kansatsu

/datum/outfit/job/cel/syndicate/captain/cybersun
	name = "Syndi Cybersun - Captain"

	id = /obj/item/card/id/cel/syndicate/captain/cybersun
	uniform = /obj/item/clothing/under/cybersun/officer
	suit = /obj/item/clothing/suit/armor/vest/capcarapace/syndicate
	head = /obj/item/clothing/head/cybersun
	gloves = /obj/item/clothing/gloves/combat
	shoes = /obj/item/clothing/shoes/combat
	ears = /obj/item/radio/headset/syndicate/alt
	backpack_contents = list(
						/obj/item/modular_computer/tablet/syndicate_contract_uplink,
						/obj/item/uplink/nuclear)

/datum/outfit/job/cel/syndicate/head_of_personnel/cybersun
	name = "Syndi Cybersun - Intelligence Officer"
	id_assignment = "Intelligence Officer"

	id = /obj/item/card/id/cel/syndicate/command_hop/cybersun
	ears = /obj/item/radio/headset/syndicate/alt
	uniform = /obj/item/clothing/under/cybersun/officer
	suit = /obj/item/clothing/suit/cybersun
	shoes = /obj/item/clothing/shoes/combat
	head = /obj/item/clothing/head/cybersun
	gloves = /obj/item/clothing/gloves/combat
	glasses = /obj/item/clothing/glasses/sunglasses
	backpack_contents = list(
						/obj/item/stack/telecrystal/five,
						/obj/item/stack/telecrystal/five,
						/obj/item/uplink/old)

/datum/outfit/job/cel/syndicate/miner/cybersun
	name = "Syndi Cybersun - Field Agent"
	id_assignment = "Field Agent"

	id = /obj/item/card/id/cel/syndicate/crew/miner/cybersun
	ears = /obj/item/radio/headset
	uniform = /obj/item/clothing/under/cybersun
	accessory = /obj/item/clothing/accessory/armband/cargo
	head = /obj/item/clothing/head/soft/cybersun
	r_pocket = /obj/item/radio
	shoes = /obj/item/clothing/shoes/combat
	backpack_contents = list(
						/obj/item/stack/telecrystal/five,
						/obj/item/stack/telecrystal/five)

/datum/outfit/job/cel/syndicate/engineer/cybersun
	name = "Syndi Cybersun - Engineer"

	id = /obj/item/card/id/cel/syndicate/crew/engineer/cybersun
	uniform = /obj/item/clothing/under/cybersun
	shoes = /obj/item/clothing/shoes/combat
	r_pocket = /obj/item/radio
	head = /obj/item/clothing/head/soft/cybersun
	accessory = /obj/item/clothing/accessory/armband/engine
	ears = /obj/item/radio/headset/syndicate
	backpack_contents = list(
						/obj/item/stack/telecrystal/five,
						/obj/item/stack/telecrystal/five)
