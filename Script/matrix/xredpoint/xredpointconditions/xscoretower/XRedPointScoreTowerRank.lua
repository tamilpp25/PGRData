--- 新矿区排行榜蓝点
local XRedPointScoreTowerRank = {}

function XRedPointScoreTowerRank.Check(ignoreActivityCheck)

    if not ignoreActivityCheck then
        if not XMVCA.XScoreTower:GetIsOpen(true) then
            return false
        end
    end

    return XMVCA.XScoreTower:IsShowRankRedPoint()
end

return XRedPointScoreTowerRank