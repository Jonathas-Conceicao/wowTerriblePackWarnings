local addonName, ns = ...

ns.AbilityDB = ns.AbilityDB or {}

-- Pit of Saron ability database
-- Keyed by npcID
-- mobCategory: semantic role — "boss"|"miniboss"|"caster"|"warrior"|"rogue"|"trivial"|"unknown"
--   (not to be confused with the runtime WoW class token e.g. "WARRIOR"; that is never stored here)

-- Deathwhisper Necrolyte (252551)
ns.AbilityDB[252551] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1258448, defaultEnabled = false },
    },
}

-- Risen Soldier (252602)
ns.AbilityDB[252602] = {
    mobCategory = "trivial",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1258451, defaultEnabled = false },
    },
}

-- Arcanist Cadaver (252603)
ns.AbilityDB[252603] = {
    mobCategory = "trivial",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1258448, defaultEnabled = false },
        { spellID = 1271479, defaultEnabled = false },
    },
}

-- Gloombound Shadebringer (252567)
ns.AbilityDB[252567] = {
    mobCategory = "caster",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1258431, defaultEnabled = false },
    },
}

-- Quarry Tormentor (252561)
ns.AbilityDB[252561] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1258433, defaultEnabled = false },
        { spellID = 1258434, defaultEnabled = false },
    },
}

-- Dreadpulse Lich (252563)
ns.AbilityDB[252563] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1258798, defaultEnabled = false },
        { spellID = 1258802, defaultEnabled = false },
        { spellID = 1258820, defaultEnabled = false },
        { spellID = 1258826, defaultEnabled = false },
        { spellID = 1271074, defaultEnabled = false },
    },
}

-- Rotting Ghoul (252558)
ns.AbilityDB[252558] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1258459, defaultEnabled = false },
    },
}

-- Ymirjar Graveblade (252610)
ns.AbilityDB[252610] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1258439, defaultEnabled = false },
        { spellID = 1258445, defaultEnabled = false },
        { spellID = 1278950, defaultEnabled = false },
        { spellID = 1278963, defaultEnabled = false },
        { spellID = 1278967, defaultEnabled = false },
    },
}

-- Leaping Geist (252559)
ns.AbilityDB[252559] = {
    mobCategory = "trivial",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1258464, defaultEnabled = false },
    },
}

-- Mindless Laborer (252557)
ns.AbilityDB[252557] = { mobCategory = "trivial", abilities = {} }

-- Plungetalon Gargoyle (252606)
ns.AbilityDB[252606] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1258997, defaultEnabled = false },
        { spellID = 1271543, defaultEnabled = false },
    },
}

-- Lumbering Plaguehorror (252555)
ns.AbilityDB[252555] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1259116, defaultEnabled = false },
        { spellID = 1259132, defaultEnabled = false },
    },
}

-- Iceborn Proto-Drake (257190)
ns.AbilityDB[257190] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1271009, defaultEnabled = false },
        { spellID = 1278986, defaultEnabled = false },
    },
}

-- Wrathbone Enforcer (252565)
ns.AbilityDB[252565] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1258435, defaultEnabled = false },
    },
}

-- Rimebone Coldwraith (252566)
ns.AbilityDB[252566] = {
    mobCategory = "caster",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1258436, defaultEnabled = false },
        { spellID = 1258437, defaultEnabled = false },
    },
}

-- Glacieth (252564)
ns.AbilityDB[252564] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1259188, defaultEnabled = false },
        { spellID = 1259202, defaultEnabled = false },
        { spellID = 1259205, defaultEnabled = false },
        { spellID = 1259226, defaultEnabled = false },
        { spellID = 1278754, defaultEnabled = false },
    },
}

-- Krick (252621)
ns.AbilityDB[252621] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1264027, defaultEnabled = false },
        { spellID = 1264246, defaultEnabled = false },
        { spellID = 1264363, defaultEnabled = false },
        { spellID = 1278893, defaultEnabled = false },
        { spellID = 1279667, defaultEnabled = false },
        { spellID = 1279668, defaultEnabled = false },
    },
}

-- Ick (252625)
ns.AbilityDB[252625] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1264287, defaultEnabled = false },
        { spellID = 1264299, defaultEnabled = false },
        { spellID = 1264336, defaultEnabled = false },
        { spellID = 1264349, defaultEnabled = false },
        { spellID = 1264453, defaultEnabled = false },
        { spellID = 1264461, defaultEnabled = false },
    },
}

-- Forgemaster Garfrost (252635)
ns.AbilityDB[252635] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1261299, defaultEnabled = false },
        { spellID = 1261315, defaultEnabled = false },
        { spellID = 1261546, defaultEnabled = false },
        { spellID = 1261799, defaultEnabled = false },
        { spellID = 1261806, defaultEnabled = false },
        { spellID = 1261808, defaultEnabled = false },
        { spellID = 1261847, defaultEnabled = false },
        { spellID = 1261921, defaultEnabled = false },
        { spellID = 1262029, defaultEnabled = false },
        { spellID = 1272433, defaultEnabled = false },
    },
}

-- Scourgelord Tyrannus (252648)
ns.AbilityDB[252648] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1262582, defaultEnabled = false },
        { spellID = 1262596, defaultEnabled = false },
        { spellID = 1263406, defaultEnabled = false },
        { spellID = 1263671, defaultEnabled = false },
        { spellID = 1263756, defaultEnabled = false },
        { spellID = 1263766, defaultEnabled = false },
        { spellID = 1276648, defaultEnabled = false },
    },
}

-- Rimefang (252653)
ns.AbilityDB[252653] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1262739, defaultEnabled = false },
        { spellID = 1262745, defaultEnabled = false },
        { spellID = 1262750, defaultEnabled = false },
        { spellID = 1263716, defaultEnabled = false },
        { spellID = 1276948, defaultEnabled = false },
        { spellID = 1276973, defaultEnabled = false },
    },
}

-- Rotling (254684)
ns.AbilityDB[254684] = {
    mobCategory = "trivial",  -- semantic role; see header for vocabulary
    abilities = {},
}

-- Scourge Plaguespreader (254691)
ns.AbilityDB[254691] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1262941, defaultEnabled = false },
        { spellID = 1263000, defaultEnabled = false },
    },
}

-- Shade of Krick (255037)
ns.AbilityDB[255037] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1264186, defaultEnabled = false },
        { spellID = 1271678, defaultEnabled = false },
    },
}
