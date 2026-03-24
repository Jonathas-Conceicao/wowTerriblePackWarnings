local addonName, ns = ...

ns.AbilityDB = ns.AbilityDB or {}

-- Magisters Terrace ability database
-- Keyed by npcID
-- mobCategory: semantic role — "boss"|"miniboss"|"caster"|"warrior"|"rogue"|"trivial"|"unknown"
--   (not to be confused with the runtime WoW class token e.g. "WARRIOR"; that is never stored here)

-- Arcane Magister (232369)
ns.AbilityDB[232369] = {
    mobCategory = "caster",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 468962, defaultEnabled = false },
        { spellID = 468966, defaultEnabled = false },
        { spellID = 1245046, defaultEnabled = false },
    },
}

-- Animated Codex (234089)
ns.AbilityDB[234089] = { mobCategory = "trivial", abilities = {} }

-- Blazing Pyromancer (251861)
ns.AbilityDB[251861] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1254294, defaultEnabled = false },
        { spellID = 1254301, defaultEnabled = false },
        { spellID = 1254336, defaultEnabled = false },
        { spellID = 1254338, defaultEnabled = false },
    },
}

-- Runed Spellbreaker (240973)
ns.AbilityDB[240973] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1244907, defaultEnabled = false },
        { spellID = 1283901, defaultEnabled = false },
        { spellID = 1283905, defaultEnabled = false },
    },
}

-- Voidling (234069)
ns.AbilityDB[234069] = {
    mobCategory = "trivial",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1248229, defaultEnabled = false },
        { spellID = 1255434, defaultEnabled = false },
    },
}

-- Hollowsoul Shredder (234065)
ns.AbilityDB[234065] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1227020, defaultEnabled = false },
        { spellID = 1248229, defaultEnabled = false },
    },
}

-- Dreaded Voidwalker (234064)
ns.AbilityDB[234064] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1248229, defaultEnabled = false },
        { spellID = 1248327, defaultEnabled = false },
    },
}

-- Vigilant Librarian (234067)
ns.AbilityDB[234067] = { mobCategory = "unknown", abilities = {} }

-- Shadowrift Voidcaller (234068)
ns.AbilityDB[234068] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1217087, defaultEnabled = false },
        { spellID = 1255462, defaultEnabled = false },
        { spellID = 1265977, defaultEnabled = false },
    },
}

-- Devouring Tyrant (234066)
ns.AbilityDB[234066] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1248138, defaultEnabled = false },
        { spellID = 1248219, defaultEnabled = false },
        { spellID = 1248229, defaultEnabled = false },
        { spellID = 1264687, defaultEnabled = false },
    },
}

-- Void Infuser (249086)
ns.AbilityDB[249086] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1245068, defaultEnabled = false },
        { spellID = 1248229, defaultEnabled = false },
        { spellID = 1264693, defaultEnabled = false },
    },
}

-- Arcanotron Custos (231861)
ns.AbilityDB[231861] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 474345, defaultEnabled = false },
        { spellID = 474496, defaultEnabled = false },
        { spellID = 1214038, defaultEnabled = false },
        { spellID = 1214081, defaultEnabled = false },
        { spellID = 1243905, defaultEnabled = false },
    },
}

-- Seranel Sunlash (231863)
ns.AbilityDB[231863] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1224903, defaultEnabled = false },
        { spellID = 1225015, defaultEnabled = false },
        { spellID = 1225135, defaultEnabled = false },
        { spellID = 1225193, defaultEnabled = false },
        { spellID = 1225201, defaultEnabled = false },
        { spellID = 1225205, defaultEnabled = false },
        { spellID = 1225792, defaultEnabled = false },
        { spellID = 1225796, defaultEnabled = false },
        { spellID = 1246446, defaultEnabled = false },
        { spellID = 1248689, defaultEnabled = false },
        { spellID = 1271317, defaultEnabled = false },
    },
}

-- Gemellus (231864)
ns.AbilityDB[231864] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1223847, defaultEnabled = false },
        { spellID = 1223936, defaultEnabled = false },
        { spellID = 1224104, defaultEnabled = false },
        { spellID = 1224299, defaultEnabled = false },
        { spellID = 1224401, defaultEnabled = false },
        { spellID = 1253707, defaultEnabled = false },
        { spellID = 1253709, defaultEnabled = false },
        { spellID = 1284954, defaultEnabled = false },
        { spellID = 1284958, defaultEnabled = false },
    },
}

-- Degentrius (231865)
ns.AbilityDB[231865] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1215087, defaultEnabled = false },
        { spellID = 1215897, defaultEnabled = false },
        { spellID = 1269631, defaultEnabled = false },
        { spellID = 1271066, defaultEnabled = false },
        { spellID = 1280113, defaultEnabled = false },
        { spellID = 1280119, defaultEnabled = false },
        { spellID = 1284627, defaultEnabled = false },
        { spellID = 1284633, defaultEnabled = false },
    },
}

-- Brightscale Wyrm (232106)
ns.AbilityDB[232106] = {
    mobCategory = "trivial",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 467068, defaultEnabled = false },
        { spellID = 1254595, defaultEnabled = false },
    },
}

-- Arcane Sentry (234062)
ns.AbilityDB[234062] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 473258, defaultEnabled = false },
        { spellID = 1282050, defaultEnabled = false },
        { spellID = 1282051, defaultEnabled = false },
        { spellID = 1282053, defaultEnabled = false },
        { spellID = 1282055, defaultEnabled = false },
    },
}

-- Sunblade Enforcer (234124)
ns.AbilityDB[234124] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1252910, defaultEnabled = false },
        { spellID = 1253224, defaultEnabled = false },
        { spellID = 1265561, defaultEnabled = false },
    },
}

-- Lightward Healer (234486)
ns.AbilityDB[234486] = {
    mobCategory = "caster",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1254306, defaultEnabled = false },
        { spellID = 1255187, defaultEnabled = false },
    },
}

-- Gemellus (239636)
ns.AbilityDB[239636] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1223936, defaultEnabled = false },
        { spellID = 1224104, defaultEnabled = false },
        { spellID = 1224299, defaultEnabled = false },
        { spellID = 1224401, defaultEnabled = false },
        { spellID = 1253707, defaultEnabled = false },
        { spellID = 1253709, defaultEnabled = false },
        { spellID = 1284954, defaultEnabled = false },
        { spellID = 1284958, defaultEnabled = false },
    },
}

-- Void-Infused Brightscale (241354)
ns.AbilityDB[241354] = {
    mobCategory = "trivial",  -- semantic role; see header for vocabulary
    abilities = {},
}

-- Celestial Drifter (241397)
ns.AbilityDB[241397] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1248015, defaultEnabled = false },
    },
}

-- Unstable Voidling (255376)
ns.AbilityDB[255376] = {
    mobCategory = "trivial",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1248229, defaultEnabled = false },
        { spellID = 1264951, defaultEnabled = false },
    },
}

-- Hollowsoul Shredder (257447)
ns.AbilityDB[257447] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1227020, defaultEnabled = false },
        { spellID = 1248229, defaultEnabled = false },
    },
}

-- Spellwoven Familiar (259387)
ns.AbilityDB[259387] = {
    mobCategory = "caster",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1279994, defaultEnabled = false },
        { spellID = 1279995, defaultEnabled = false },
    },
}
