local XUiRogueLikeStoryEntrance = XClass(nil, "XUiRogueLikeStoryEntrance")

function XUiRogueLikeStoryEntrance:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
    self.OptionsList = {}
end

function XUiRogueLikeStoryEntrance:UpdateByNode(node)
    self.Node = node
    self.NodeTemplate = XFubenRogueLikeConfig.GetNodeTemplateById(self.Node.Id)
    self.NodeConfig = XFubenRogueLikeConfig.GetNodeConfigteById(self.Node.Id)
    local sectionInfo = XDataCenter.FubenRogueLikeManager.GetCurSectionInfo()
    local selectNodeInfo = sectionInfo.SelectNodeInfo[self.Node.Id]
    if not selectNodeInfo then return end
    self.EventId = selectNodeInfo.EventId
    self.EventTemplate = XFubenRogueLikeConfig.GetEventTemplateById(self.EventId)
    if not self.EventTemplate then return end

    self.TxtName.text = self.NodeConfig.Name
    self.RImgIcon:SetRawImage(self.NodeConfig.Icon)
    self.TxtStory.text = self.NodeConfig.Description

    self:ShowSpecialEventGroupView()
--[[不存在单个事件组、统一当成多个事件组
    -- 根据事件类型收集
    if XFubenRogueLikeConfig.IsSpecialGroupType(self.NodeTemplate.Type) then
        self:ShowSpecialEventGroupView()
    else
        -- 展示event表中的选项，拱玩家选择
        self:ShowSpecialEventView()
    end
    --]]
end

-- 显示事件组特殊事件
function XUiRogueLikeStoryEntrance:ShowSpecialEventGroupView()
    -- self.SpecailEventGroupTemplate = XFubenRogueLikeConfig.GetSepcialEventGroupTemplateById(self.EventId)
    self.SpecialEventGroupConfig = XFubenRogueLikeConfig.GetSpecialEventGroupConfigById(self.EventId)

    self.CurrentGroupItemConfig = XFubenRogueLikeConfig.GetSpecialEventGroupItemConfigById(self.SpecialEventGroupConfig.GroupItemId)
    self:UpdateSpecialEventGroupItem()
end

-- 更新跳转页面
function XUiRogueLikeStoryEntrance:UpdateSpecialEventGroupItem()
    self.SpecialEventGroupList = {}
    if self.SpecialEventGroupConfig.IsEnd == 1 then
        self.TxtName.text = self.NodeConfig.Name
        self.RImgIcon:SetRawImage(self.NodeConfig.Icon)
        self.TxtStory.text = self.NodeConfig.Description

        for i = 1, #self.EventTemplate.Param do
            local groupId = self.EventTemplate.Param[i]

            table.insert(self.SpecialEventGroupList, {
                OptionId = groupId,
                IsEnd = true,
                Title = self.SpecialEventGroupConfig.OptionDesc[i],
            })
        end
        if self.SpecialEventGroupConfig.HasLeave == 1 then
            table.insert(self.SpecialEventGroupList, {
                IsEnd = false,
                IsLeave = true,
                Title = CS.XTextManager.GetText("RogueLikeOptionLeave")
            })
        end
    elseif self.CurrentGroupItemConfig.IsEnd == 1 then
        self.TxtName.text = self.CurrentGroupItemConfig.Title
        self.RImgIcon:SetRawImage(self.CurrentGroupItemConfig.Icon)
        self.TxtStory.text = self.CurrentGroupItemConfig.Description

        for i = 1, #self.CurrentGroupItemConfig.OptionId do
            local optionIdx = self.CurrentGroupItemConfig.OptionId[i]
            local groupId = self.EventTemplate.Param[optionIdx]
            table.insert(self.SpecialEventGroupList, {
                OptionId = groupId,
                IsEnd = true,
                Title = self.SpecialEventGroupConfig.OptionDesc[optionIdx],
            })
        end
        if self.SpecialEventGroupConfig.HasLeave == 1 then
            table.insert(self.SpecialEventGroupList, {
                IsEnd = false,
                IsLeave = true,
                Title = CS.XTextManager.GetText("RogueLikeOptionLeave")
            })
        end
    else
        self.TxtName.text = self.CurrentGroupItemConfig.Title
        self.RImgIcon:SetRawImage(self.CurrentGroupItemConfig.Icon)
        self.TxtStory.text = self.CurrentGroupItemConfig.Description
        for i = 1, #self.CurrentGroupItemConfig.OptionId do
            local optionId = self.CurrentGroupItemConfig.OptionId[i]
            table.insert(self.SpecialEventGroupList, {
                OptionId = optionId,
                IsEnd = false,
                Title = self.CurrentGroupItemConfig.OptionDesc[i]
            })
        end
        if self.CurrentGroupItemConfig.HasLeave == 1 then
            table.insert(self.SpecialEventGroupList, {
                IsEnd = false,
                IsLeave = true,
                Title = CS.XTextManager.GetText("RogueLikeOptionLeave")
            })
        end
    end
    for i = 1, #self.SpecialEventGroupList do
        local specialEventGroupItem = self.SpecialEventGroupList[i]
        if not self.OptionsList[i] then
            local optionUi = CS.UnityEngine.Object.Instantiate(self.BtnOption)
            optionUi.transform:SetParent(self.PanelOption.transform, false)
            self.OptionsList[i] = optionUi.transform:GetComponent("XUiButton")
            self.OptionsList[i].CallBack = function() self:OnSubOptionsClick(i) end
        end
        self.OptionsList[i].gameObject:SetActiveEx(true)
        self.OptionsList[i]:SetNameByGroup(0, specialEventGroupItem.Title)
    end
    for i = #self.SpecialEventGroupList + 1, #self.OptionsList do
        self.OptionsList[i].gameObject:SetActiveEx(false)
    end
end

-- 点击特殊事件的子选项
function XUiRogueLikeStoryEntrance:OnSubOptionsClick(index)
    if self.SpecialEventGroupList and self.SpecialEventGroupList[index] and self.Node then
        local specialEventGroupItem = self.SpecialEventGroupList[index]
        -- 离开选项
        if specialEventGroupItem.IsLeave then
            XDataCenter.FubenRogueLikeManager.FinishNode(self.Node.Id, function()
                self.UiRoot:Close()
            end)
        else
            -- 非离开选项
            -- 结束
            if specialEventGroupItem.IsEnd then
                -- 检查兑换物品选项
                local specialEventGroupTemplate = XFubenRogueLikeConfig.GetSepcialEventGroupTemplateById(specialEventGroupItem.OptionId)
                for i = 1, #specialEventGroupTemplate.EventId do
                    local currentEventId = specialEventGroupTemplate.EventId[i]
                    local specialEventTemplate = XFubenRogueLikeConfig.GetSpecialEventTemplateById(currentEventId)
                    if self:CheckExchangeItem(specialEventTemplate) then
                        return
                    end
                end
                XDataCenter.FubenRogueLikeManager.SelectSpecialEventGroup(self.Node.Id, specialEventGroupItem.OptionId, function()
                    self.UiRoot:Close()
                end)
            else
                -- 更新选项
                self.CurrentGroupItemConfig = XFubenRogueLikeConfig.GetSpecialEventGroupItemConfigById(specialEventGroupItem.OptionId)
                self:UpdateSpecialEventGroupItem()
            end
        end
    end
end

-- 显示一般的特殊事件
function XUiRogueLikeStoryEntrance:ShowSpecialEventView()
    local eventId = self.NodeTemplate.Param[1]
    self.EventTemplate = XFubenRogueLikeConfig.GetEventTemplateById(eventId)
    if not self.EventTemplate then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetEventTemplateById",
        "RogueLikeEvent", "Share/Fuben/RogueLike/RogueLikeEvent.tab", "Id", tostring(eventId))
        return
    end

    self.SpecitalEventList = {}
    for i = 1, #self.EventTemplate.Param do
        local specialEventId = self.EventTemplate.Param[i]
        local specialTemplate = XFubenRogueLikeConfig.GetSpecialEventTemplateById(specialEventId)
        local specialConfig = XFubenRogueLikeConfig.GetSpecialEventConfigById(specialEventId)
        table.insert(self.SpecitalEventList, {
            SpecitalEventId = specialEventId,
            SpecialTemplate = specialTemplate,
            SpecialConfig = specialConfig,
        })
    end

    for i = 1, #self.SpecitalEventList do
        local specailEventItems = self.SpecitalEventList[i]
        if not self.OptionsList[i] then
            local optionUi = CS.UnityEngine.Object.Instantiate(self.BtnOption)
            optionUi.transform:SetParent(self.PanelOption.transform, false)
            self.OptionsList[i] = optionUi.transform:GetComponent("XUiButton")
            self.OptionsList[i].CallBack = function() self:OnOptionsClick(i) end
        end
        self.OptionsList[i].gameObject:SetActiveEx(true)
        self.OptionsList[i]:SetNameByGroup(0, specailEventItems.SpecialConfig.Title)
    end
    -- 处理多余的
    for i = #self.SpecitalEventList + 1, #self.OptionsList do
        self.OptionsList[i].gameObject:SetActiveEx(false)
    end
end


-- 点击选项
function XUiRogueLikeStoryEntrance:OnOptionsClick(index)
    if self.SpecitalEventList and self.SpecitalEventList[index] and self.Node then
        local specialEventId = self.SpecitalEventList[index].SpecitalEventId
        local specialTemplate = self.SpecitalEventList[index].SpecialTemplate

        -- 检查兑换物品
        -- 兑换所需{0}{1}不足
        if self:CheckExchangeItem(specialTemplate) then
            return
        end

        XDataCenter.FubenRogueLikeManager.SelectSpecialEvent(self.Node.Id, specialEventId, function()
            -- 打开获得界面
            self.UiRoot:Close()
            XLuaUiManager.Open("UiRogueLikeStoryResult", specialEventId, XFubenRogueLikeConfig.SpecialResultType.SingleEvent)
        end)
    end
end

-- 检查减少行动点
function XUiRogueLikeStoryEntrance:CheckCostActionPoint(specialTemplate)
    if specialTemplate.Type == XFubenRogueLikeConfig.XRLOtherEventType.ActionPoint then
        local needActionPoint = specialTemplate.Param[1]
        local ownActionPoint = XDataCenter.FubenRogueLikeManager.GetRogueLikeActionPoint()
        if needActionPoint > ownActionPoint then
            XUiManager.TipMsg(CS.XTextManager.GetText("RogueLikeOutOfActionPoint", needActionPoint))
            return true
        end
    end
    return false
end

-- 检查消耗物品
function XUiRogueLikeStoryEntrance:CheckConsumeItem(specialTemplate)
    if specialTemplate.Type == XFubenRogueLikeConfig.XRLOtherEventType.ConsumeItem then
        local itemId = specialTemplate.Param[1]
        local itemName = XDataCenter.ItemManager.GetItemName(itemId)
        local itemNum = specialTemplate.Param[2]
        local ownCount = XDataCenter.ItemManager.GetCount(itemId)
        if itemNum > ownCount then
            XUiManager.TipMsg(CS.XTextManager.GetText("RogueLikeCostItemTips", itemNum, itemName))
            return true
        end
    end
    return false
end

-- 兑换物品检查
function XUiRogueLikeStoryEntrance:CheckExchangeItem(specialTemplate)
    if specialTemplate.Type == XFubenRogueLikeConfig.XRLOtherEventType.ExchangeItem then
        local shopItemId = specialTemplate.Param[1]
        local shopItemTemplate = XFubenRogueLikeConfig.GetShopItemTemplateById(shopItemId)
        local itemId = shopItemTemplate.ConsumeId[1]
        local itemName = XDataCenter.ItemManager.GetItemName(itemId)
        local itemNum = shopItemTemplate.ConsumeNum[1]
        local ownCount = XDataCenter.ItemManager.GetCount(itemId)
        if itemNum > ownCount then
            XUiManager.TipMsg(CS.XTextManager.GetText("RogueLikeExchangeItemTips", itemNum, itemName))
            return true
        end
    end
    return false
end

return XUiRogueLikeStoryEntrance