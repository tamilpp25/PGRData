local XRedPointConditionPokemonCanGetTimeSupply = {}
local Events = nil

function XRedPointConditionPokemonCanGetTimeSupply.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_POKEMON_RED_POINT_TIME_SUPPLY),
    }
    return Events
end

function XRedPointConditionPokemonCanGetTimeSupply.Check()
    return XDataCenter.PokemonManager.CheckCanGetTimeSupply()
end

return XRedPointConditionPokemonCanGetTimeSupply