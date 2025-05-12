---@class XBigWorldServiceModel : XModel Dlc公共服务
---@field private _RewardId2SubIds table<number, number[]>
---@field private _ItemMap table<number, number>
local XBigWorldServiceModel = XClass(XModel, "XBigWorldServiceModel")

local ReadIntType = XConfigUtil.ReadType.Int
local NormalCacheType = XConfigUtil.CacheType.Normal

local TablePath = {
    BigWorldTask = "Share/BigWorld/Common/Task/BigWorldTask.tab",
    BigWorldCondition = "Share/BigWorld/Common/Condition/BigWorldCondition.tab",
    BigWorldReward = "Share/BigWorld/Common/Reward/BigWorldReward.tab",
    BigWorldRewardGoods = "Share/BigWorld/Common/Reward/BigWorldRewardGoods.tab",
    BigWorldText = "Client/BigWorld/Common/Text/BigWorldText.tab",
    BigWorldNarrativeText = "Client/BigWorld/Common/Text/BigWorldNarrativeText.tab",
    BigWorldItem = "Share/BigWorld/Common/Item/BigWorldItem.tab",
}

function XBigWorldServiceModel:OnInit()
    local identifier = "Id"
    local config = {
        [TablePath.BigWorldTask] = {
            XConfigUtil.ReadType.IntAll,
            XTable.XTableTask,
            identifier,
            NormalCacheType,
        },
        [TablePath.BigWorldCondition] = {
            ReadIntType,
            XTable.XTableCondition,
            identifier,
            NormalCacheType,
        },
        [TablePath.BigWorldReward] = {
            ReadIntType,
            XTable.XTableReward,
            identifier,
            NormalCacheType,
        },
        [TablePath.BigWorldRewardGoods] = {
            ReadIntType,
            XTable.XTableRewardGoods,
            identifier,
            NormalCacheType,
        },
        [TablePath.BigWorldText] = {
            XConfigUtil.ReadType.String,
            XTable.XTableBigWorldText,
            "Key",
            NormalCacheType,
        },
        [TablePath.BigWorldNarrativeText] = {
            XConfigUtil.ReadType.Int,
            XTable.XTableBigWorldNarrativeText,
            "Id",
            NormalCacheType,
        },
        [TablePath.BigWorldItem] = {
            ReadIntType,
            XTable.XTableItem,
            identifier,
            NormalCacheType,
        },
    }
    self._ConfigUtil:InitConfig(config)
    self._QuestItemMap = {}

    self._ItemMap = {}
    self._RecoveryItemIds = {}
    self._ItemTemplateMap = {}
end

---@return XTableCondition
function XBigWorldServiceModel:GetDlcConditionTemplate(conditionId, noTips)
    return self._ConfigUtil:GetCfgByPathAndIdKey(TablePath.BigWorldCondition, conditionId, noTips)
end

---@return XTableTask
function XBigWorldServiceModel:GetBigWorldTaskTemplate(taskId, noTip)
    return self._ConfigUtil:GetCfgByPathAndIdKey(TablePath.BigWorldTask, taskId, noTip)
end

---@return table<number, XTableTask>
function XBigWorldServiceModel:GetBigWorldTaskTemplates()
    return self._ConfigUtil:Get(TablePath.BigWorldTask)
end

---@return XTableReward
function XBigWorldServiceModel:GetDlcRewardTemplate(rewardId, noTip)
    return self._ConfigUtil:GetCfgByPathAndIdKey(TablePath.BigWorldReward, rewardId, noTip)
end

---@return XTableRewardGoods
function XBigWorldServiceModel:GetDlcRewardGoodsTemplate(rewardSubId, noTip)
    return self._ConfigUtil:GetCfgByPathAndIdKey(TablePath.BigWorldRewardGoods, rewardSubId, noTip)
end

---@return XTableBigWorldText
function XBigWorldServiceModel:GetTextTemplate(key)
    return self._ConfigUtil:GetCfgByPathAndIdKey(TablePath.BigWorldText, key)
end

---@return XTableBigWorldNarrativeText
function XBigWorldServiceModel:GetNarrativeTextTemplate(id)
    return self._ConfigUtil:GetCfgByPathAndIdKey(TablePath.BigWorldNarrativeText, id)
end

---@return XTableItem
function XBigWorldServiceModel:GetItemTemplate(itemId, isNoTip)
    return self._ConfigUtil:GetCfgByPathAndIdKey(TablePath.BigWorldItem, itemId, isNoTip)
end

function XBigWorldServiceModel:ClearPrivate()
end

function XBigWorldServiceModel:ResetAll()
    self._QuestItemMap = {}
end
-- region Quest

function XBigWorldServiceModel:UpdateQuestItemMap(map)
    if not map then
        return
    end
    for id, item in pairs(map) do
        self._QuestItemMap[id] = item.Count
    end
end

function XBigWorldServiceModel:InitQuestItemMap(map)
    if not map then
        return
    end
    for id, item in pairs(map) do
        self._QuestItemMap[id] = item.Count
    end
end

function XBigWorldServiceModel:IsQuestItemExist(itemId)
    return self:GetQuestItemMap()[itemId] and true or false
end

function XBigWorldServiceModel:GetQuestItemCount(itemId)
    return self:GetQuestItemMap()[itemId] or 0
end

function XBigWorldServiceModel:GetQuestItemMap()
    return self._QuestItemMap
end

-- endregion

-- region Item

---@return XItem
function XBigWorldServiceModel:GetItem(itemId)
    local item = self._ItemMap[itemId]

    if not item then
        local itemTemplate = self:GetItemTemplateObject(itemId)

        if not itemTemplate then
            XLog.Error("不存在道具! ItemId = " .. itemId .. " Path = " .. " " .. TablePath.BigWorldItem)
            return
        end

        item = XDataCenter.ItemManager.CreateXItem(itemTemplate)
        self._ItemMap[itemId] = item

        if itemTemplate.RecType ~= XResetManager.ResetType.NoNeed then
            table.insert(self._RecoveryItemIds, itemId)
        end
    end

    return item
end

---@return XRecItem
function XBigWorldServiceModel:GetRecoveryItem(itemId)
    local item = self:GetItem(itemId)

    if item.Template.RecType ~= XResetManager.ResetType.NoNeed then
        return item
    end

    return nil
end

function XBigWorldServiceModel:GetRecoveryItemIds()
    return self._RecoveryItemIds
end

function XBigWorldServiceModel:RecycleItem(itemId)
    self._ItemMap[itemId] = nil

    for i, id in pairs(self._RecoveryItemIds) do
        if itemId == id then
            table.remove(self._RecoveryItemIds, i)
            break
        end
    end
end

---@return XItem[]
function XBigWorldServiceModel:GetItemsByType(itemType, isIncludeZero)
    local itemConfigs = self._ConfigUtil:Get(TablePath.BigWorldItem)
    local result = {}

    for itemId, itemConfigs in pairs(itemConfigs) do
        if itemConfigs.ItemType == itemType then
            local item = self:GetItem(itemId)

            if item and (item.Count > 0 or isIncludeZero) then
                table.insert(result, item)
            end
        end
    end

    return result
end

---@return XItem[]
function XBigWorldServiceModel:GetItemsByTypes(itemTypes, isIncludeZero)
    local itemConfigs = self._ConfigUtil:Get(TablePath.BigWorldItem)
    local result = {}

    if not XTool.IsTableEmpty(itemTypes) then
        local itemTypeMap = {}

        for _, itemType in pairs(itemTypes) do
            itemTypeMap[itemType] = true
        end
        for itemId, itemConfigs in pairs(itemConfigs) do
            if itemTypeMap[itemConfigs.ItemType] then
                local item = self:GetItem(itemId)

                if item and (item.Count > 0 or isIncludeZero) then
                    table.insert(result, item)
                end
            end
        end
    end

    return result
end

function XBigWorldServiceModel:GetItemTemplateObject(itemId)
    local template = self._ItemTemplateMap[itemId]

    if not template then
        template = self:GetItemTemplate(itemId)

        if not template then
            XLog.Error("不存在道具! ItemId = " .. itemId .. " Path = " .. " " .. TablePath.BigWorldItem)
            return
        end

        template = XItemConfigs.CreateItemTemplate(template)
        self._ItemTemplateMap[itemId] = template
    end

    return template
end

-- endregion

return XBigWorldServiceModel
