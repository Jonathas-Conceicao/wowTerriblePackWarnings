local addonName, ns = ...

ns.PackDatabase["windrunner_spire"] = ns.PackDatabase["windrunner_spire"] or {}
local packs = ns.PackDatabase["windrunner_spire"]

packs[#packs + 1] = {
    key = "windrunner_spire_pack_1",
    displayName = "Windrunner Spire -- Pack 1",
    mobs = {
        {
            name = "Spellguard Magus",
            npcID = 232113,
            abilities = {
                {
                    name = "Spellguard's Protection",
                    spellID = 1253686,
                    first_cast = 50,   -- seconds after pull
                    cooldown = 50,     -- repeat interval in seconds
                },
            },
        },
    },
}
