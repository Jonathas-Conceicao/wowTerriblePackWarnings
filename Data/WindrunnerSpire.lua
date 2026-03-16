local addonName, ns = ...

ns.AbilityDB = ns.AbilityDB or {}

-- Windrunner's Spire ability database
-- Keyed by npcID; mobClass stored per-npc, abilities as array of spell entries

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
    },
}

ns.AbilityDB[232070] = {
    mobClass = "WARRIOR",
    abilities = {
        {
            name    = "Spirit Bolt",
            spellID = 1216135,
            label   = "Bolt",
        },
    },
}

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

ns.AbilityDB[232056] = {
    mobClass = "WARRIOR",
    abilities = {
        {
            name    = "Fire Spit",
            spellID = 1216848,
            label   = "DMG",
        },
    },
}

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
    },
}

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
    },
}
