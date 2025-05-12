
local XRedPointConditionDevilMayCryCanReceiveCharacter = {}

function XRedPointConditionDevilMayCryCanReceiveCharacter.Check()
    local cfg = XDrawConfigs.GetDevilMayCryActivityCfg()
    for drawId, v in pairs(cfg) do
        local count = XDataCenter.DrawManager:CheckIsCanReceiveCharacterByDrawId(drawId)
        if XTool.IsNumberValid(count) then
            return true
        end
    end

    return false
end

return XRedPointConditionDevilMayCryCanReceiveCharacter