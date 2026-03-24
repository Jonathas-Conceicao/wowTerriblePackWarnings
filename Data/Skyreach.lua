local addonName, ns = ...

ns.AbilityDB = ns.AbilityDB or {}

-- Skyreach ability database
-- Keyed by npcID
-- mobCategory: semantic role — "boss"|"miniboss"|"caster"|"warrior"|"rogue"|"trivial"|"unknown"
--   (not to be confused with the runtime WoW class token e.g. "WARRIOR"; that is never stored here)

-- Soaring Chakram Master (76132)
ns.AbilityDB[76132] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1254666, defaultEnabled = false },
    },
}

-- Driving Gale-Caller (78932)
ns.AbilityDB[78932] = {
    mobCategory = "caster",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1255377, defaultEnabled = false },
    },
}

-- Raging Squall (250992)
ns.AbilityDB[250992] = {
    mobCategory = "rogue",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1254676, defaultEnabled = false },
        { spellID = 1254677, defaultEnabled = false },
        { spellID = 1254678, defaultEnabled = false },
        { spellID = 1254679, defaultEnabled = false },
        { spellID = 1255922, defaultEnabled = false },
    },
}

-- Outcast Servant (75976) -- in DungeonEnemies, no tracked abilities
ns.AbilityDB[75976] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {},
}

-- Blinding Sun Priestess (79462)
ns.AbilityDB[79462] = {
    mobCategory = "caster",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 152953, defaultEnabled = false },
        { spellID = 1273356, defaultEnabled = false },
    },
}

-- Initiate of the Rising Sun (79466)
ns.AbilityDB[79466] = {
    mobCategory = "caster",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1254669, defaultEnabled = false },
    },
}

-- Adept of the Dawn (79467)
ns.AbilityDB[79467] = {
    mobCategory = "caster",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1254671, defaultEnabled = false },
        { spellID = 1254672, defaultEnabled = false },
    },
}

-- Herald of Sunrise (78933)
ns.AbilityDB[78933] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1254355, defaultEnabled = false },
        { spellID = 1258217, defaultEnabled = false },
        { spellID = 1258220, defaultEnabled = false },
    },
}

-- Solar Construct (76087)
ns.AbilityDB[76087] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1253446, defaultEnabled = false },
        { spellID = 1253448, defaultEnabled = false },
    },
}

-- Skyreach Sun Talon (79093)
ns.AbilityDB[79093] = {
    mobCategory = "trivial",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1254689, defaultEnabled = false },
        { spellID = 1254690, defaultEnabled = false },
    },
}

-- Sun Talon Tamer (76154)
ns.AbilityDB[76154] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1254686, defaultEnabled = false },
        { spellID = 1254687, defaultEnabled = false },
    },
}

-- Ranjit (75964)
ns.AbilityDB[75964] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 153757, defaultEnabled = false },
        { spellID = 156793, defaultEnabled = false },
        { spellID = 1252690, defaultEnabled = false },
        { spellID = 1252691, defaultEnabled = false },
        { spellID = 1252733, defaultEnabled = false },
        { spellID = 1255472, defaultEnabled = false },
        { spellID = 1258140, defaultEnabled = false },
        { spellID = 1258152, defaultEnabled = false },
        { spellID = 1258160, defaultEnabled = false },
        { spellID = 1281396, defaultEnabled = false },
    },
}

-- Araknath (76141)
ns.AbilityDB[76141] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 154110, defaultEnabled = false },
        { spellID = 154113, defaultEnabled = false },
        { spellID = 154132, defaultEnabled = false },
        { spellID = 154135, defaultEnabled = false },
        { spellID = 154149, defaultEnabled = false },
        { spellID = 1252877, defaultEnabled = false },
        { spellID = 1258205, defaultEnabled = false },
        { spellID = 1283770, defaultEnabled = false },
    },
}

-- Skyreach Sun Construct Prototype (76142)
ns.AbilityDB[76142] = {
    mobCategory = "unknown",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 154159, defaultEnabled = false },
        { spellID = 1281874, defaultEnabled = false },
        { spellID = 1287905, defaultEnabled = false },
    },
}

-- Rukhran (76143)
ns.AbilityDB[76143] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 159381, defaultEnabled = false },
        { spellID = 159382, defaultEnabled = false },
        { spellID = 1253510, defaultEnabled = false },
        { spellID = 1253519, defaultEnabled = false },
        { spellID = 1253520, defaultEnabled = false },
    },
}

-- Dread Raven (76149)
ns.AbilityDB[76149] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1254566, defaultEnabled = false },
        { spellID = 1254569, defaultEnabled = false },
        { spellID = 1258174, defaultEnabled = false },
    },
}

-- Blooded Bladefeather (76205)
ns.AbilityDB[76205] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1254670, defaultEnabled = false },
    },
}

-- Sunwings (76227)
ns.AbilityDB[76227] = {
    mobCategory = "unknown",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1253367, defaultEnabled = false },
        { spellID = 1253368, defaultEnabled = false },
        { spellID = 1253416, defaultEnabled = false },
        { spellID = 1253511, defaultEnabled = false },
    },
}

-- High Sage Viryx (76266)
ns.AbilityDB[76266] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 153954, defaultEnabled = false },
        { spellID = 154396, defaultEnabled = false },
        { spellID = 1253538, defaultEnabled = false },
        { spellID = 1253840, defaultEnabled = false },
    },
}

-- Arakkoa Magnifying Glass (76285)
ns.AbilityDB[76285] = {
    mobCategory = "unknown",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 154043, defaultEnabled = false },
        { spellID = 1253543, defaultEnabled = false },
    },
}

-- Adorned Bladetalon (79303)
ns.AbilityDB[79303] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1254380, defaultEnabled = false },
        { spellID = 1254460, defaultEnabled = false },
        { spellID = 1254475, defaultEnabled = false },
    },
}

-- Solar Orb (251880)
ns.AbilityDB[251880] = {
    mobCategory = "trivial",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1254329, defaultEnabled = false },
        { spellID = 1254332, defaultEnabled = false },
    },
}
