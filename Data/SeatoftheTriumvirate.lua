local addonName, ns = ...

ns.AbilityDB = ns.AbilityDB or {}

-- Seat of the Triumvirate ability database
-- Keyed by npcID; mobClass defaults to WARRIOR, abilities from MDT spells

-- Merciless Subjugator (124171)
ns.AbilityDB[124171] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1262506, defaultEnabled = false },
        { spellID = 1262509, defaultEnabled = false },
        { spellID = 1277343, defaultEnabled = false },
    },
}

-- Rift Warden (122571)
ns.AbilityDB[122571] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1264505, defaultEnabled = false },
        { spellID = 1264532, defaultEnabled = false },
        { spellID = 1264569, defaultEnabled = false },
        { spellID = 1280330, defaultEnabled = false },
    },
}

-- Ruthless Riftstalker (122413)
ns.AbilityDB[122413] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1262519, defaultEnabled = false },
        { spellID = 1277339, defaultEnabled = false },
        { spellID = 1277340, defaultEnabled = false },
    },
}

-- Ravenous Umbralfin (255320)
ns.AbilityDB[255320] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1264670, defaultEnabled = false },
        { spellID = 1264678, defaultEnabled = false },
    },
}

-- Umbral War-Adept (122421)
ns.AbilityDB[122421] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1269183, defaultEnabled = false },
        { spellID = 1280326, defaultEnabled = false },
    },
}

-- Dire Voidbender (122404)
ns.AbilityDB[122404] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1262526, defaultEnabled = false },
        { spellID = 1262527, defaultEnabled = false },
    },
}

-- Void-Infused Destroyer (252756)
ns.AbilityDB[252756] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1262335, defaultEnabled = false },
        { spellID = 1262429, defaultEnabled = false },
        { spellID = 1262441, defaultEnabled = false },
    },
}

-- Grand Shadow-Weaver (122423)
ns.AbilityDB[122423] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1262508, defaultEnabled = false },
        { spellID = 1264286, defaultEnabled = false },
    },
}

-- Viceroy Nezhar (122056)
ns.AbilityDB[122056] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 244750, defaultEnabled = false },
        { spellID = 246913, defaultEnabled = false },
        { spellID = 1263528, defaultEnabled = false },
        { spellID = 1263529, defaultEnabled = false },
        { spellID = 1263532, defaultEnabled = false },
        { spellID = 1263538, defaultEnabled = false },
        { spellID = 1263542, defaultEnabled = false },
    },
}

-- Zuraal the Ascended (122313)
ns.AbilityDB[122313] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 244579, defaultEnabled = false },
        { spellID = 1263282, defaultEnabled = false },
        { spellID = 1263297, defaultEnabled = false },
        { spellID = 1263399, defaultEnabled = false },
        { spellID = 1263440, defaultEnabled = false },
        { spellID = 1263484, defaultEnabled = false },
        { spellID = 1263492, defaultEnabled = false },
        { spellID = 1263494, defaultEnabled = false },
        { spellID = 1268916, defaultEnabled = false },
    },
}

-- Saprish (122316)
ns.AbilityDB[122316] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 246943, defaultEnabled = false },
        { spellID = 1263523, defaultEnabled = false },
        { spellID = 1280065, defaultEnabled = false },
    },
}

-- Darkfang (122319)
ns.AbilityDB[122319] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 245742, defaultEnabled = false },
        { spellID = 246943, defaultEnabled = false },
    },
}

-- Famished Broken (122322)
ns.AbilityDB[122322] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1269468, defaultEnabled = false },
        { spellID = 1269469, defaultEnabled = false },
        { spellID = 1269470, defaultEnabled = false },
    },
}

-- Shadowguard Champion (122403)
ns.AbilityDB[122403] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1262517, defaultEnabled = false },
        { spellID = 1264036, defaultEnabled = false },
    },
}

-- Dark Conjurer (122405)
ns.AbilityDB[122405] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1262510, defaultEnabled = false },
        { spellID = 1262522, defaultEnabled = false },
        { spellID = 1262523, defaultEnabled = false },
    },
}

-- Umbral Tentacle (122827)
ns.AbilityDB[122827] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 249082, defaultEnabled = false },
        { spellID = 1268733, defaultEnabled = false },
    },
}

-- L'ura (124729)
ns.AbilityDB[124729] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1264159, defaultEnabled = false },
        { spellID = 1264196, defaultEnabled = false },
        { spellID = 1265419, defaultEnabled = false },
        { spellID = 1265420, defaultEnabled = false },
        { spellID = 1265421, defaultEnabled = false },
        { spellID = 1265426, defaultEnabled = false },
        { spellID = 1265463, defaultEnabled = false },
        { spellID = 1265689, defaultEnabled = false },
        { spellID = 1265999, defaultEnabled = false },
        { spellID = 1266001, defaultEnabled = false },
        { spellID = 1266003, defaultEnabled = false },
        { spellID = 1267207, defaultEnabled = false },
        { spellID = 1267274, defaultEnabled = false },
        { spellID = 1268598, defaultEnabled = false },
        { spellID = 1268646, defaultEnabled = false },
        { spellID = 1268647, defaultEnabled = false },
    },
}

-- Shadewing (125340)
ns.AbilityDB[125340] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 246943, defaultEnabled = false },
        { spellID = 248829, defaultEnabled = false },
        { spellID = 248830, defaultEnabled = false },
        { spellID = 248831, defaultEnabled = false },
    },
}

-- Void Tentacle (256424)
ns.AbilityDB[256424] = {
    mobClass = "WARRIOR",
    abilities = {
        { spellID = 1269081, defaultEnabled = false },
    },
}

