local addonName, ns = ...

ns.AbilityDB = ns.AbilityDB or {}

-- Algethar Academy ability database
-- Keyed by npcID
-- mobCategory: semantic role — "boss"|"miniboss"|"caster"|"warrior"|"rogue"|"trivial"|"unknown"
--   (not to be confused with the runtime WoW class token e.g. "WARRIOR"; that is never stored here)

-- Corrupted Manafiend (196045)
ns.AbilityDB[196045] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 387523, defaultEnabled = false },
        { spellID = 388862, defaultEnabled = false },
        { spellID = 388863, defaultEnabled = false },
        { spellID = 388866, defaultEnabled = false },
    },
}

-- Spellbound Battleaxe (196577)
ns.AbilityDB[196577] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 387523, defaultEnabled = false },
        { spellID = 388841, defaultEnabled = false },
        { spellID = 1270098, defaultEnabled = false },
    },
}

-- Arcane Ravager (196671)
ns.AbilityDB[196671] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 388940, defaultEnabled = false },
        { spellID = 388942, defaultEnabled = false },
        { spellID = 388957, defaultEnabled = false },
        { spellID = 388958, defaultEnabled = false },
        { spellID = 388976, defaultEnabled = false },
        { spellID = 388982, defaultEnabled = false },
        { spellID = 388984, defaultEnabled = false },
    },
}

-- Arcane Forager (196694)
ns.AbilityDB[196694] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 389054, defaultEnabled = false },
        { spellID = 389055, defaultEnabled = false },
    },
}

-- Unruly Textbook (196044)
ns.AbilityDB[196044] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 387523, defaultEnabled = false },
        { spellID = 388392, defaultEnabled = false },
    },
}

-- Vexamus (194181)
ns.AbilityDB[194181] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 385958, defaultEnabled = false },
        { spellID = 386173, defaultEnabled = false },
        { spellID = 386181, defaultEnabled = false },
        { spellID = 386201, defaultEnabled = false },
        { spellID = 386202, defaultEnabled = false },
        { spellID = 387691, defaultEnabled = false },
        { spellID = 388537, defaultEnabled = false },
        { spellID = 388546, defaultEnabled = false },
        { spellID = 388651, defaultEnabled = false },
    },
}

-- Guardian Sentry (192680)
ns.AbilityDB[192680] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 377912, defaultEnabled = false },
        { spellID = 377991, defaultEnabled = false },
        { spellID = 378003, defaultEnabled = false },
        { spellID = 378011, defaultEnabled = false },
    },
}

-- Territorial Eagle (192329)
ns.AbilityDB[192329] = {
    mobCategory = "trivial",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 377344, defaultEnabled = false },
        { spellID = 377389, defaultEnabled = false },
    },
}

-- Alpha Eagle (192333)
ns.AbilityDB[192333] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 377383, defaultEnabled = false },
        { spellID = 377389, defaultEnabled = false },
        { spellID = 1276632, defaultEnabled = false },
    },
}

-- Crawth (191736)
ns.AbilityDB[191736] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 181089, defaultEnabled = false },
        { spellID = 376997, defaultEnabled = false },
        { spellID = 377004, defaultEnabled = false },
        { spellID = 377009, defaultEnabled = false },
        { spellID = 377034, defaultEnabled = false },
        { spellID = 1276752, defaultEnabled = false },
        { spellID = 1285508, defaultEnabled = false },
        { spellID = 1285509, defaultEnabled = false },
    },
}

-- Aggravated Skitterfly (197406)
ns.AbilityDB[197406] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 390938, defaultEnabled = false },
        { spellID = 390942, defaultEnabled = false },
        { spellID = 390944, defaultEnabled = false },
    },
}

-- Vile Lasher (197219)
ns.AbilityDB[197219] = {
    mobCategory = "miniboss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 390912, defaultEnabled = false },
        { spellID = 390915, defaultEnabled = false },
        { spellID = 390918, defaultEnabled = false },
        { spellID = 1282244, defaultEnabled = false },
    },
}

-- Hungry Lasher (197398)
ns.AbilityDB[197398] = { mobCategory = "trivial", abilities = {} }

-- Overgrown Ancient (196482)
ns.AbilityDB[196482] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 388544, defaultEnabled = false },
        { spellID = 388623, defaultEnabled = false },
        { spellID = 388796, defaultEnabled = false },
        { spellID = 388799, defaultEnabled = false },
        { spellID = 388923, defaultEnabled = false },
        { spellID = 390297, defaultEnabled = false },
        { spellID = 396716, defaultEnabled = false },
    },
}

-- Algeth'ar Echoknight (196200)
ns.AbilityDB[196200] = {
    mobCategory = "warrior",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1270349, defaultEnabled = false },
        { spellID = 1270356, defaultEnabled = false },
    },
}

-- Spectral Invoker (196202)
ns.AbilityDB[196202] = {
    mobCategory = "caster",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 1279627, defaultEnabled = false },
    },
}

-- Echo of Doragosa (190609)
ns.AbilityDB[190609] = {
    mobCategory = "boss",  -- semantic role; see header for vocabulary
    abilities = {
        { spellID = 373326, defaultEnabled = false },
        { spellID = 374343, defaultEnabled = false },
        { spellID = 374350, defaultEnabled = false },
        { spellID = 374352, defaultEnabled = false },
        { spellID = 388822, defaultEnabled = false },
        { spellID = 439488, defaultEnabled = false },
        { spellID = 1279418, defaultEnabled = false },
        { spellID = 1282251, defaultEnabled = false },
        { spellID = 1282252, defaultEnabled = false },
    },
}
