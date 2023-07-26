local XRedPointConditionPokemonNewRole = {}
local Events = nil

function XRedPointConditionPokemonNewRole.GetSubEvents()
end

function XRedPointConditionPokemonNewRole.Check(monsterId)
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Pokemon) then
        return false
    end
    local key = string.format("%s_%s_%s", XPokemonConfigs.PokemonNewRoleClickedPrefix, tostring(XPlayer.Id), tostring(monsterId))
    local isClicked = XSaveTool.GetData(key)
    return isClicked
end

return XRedPointConditionPokemonNewRole