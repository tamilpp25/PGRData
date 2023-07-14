local XRedPointConditionPokemonTaskRed = {}
local Events = nil

function XRedPointConditionPokemonTaskRed.GetSubEvents()
end

function XRedPointConditionPokemonTaskRed.Check()
    return XDataCenter.PokemonManager.CheckPokemonTaskRedPoint()
end

return XRedPointConditionPokemonTaskRed