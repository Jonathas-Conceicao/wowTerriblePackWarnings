local addonName, ns = ...
ns.DungeonEnemies = ns.DungeonEnemies or {}

-- Sourced from MythicDungeonTools/Midnight/*.lua
-- Only id (npcID), name, displayId retained -- clone coordinates omitted
-- enemyIdx keys match MDT originals exactly (used by import pipeline for npcID resolution)

----------------------------------------------------------------
-- dungeonIdx 11 = Seat of the Triumvirate
----------------------------------------------------------------
ns.DungeonEnemies[11] = {
    [1]  = { id = 124171, name = "Merciless Subjugator", displayId = 75011 },
    [2]  = { id = 122571, name = "Rift Warden", displayId = 136883 },
    [3]  = { id = 122413, name = "Ruthless Riftstalker", displayId = 75003 },
    [4]  = { id = 255320, name = "Ravenous Umbralfin", displayId = 74902 },
    [5]  = { id = 122421, name = "Umbral War-Adept", displayId = 124453 },
    [6]  = { id = 122404, name = "Dire Voidbender", displayId = 124412 },
    [7]  = { id = 252756, name = "Void-Infused Destroyer", displayId = 126552 },
    [8]  = { id = 122423, name = "Grand Shadow-Weaver", displayId = 124089 },
    [9]  = { id = 122056, name = "Viceroy Nezhar", displayId = 78415 },
    [10] = { id = 122313, name = "Zuraal the Ascended", displayId = 77871 },
    [11] = { id = 122316, name = "Saprish", displayId = 143117 },
    [12] = { id = 122319, name = "Darkfang", displayId = 76602 },
    [13] = { id = 122322, name = "Famished Broken", displayId = 75479 },
    [14] = { id = 122403, name = "Shadowguard Champion", displayId = 124440 },
    [15] = { id = 122405, name = "Dark Conjurer", displayId = 124411 },
    [16] = { id = 122412, name = "Bound Voidcaller", displayId = 71758 },
    [17] = { id = 122716, name = "Coalesced Void", displayId = 76601 },
    [18] = { id = 122827, name = "Umbral Tentacle", displayId = 77103 },
    [19] = { id = 124729, name = "L'ura", displayId = 141808 },
    [20] = { id = 125340, name = "Shadewing", displayId = 78427 },
    [21] = { id = 255551, name = "Depravation Wave Stalker", displayId = 5187 },
    [22] = { id = 256424, name = "Void Tentacle", displayId = 94382 },
}

----------------------------------------------------------------
-- dungeonIdx 45 = Algethar Academy
----------------------------------------------------------------
ns.DungeonEnemies[45] = {
    [1]  = { id = 196045, name = "Corrupted Manafiend", displayId = 107525 },
    [2]  = { id = 196577, name = "Spellbound Battleaxe", displayId = 23926 },
    [3]  = { id = 196671, name = "Arcane Ravager", displayId = 110795 },
    [4]  = { id = 196694, name = "Arcane Forager", displayId = 62384 },
    [5]  = { id = 196044, name = "Unruly Textbook", displayId = 109308 },
    [6]  = { id = 194181, name = "Vexamus", displayId = 109099 },
    [7]  = { id = 192680, name = "Guardian Sentry", displayId = 26385 },
    [8]  = { id = 192329, name = "Territorial Eagle", displayId = 34918 },
    [9]  = { id = 192333, name = "Alpha Eagle", displayId = 101438 },
    [10] = { id = 191736, name = "Crawth", displayId = 110805 },
    [11] = { id = 197406, name = "Aggravated Skitterfly", displayId = 103762 },
    [12] = { id = 197219, name = "Vile Lasher", displayId = 104635 },
    [13] = { id = 197398, name = "Hungry Lasher", displayId = 104474 },
    [14] = { id = 196482, name = "Overgrown Ancient", displayId = 109194 },
    [15] = { id = 196200, name = "Algeth'ar Echoknight", displayId = 109104 },
    [16] = { id = 196202, name = "Spectral Invoker", displayId = 109105 },
    [17] = { id = 190609, name = "Echo of Doragosa", displayId = 108925 },
}

----------------------------------------------------------------
-- dungeonIdx 150 = Pit of Saron
----------------------------------------------------------------
ns.DungeonEnemies[150] = {
    [1]  = { id = 252551, name = "Deathwhisper Necrolyte", displayId = 98697 },
    [2]  = { id = 252602, name = "Risen Soldier", displayId = 137464 },
    [3]  = { id = 252603, name = "Arcanist Cadaver", displayId = 137490 },
    [4]  = { id = 252567, name = "Gloombound Shadebringer", displayId = 137462 },
    [5]  = { id = 252561, name = "Quarry Tormentor", displayId = 137458 },
    [6]  = { id = 252563, name = "Dreadpulse Lich", displayId = 137459 },
    [7]  = { id = 252558, name = "Rotting Ghoul", displayId = 75103 },
    [8]  = { id = 252610, name = "Ymirjar Graveblade", displayId = 137498 },
    [9]  = { id = 252559, name = "Leaping Geist", displayId = 25742 },
    [10] = { id = 252606, name = "Plungetalon Gargoyle", displayId = 137853 },
    [11] = { id = 252555, name = "Lumbering Plaguehorror", displayId = 137508 },
    [12] = { id = 257190, name = "Iceborn Proto-Drake", displayId = 139964 },
    [13] = { id = 252565, name = "Wrathbone Enforcer", displayId = 137460 },
    [14] = { id = 252566, name = "Rimebone Coldwraith", displayId = 137461 },
    [15] = { id = 252564, name = "Glacieth", displayId = 140012 },
    [16] = { id = 252621, name = "Krick", displayId = 137499 },
    [17] = { id = 252625, name = "Ick", displayId = 137500 },
    [18] = { id = 252635, name = "Forgemaster Garfrost", displayId = 137504 },
    [19] = { id = 252648, name = "Scourgelord Tyrannus", displayId = 137505 },
    [20] = { id = 252653, name = "Rimefang", displayId = 31154 },
    [21] = { id = 254684, name = "Rotling", displayId = 138343 },
    [22] = { id = 254691, name = "Scourge Plaguespreader", displayId = 138341 },
    [23] = { id = 255037, name = "Shade of Krick", displayId = 138601 },
    [24] = { id = 252557, name = "Mindless Laborer", displayId = 137487 },
}

----------------------------------------------------------------
-- dungeonIdx 151 = Skyreach
----------------------------------------------------------------
ns.DungeonEnemies[151] = {
    [1]  = { id = 76132, name = "Soaring Chakram Master", displayId = 60336 },
    [2]  = { id = 78932, name = "Driving Gale-Caller", displayId = 60335 },
    [3]  = { id = 250992, name = "Raging Squall", displayId = 109236 },
    [4]  = { id = 75976, name = "Outcast Servant", displayId = 59446 },
    [5]  = { id = 79462, name = "Blinding Sun Priestess", displayId = 60333 },
    [6]  = { id = 79466, name = "Initiate of the Rising Sun", displayId = 57094 },
    [7]  = { id = 79467, name = "Adept of the Dawn", displayId = 56022 },
    [8]  = { id = 78933, name = "Herald of Sunrise", displayId = 137750 },
    [9]  = { id = 76087, name = "Solar Construct", displayId = 56653 },
    [10] = { id = 79093, name = "Skyreach Sun Talon", displayId = 58829 },
    [11] = { id = 76154, name = "Sun Talon Tamer", displayId = 56007 },
    [12] = { id = 75964, name = "Ranjit", displayId = 56015 },
    [13] = { id = 76141, name = "Araknath", displayId = 54006 },
    [14] = { id = 76142, name = "Skyreach Sun Construct Prototype", displayId = 56654 },
    [15] = { id = 76143, name = "Rukhran", displayId = 125047 },
    [16] = { id = 76149, name = "Dread Raven", displayId = 54173 },
    [17] = { id = 76205, name = "Blooded Bladefeather", displayId = 59454 },
    [18] = { id = 76227, name = "Sunwings", displayId = 54030 },
    [19] = { id = 76266, name = "High Sage Viryx", displayId = 56016 },
    [20] = { id = 76285, name = "Arakkoa Magnifying Glass", displayId = 21423 },
    [21] = { id = 79303, name = "Adorned Bladetalon", displayId = 57282 },
    [22] = { id = 251880, name = "Solar Orb", displayId = 11686 },
}

----------------------------------------------------------------
-- dungeonIdx 152 = Windrunner Spire
----------------------------------------------------------------
ns.DungeonEnemies[152] = {
    [1]  = { id = 232070, name = "Restless Steward", displayId = 136509 },
    [2]  = { id = 232071, name = "Dutiful Groundskeeper", displayId = 136510 },
    [3]  = { id = 232113, name = "Spellguard Magus", displayId = 136511 },
    [4]  = { id = 232116, name = "Windrunner Soldier", displayId = 139554 },
    [5]  = { id = 232173, name = "Fervent Apothecary", displayId = 124490 },
    [6]  = { id = 232171, name = "Ardent Cutthroat", displayId = 124494 },
    [7]  = { id = 232232, name = "Zealous Reaver", displayId = 114147 },
    [8]  = { id = 232175, name = "Devoted Woebringer", displayId = 140702 },
    [9]  = { id = 232176, name = "Flesh Behemoth", displayId = 140689 },
    [10] = { id = 232056, name = "Territorial Dragonhawk", displayId = 140630 },
    [11] = { id = 234673, name = "Spindleweb Hatchling", displayId = 140631 },
    [12] = { id = 232067, name = "Creeping Spindleweb", displayId = 140652 },
    [13] = { id = 232063, name = "Apex Lynx", displayId = 131955 },
    [14] = { id = 238099, name = "Pesty Lashling", displayId = 140667 },
    [15] = { id = 236894, name = "Bloated Lasher", displayId = 112489 },
    [16] = { id = 238049, name = "Scouting Trapper", displayId = 18830 },
    [17] = { id = 232119, name = "Swiftshot Archer", displayId = 139552 },
    [18] = { id = 232122, name = "Phalanx Breaker", displayId = 140454 },
    [19] = { id = 232283, name = "Loyal Worg", displayId = 70180 },
    [20] = { id = 232147, name = "Lingering Marauder", displayId = 136066 },
    [21] = { id = 232148, name = "Spectral Axethrower", displayId = 142686 },
    [22] = { id = 232146, name = "Phantasmal Mystic", displayId = 136067 },
    [23] = { id = 231606, name = "Emberdawn", displayId = 123453 },
    [24] = { id = 231626, name = "Kalis", displayId = 125201 },
    [25] = { id = 231629, name = "Latch", displayId = 124335 },
    [26] = { id = 231631, name = "Commander Kroluk", displayId = 122981 },
    [27] = { id = 231636, name = "Restless Heart", displayId = 125199 },
    [28] = { id = 232118, name = "Flaming Updraft", displayId = 100728 },
    [29] = { id = 232121, name = "Phalanx Breaker", displayId = 88968 },
    [30] = { id = 232446, name = "Haunting Grunt", displayId = 141117 },
    [31] = { id = 250883, name = "Scouting Trapper", displayId = 139555 },
}

----------------------------------------------------------------
-- dungeonIdx 153 = Magisters Terrace
----------------------------------------------------------------
ns.DungeonEnemies[153] = {
    [1]  = { id = 232369, name = "Arcane Magister", displayId = 138454 },
    [2]  = { id = 234089, name = "Animated Codex", displayId = 125911 },
    [3]  = { id = 251861, name = "Blazing Pyromancer", displayId = 138460 },
    [4]  = { id = 240973, name = "Runed Spellbreaker", displayId = 127769 },
    [5]  = { id = 234069, name = "Voidling", displayId = 127714 },
    [6]  = { id = 234065, name = "Hollowsoul Shredder", displayId = 60660 },
    [7]  = { id = 234064, name = "Dreaded Voidwalker", displayId = 93869 },
    [8]  = { id = 234068, name = "Shadowrift Voidcaller", displayId = 138102 },
    [9]  = { id = 234066, name = "Devouring Tyrant", displayId = 136220 },
    [10] = { id = 249086, name = "Void Infuser", displayId = 92689 },
    [11] = { id = 231861, name = "Arcanotron Custos", displayId = 131334 },
    [12] = { id = 231863, name = "Seranel Sunlash", displayId = 127739 },
    [13] = { id = 231864, name = "Gemellus", displayId = 131317 },
    [14] = { id = 231865, name = "Degentrius", displayId = 132031 },
    [15] = { id = 232106, name = "Brightscale Wyrm", displayId = 16217 },
    [16] = { id = 234062, name = "Arcane Sentry", displayId = 137562 },
    [17] = { id = 234067, name = "Vigilant Librarian", displayId = 138458 },
    [18] = { id = 234124, name = "Sunblade Enforcer", displayId = 138453 },
    [19] = { id = 234486, name = "Lightward Healer", displayId = 138455 },
    [20] = { id = 239636, name = "Gemellus", displayId = 141672 },
    [21] = { id = 241354, name = "Void-Infused Brightscale", displayId = 127897 },
    [22] = { id = 241397, name = "Celestial Drifter", displayId = 98834 },
    [23] = { id = 255376, name = "Unstable Voidling", displayId = 127714 },
    [24] = { id = 257447, name = "Hollowsoul Shredder", displayId = 60660 },
    [25] = { id = 259387, name = "Spellwoven Familiar", displayId = 141476 },
}

----------------------------------------------------------------
-- dungeonIdx 154 = Maisara Caverns
----------------------------------------------------------------
ns.DungeonEnemies[154] = {
    [1]  = { id = 248684, name = "Frenzied Berserker", displayId = 131683 },
    [2]  = { id = 242964, name = "Keen Headhunter", displayId = 131701 },
    [3]  = { id = 248686, name = "Dread Souleater", displayId = 130882 },
    [4]  = { id = 248685, name = "Ritual Hexxer", displayId = 131690 },
    [5]  = { id = 249020, name = "Hexbound Eagle", displayId = 142403 },
    [6]  = { id = 253302, name = "Hex Guardian", displayId = 169 },
    [7]  = { id = 249002, name = "Warding Mask", displayId = 169 },
    [8]  = { id = 249022, name = "Bramblemaw Bear", displayId = 71577 },
    [9]  = { id = 248693, name = "Mire Laborer", displayId = 130872 },
    [10] = { id = 248678, name = "Hulking Juggernaut", displayId = 100959 },
    [11] = { id = 254740, name = "Umbral Shadowbinder", displayId = 131719 },
    [12] = { id = 249030, name = "Restless Gnarldin", displayId = 124058 },
    [13] = { id = 248692, name = "Reanimated Warrior", displayId = 125076 },
    [14] = { id = 248690, name = "Grim Skirmisher", displayId = 125075 },
    [15] = { id = 249036, name = "Tormented Shade", displayId = 131722 },
    [16] = { id = 253683, name = "Rokh'zal", displayId = 138664 },
    [17] = { id = 249025, name = "Bound Defender", displayId = 125072 },
    [18] = { id = 249024, name = "Hollow Soulrender", displayId = 125074 },
    [19] = { id = 247570, name = "Muro'jin", displayId = 130699 },
    [20] = { id = 247572, name = "Nekraxx", displayId = 130705 },
    [21] = { id = 248595, name = "Vordaza", displayId = 131548 },
    [22] = { id = 248605, name = "Rak'tul", displayId = 131550 },
    [23] = { id = 250443, name = "Unstable Phantom", displayId = 140143 },
    [24] = { id = 251047, name = "Soulbind Totem", displayId = 137911 },
    [25] = { id = 251639, name = "Lost Soul", displayId = 140143 },
    [26] = { id = 251674, name = "Malignant Soul", displayId = 137163 },
    [27] = { id = 252886, name = "Potatoad", displayId = 138434 },
    [28] = { id = 253458, name = "Zil'jan", displayId = 131679 },
    [29] = { id = 253473, name = "Gloomwing Bat", displayId = 114972 },
    [30] = { id = 253647, name = "Lost Soul", displayId = 140110 },
    [31] = { id = 253701, name = "Death's Grasp", displayId = 169 },
    [32] = { id = 254233, name = "Rokh'zal", displayId = 138234 },
}

----------------------------------------------------------------
-- dungeonIdx 155 = Nexus Point Xenas
----------------------------------------------------------------
ns.DungeonEnemies[155] = {
    [1]  = { id = 241643, name = "Shadowguard Defender", displayId = 131485 },
    [2]  = { id = 248501, name = "Reformed Voidling", displayId = 131529 },
    [3]  = { id = 241644, name = "Corewright Arcanist", displayId = 131625 },
    [4]  = { id = 241645, name = "Hollowsoul Scrounger", displayId = 131528 },
    [5]  = { id = 241647, name = "Flux Engineer", displayId = 131487 },
    [6]  = { id = 248708, name = "Nexus Adept", displayId = 131532 },
    [7]  = { id = 248373, name = "Circuit Seer", displayId = 131484 },
    [8]  = { id = 248706, name = "Cursed Voidcaller", displayId = 131624 },
    [9]  = { id = 248506, name = "Dreadflail", displayId = 131531 },
    [10] = { id = 241660, name = "Duskfright Herald", displayId = 131525 },
    [11] = { id = 251853, name = "Grand Nullifier", displayId = 137240 },
    [12] = { id = 248502, name = "Null Sentinel", displayId = 131526 },
    [13] = { id = 241642, name = "Lingering Image", displayId = 140945 },
    [14] = { id = 254932, name = "Radiant Swarm", displayId = 52309 },
    [15] = { id = 254926, name = "Lightwrought", displayId = 140804 },
    [16] = { id = 254928, name = "Flarebat", displayId = 138559 },
    [17] = { id = 241539, name = "Kasreth", displayId = 131510 },
    [18] = { id = 241542, name = "Corewarden Nysarra", displayId = 131511 },
    [19] = { id = 241546, name = "Lothraxion", displayId = 137705 },
    [20] = { id = 248769, name = "Smudge", displayId = 141002 },
    [21] = { id = 250299, name = "[DNT] Conduit Stalker", displayId = 169 },
    [22] = { id = 251024, name = "Null Guardian", displayId = 131531 },
    [23] = { id = 251031, name = "Wretched Supplicant", displayId = 137240 },
    [24] = { id = 251568, name = "Fractured Image", displayId = 136110 },
    [25] = { id = 251852, name = "Nullifier", displayId = 137251 },
    [26] = { id = 251878, name = "Voidcaller", displayId = 137240 },
    [27] = { id = 252825, name = "Mana Battery", displayId = 137629 },
    [28] = { id = 252852, name = "Corespark Conduit", displayId = 138268 },
    [29] = { id = 254227, name = "Corewarden Nysarra", displayId = 131511 },
    [30] = { id = 254459, name = "Broken Pipe", displayId = 169 },
    [31] = { id = 254485, name = "Corespark Pylon", displayId = 169 },
    [32] = { id = 255179, name = "Fractured Image", displayId = 140945 },
    [33] = { id = 259569, name = "Mana Battery", displayId = 137629 },
    [34] = { id = 249711, name = "Core Technician", displayId = 132030 },
}

----------------------------------------------------------------
-- dungeonIdx 160 = Murder Row (no enemy data yet)
----------------------------------------------------------------
ns.DungeonEnemies[160] = {}
