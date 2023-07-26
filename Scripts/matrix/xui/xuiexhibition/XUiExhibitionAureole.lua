local XUiExhibitionAureole = XLuaUiManager.Register(XLuaUi, "UiExhibitionAureole")
local XUiGridExhibitionAureBallSelect = require("XUi/XUiExhibition/XUiGridExhibitionAureBallSelect") -- 选球或者环

function XUiExhibitionAureole:OnAwake()
    self.TextTitleDic = {}
    self.TextDescDic = {}
    self:InitButton()
    self:InitDynamicTable()
end

function XUiExhibitionAureole:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelList)
    self.DynamicTable:SetProxy(XUiGridExhibitionAureBallSelect, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiExhibitionAureole:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnCloes, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.OnBtnConfirmClick)
end

function XUiExhibitionAureole:OnStart(list, currIndex, titleName, titleDesc, confirmCb, onSelectCb, closeCb)
    self.DataList = list
    self.CurrInitIndex = currIndex
    self.CurrSelectIndex = currIndex
    self.ConfirmCb = confirmCb
    self.OnSelectCb = onSelectCb
    self.CloseCb = closeCb

    self.TxtTitle.text = titleName
    self.TextName.text = titleDesc
end

function XUiExhibitionAureole:OnEnable()
    self:RefreshUiShow()
end

function XUiExhibitionAureole:RefreshUiShow()
    self:RefreshDynamicTable(self.DataList)
end

function XUiExhibitionAureole:RefreshDynamicTable(list)
    self.DynamicTable:SetDataSource(list)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiExhibitionAureole:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index], index)
        grid:SetUsing(index == self.CurrInitIndex)
        local isSelect = index == self.CurrSelectIndex
        grid:SetSelect(isSelect)
        if isSelect then
            self.CurrGrid = grid
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.CurrGrid:SetSelect(false)
        grid:SetSelect(true)
        self.CurrGrid = grid
        self.CurrSelectIndex = index
    end
end

function XUiExhibitionAureole:OnGridSelect(grid)
    if self.TargetId == grid.Id then
        return
    end

    self.TargetId = grid.Id
    if self.OnSelectCb then
        self.OnSelectCb(grid.Id, grid.Index, self)
    end
end

function XUiExhibitionAureole:OnBtnConfirmClick()
    if self.ConfirmCb then
        self.ConfirmCb(self.TargetId)
    end
    self:Close()
end

function XUiExhibitionAureole:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end

return XUiExhibitionAureole