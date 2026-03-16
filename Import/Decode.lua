local addonName, ns = ...

local LibDeflate = LibStub:GetLibrary("LibDeflate")
local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")

--- Decode an MDT export string into a Lua table.
-- Follows the same chain as MDT:StringToTable for user-pasted strings:
--   strip "!" prefix -> DecodeForPrint -> DecompressDeflate -> Deserialize
-- @param inString string  The MDT export string (modern format with ! prefix)
-- @return boolean success, table|string dataOrError
function ns.MDTDecode(inString)
    -- 1. Validate input
    if not inString or inString == "" then
        return false, "No input string provided"
    end

    -- 2. Strip ! prefix
    local encoded, usesDeflate = inString:gsub("^%!", "")

    -- 3. Check modern format
    if usesDeflate ~= 1 then
        return false, "Legacy MDT format (no ! prefix) is not supported"
    end

    -- 4. DecodeForPrint
    local decoded = LibDeflate:DecodeForPrint(encoded)
    if not decoded then
        return false, "DecodeForPrint failed -- string may be corrupted or wrong format"
    end

    -- 5. DecompressDeflate
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then
        return false, "DecompressDeflate failed"
    end

    -- 6. Deserialize
    local success, data = AceSerializer:Deserialize(decompressed)
    if not success then
        return false, "AceSerializer:Deserialize failed: " .. tostring(data)
    end

    -- 7. Return success
    return true, data
end
