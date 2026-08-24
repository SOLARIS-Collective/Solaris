// [SOLARIS-ADD] - STOCK_MARKET
// Issuers listed on the exchange. Add new companies as /datum/stock_company subtypes.
// faction_path ties an issuer to a playable faction so mission results of that
// faction's ships move the price (see SSstock_market.on_mission_result).

/datum/stock_company/sharplight
	ticker = "SHRP"
	name = "Sharplight Defense Dynamics"
	blurb = "Prime defense contractor arming NanoTrasen security fleets with ship-grade weaponry."
	sector = STOCK_SECTOR_DEFENSE
	faction_path = /datum/faction/nt
	base_price = 150
	volatility = 0.015
	depth = 500
	float_shares = 20000

/datum/stock_company/gorlex
	ticker = "GRXL"
	name = "Gorlex Martial Holdings"
	blurb = "Umbrella holding of the Gorlex Marauders. Profits from every conflict it can find."
	sector = STOCK_SECTOR_DEFENSE
	faction_path = /datum/faction/syndicate/ngr
	base_price = 85
	volatility = 0.03
	depth = 350
	float_shares = 12000
	correlations = list("ITQ" = 0.8)

/datum/stock_company/inteq
	ticker = "ITQ"
	name = "Inteq Risk Group"
	blurb = "Professional risk management: escort contracts, bounties and deniable operations."
	sector = STOCK_SECTOR_DEFENSE
	faction_path = /datum/faction/inteq
	base_price = 110
	volatility = 0.025
	depth = 300
	float_shares = 9000
	correlations = list("GRXL" = 0.8)

/datum/stock_company/cybersun
	ticker = "CYBN"
	name = "Cybersun Industries"
	blurb = "Syndicate industrial conglomerate: cybernetics, MODsuits and questionable chemistry."
	sector = STOCK_SECTOR_INDUSTRIAL
	faction_path = /datum/faction/syndicate/cybersun
	base_price = 60
	volatility = 0.032
	depth = 450
	float_shares = 25000
	correlations = list("MRDB" = 0.3)

/datum/stock_company/solgov_yards
	ticker = "SOLY"
	name = "SolGov Orbital Yards"
	blurb = "State-backed shipyards churning out patrol hulls for the Sol Alliance."
	sector = STOCK_SECTOR_INDUSTRIAL
	faction_path = /datum/faction/solgov
	base_price = 175
	volatility = 0.012
	depth = 550
	float_shares = 16000

/datum/stock_company/transstellar
	ticker = "TSFH"
	name = "Trans-Stellar Freight & Haulage"
	blurb = "The arteries of frontier trade. When haulers move, TSFH profits."
	sector = STOCK_SECTOR_LOGISTICS
	base_price = 70
	volatility = 0.02
	depth = 600
	float_shares = 30000
	correlations = list("DCEX" = 0.4)

/datum/stock_company/deepcore
	ticker = "DCEX"
	name = "Deep Core Extraction Consortium"
	blurb = "Asteroid mining consortium. Metal demand is metal profit."
	sector = STOCK_SECTOR_MATERIALS
	base_price = 95
	volatility = 0.022
	depth = 700
	float_shares = 35000

/datum/stock_company/hyperion
	ticker = "HYPN"
	name = "Hyperion Fuel Refineries"
	blurb = "Refines helium-3 and plasma feedstock for half the ships on the spacelanes."
	sector = STOCK_SECTOR_ENERGY
	base_price = 125
	volatility = 0.024
	depth = 400
	float_shares = 18000
	correlations = list("DCEX" = 0.6)

/datum/stock_company/viridian
	ticker = "VRAC"
	name = "Viridian Agri-Cooperative"
	blurb = "Hydroponic mega-farms feeding the frontier. Boring, stable, essential."
	sector = STOCK_SECTOR_AGRO
	base_price = 45
	volatility = 0.014
	depth = 800
	float_shares = 40000

/datum/stock_company/meridian
	ticker = "MRDB"
	name = "Meridian Biotechnica"
	blurb = "Gene-therapies and synthetic organs. An epidemic somewhere is revenue here."
	sector = STOCK_SECTOR_MEDICAL
	base_price = 210
	volatility = 0.02
	depth = 250
	float_shares = 8000

/datum/stock_company/centcom_mutual
	ticker = "CCMA"
	name = "CentCom Mutual Assurance"
	blurb = "Insures everything the other issuers can lose. Too big to fail, allegedly."
	sector = STOCK_SECTOR_FINANCE
	faction_path = /datum/faction/nt
	base_price = 320
	volatility = 0.008
	depth = 300
	float_shares = 10000
// [/SOLARIS-ADD]
