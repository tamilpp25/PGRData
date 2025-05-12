local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiTheatre4BubbleBagGrid = require("XUi/XUiTheatre4/Game/Bubble/XUiTheatre4BubbleBagGrid")
---@class XUiTheatre4BubbleBag : XLuaUi
---@field private _Control XTheatre4Control
local XUiTheatre4BubbleBag = XLuaUiManager.Register(XLuaUi, "UiTheatre4BubbleBag")

function XUiTheatre4BubbleBag:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    self.PanelNone.gameObject:SetActiveEx(false)
    self.Grid.gameObject:SetActiveEx(false)
end

function XUiTheatre4BubbleBag:OnStart()
    self:InitDynamicTable()
end

function XUiTheatre4BubbleBag:OnEnable()
    self:RefreshAffixInfo()
    self:SetupDynamicTable()
    self:RefreshNum()
end

-- 刷新藏品数量和上限
function XUiTheatre4BubbleBag:RefreshNum()
    local count = table.nums(self.DataList)
    local limit = self._Control.AssetSubControl:GetItemLimit()
    self.TxtNum.text = string.format("%s/%s", count, limit)
end

-- 刷新词缀信息
function XUiTheatre4BubbleBag:RefreshAffixInfo()
    local affix = self._Control:GetAffix()
    local icon = self._Control:GetAffixIcon(affix)
    if icon then
        self.ImgStartEffect:SetSprite(icon)
    end
    self.TxtDetail.text = self._Control:GetAffixDesc(affix)
end

function XUiTheatre4BubbleBag:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelBagList)
    self.DynamicTable:SetProxy(XUiTheatre4BubbleBagGrid, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiTheatre4BubbleBag:SetupDynamicTable()
    self.DataList = self._Control:GetBagSideItemDataList()
    if XTool.IsTableEmpty(self.DataList) then
        self.PanelNone.gameObject:SetActiveEx(true)
        return
    end
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync()
end

---@param grid XUiTheatre4BubbleBagGrid
function XUiTheatre4BubbleBag:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index])
    end
end

function XUiTheatre4BubbleBag:OnBtnCloseClick()
    self:Close()
end

return XUiTheatre4BubbleBag
