---黄金矿工可强化属性
---@class XGoldenMinerStrengthenData
local XGoldenMinerStrengthenDb = XClass(nil, "XGoldenMinerStrengthenDb")

function XGoldenMinerStrengthenDb:Ctor(id)
    --强化属性id
    if id then
        self._StrengthenId = id
    else
        self._StrengthenId = 0
    end
    self._LevelIndex = -1   --等级下标（从0开始有数据）
    self._AlreadyBuys = {}  --已购买的
    
    self:UpdateLevelIndex(-1)
end

function XGoldenMinerStrengthenDb:UpdateData(data)
    self._StrengthenId = data.StrengthenId
    self:UpdateLevelIndex(data.LevelIndex)
    self:UpdateAlreadyBuys(data.AlreadyBuys)
end

function XGoldenMinerStrengthenDb:UpdateClientLevelIndex(levelIndex)
    self._ClientLevelIndex = levelIndex
end

function XGoldenMinerStrengthenDb:UpdateLevelIndex(levelIndex)
    self._LevelIndex = levelIndex
    self:UpdateClientLevelIndex(levelIndex + 1)
end

function XGoldenMinerStrengthenDb:UpdateAlreadyBuys(alreadyBuys)
    self._AlreadyBuys = alreadyBuys
end

function XGoldenMinerStrengthenDb:AddAlreadyBuys(serverLevelIndex)
    if XTool.IsTableEmpty(self._AlreadyBuys) then
        self._AlreadyBuys = {}
    end
    for _, index in ipairs(self._AlreadyBuys) do
        if index == serverLevelIndex then
            return
        end
    end
    self._AlreadyBuys[#self._AlreadyBuys + 1] = serverLevelIndex
end

function XGoldenMinerStrengthenDb:GetStrengthenId()
    return self._StrengthenId
end

function XGoldenMinerStrengthenDb:GetLevelIndex()
    return self._LevelIndex
end

function XGoldenMinerStrengthenDb:GetAlreadyBuys()
    return self._AlreadyBuys
end

function XGoldenMinerStrengthenDb:GetClientLevelIndex()
    return self._ClientLevelIndex
end

function XGoldenMinerStrengthenDb:GetNextClientLevelIndex()
    return self._ClientLevelIndex + 1
end

function XGoldenMinerStrengthenDb:IsMaxLv()
    local levelIndex = self:GetNextClientLevelIndex()
    local nextUpgradeCosts = XMVCA.XGoldenMiner:GetCfgUpgradeCfgCosts(self:GetStrengthenId(), levelIndex)
    return not nextUpgradeCosts
end

function XGoldenMinerStrengthenDb:GetBuffId()
    local strengthenId = self:GetStrengthenId()
    local levelIndex = self:GetClientLevelIndex()
    return XMVCA.XGoldenMiner:GetCfgUpgradeCfgBuffId(strengthenId, levelIndex)
end

function XGoldenMinerStrengthenDb:GetLvMaxShipKey()
    local strengthenId = self:GetStrengthenId()
    return XMVCA.XGoldenMiner:GetCfgUpgradeLvMaxShipKey(strengthenId)
end

--region Check
function XGoldenMinerStrengthenDb:CheckIsBuy(index)
    if XTool.IsTableEmpty(self._AlreadyBuys) then
        return false
    end
    for _, value in ipairs(self._AlreadyBuys) do
        --存的是后端下标,因此index需要-1
        if value == index - 1 then
            return true
        end
    end
    return false
end
--endregion

return XGoldenMinerStrengthenDb