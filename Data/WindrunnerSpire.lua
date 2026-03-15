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
        },
        {
            name     = "Spirit Bolt",
            spellID  = 1216135,
            mobClass = "WARRIOR",
            -- no first_cast, no cooldown = untimed (icon-only)
        },
    },
}
