

local XRedPointConditionBlackRockChessEntrance = {}

function XRedPointConditionBlackRockChessEntrance:Check()
    ---@type XBlackRockChessAgency
    local ag = XMVCA:GetAgency(ModuleId.XBlackRockChess)
    if not ag then
        return false
    end
    
    return ag:CheckEntrancePoint()
end

return XRedPointConditionBlackRockChessEntrance
