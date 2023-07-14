local type = type

--黄金矿工可强化属性
local XGoldenMinerStrengthenDb = XClass(nil, "XGoldenMinerStrengthenDb")

local Default = {
    _StrengthenId = 0, --强化属性id
    _LevelIndex = -1, --等级下标（从0开始有数据）
}

function XGoldenMinerStrengthenDb:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    if id then
        self._StrengthenId = id
    end
    self:UpdateLevelIndex(-1)
end

function XGoldenMinerStrengthenDb:UpdateData(data)
    self._StrengthenId = data.StrengthenId
    self:UpdateLevelIndex(data.LevelIndex)
end

function XGoldenMinerStrengthenDb:UpdateClientLevelIndex(levelIndex)
    self._ClientLevelIndex = levelIndex
end

function XGoldenMinerStrengthenDb:UpdateLevelIndex(levelIndex)
    self._LevelIndex = levelIndex
    self:UpdateClientLevelIndex(levelIndex + 1)
end

function XGoldenMinerStrengthenDb:GetStrengthenId()
    return self._StrengthenId
end

function XGoldenMinerStrengthenDb:GetLevelIndex()
    return self._LevelIndex
end

function XGoldenMinerStrengthenDb:GetClientLevelIndex()
    return self._ClientLevelIndex
end

function XGoldenMinerStrengthenDb:GetNextClientLevelIndex()
    return self._ClientLevelIndex + 1
end

function XGoldenMinerStrengthenDb:IsMaxLv()
    local levelIndex = self:GetNextClientLevelIndex()
    local nextUpgradeCosts = XGoldenMinerConfigs.GetUpgradeCosts(self:GetStrengthenId(), levelIndex)
    return not nextUpgradeCosts
end

function XGoldenMinerStrengthenDb:GetBuffId()
    local strengthenId = self:GetStrengthenId()
    local levelIndex = self:GetClientLevelIndex()
    return XGoldenMinerConfigs.GetUpgradeBuffId(strengthenId, levelIndex)
end

function XGoldenMinerStrengthenDb:GetLvMaxShipKey()
    local strengthenId = self:GetStrengthenId()
    return XGoldenMinerConfigs.GetUpgradeLvMaxShipKey(strengthenId)
end

return XGoldenMinerStrengthenDb