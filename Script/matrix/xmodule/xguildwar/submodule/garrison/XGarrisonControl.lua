--- 公会战5.0新增驻守系统的子控制器，用于封装驻守系统玩法在XGuildWarControl上的接口
---@class XGarrisonControl: XControl
---@field private _Model XGuildWarModel
local XGarrisonControl = XClass(XControl, 'XGarrisonControl')

function XGarrisonControl:OnInit()

end


function XGarrisonControl:OnRelease()

end

--- 检查当前轮次最后一次炮击是否防守成功
function XGarrisonControl:CheckLastDefendSuccess()
    ---@type XGuildWarGarrisonData
    local garrisonData = self._Model:GetGarrisonData()

    if garrisonData then
        return garrisonData:CheckLastDefendSuccess()
    end
    
    return false
end

--- 判断最近的炮击是否播放过（通过读取客户端缓存记录的方式）
function XGarrisonControl:CheckNearestAttackAnimIsPlayed()
    ---@type XGuildWarGarrisonData
    local garrisonData = self._Model:GetGarrisonData()

    if garrisonData then
        return garrisonData:CheckNearestAttackAnimIsPlayed()
    end

    return true
end

--- 获取当前轮次最近一次被炮击的资源点Id
function XGarrisonControl:GetLastAttackedResourcesId()
    ---@type XGuildWarGarrisonData
    local garrisonData = self._Model:GetGarrisonData()

    if garrisonData then
        return garrisonData:GetLastAttackedResourcesId()
    end
end

--- 获取所有驻守人数最大（存在相同）的节点Id
function XGarrisonControl:GetMaxDefendResourceNodeIds()
    ---@type XGuildWarGarrisonData
    local garrisonData = self._Model:GetGarrisonData()

    if garrisonData then
        return garrisonData:GetMaxDefendResourceNodeIds()
    end
end

return XGarrisonControl