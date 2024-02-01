local XUiCharacterAttributeDetail = XLuaUiManager.Register(XLuaUi, "UiCharacterAttributeDetail")

function XUiCharacterAttributeDetail:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)
    local btns = { self.BtnTab1, self.BtnTab2, self.BtnTab3 }
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
    if not XTool.IsNumberValid(characterId) then
        return
    end

    self.CharacterId = characterId
    self.InitGeneralSkillIndex = initGeneralSkillIndex
    -- 刷新
    self:UpdateDynamicTable()
    self.GeneralSkillIds = XMVCA.XCharacter:GetCharacterGeneralSkillIds(characterId)
    if not XTool.IsTableEmpty(self.GeneralSkillIds) then
        self:RefreshPanelGeneralSkill()
    end
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

        if self.XUiPanelGeneralSkill and self.BtnGroup.TabBtnList.Count == i then
            if isShow  then
                self.XUiPanelGeneralSkill:Open()
            else
                self.XUiPanelGeneralSkill:Close()
            end
        end
    end
end

function XUiCharacterAttributeDetail:ConstructSortedElementIds(characterId)
    local sortedElementIds = {}

    local curElementIdsCheckDic = {}
    local detailConfig = XMVCA.XCharacter:GetCharDetailTemplate(characterId)
    local curElementList = detailConfig.ObtainElementList
    for _, elementId in pairs(curElementList) do
        curElementIdsCheckDic[elementId] = true
        table.insert(sortedElementIds, -elementId)
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
        grid:Refresh(self.SortedElementIds[index])
    end
end

function XUiCharacterAttributeDetail:RefreshPanelGeneralSkill()
    local XUiPanelGeneralSkill = require("XUi/XUiCharacterV2P6/Grid/XUiPanelGeneralSkill")
    self.XUiPanelGeneralSkill = XUiPanelGeneralSkill.New(self.PanelGeneralSkill, self, self.CharacterId, self.InitGeneralSkillIndex)
    self.XUiPanelGeneralSkill:Close()
end