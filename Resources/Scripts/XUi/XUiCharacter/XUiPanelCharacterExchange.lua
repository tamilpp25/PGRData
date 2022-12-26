local XUiGridCharacterNew = require("XUi/XUiCharacter/XUiGridCharacterNew")

local TabBtnIndex = {
    Normal = 1,
    Isomer = 2,
}
local CharacterTypeConvert = {
    [TabBtnIndex.Normal] = XCharacterConfigs.CharacterType.Normal,
    [TabBtnIndex.Isomer] = XCharacterConfigs.CharacterType.Isomer,
}
local CSXTextManagerGetText = CS.XTextManager.GetText
local BtnGouzaotiName = CSXTextManagerGetText("UiPanelCharacterExchangeBtnNameGouzaoti")
local BtnGanrantiName = CSXTextManagerGetText("UiPanelCharacterExchangeBtnNameGanranti")

local XUiPanelCharacterExchange = XLuaUiManager.Register(XLuaUi, "UiPanelCharacterExchange")

function XUiPanelCharacterExchange:OnAwake()
    self:AutoAddListener()
    self.GridCharacterNew.gameObject:SetActiveEx(false)

    local isIsomerOpen = XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Isomer) and not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Isomer)
    self.BtnGouzaoti.gameObject:SetActiveEx(isIsomerOpen)
    self.BtnGouzaoti.CallBack = function()
        local btnIndex = self.SelectTabBtnIndex == TabBtnIndex.Isomer and TabBtnIndex.Normal or TabBtnIndex.Isomer
        self:OnSelectCharacterType(btnIndex)
    end
end

function XUiPanelCharacterExchange:OnStart(parent, closeCb)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelScrollView)
    self.DynamicTable:SetProxy(XUiGridCharacterNew)
    self.DynamicTable:SetDelegate(self)

    self.Parent = parent
    self.CloseCb = closeCb
end

function XUiPanelCharacterExchange:OnEnable()
    local characterId = self.Parent.CharacterId
    self.CharacterId = characterId

    local characterType = CharacterTypeConvert[self.SelectTabBtnIndex]
    local paramCharacterType = XCharacterConfigs.GetCharacterType(characterId)
    if paramCharacterType ~= characterType then
        --选中角色与当前类型页签不符时，强制选中对应角色类型页签
        if XCharacterConfigs.IsIsomer(characterId) then
            self.LastSelectIsomerCharacterId = characterId
            -- self.PanelCharacterTypeBtns:SelectIndex(TabBtnIndex.Isomer)
            self:OnSelectCharacterType(TabBtnIndex.Isomer)
        else
            self.LastSelectNormalCharacterId = characterId
            -- self.PanelCharacterTypeBtns:SelectIndex(TabBtnIndex.Normal)
            self:OnSelectCharacterType(TabBtnIndex.Normal)
        end
    else
        self:OnSelectCharacterType(self.SelectTabBtnIndex)
        -- self.PanelCharacterTypeBtns:SelectIndex(self.SelectTabBtnIndex)
    end
end

function XUiPanelCharacterExchange:OnSelectCharacterType(index)
    self.SelectTabBtnIndex = index

    if index == TabBtnIndex.Isomer then
        self.BtnGouzaoti:SetNameByGroup(0, BtnGanrantiName)
    elseif index == TabBtnIndex.Normal then
        self.BtnGouzaoti:SetNameByGroup(0, BtnGouzaotiName)
    end

    self:SetupDynamicTable()
end

function XUiPanelCharacterExchange:SetupDynamicTable()
    local characterType = CharacterTypeConvert[self.SelectTabBtnIndex]
    self.CharList = XDataCenter.CharacterManager.GetOwnCharacterList(characterType, true)
    if not self.CharList then
        return
    end

    local len = #self.CharList
    local index = 1

    for i = 1, len do
        if self.CharList[i].Id == self.CharacterId then
            index = i
            break
        end
    end

    self.DynamicTable:SetDataSource(self.CharList)
    self.DynamicTable:ReloadDataASync(index)
end

function XUiPanelCharacterExchange:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.CharList[index]
        grid:Reset()
        grid:UpdateGrid(data)

        if self.CharacterId == data.Id then
            self.CurSelectGrid = grid
        end

        grid:SetSelect(self.CharacterId == data.Id)
        grid:SetCurSignState(self.CharacterId == data.Id)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local charData = self.CharList[index]

        if not XCharacterConfigs.IsCharacterForeShow(charData.Id) then
            XUiManager.TipMsg(CS.XTextManager.GetText("ComingSoon"), XUiManager.UiTipType.Tip)
            return
        end

        if self.CharacterId ~= charData.Id then
            self.CharacterId = charData.Id

            if self.CurSelectGrid then
                self.CurSelectGrid:SetSelect(false)
                self.CurSelectGrid:SetCurSignState(false)
            end

            grid:SetSelect(true)
            grid:SetCurSignState(true)
            self.CurSelectGrid = grid
        end

        self:OnSelectCharacter()
    end
end

function XUiPanelCharacterExchange:AutoAddListener()
    self:RegisterClickEvent(self.BtnCancel, self.OnBtnCancelClick)
    self:RegisterClickEvent(self.BtnAllCategory, self.OnBtnAllCategory)
end

function XUiPanelCharacterExchange:OnBtnCancelClick()
    self:OnSelectCharacter()
end

function XUiPanelCharacterExchange:OnBtnAllCategory()
    XDataCenter.RoomCharFilterTipsManager.Reset()
    self:SetupDynamicTable()
end

function XUiPanelCharacterExchange:OnSelectCharacter()
    if self.CloseCb then
        self.CloseCb(self.CharacterId)
    end
end

return XUiPanelCharacterExchange