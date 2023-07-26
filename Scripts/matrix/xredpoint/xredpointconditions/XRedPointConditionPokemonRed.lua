local XRedPointConditionPokemonRed = {}
local Events = nil

function XRedPointConditionPokemonRed.GetSubEvents()
end

function XRedPointConditionPokemonRed.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Pokemon) then
        return false
    end
    return XDataCenter.PokemonManager.CheckPokemonEnterRedPoint()
end

return XRedPointConditionPokemonRed