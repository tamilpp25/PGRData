local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridCharacter = require("XUi/XUiCharacter/XUiGridCharacter")
---@class XUiCharacterAttributeDetail
local XUiCharacterAttributeDetail = XLuaUiManager.Register(XLuaUi, "UiCharacterAttributeDetail")

local PanelEnum = {
    SelfGeneralSkill = 3,
    TotalGeneralSkill = 4,
}

function XUiCharacterAttributeDetail:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)
    local btns = { self.BtnTab1, self.BtnTab2, self.BtnTab3, self.BtnTab4 }
    self.BtnGroup:Init(btns, function(index)
        self:OnSelectTab(index)
    end)
    self:InitDynamicTable()

    self.DytNameDic = 
    {
        [1] = "DynamicTableCareer",
        [2] = "DynamicTableElement",
    }
end

function XUiCharacterAttributeDetail:InitDynamicTable()
    local XUiGridCharacterCareerV2P6 = require("XUi/XUiCharacterV2P6/Grid/XUiGridCharacterCareerV2P6")
    self.DynamicTableCareer = XDynamicTableNormal.New(self.PanelCareerDetails)
    self.DynamicTableCareer:SetProxy(XUiGridCharacterCareerV2P6, self)
    self.DynamicTableCareer:SetDelegate(self)
    self.DynamicTableCareer:SetDynamicEventDelegate(function (...)
        self:OnDynamicTableCareerEvent(...)
    end)

    local XUiGridElementDetail = require("XUi/XUiCharacter/XUiGridElementDetail")
    self.DynamicTableElement = XDynamicTableNormal.New(self.PanelElementDetails)
    self.DynamicTableElement:SetProxy(XUiGridElementDetail, self)
    self.DynamicTableElement:SetDelegate(self)
    self.DynamicTableElement:SetDynamicEventDelegate(function (...)
        self:OnDynamicTableElementEvent(...)
    end)
end

function XUiCharacterAttributeDetail:OnStart(characterId, tabIndex, initGeneralSkillIndex)
    self:RefreshByCharacterId(characterId, tabIndex, initGeneralSkillIndex)
    
    XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_SKILL_UNLOCK, self.RefreshPanelGeneralSkillByEvent, self)
    XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_SKILL_UP, self.RefreshPanelGeneralSkillByEvent, self)
    XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_ENHANCESKILL_UNLOCK, self.RefreshPanelGeneralSkillByEvent, self)
    XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_ENHANCESKILL_UP, self.RefreshPanelGeneralSkillByEvent, self)
end

function XUiCharacterAttributeDetail:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_CHARACTER_SKILL_UNLOCK, self.RefreshPanelGeneralSkillByEvent, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_CHARACTER_SKILL_UP, self.RefreshPanelGeneralSkillByEvent, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_CHARACTER_ENHANCESKILL_UNLOCK, self.RefreshPanelGeneralSkillByEvent, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_CHARACTER_ENHANCESKILL_UP, self.RefreshPanelGeneralSkillByEvent, self)
end

function XUiCharacterAttributeDetail:RefreshByCharacterId(characterId, tabIndex, initGeneralSkillIndex)
    if not XTool.IsNumberValid(characterId) then
        return
    end
    if XRobotManager.CheckIsRobotId(characterId) then
        self.RobotId = characterId
    end
    characterId = XRobotManager.GetCharacterId(characterId)
    
    self.CharacterId = characterId
    self.InitGeneralSkillIndex = initGeneralSkillIndex
    -- 刷新
    self:UpdateDynamicTable()
    self.GeneralSkillIds = XMVCA.XCharacter:GetCharacterGeneralSkillIds(characterId)
    if not XTool.IsTableEmpty(self.GeneralSkillIds) then
        self:RefreshPanelGeneralSkill()
        self.XUiPanelGeneralSkill:Close()
    end
    self:RefreshPanelTotalGeneralSkill()
    self.BtnTab3.gameObject:SetActiveEx(not XTool.IsTableEmpty(self.GeneralSkillIds))
    
    self.BtnGroup:SelectIndex(tabIndex or 1)
end

function XUiCharacterAttributeDetail:OnSelectTab(index)
    self.CurSelectTabIndex = index
    for i = 1, self.BtnGroup.TabBtnList.Count, 1 do
        local isShow = i == index
        local panel = self["Panel"..i]
        panel.gameObject:SetActiveEx(isShow)

        local dytName = self.DytNameDic[i]
        if dytName then
            local dyt = self[dytName]
            if dyt then
                dyt:SetActive(isShow)
            end
        end

        if self.XUiPanelGeneralSkill and PanelEnum.SelfGeneralSkill == i then
            if isShow  then
                self.XUiPanelGeneralSkill:Open()
            else
                self.XUiPanelGeneralSkill:Close()
            end
        end

        if self._PanelTotalGeneralSkill and PanelEnum.TotalGeneralSkill == i then
            if isShow then
                self._PanelTotalGeneralSkill:Open()
            else
                self._PanelTotalGeneralSkill:Close()
            end
        end
        
    end
end

function XUiCharacterAttributeDetail:ConstructSortedElementIds(characterId)
    local sortedElementIds = {}

    local curElementIdsCheckDic = {}
    local curElementList = XMVCA.XCharacter:GetCharacterAllElement(characterId)
    if not XTool.IsTableEmpty(curElementList) then
        for _, elementId in pairs(curElementList) do
            curElementIdsCheckDic[elementId] = true
            table.insert(sortedElementIds, -elementId)
        end
    end

    local allElementIds = XMVCA.XCharacter:GetModelCharacterElement()
    for _, element in pairs(allElementIds) do
        local elementId = element.Id
        if not curElementIdsCheckDic[elementId] then
            table.insert(sortedElementIds, elementId)
        end
    end

    return sortedElementIds
end

function XUiCharacterAttributeDetail:UpdateDynamicTable()
    self.CareerIds = XMVCA.XCharacter:GetAllCharacterCareerIds()
    self.DynamicTableCareer:SetDataSource(self.CareerIds)

    local curCareerId = XMVCA.XCharacter:GetCharacterCareer(self.CharacterId)
    local _, index = table.contains(self.CareerIds, curCareerId)
    self.DynamicTableCareer:ReloadDataASync(index or 1)

    self.SortedElementIds = self:ConstructSortedElementIds(self.CharacterId)
    self.DynamicTableElement:SetDataSource(self.SortedElementIds)
    self.DynamicTableElement:ReloadDataASync()
end

function XUiCharacterAttributeDetail:OnDynamicTableCareerEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.CareerIds[index], self.CharacterId)
    end
end

function XUiCharacterAttributeDetail:OnDynamicTableElementEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.CharacterId, self.SortedElementIds[index])
    end
end

function XUiCharacterAttributeDetail:RefreshPanelGeneralSkill()
    if not self.XUiPanelGeneralSkill then
        local XUiPanelGeneralSkill = require("XUi/XUiCharacterV2P6/Grid/XUiPanelGeneralSkill")
        self.XUiPanelGeneralSkill = XUiPanelGeneralSkill.New(self.PanelGeneralSkill, self)
    end
    self.XUiPanelGeneralSkill:Refresh(self.CharacterId, self.InitGeneralSkillIndex, self.RobotId)
end

function XUiCharacterAttributeDetail:RefreshPanelGeneralSkillByEvent()
    self:RefreshPanelGeneralSkill()
end

function XUiCharacterAttributeDetail:RefreshPanelTotalGeneralSkill()
    if not self._PanelTotalGeneralSkill then
        self.PanelGeneralSkillTotal.gameObject:SetActiveEx(false)
        self._PanelTotalGeneralSkill = require('XUi/XUiCharacterV2P6/Grid/XUiPanelGeneralSkillTotal').New(self.PanelGeneralSkillTotal, self)
    end

    self._PanelTotalGeneralSkill:Close()
end 