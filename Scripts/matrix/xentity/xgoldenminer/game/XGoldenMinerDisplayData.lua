--地图抓取物数据
---@class XGoldenMinerDisplayData
local XGoldenMinerDisplayData = XClass(nil, "XGoldenMinerDisplayData")

local function sortDisplayBuff(buffIdA, buffIdB)
    local priorityA = XGoldenMinerConfigs.GetBuffDisplayPriority(buffIdA)
    local priorityB = XGoldenMinerConfigs.GetBuffDisplayPriority(buffIdB)
    return priorityA < priorityB
end

function XGoldenMinerDisplayData:Ctor()
    self._CharacterId = 0
    ---@type XGoldenMinerStrengthenDb[]
    self._UpgradeList = {}
    ---@type XGoldenMinerItemData[]
    self._BuffList = {}
    ---@type XGoldenMinerItemData[]
    self._ItemList = {}
end

--region Setter
function XGoldenMinerDisplayData:SetCharacterId(CharacterId)
    self._CharacterId = CharacterId
end

function XGoldenMinerDisplayData:SetDisplayUpgrade(UpgradeList)
    self._UpgradeList = UpgradeList
end

function XGoldenMinerDisplayData:SetDisplayBuff(BuffList)
    self._BuffList = BuffList
end

function XGoldenMinerDisplayData:SetDisplayItem(ItemList)
    self._ItemList = ItemList
end
--endregion

--region Getter
function XGoldenMinerDisplayData:GetCharacterId()
    return self._CharacterId
end

function XGoldenMinerDisplayData:GetDisplayUpgrade()
    return self._UpgradeList
end

function XGoldenMinerDisplayData:GetDisplayBuff()
    return self._BuffList
end

function XGoldenMinerDisplayData:GetDisplayItem()
    return self._ItemList
end

function XGoldenMinerDisplayData:GetDisplayShipList()
    local result = {}
    local buffList = XGoldenMinerConfigs.GetCharacterBuffIds(self:GetCharacterId())
    local buffIcon = buffList[1] and XGoldenMinerConfigs.GetBuffIcon(buffList[1])
    local characterDisplayData = {
        icon = buffIcon,
        desc = XGoldenMinerConfigs.GetCharacterSkillDesc(self:GetCharacterId())
    }

    for _, upgradeData in pairs(self:GetDisplayUpgrade()) do
        local buffId = XGoldenMinerConfigs.GetUpgradeBuffId(upgradeData:GetStrengthenId(), upgradeData:GetClientLevelIndex())
        if XTool.IsNumberValid(buffId) and XGoldenMinerConfigs.GetBuffDisplayType(buffId) == XGoldenMinerConfigs.BuffDisplayType.Ship then
            result[#result + 1] = buffId
        end
    end
    if not XTool.IsTableEmpty(result) then
        table.sort(result, sortDisplayBuff)
    end
    return result, characterDisplayData
end

function XGoldenMinerDisplayData:GetDisplayItemList()
    local result = {}
    for _, item in pairs(self:GetDisplayItem()) do
        if XGoldenMinerConfigs.GetBuffDisplayType(item:GetBuffId()) == XGoldenMinerConfigs.BuffDisplayType.Item then
            result[#result + 1] = { 
                icon = XGoldenMinerConfigs.GetItemIcon(item:GetItemId()),
                desc = XGoldenMinerConfigs.GetBuffDesc(item:GetBuffId())
            }
        end
    end
    return result
end

function XGoldenMinerDisplayData:GetDisplayBuffList()
    local result = {}
    for _, buff in pairs(self:GetDisplayBuff()) do
        if XGoldenMinerConfigs.GetBuffDisplayType(buff:GetBuffId()) == XGoldenMinerConfigs.BuffDisplayType.Buff then
            result[#result + 1] = buff:GetBuffId()
        end
    end
    if not XTool.IsTableEmpty(result) then
        table.sort(result, sortDisplayBuff)
    end
    return result
end
--endregion

return XGoldenMinerDisplayData