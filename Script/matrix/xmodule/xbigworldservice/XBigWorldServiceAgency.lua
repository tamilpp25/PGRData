---@class XBigWorldServiceAgency : XAgency Dlc公共服务
---@field private _Model XBigWorldServiceModel
local XBigWorldServiceAgency = XClass(XAgency, "XBigWorldServiceAgency")

local XBigWorldCondition

local stringFormat = string.format

function XBigWorldServiceAgency:OnInit()
    self.DlcEventId = require("XModule/XBigWorldService/Common/XBigWorldEventId")
end

function XBigWorldServiceAgency:InitRpc()
    XRpc.NotifyDlcQuestItemUpdate = handler(self, self.NotifyDlcQuestItemUpdate)
end

function XBigWorldServiceAgency:InitEvent()

end

function XBigWorldServiceAgency:OnRelease()
    if XBigWorldCondition then
        XBigWorldCondition:OnRelease()
    end
end

function XBigWorldServiceAgency:GetDlcConditionTemplate(conditionId, noTips)
    return self._Model:GetDlcConditionTemplate(conditionId, noTips)
end

function XBigWorldServiceAgency:_InitXBigWorldCondition()
    if XBigWorldCondition then return end
    XBigWorldCondition = require("XModule/XBigWorldService/Common/XBigWorldCondition").New()
end

function XBigWorldServiceAgency:RegisterConditionFunc(conditionType, func)
    self:_InitXBigWorldCondition()
    XBigWorldCondition:RegisterConditionFunc(conditionType, func)
end

function XBigWorldServiceAgency:CheckCondition(conditionId, ...)
    local template = self:GetDlcConditionTemplate(conditionId, true)
    -- 非Dlc内部
    if not template then
        return XConditionManager.CheckCondition(conditionId, ...)
    end
    self:_InitXBigWorldCondition()
    return XBigWorldCondition:CheckCondition(template, ...)
end

function XBigWorldServiceAgency:GetBigWorldTaskTemplate(taskId, noTip)
    return self._Model:GetBigWorldTaskTemplate(taskId, noTip)
end

function XBigWorldServiceAgency:GetBigWorldTaskTemplates()
    return self._Model:GetBigWorldTaskTemplates()
end

function XBigWorldServiceAgency:GetDlcRewardGoodsTemplate(rewardSubId, noTip)
    return self._Model:GetDlcRewardGoodsTemplate(rewardSubId, noTip)
end

function XBigWorldServiceAgency:GetDlcRewardTemplate(rewardId, noTip)
    return self._Model:GetDlcRewardTemplate(rewardId, noTip)
end

function XBigWorldServiceAgency:GetDlcRewardSubIds(rewardId, noTip)
    local template = self:GetDlcRewardTemplate(rewardId, noTip)
    return template and template.SubIds
end

function XBigWorldServiceAgency:GetText(key, ...)
    local t = self._Model:GetTextTemplate(key)
    if not t then
        XLog.Error("BigWorldText 不存在Key: " .. key)
        return ""
    end

    return stringFormat(t.Value, ...)
end

function XBigWorldServiceAgency:GetNarrativeTitle(id)
    local template = self._Model:GetNarrativeTextTemplate(id)
    return template and template.Title or ""
end

function XBigWorldServiceAgency:GetNarrativeContent(id)
    local template = self._Model:GetNarrativeTextTemplate(id)
    local content = template and XUiHelper.ReplaceTextNewLine(template.Content) or ""
    -- 当策划使用 Alt+Enter 换行的时候，文本的首尾会有一个“，所以这里要去除
    if string.StartsWith(content, "\"") and string.EndsWith(content, "\"") then
        content = string.Utf8Sub(content, 2, string.Utf8Len(content) - 2)
    end

    return content
end

function XBigWorldServiceAgency:TipText(key, ...)
    local text = self:GetText(key, ...)
    XUiManager.TipMsg(text)
end

-- region Item

---@return XItem
function XBigWorldServiceAgency:GetItemById(itemId)
    return self._Model:GetItem(itemId)
end

---@return XItem[]
function XBigWorldServiceAgency:GetItemsByItemType(itemType, isIncludeZero)
    return self._Model:GetItemsByType(itemType, isIncludeZero)
end

---@return XItem[]
function XBigWorldServiceAgency:GetItemsByItemTypes(itemTypes, isIncludeZero)
    return self._Model:GetItemsByTypes(itemTypes, isIncludeZero)
end

function XBigWorldServiceAgency:GetItemTemplateObject(itemId)
    if self:IsDlcItem(itemId) then
        return self._Model:GetItemTemplateObject(itemId)
    end

    return nil
end

---@return XTableItem
function XBigWorldServiceAgency:GetItemTemplate(itemId, isNoTip)
    return self._Model:GetItemTemplate(itemId, isNoTip)
end

function XBigWorldServiceAgency:GetItemDescription(itemId)
    local template = self:GetItemTemplate(itemId)

    return template and template.Description or ""
end

function XBigWorldServiceAgency:GetItemWorldDesc(itemId)
    local template = self:GetItemTemplate(itemId)

    return template and template.WorldDesc or ""
end

function XBigWorldServiceAgency:GetItemName(itemId)
    local template = self:GetItemTemplate(itemId)

    return template and template.Name or ""
end

function XBigWorldServiceAgency:GetItemQuality(itemId)
    local template = self:GetItemTemplate(itemId)

    return template and template.Quality or 0
end

function XBigWorldServiceAgency:GetItemIcon(itemId)
    local template = self:GetItemTemplate(itemId)

    return template and template.Icon or ""
end

function XBigWorldServiceAgency:GetItemBigIcon(itemId)
    local template = self:GetItemTemplate(itemId)

    return template and template.BigIcon or ""
end

function XBigWorldServiceAgency:GetItemSkipIdParams(itemId)
    local template = self:GetItemTemplate(itemId)

    return template and template.SkipIdParams
end

function XBigWorldServiceAgency:GetItemType(itemId)
    local template = self:GetItemTemplate(itemId)

    return template and template.ItemType
end

function XBigWorldServiceAgency:GetItemRecycleLeftTime(id)
    local leftTime = 0

    local item = self:GetItemById(id)

    if not item then
        return leftTime
    end

    local startTime = nil

    if item.Template.TimelinessType == XDataCenter.ItemManager.TimelinessType.FromConfig then
        startTime = XTime.ParseToTimestamp(item.Template.StartTime)
    elseif item.Template.TimelinessType == XDataCenter.ItemManager.TimelinessType.AfterGet then
        startTime = item.CreateTime
    end

    if startTime then
        local endTime = startTime + item.Template.Duration

        leftTime = endTime - XTime.GetServerNowTimestamp()
    end

    return leftTime
end

function XBigWorldServiceAgency:UseItem(id, recycleTime, count, callback, rewardIds)
    XDataCenter.ItemManager.Use(id, recycleTime, count, callback, rewardIds)
end

function XBigWorldServiceAgency:CheckItemAutoUseGift(itemList)
    if not XTool.IsTableEmpty(itemList) then
        -- 收集所有礼包的结果，一次弹出来
        local allReward = {}
        local rewardAmount = 0

        for _, data in pairs(itemList) do
            local id = data.Id

            if XDataCenter.ItemManager.IsAutoGift(id) then
                local leftTime = self:GetItemRecycleLeftTime(id)
                local count = data.Count or 0

                if count > 0 then
                    rewardAmount = rewardAmount + 1
                    self:UseItem(id, leftTime, count, function(rewardGoodList)
                        for i = 1, #rewardGoodList do
                            allReward[#allReward + 1] = rewardGoodList[i]
                        end
                        rewardAmount = rewardAmount - 1
                        if rewardAmount == 0 then
                            XMVCA.XBigWorldUI:OpenBigWorldObtain(allReward)
                        end
                    end)
                end
            end
        end
    end
end

function XBigWorldServiceAgency:IsDlcItem(itemId)
    return itemId >= 990000 and itemId < 1000000
end

function XBigWorldServiceAgency:GetItemsShowParams(data)
    if not data then
        return nil
    end

    local params = {}
    if type(data) == "number" then
        params.TemplateId = data
    else
        params.TemplateId = (data.TemplateId and data.TemplateId > 0) and data.TemplateId or data.Id
        params.Count = data.Count
        params.IsUseBigIcon = data.UseBigIcon or false
        params.IsAllowSkip = data.IsSkip and true or false
    end

    return params
end

function XBigWorldServiceAgency:GetItemGoodsShowParams(itemId)
    return {
        RewardType = XRewardManager.XRewardType.Item,
        TemplateId = itemId,
        Name = self:GetItemName(itemId),
        Quality = self:GetItemQuality(itemId),
        Icon = self:GetItemIcon(itemId),
        BigIcon = self:GetItemBigIcon(itemId),
        WorldDesc = self:GetItemWorldDesc(itemId),
        Description = self:GetItemDescription(itemId),
    }
end

function XBigWorldServiceAgency:GetItemCount(itemId)
    local item = self:GetItemById(itemId)

    return item and item.Count or 0
end

function XBigWorldServiceAgency:OnCheckRecoveryItemsCount()
    local itemIds = self._Model:GetRecoveryItemIds()

    if not XTool.IsTableEmpty(itemIds) then
        for _, itemId in pairs(itemIds) do
            local item = self._Model:GetRecoveryItem(itemId)

            if item then
                item:CheckCount()
            end
        end
    end
end

function XBigWorldServiceAgency:OnInitItemData(itemData)
    if self:IsDlcItem(itemData.Id) then
        local item = self:GetItemById(itemData.Id)

        if item then
            item:RefreshItem(itemData)
        end
    end
end

function XBigWorldServiceAgency:OnNotifyItemData(itemData)
    self:OnInitItemData(itemData)
end

function XBigWorldServiceAgency:OnNotifyItemRecycle(itemId)
    if self:IsDlcItem(itemId) then
        self._Model:RecycleItem(itemId)
    end
end

-- endregion

-- region QuestItem

function XBigWorldServiceAgency:InitQuestItemMap(map)
    self._Model:InitQuestItemMap(map)
end

function XBigWorldServiceAgency:GetAllQuestItemIdList()
    local questItemMap = self._Model:GetQuestItemMap()
    local result = {}

    for id, _ in pairs(questItemMap) do
        table.insert(result, id)
    end

    return result
end

function XBigWorldServiceAgency:GetQuestItemCount(itemId)
    return self._Model:GetQuestItemCount(itemId)
end

function XBigWorldServiceAgency:IsQuestItemExist(itemId)
    return self._Model:IsQuestItemExist(itemId)
end

function XBigWorldServiceAgency:GetQuestItemParams(templateId)
    if not XTool.IsNumberValid(templateId) then
        XLog.Error("显示的道具数据TemplateId为空！")
        return
    end
    return {
        RewardType = XRewardManager.XRewardType.QuestItem,
        TemplateId = templateId,
        Name = XMVCA.XBigWorldQuest:GetQuestItemName(templateId),
        Icon = XMVCA.XBigWorldQuest:GetQuestItemIcon(templateId),
        Quality = XMVCA.XBigWorldQuest:GetQuestItemQuality(templateId),
        Priority = XMVCA.XBigWorldQuest:GetQuestItemPriority(templateId),
        WorldDesc = XMVCA.XBigWorldQuest:GetQuestItemWorldDescription(templateId),
        Description = XMVCA.XBigWorldQuest:GetQuestItemDescription(templateId),
    }
end

function XBigWorldServiceAgency:NotifyDlcQuestItemUpdate(data)
    self._Model:UpdateQuestItemMap(data.DlcQuestItemChangeDict)
    local newItems = data.DlcQuestItemChangeDict
    if XTool.IsTableEmpty(newItems) then
        return
    end
    local rewardData = {}
    -- newItems 是一个字典
    for id, item in pairs(newItems) do
        if item.Count > 0 then
            rewardData[#rewardData + 1] = {
                Id = id,
                Count = item.Count,
            }
        end
    end
    if not XTool.IsTableEmpty(rewardData) then
        XMVCA.XBigWorldUI:OpenBigWorldObtain(rewardData)
    end
end

-- endregion

-- region SceneObject

function XBigWorldServiceAgency:OnSceneObjectActive(data)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_SCENE_OBJECT_ACTIVATE, data.WorldId, data.LevelId, data.PlaceId, data.Active)
end

function XBigWorldServiceAgency:CheckSceneObjectActive(worldId, levelId, placeId)
    return CS.StatusSyncFight.XWorldSaveSystem.GetLevelSceneObjectActive(worldId, levelId, placeId)
end

-- endregion

return XBigWorldServiceAgency
