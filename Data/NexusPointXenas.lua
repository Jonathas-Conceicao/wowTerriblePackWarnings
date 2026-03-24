local addonName, ns = ...

ns.AbilityDB = ns.AbilityDB or {}

-- Nexus Point Xenas ability database
-- Keyed by npcID
-- mobCategory: semantic role — "boss"|"miniboss"|"caster"|"warrior"|"rogue"|"trivial"|"unknown"
--   (not to be confused with the runtime WoW class token e.g. "WARRIOR"; that is never stored here)

-- Shadowguard Defender (241643)
ns.AbilityDB[241643] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1249645, defaultEnabled = false },
        { spellID = 1252218, defaultEnabled = false },
        { spellID = 1282745, defaultEnabled = false },
    },
}

-- Reformed Voidling (248501)
ns.AbilityDB[248501] = {
    mobCategory = "trivial",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1252218, defaultEnabled = false },
    },
}

-- Corewright Arcanist (241644)
ns.AbilityDB[241644] = {
    mobCategory = "caster",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1249815, defaultEnabled = false },
        { spellID = 1249818, defaultEnabled = false },
        { spellID = 1252218, defaultEnabled = false },
        { spellID = 1277451, defaultEnabled = false },
        { spellID = 1278882, defaultEnabled = false },
        { spellID = 1285445, defaultEnabled = false },
        { spellID = 1285450, defaultEnabled = false },
    },
}

-- Hollowsoul Scrounger (241645)
ns.AbilityDB[241645] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1227020, defaultEnabled = false },
        { spellID = 1252204, defaultEnabled = false },
        { spellID = 1252218, defaultEnabled = false },
    },
}

-- Flux Engineer (241647)
ns.AbilityDB[241647] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1257124, defaultEnabled = false },
        { spellID = 1269283, defaultEnabled = false },
        { spellID = 1282950, defaultEnabled = false },
    },
}

-- Nexus Adept (248708)
ns.AbilityDB[248708] = {
    mobCategory = "trivial",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1271094, defaultEnabled = false },
    },
}

-- Circuit Seer (248373)
ns.AbilityDB[248373] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1249801, defaultEnabled = false },
        { spellID = 1249806, defaultEnabled = false },
        { spellID = 1257100, defaultEnabled = false },
        { spellID = 1257103, defaultEnabled = false },
        { spellID = 1257105, defaultEnabled = false },
    },
}

-- Cursed Voidcaller (248706)
ns.AbilityDB[248706] = {
    mobCategory = "trivial",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1252218, defaultEnabled = false },
        { spellID = 1281636, defaultEnabled = false },
    },
}

-- Dreadflail (248506)
ns.AbilityDB[248506] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1252218, defaultEnabled = false },
        { spellID = 1252436, defaultEnabled = false },
        { spellID = 1252437, defaultEnabled = false },
        { spellID = 1252438, defaultEnabled = false },
        { spellID = 1252621, defaultEnabled = false },
        { spellID = 1252622, defaultEnabled = false },
        { spellID = 1252628, defaultEnabled = false },
    },
}

-- Duskfright Herald (241660)
ns.AbilityDB[241660] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1252062, defaultEnabled = false },
        { spellID = 1252076, defaultEnabled = false },
        { spellID = 1252134, defaultEnabled = false },
        { spellID = 1254096, defaultEnabled = false },
        { spellID = 1259359, defaultEnabled = false },
    },
}

-- Grand Nullifier (251853)
ns.AbilityDB[251853] = {
    mobCategory = "caster",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1252218, defaultEnabled = false },
        { spellID = 1258681, defaultEnabled = false },
        { spellID = 1258684, defaultEnabled = false },
        { spellID = 1281634, defaultEnabled = false },
        { spellID = 1281637, defaultEnabled = false },
        { spellID = 1264295, defaultEnabled = false },
    },
}

-- Null Sentinel (248502)
ns.AbilityDB[248502] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1252218, defaultEnabled = false },
        { spellID = 1252406, defaultEnabled = false },
        { spellID = 1252414, defaultEnabled = false },
        { spellID = 1252417, defaultEnabled = false },
        { spellID = 1252429, defaultEnabled = false },
    },
}

-- Lingering Image (241642)
ns.AbilityDB[241642] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1257701, defaultEnabled = false },
        { spellID = 1257736, defaultEnabled = false },
        { spellID = 1257745, defaultEnabled = false },
        { spellID = 1257746, defaultEnabled = false },
        { spellID = 1264354, defaultEnabled = false },
        { spellID = 1281657, defaultEnabled = false },
    },
}

-- Radiant Swarm (254932)
ns.AbilityDB[254932] = {
    mobCategory = "trivial",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1263775, defaultEnabled = false },
        { spellID = 1282944, defaultEnabled = false },
    },
}

-- Lightwrought (254926)
ns.AbilityDB[254926] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1263892, defaultEnabled = false },
        { spellID = 1277557, defaultEnabled = false },
    },
}

-- Flarebat (254928)
ns.AbilityDB[254928] = {
    mobCategory = "trivial",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1263783, defaultEnabled = false },
        { spellID = 1263785, defaultEnabled = false },
    },
}

-- Kasreth (241539)
ns.AbilityDB[241539] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1250553, defaultEnabled = false },
        { spellID = 1251626, defaultEnabled = false },
        { spellID = 1251767, defaultEnabled = false },
        { spellID = 1251772, defaultEnabled = false },
        { spellID = 1257509, defaultEnabled = false },
        { spellID = 1257512, defaultEnabled = false },
        { spellID = 1257524, defaultEnabled = false },
        { spellID = 1264040, defaultEnabled = false },
        { spellID = 1264042, defaultEnabled = false },
        { spellID = 1264048, defaultEnabled = false },
        { spellID = 1265894, defaultEnabled = false },
        { spellID = 1276485, defaultEnabled = false },
        { spellID = 1282915, defaultEnabled = false },
    },
}

-- Corewarden Nysarra (241542)
ns.AbilityDB[241542] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1247937, defaultEnabled = false },
        { spellID = 1248007, defaultEnabled = false },
        { spellID = 1249014, defaultEnabled = false },
        { spellID = 1249027, defaultEnabled = false },
        { spellID = 1252875, defaultEnabled = false },
        { spellID = 1252883, defaultEnabled = false },
        { spellID = 1254096, defaultEnabled = false },
        { spellID = 1259359, defaultEnabled = false },
        { spellID = 1271433, defaultEnabled = false },
    },
}

-- Lothraxion (241546)
ns.AbilityDB[241546] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1253855, defaultEnabled = false },
        { spellID = 1253950, defaultEnabled = false },
        { spellID = 1255208, defaultEnabled = false },
        { spellID = 1255310, defaultEnabled = false },
        { spellID = 1255335, defaultEnabled = false },
        { spellID = 1255503, defaultEnabled = false },
        { spellID = 1257595, defaultEnabled = false },
        { spellID = 1257613, defaultEnabled = false },
        { spellID = 1271511, defaultEnabled = false },
        { spellID = 1282791, defaultEnabled = false },
    },
}

-- Smudge (248769)
ns.AbilityDB[248769] = {
    mobCategory = "trivial",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1257268, defaultEnabled = false },
    },
}

-- [DNT] Conduit Stalker (250299)
ns.AbilityDB[250299] = {
    mobCategory = "unknown",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1251579, defaultEnabled = false },
    },
}

-- Null Guardian (251024)
ns.AbilityDB[251024] = {
    mobCategory = "unknown",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1282663, defaultEnabled = false },
        { spellID = 1282664, defaultEnabled = false },
        { spellID = 1282665, defaultEnabled = false },
        { spellID = 1282678, defaultEnabled = false },
        { spellID = 1282679, defaultEnabled = false },
    },
}

-- Wretched Supplicant (251031)
ns.AbilityDB[251031] = {
    mobCategory = "unknown",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1282722, defaultEnabled = false },
        { spellID = 1282723, defaultEnabled = false },
    },
}

-- Fractured Image (251568)
ns.AbilityDB[251568] = {
    mobCategory = "unknown",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1255310, defaultEnabled = false },
        { spellID = 1255533, defaultEnabled = false },
        { spellID = 1257601, defaultEnabled = false },
        { spellID = 1269220, defaultEnabled = false },
        { spellID = 1269222, defaultEnabled = false },
        { spellID = 1271956, defaultEnabled = false },
    },
}

-- Core Technician (249711)
ns.AbilityDB[249711] = { mobCategory = "unknown", abilities = {} }

-- Nullifier (251852)
ns.AbilityDB[251852] = { mobCategory = "unknown", abilities = {} }

-- Voidcaller (251878)
ns.AbilityDB[251878] = {
    mobCategory = "unknown",  -- semantic role; see header for vocabulary
    abilities = {},
}

-- Mana Battery (252825)
ns.AbilityDB[252825] = {
    mobCategory = "trivial",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1257126, defaultEnabled = false },
    },
}

-- Corespark Conduit (252852)
ns.AbilityDB[252852] = {
    mobCategory = "unknown",  -- semantic role; see header for vocabulary
    abilities = {},
}

-- Corewarden Nysarra (254227)
ns.AbilityDB[254227] = {
    mobCategory = "unknown",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1271388, defaultEnabled = false },
    },
}

-- Broken Pipe (254459)
ns.AbilityDB[254459] = {
    mobCategory = "unknown",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1262088, defaultEnabled = false },
        { spellID = 1262630, defaultEnabled = false },
    },
}

-- Corespark Pylon (254485)
ns.AbilityDB[254485] = {
    mobCategory = "unknown",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1262084, defaultEnabled = false },
        { spellID = 1262088, defaultEnabled = false },
        { spellID = 1262630, defaultEnabled = false },
    },
}

-- Fractured Image (255179)
ns.AbilityDB[255179] = {
    mobCategory = "unknown",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1264429, defaultEnabled = false },
        { spellID = 1265984, defaultEnabled = false },
    },
}

-- Mana Battery (259569)
ns.AbilityDB[259569] = {
    mobCategory = "unknown",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1257126, defaultEnabled = false },
    },
}
