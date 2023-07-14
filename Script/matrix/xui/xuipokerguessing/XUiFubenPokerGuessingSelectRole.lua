local XUiGridPokerGuessingRole = XClass(nil, "XUiGridPokerGuessingRole")

function XUiGridPokerGuessingRole:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridPokerGuessingRole:Refresh(data, useId)
    self.ImgIcon:SetRawImage(data.RoundnessNotItemHeadIcon)
    self.TxtName.text = XCharacterConfigs.GetCharacterName(data.CharacterId)
    self.ImgUse.gameObject:SetActiveEx(data.Id == useId)
    self:SetSelect(false)
end

function XUiGridPokerGuessingRole:SetSelect(select)
    self.ImgSelect.gameObject:SetActiveEx(select)
end



local XUiFubenPokerGuessingSelectRole = XLuaUiManager.Register(XLuaUi, "UiFubenPokerGuessingSelectRole")

function XUiFubenPokerGuessingSelectRole:OnAwake()
    self:InitCb()
    self:InitDynamicTable()
end 

function XUiFubenPokerGuessingSelectRole:OnStart(usedId)
    self.UsedId = usedId
    self.PokerGuessing = XDataCenter.PokerGuessingManager.GetPokerGuessingData()
    self:SetupDynamicTable()
end 

function XUiFubenPokerGuessingSelectRole:InitCb()
    self.BtnClose.CallBack = function() self:Close() end
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.BtnCancel.CallBack = function() self:Close() end
    self.BtnConfirm.CallBack = function() 
        self:OnBtnConfirmClick()
    end
end 

function XUiFubenPokerGuessingSelectRole:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelSelectList)
    self.DynamicTable:SetProxy(XUiGridPokerGuessingRole)
    self.DynamicTable:SetDelegate(self)
    self.DormSelectItem.gameObject:SetActiveEx(false)
end 

function XUiFubenPokerGuessingSelectRole:SetupDynamicTable()
    self.RoleList = {}
    local list = XTool.Clone(XPokerGuessingConfig.PokerRoleConfig:GetConfigs())
    
    table.sort(list, function(a, b) 
        return a.Id < b.Id
    end)
    self.RoleList = list
    self.DynamicTable:SetDataSource(self.RoleList)
    self.DynamicTable:ReloadDataASync()
end 

function XUiFubenPokerGuessingSelectRole:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.RoleList[index], self.UsedId)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnSelect(index, grid)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local tmpGrid = self.DynamicTable:GetGridByIndex(1)
        tmpGrid:SetSelect(true)
        self:OnSelect(1, tmpGrid)
    end
end 

function XUiFubenPokerGuessingSelectRole:RefreshButtonState()
    local used = self.SelectId == self.UsedId 
    self.BtnConfirm:SetDisable(used, not used)
end 

function XUiFubenPokerGuessingSelectRole:OnBtnConfirmClick()
    XUiManager.TipText("PokerGuessingCharacterSwitch")
    self.PokerGuessing:RefreshSelectRoleId(self.SelectId)
    self:Close()
end

function XUiFubenPokerGuessingSelectRole:OnSelect(index, grid)
    if not grid then
        return
    end
    self.SelectId = self.RoleList[index].Id
    grid:SetSelect(true)
    self:RefreshButtonState()
    if self.LastGrid then
        self.LastGrid:SetSelect(false)
    end
    self.LastGrid = grid
end 