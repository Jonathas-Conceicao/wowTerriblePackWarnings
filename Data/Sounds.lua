local addonName, ns = ...

-- Sound catalog for the per-skill alert dropdown in the Config UI.
-- First entry is TTS (soundKitID = nil means use C_VoiceChat.SpeakText).
-- Remaining entries are WoW built-in sound kit IDs sourced from CDM alert sounds.
ns.AlertSounds = {
    { name = "TTS",             soundKitID = nil    },
    { name = "Bell Ring",       soundKitID = 316493 },
    { name = "Low Thud",        soundKitID = 316531 },
    { name = "Air Horn",        soundKitID = 316436 },
    { name = "Warhorn",         soundKitID = 316723 },
    { name = "Fanfare",         soundKitID = 316769 },
    { name = "Wolf Howl",       soundKitID = 316766 },
    { name = "Chime Ascending", soundKitID = 316447 },
    { name = "Anvil Strike",    soundKitID = 316528 },
    { name = "Metal Clanks",    soundKitID = 316532 },
    { name = "Bell Trill",      soundKitID = 316712 },
    { name = "Rooster",         soundKitID = 316765 },
}
