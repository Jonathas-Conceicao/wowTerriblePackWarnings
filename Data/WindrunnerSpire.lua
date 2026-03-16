local addonName, ns = ...

ns.PackDatabase["windrunner_spire"] = ns.PackDatabase["windrunner_spire"] or {}
local packs = ns.PackDatabase["windrunner_spire"]

packs[#packs + 1] = {
    key         = "windrunner_spire_pack_1",
    displayName = "Windrunner Spire -- Pack 1",
    abilities = {
        {
            name       = "Spellguard's Protection",
            spellID    = 1253686,
            mobClass   = "PALADIN",
            first_cast = 50,
            cooldown   = 50,
            ttsMessage = "Shield",
            label      = "DR",
        },
        {
            name     = "Spirit Bolt",
            spellID  = 1216135,
            mobClass = "WARRIOR",
            -- no first_cast, no cooldown = untimed (icon-only)
            label    = "Bolt",
        },
    },
}

packs[#packs + 1] = {
    key         = "windrunner_spire_pack_2",
    displayName = "Pack 2",
    abilities = {
        {
            name     = "Spirit Bolt",
            spellID  = 1216135,
            mobClass = "WARRIOR",
            label    = "Bolt",
        },
    },
}

packs[#packs + 1] = {
    key         = "windrunner_spire_pack_3",
    displayName = "Pack 3",
    abilities = {
        {
            name     = "Fire Spit",
            spellID  = 1216848,
            mobClass = "WARRIOR",
            label    = "DMG",
        },
    },
}

packs[#packs + 1] = {
    key         = "windrunner_spire_pack_4",
    displayName = "Pack 4",
    abilities   = {},
}

packs[#packs + 1] = {
    key         = "windrunner_spire_pack_5",
    displayName = "Pack 5",
    abilities   = {},
}

packs[#packs + 1] = {
    key         = "windrunner_spire_pack_6",
    displayName = "Pack 6",
    abilities = {
        {
            name     = "Fire Spit",
            spellID  = 1216848,
            mobClass = "WARRIOR",
            label    = "DMG",
        },
    },
}

packs[#packs + 1] = {
    key         = "windrunner_spire_pack_7",
    displayName = "Pack 7",
    abilities   = {},
}

packs[#packs + 1] = {
    key         = "windrunner_spire_pack_8",
    displayName = "Pack 8",
    abilities = {
        {
            name     = "Spirit Bolt",
            spellID  = 1216135,
            mobClass = "WARRIOR",
            label    = "Bolt",
        },
    },
}

packs[#packs + 1] = {
    key         = "windrunner_spire_pack_9",
    displayName = "Pack 9",
    abilities   = {},
}

packs[#packs + 1] = {
    key         = "windrunner_spire_pack_10",
    displayName = "Pack 10",
    abilities   = {},
}

packs[#packs + 1] = {
    key         = "windrunner_spire_pack_11",
    displayName = "Pack 11",
    abilities   = {},
}

packs[#packs + 1] = {
    key         = "windrunner_spire_pack_12",
    displayName = "Pack 12",
    abilities   = {},
}

packs[#packs + 1] = {
    key         = "windrunner_spire_pack_13",
    displayName = "Pack 13",
    abilities = {
        {
            name       = "Interrupting Screech",
            spellID    = 471643,
            mobClass   = "PALADIN",
            first_cast = 20,
            cooldown   = 25,
            ttsMessage = "Stop Casting",
            label      = "Kick",
        },
    },
}

packs[#packs + 1] = {
    key         = "windrunner_spire_pack_14",
    displayName = "Pack 14",
    abilities   = {},
}

packs[#packs + 1] = {
    key         = "windrunner_spire_pack_15",
    displayName = "Pack 15",
    abilities   = {},
}

packs[#packs + 1] = {
    key         = "windrunner_spire_pack_16",
    displayName = "Pack 16",
    abilities   = {},
}

packs[#packs + 1] = {
    key         = "windrunner_spire_pack_17",
    displayName = "Pack 17",
    abilities   = {},
}
