
---@class XUiPanelBWTaskGroup : XUiNode
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Parent XUiBigWorldTaskMain
---@field _Control XBigWorldQuestControl
local XUiPanelBWTaskGroup = XClass(XUiNode, "XUiPanelBWTaskGroup")

function XUiPanelBWTaskGroup:OnStart(typeId, selectQuestId)
    -- typeId 可能为0
    self._TypeId = typeId
    self._SelectQuestId = selectQuestId
    self._QuestId2BtnIndex = {}
    self:InitCb()
    self:InitView()
end

function XUiPanelBWTaskGroup:OnEnable()
    self:RefreshView()
end

function XUiPanelBWTaskGroup:OnDisable()
    self._TabIndex = nil
end

function XUiPanelBWTaskGroup:InitCb()
end

function XUiPanelBWTaskGroup:InitView()
    local typeId = self._TypeId
    self.BtnFirst.gameObject:SetActiveEx(false)
    self.BtnSecond.gameObject:SetActiveEx(false)
    if typeId == XMVCA.XBigWorldQuest.QuestType.All then
        self:InitMultiTypeGroupBtn()
    else
        self:InitSingleTypeGroupBtn()
    end
end

function XUiPanelBWTaskGroup:InitSingleTypeGroupBtn()
    local typeId = self._TypeId
    local btnList = {}
    local btnData = {}

    self:InitTypeGroupBtn(1, typeId, btnData, btnList, 0)

    self._TabData = btnData
    self.PanelTitleBtnGroup:Init(btnList, function(tabIndex)
        self:OnSelectTab(tabIndex)
    end)
end

function XUiPanelBWTaskGroup:InitMultiTypeGroupBtn()
    local typeIds = self._Control:GetQuestTypeIds()

    local btnList = {}
    local btnData = {}
    local btnIndex = 0
    for index, typeId in ipairs(typeIds) do
        btnIndex = self:InitTypeGroupBtn(index, typeId, btnData, btnList, btnIndex)
    end
    self._TabData = btnData
    self.PanelTitleBtnGroup:Init(btnList, function(tabIndex)
        self:OnSelectTab(tabIndex)
    end)
end

function XUiPanelBWTaskGroup:InitTypeGroupBtn(typeIndex, typeId, btnData, btnList, btnIndex)
    local groupIds = self._Control:GetGroupIdsByTypeId(typeId)
    local receiveQuestIds = self._Control:GetReceiveQuestIds()
    local title = self:GetTextTitle(typeIndex)
    title.transform.parent.gameObject:SetActiveEx(false)
    for _, groupId in ipairs(groupIds) do
        local questIds = self._Control:GetQuestIdsByGroupId(groupId, receiveQuestIds)
        local isCreateParent = not XTool.IsTableEmpty(questIds)
        if not isCreateParent then
            goto continue
        end
        title.transform.parent.gameObject:SetActiveEx(true)
        title.text = self._Control:GetQuestTypeName(typeId)
        local btn = self:GetTabBtn(true)
        btn:SetNameByGroup(0, self._Control:GetGroupName(groupId))
        btn:ShowReddot(self:CheckRedPoint(true, groupId))

        btnIndex = btnIndex + 1
        btnList[btnIndex] = btn
        btnData[btnIndex] = self:GetBtnData(true, groupId, btn)

        local firstIndex = btnIndex
        for _, questId in ipairs(questIds) do
            local btnChild = self:GetTabBtn(false)
            btnChild:SetNameByGroup(0, self._Control:GetQuestName(questId))
            btnChild:SetSprite(self._Control:GetQuestIcon(questId))
            btnChild:ShowReddot(self:CheckRedPoint(false, questId))
            btnChild.SubGroupIndex = firstIndex
            btnIndex = btnIndex + 1
            btnList[btnIndex] = btnChild
            btnData[btnIndex] = self:GetBtnData(false, questId, btnChild)
            if questId == self._SelectQuestId then
                self.Parent:SetGroupSelectIndex(btnIndex)
            end
            self._QuestId2BtnIndex[questId] = btnIndex
            local quest = XMVCA.XBigWorldQuest:GetQuestData(questId)
            local stepList = quest:GetActiveStepData()
            local location = ""
            if stepList then
                local step = stepList[1]
                location = self._Control:GetStepLocation(step:GetId())
            end
            btnChild:SetNameByGroup(1, location)
        end

        :: continue ::
    end
    return btnIndex
end

function XUiPanelBWTaskGroup:RefreshView()
    local selectIndex = self.Parent:GetGroupSelectIndex()
    local data = self._TabData[selectIndex]
    if data then
        self.PanelTitleBtnGroup:SelectIndex(selectIndex)
    else
        self.Parent:RefreshTaskContent(false, nil, nil)
    end
end

function XUiPanelBWTaskGroup:OnSelectTab(tabIndex)
    if self._TabIndex == tabIndex then
        return
    end

    self._TabIndex = tabIndex
    local data = self._TabData[tabIndex]
    if not data then
        return
    end
    local btn = data.Tab
    local parentData = self._TabData[btn.SubGroupIndex]
    btn:ShowReddot(self:CheckRedPoint(false, data.Id))
    if parentData then
        local parentBtn = parentData.Tab
        parentBtn:ShowReddot(self:CheckRedPoint(true, data.Id))
    end
    self.Parent:RefreshTaskContent(data.IsGroup, data.Id, tabIndex)
end

---@return XUiComponent.XUiButton
function XUiPanelBWTaskGroup:GetTabBtn(isFirst)
    local prefab = isFirst and self.BtnFirst or self.BtnSecond
    local btn = XUiHelper.Instantiate(prefab, self.PanelTitleBtnGroup.transform)
    btn.gameObject:SetActiveEx(true)
    return btn
end

function XUiPanelBWTaskGroup:GetBtnData(isGroup, id, btn)
    return {
        IsGroup = isGroup,
        Id = id,
        Tab = btn
    }
end

function XUiPanelBWTaskGroup:CheckRedPoint(isGroup, id)
    return false
end

---@return UnityEngine.UI.Text
function XUiPanelBWTaskGroup:GetTextTitle(index)
    local text
    if index == 1 then
        text = self.TxtTitle
    else
        text = self["TxtTitle" .. index]
    end
    if text then
        return text
    end

    local trans = XUiHelper.Instantiate(self.PanelTitle, self.Transform)
    text = trans:Find("TxtTitle"):GetComponent("Text")
    self["TxtTitle" .. index] = text
    return text
end

function XUiPanelBWTaskGroup:GetIndexByQuestId(questId)
    local index = self._QuestId2BtnIndex[questId]
    return index and index or 1
end

return XUiPanelBWTaskGroup