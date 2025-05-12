local XTempleEnumConst = require("XEntity/XTemple/XTempleEnumConst")

local XRedPointConditionTempleChallenge = {}

function XRedPointConditionTempleChallenge.Check()
    if XMVCA.XTemple:ExGetIsLocked() then
        return false
    end

    if XMVCA.XTemple:IsChapterJustUnlock(XTempleEnumConst.CHAPTER.COUPLE) then
        return true
    end

    if XMVCA.XTemple:IsChapterJustUnlock(XTempleEnumConst.CHAPTER.SPRING) then
        return true
    end

    if XMVCA.XTemple:IsChapterJustUnlock(XTempleEnumConst.CHAPTER.LANTERN) then
        return true
    end

    return false
end

return XRedPointConditionTempleChallenge
