---@class XScoreTowerTowerRecord
local XScoreTowerTowerRecord = XClass(nil, "XScoreTowerTowerRecord")

function XScoreTowerTowerRecord:Ctor()
    self.TowerId = 0
    ---@type XScoreTowerCharacterInfo[]
    self.CharacterInfos = {}
end

function XScoreTowerTowerRecord:NotifyScoreTowerTowerRecordData(data)
    self.TowerId = data.TowerId or 0
    self:UpdateCharacterInfos(data.CharacterInfos)
end

--region 数据更新

function XScoreTowerTowerRecord:UpdateCharacterInfos(data)
    self.CharacterInfos = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddCharacterInfo(v)
    end
end

function XScoreTowerTowerRecord:AddCharacterInfo(data)
    if not data then
        return
    end
    ---@type XScoreTowerCharacterInfo
    local characterInfo = require("XModule/XScoreTower/XEntity/Data/XScoreTowerCharacterInfo").New()
    characterInfo:NotifyScoreTowerCharacterInfo(data)
    table.insert(self.CharacterInfos, characterInfo)
end

--endregion

--region 数据获取

function XScoreTowerTowerRecord:GetTowerId()
    return self.TowerId
end

function XScoreTowerTowerRecord:GetCharacterInfos()
    return self.CharacterInfos
end

--endregion

return XScoreTowerTowerRecord
