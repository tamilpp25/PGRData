---@class XScoreTowerStrengthen
local XScoreTowerStrengthen = XClass(nil, "XScoreTowerStrengthen")

function XScoreTowerStrengthen:Ctor()
    self.CfgId = 0
    self.Lv = 0
    -- 等级强化失败次数
    self.StrengthenFailCount = 0
end

function XScoreTowerStrengthen:NotifyScoreTowerStrengthenData(data)
    self.CfgId = data.CfgId or 0
    self.Lv = data.Lv or 0
    self.StrengthenFailCount = data.StrengthenFailCount or 0
end

--region 数据获取

function XScoreTowerStrengthen:GetCfgId()
    return self.CfgId
end

function XScoreTowerStrengthen:GetLv()
    return self.Lv
end

function XScoreTowerStrengthen:GetStrengthenFailCount()
    return self.StrengthenFailCount
end

--endregion

return XScoreTowerStrengthen
