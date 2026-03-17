local addonName, ns = ...

ns.AbilityDB = ns.AbilityDB or {}

-- Windrunner's Spire ability database
-- Keyed by npcID; mobClass stored per-npc, abilities as array of spell entries
-- Existing hand-authored entries retain full timing/label/TTS data (enabled by default).
-- MDT-reconciled entries added with defaultEnabled = false (not tracked until user enables).

-- 231606 - Emberdawn (boss)
ns.AbilityDB[231606] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 465904,  defaultEnabled = false },
        { spellID = 466064,  defaultEnabled = false },
        { spellID = 466091,  defaultEnabled = false },
        { spellID = 466556,  defaultEnabled = false },
        { spellID = 466559,  defaultEnabled = false },
        { spellID = 467040,  defaultEnabled = false },
        { spellID = 1217763, defaultEnabled = false },
        { spellID = 1217795, defaultEnabled = false },
        { spellID = 1252548, defaultEnabled = false },
    },
}

-- 231626 - Kalis (boss)
ns.AbilityDB[231626] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 472724,  defaultEnabled = false },
        { spellID = 472736,  defaultEnabled = false },
        { spellID = 474105,  defaultEnabled = false },
        { spellID = 1219491, defaultEnabled = false },
        { spellID = 1219551, defaultEnabled = false },
    },
}

-- 231629 - Latch (boss)
ns.AbilityDB[231629] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 472745,  defaultEnabled = false },
        { spellID = 472758,  defaultEnabled = false },
        { spellID = 472777,  defaultEnabled = false },
        { spellID = 472795,  defaultEnabled = false },
        { spellID = 472888,  defaultEnabled = false },
        { spellID = 474065,  defaultEnabled = false },
        { spellID = 474075,  defaultEnabled = false },
        { spellID = 1219551, defaultEnabled = false },
        { spellID = 1282272, defaultEnabled = false },
    },
}

-- 231631 - Commander Kroluk (boss)
ns.AbilityDB[231631] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 467620,  defaultEnabled = false },
        { spellID = 467621,  defaultEnabled = false },
        { spellID = 468221,  defaultEnabled = false },
        { spellID = 468924,  defaultEnabled = false },
        { spellID = 470963,  defaultEnabled = false },
        { spellID = 471038,  defaultEnabled = false },
        { spellID = 472043,  defaultEnabled = false },
        { spellID = 472053,  defaultEnabled = false },
        { spellID = 472054,  defaultEnabled = false },
        { spellID = 472081,  defaultEnabled = false },
        { spellID = 1214874, defaultEnabled = false },
        { spellID = 1250851, defaultEnabled = false },
        { spellID = 1253026, defaultEnabled = false },
        { spellID = 1253270, defaultEnabled = false },
        { spellID = 1253272, defaultEnabled = false },
        { spellID = 1271676, defaultEnabled = false },
        { spellID = 1283335, defaultEnabled = false },
        { spellID = 1283357, defaultEnabled = false },
    },
}

-- 231636 - Restless Heart (boss)
ns.AbilityDB[231636] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 468429,  defaultEnabled = false },
        { spellID = 468442,  defaultEnabled = false },
        { spellID = 472556,  defaultEnabled = false },
        { spellID = 472634,  defaultEnabled = false },
        { spellID = 472662,  defaultEnabled = false },
        { spellID = 472672,  defaultEnabled = false },
        { spellID = 474528,  defaultEnabled = false },
        { spellID = 734277,  defaultEnabled = false },
        { spellID = 1216042, defaultEnabled = false },
        { spellID = 1253977, defaultEnabled = false },
        { spellID = 1253978, defaultEnabled = false },
        { spellID = 1253986, defaultEnabled = false },
        { spellID = 1283371, defaultEnabled = false },
    },
}

-- 232056 - Territorial Dragonhawk
ns.AbilityDB[232056] = {
    mobClass = "WARRIOR",
    abilities = {
        {
            name    = "Fire Spit",
            spellID = 1216848,
            label   = "DMG",
        },
        { spellID = 1216860, defaultEnabled = false },
        { spellID = 1266745, defaultEnabled = false },
    },
}

-- 232063 - Apex Lynx
ns.AbilityDB[232063] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1216985, defaultEnabled = false },
        { spellID = 1217010, defaultEnabled = false },
        { spellID = 1217021, defaultEnabled = false },
    },
}

-- 232067 - Creeping Spindleweb
ns.AbilityDB[232067] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1216822, defaultEnabled = false },
        { spellID = 1216825, defaultEnabled = false },
        { spellID = 1216834, defaultEnabled = false },
    },
}

-- 232070 - Restless Steward
ns.AbilityDB[232070] = {
    mobClass = "WARRIOR",
    abilities = {
        {
            name    = "Spirit Bolt",
            spellID = 1216135,
            label   = "Bolt",
        },
        { spellID = 1216298, defaultEnabled = false },
        { spellID = 1253700, defaultEnabled = false },
    },
}

-- 232113 - Spellguard Magus
ns.AbilityDB[232113] = {
    mobClass = "PALADIN",
    abilities = {
        {
            name       = "Spellguard's Protection",
            spellID    = 1253686,
            first_cast = 50,
            cooldown   = 50,
            label      = "DR",
            ttsMessage = "Shield",
        },
        { spellID = 1216250, defaultEnabled = false },
        { spellID = 1216253, defaultEnabled = false },
        { spellID = 1253683, defaultEnabled = false },
    },
}

-- 232116 - Windrunner Soldier
ns.AbilityDB[232116] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1216462, defaultEnabled = false },
    },
}

-- 232118 - Flaming Updraft
ns.AbilityDB[232118] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 465957, defaultEnabled = false },
        { spellID = 467120, defaultEnabled = false },
        { spellID = 470212, defaultEnabled = false },
        { spellID = 472118, defaultEnabled = false },
    },
}

-- 232119 - Swiftshot Archer
ns.AbilityDB[232119] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1216419, defaultEnabled = false },
        { spellID = 1216449, defaultEnabled = false },
        { spellID = 1216454, defaultEnabled = false },
    },
}

-- 232121 - Phalanx Breaker (variant)
ns.AbilityDB[232121] = {
    mobClass = "PALADIN",
    abilities = {
        {
            name       = "Interrupting Screech",
            spellID    = 471643,
            first_cast = 20,
            cooldown   = 25,
            label      = "Kick",
            ttsMessage = "Stop Casting",
        },
        { spellID = 1282478, defaultEnabled = false },
    },
}

-- 232122 - Phalanx Breaker
ns.AbilityDB[232122] = {
    mobClass = "PALADIN",
    abilities = {
        {
            name       = "Interrupting Screech",
            spellID    = 471643,
            first_cast = 20,
            cooldown   = 25,
            label      = "Kick",
            ttsMessage = "Stop Casting",
        },
        { spellID = 471648, defaultEnabled = false },
        { spellID = 471650, defaultEnabled = false },
    },
}

-- 232146 - Phantasmal Mystic
ns.AbilityDB[232146] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1216459, defaultEnabled = false },
        { spellID = 1216592, defaultEnabled = false },
        { spellID = 1270618, defaultEnabled = false },
    },
}

-- 232147 - Lingering Marauder
ns.AbilityDB[232147] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1216637, defaultEnabled = false },
        { spellID = 1216643, defaultEnabled = false },
    },
}

-- 232148 - Spectral Axethrower
ns.AbilityDB[232148] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 468659, defaultEnabled = false },
    },
}

-- 232171 - Ardent Cutthroat
ns.AbilityDB[232171] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 473794, defaultEnabled = false },
        { spellID = 473795, defaultEnabled = false },
        { spellID = 473864, defaultEnabled = false },
        { spellID = 473868, defaultEnabled = false },
    },
}

-- 232173 - Fervent Apothecary
ns.AbilityDB[232173] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 473644, defaultEnabled = false },
        { spellID = 473647, defaultEnabled = false },
        { spellID = 473649, defaultEnabled = false },
    },
}

-- 232175 - Devoted Woebringer
ns.AbilityDB[232175] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 473657, defaultEnabled = false },
        { spellID = 473663, defaultEnabled = false },
        { spellID = 473668, defaultEnabled = false },
        { spellID = 473672, defaultEnabled = false },
    },
}

-- 232176 - Flesh Behemoth
ns.AbilityDB[232176] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 473776,  defaultEnabled = false },
        { spellID = 473786,  defaultEnabled = false },
        { spellID = 473789,  defaultEnabled = false },
        { spellID = 1277799, defaultEnabled = false },
    },
}

-- 232232 - Zealous Reaver
ns.AbilityDB[232232] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 473640, defaultEnabled = false },
    },
}

-- 232283 - Loyal Worg
ns.AbilityDB[232283] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1253739, defaultEnabled = false },
    },
}

-- 232446 - Haunting Grunt
ns.AbilityDB[232446] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 467815, defaultEnabled = false },
    },
}

-- 234673 - Spindleweb Hatchling
ns.AbilityDB[234673] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1216834, defaultEnabled = false },
    },
}

-- 236891 - (variant, not in MDT — keep unchanged)
ns.AbilityDB[236891] = {
    mobClass = "WARRIOR",
    abilities = {
        {
            name    = "Fire Spit",
            spellID = 1216848,
            label   = "DMG",
        },
    },
}

-- 236894 - Bloated Lasher
ns.AbilityDB[236894] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1216819, defaultEnabled = false },
        { spellID = 1216963, defaultEnabled = false },
    },
}

-- 238049 - Scouting Trapper (variant)
ns.AbilityDB[238049] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1219224, defaultEnabled = false },
    },
}

-- 238099 - Pesty Lashling
ns.AbilityDB[238099] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1277761, defaultEnabled = false },
    },
}
