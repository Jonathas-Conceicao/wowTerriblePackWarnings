local addonName, ns = ...

ns.AbilityDB = ns.AbilityDB or {}

-- Windrunner Spire ability database
-- Keyed by npcID
-- mobCategory: semantic role — "boss"|"miniboss"|"caster"|"warrior"|"rogue"|"trivial"|"unknown"
--   (not to be confused with the runtime WoW class token e.g. "WARRIOR"; that is never stored here)

-- Restless Steward (232070)
ns.AbilityDB[232070] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1216135, defaultEnabled = false },
        { spellID = 1216298, defaultEnabled = false },
        { spellID = 1253700, defaultEnabled = false },
    },
}

-- Dutiful Groundskeeper (232071)
ns.AbilityDB[232071] = { mobCategory = "warrior", abilities = {} }

-- Spellguard Magus (232113)
ns.AbilityDB[232113] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1216250, defaultEnabled = false },
        { spellID = 1216253, defaultEnabled = false },
        { spellID = 1253683, defaultEnabled = false },
        { spellID = 1253686, defaultEnabled = false },
    },
}

-- Windrunner Soldier (232116)
ns.AbilityDB[232116] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1216462, defaultEnabled = false },
    },
}

-- Fervent Apothecary (232173)
ns.AbilityDB[232173] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 473644, defaultEnabled = false },
        { spellID = 473647, defaultEnabled = false },
        { spellID = 473649, defaultEnabled = false },
    },
}

-- Ardent Cutthroat (232171)
ns.AbilityDB[232171] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 473794, defaultEnabled = false },
        { spellID = 473795, defaultEnabled = false },
        { spellID = 473864, defaultEnabled = false },
        { spellID = 473868, defaultEnabled = false },
    },
}

-- Zealous Reaver (232232)
ns.AbilityDB[232232] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 473640, defaultEnabled = false },
    },
}

-- Devoted Woebringer (232175)
ns.AbilityDB[232175] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 473657, defaultEnabled = false },
        { spellID = 473663, defaultEnabled = false },
        { spellID = 473668, defaultEnabled = false },
        { spellID = 473672, defaultEnabled = false },
    },
}

-- Flesh Behemoth (232176)
ns.AbilityDB[232176] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 473776, defaultEnabled = false },
        { spellID = 473786, defaultEnabled = false },
        { spellID = 473789, defaultEnabled = false },
        { spellID = 1277799, defaultEnabled = false },
    },
}

-- Territorial Dragonhawk (232056)
ns.AbilityDB[232056] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1216848, defaultEnabled = false },
        { spellID = 1216860, defaultEnabled = false },
        { spellID = 1266745, defaultEnabled = false },
    },
}

-- Spindleweb Hatchling (234673)
ns.AbilityDB[234673] = {
    mobCategory = "trivial",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1216834, defaultEnabled = false },
    },
}

-- Creeping Spindleweb (232067)
ns.AbilityDB[232067] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1216822, defaultEnabled = false },
        { spellID = 1216825, defaultEnabled = false },
        { spellID = 1216834, defaultEnabled = false },
    },
}

-- Apex Lynx (232063)
ns.AbilityDB[232063] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1216985, defaultEnabled = false },
        { spellID = 1217010, defaultEnabled = false },
        { spellID = 1217021, defaultEnabled = false },
    },
}

-- Pesty Lashling (238099)
ns.AbilityDB[238099] = {
    mobCategory = "trivial",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1277761, defaultEnabled = false },
    },
}

-- Bloated Lasher (236894)
ns.AbilityDB[236894] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1216819, defaultEnabled = false },
        { spellID = 1216963, defaultEnabled = false },
    },
}

-- Swiftshot Archer (232119)
ns.AbilityDB[232119] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1216419, defaultEnabled = false },
        { spellID = 1216449, defaultEnabled = false },
        { spellID = 1216454, defaultEnabled = false },
    },
}

-- Phalanx Breaker (232122)
ns.AbilityDB[232122] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 471643, defaultEnabled = false },
        { spellID = 471648, defaultEnabled = false },
        { spellID = 471650, defaultEnabled = false },
    },
}

-- Loyal Worg (232283)
ns.AbilityDB[232283] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1253739, defaultEnabled = false },
    },
}

-- Lingering Marauder (232147)
ns.AbilityDB[232147] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1216637, defaultEnabled = false },
        { spellID = 1216643, defaultEnabled = false },
    },
}

-- Spectral Axethrower (232148)
ns.AbilityDB[232148] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 468659, defaultEnabled = false },
    },
}

-- Phantasmal Mystic (232146)
ns.AbilityDB[232146] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1216459, defaultEnabled = false },
        { spellID = 1216592, defaultEnabled = false },
        { spellID = 1270618, defaultEnabled = false },
    },
}

-- Emberdawn (231606)
ns.AbilityDB[231606] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 465904, defaultEnabled = false },
        { spellID = 466064, defaultEnabled = false },
        { spellID = 466091, defaultEnabled = false },
        { spellID = 466556, defaultEnabled = false },
        { spellID = 466559, defaultEnabled = false },
        { spellID = 467040, defaultEnabled = false },
        { spellID = 1217763, defaultEnabled = false },
        { spellID = 1217795, defaultEnabled = false },
        { spellID = 1252548, defaultEnabled = false },
    },
}

-- Kalis (231626)
ns.AbilityDB[231626] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 472724, defaultEnabled = false },
        { spellID = 472736, defaultEnabled = false },
        { spellID = 474105, defaultEnabled = false },
        { spellID = 1219491, defaultEnabled = false },
        { spellID = 1219551, defaultEnabled = false },
    },
}

-- Latch (231629)
ns.AbilityDB[231629] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 472745, defaultEnabled = false },
        { spellID = 472758, defaultEnabled = false },
        { spellID = 472777, defaultEnabled = false },
        { spellID = 472795, defaultEnabled = false },
        { spellID = 472888, defaultEnabled = false },
        { spellID = 474065, defaultEnabled = false },
        { spellID = 474075, defaultEnabled = false },
        { spellID = 1219551, defaultEnabled = false },
        { spellID = 1282272, defaultEnabled = false },
    },
}

-- Commander Kroluk (231631)
ns.AbilityDB[231631] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 467620, defaultEnabled = false },
        { spellID = 467621, defaultEnabled = false },
        { spellID = 468221, defaultEnabled = false },
        { spellID = 468924, defaultEnabled = false },
        { spellID = 470963, defaultEnabled = false },
        { spellID = 471038, defaultEnabled = false },
        { spellID = 472043, defaultEnabled = false },
        { spellID = 472053, defaultEnabled = false },
        { spellID = 472054, defaultEnabled = false },
        { spellID = 472081, defaultEnabled = false },
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

-- Restless Heart (231636)
ns.AbilityDB[231636] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 468429, defaultEnabled = false },
        { spellID = 468442, defaultEnabled = false },
        { spellID = 472556, defaultEnabled = false },
        { spellID = 472662, defaultEnabled = false },
        { spellID = 472672, defaultEnabled = false },
        { spellID = 474528, defaultEnabled = false },
        { spellID = 1216042, defaultEnabled = false },
        { spellID = 1253977, defaultEnabled = false },
        { spellID = 1253978, defaultEnabled = false },
        { spellID = 1253986, defaultEnabled = false },
        { spellID = 1283371, defaultEnabled = false },
    },
}

-- Flaming Updraft (232118)
ns.AbilityDB[232118] = {
    mobCategory = "unknown",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 465957, defaultEnabled = false },
        { spellID = 467120, defaultEnabled = false },
        { spellID = 470212, defaultEnabled = false },
        { spellID = 472118, defaultEnabled = false },
    },
}

-- Phalanx Breaker (232121)
ns.AbilityDB[232121] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1282478, defaultEnabled = false },
    },
}

-- Haunting Grunt (232446)
ns.AbilityDB[232446] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 467815, defaultEnabled = false },
    },
}

-- Scouting Trapper (250883)
ns.AbilityDB[250883] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1219224, defaultEnabled = false },
        { spellID = 1219266, defaultEnabled = false },
    },
}

-- Scouting Trapper (238049)
ns.AbilityDB[238049] = { mobCategory = "warrior", abilities = {} }
