--- 新矿区任务蓝点
local XRedPointScoreTowerTask = {}

function XRedPointScoreTowerTask.Check(ignoreActivityCheck)

    if not ignoreActivityCheck then
        if not XMVCA.XScoreTower:GetIsOpen(true) then
            return false
        end
    end

    return XMVCA.XScoreTower:IsShowTaskRedPoint()
end


return XRedPointScoreTowerTask