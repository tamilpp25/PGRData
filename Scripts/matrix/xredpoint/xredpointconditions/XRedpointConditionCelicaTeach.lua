local XRedpointConditionCelicaTeach = {}


function XRedpointConditionCelicaTeach.Check(characterId)
    if not characterId then return false end
    return XDataCenter.PracticeManager.CheckShowCelicaTeachRedDot(characterId)
end

return XRedpointConditionCelicaTeach