local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridTheatre4Prop = require("XUi/XUiTheatre4/Common/XUiGridTheatre4Prop")
local XUiGridTheatre4Genius = require("XUi/XUiTheatre4/Common/XUiGridTheatre4Genius")
local XUiGridTheatre4GeniusCard = require("XUi/XUiTheatre4/Common/XUiGridTheatre4GeniusCard")
local XUiGridTheatre4PropCard = require("XUi/XUiTheatre4/Common/XUiGridTheatre4PropCard")
local XUiTheatre4ColorResource = require("XUi/XUiTheatre4/System/Resources/XUiTheatre4ColorResource")
---@class XUiPanelTheatre4SettlementPageOne : XUiNode
---@field private _Control XTheatre4Control
---@field Parent XUiTheatre4Settlement
local XUiPanelTheatre4SettlementPageOne = XClass(XUiNode, "XUiPanelTheatre4SettlementPageOne")

function XUiPanelTheatre4SettlementPageOne:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnNext, self.OnBtnNextClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    self.GridProp.gameObject:SetActiveEx(false)
    self.TxtItemNone.gameObject:SetActiveEx(false)
    self.GridGenius.gameObject:SetActiveEx(false)
    self.TxtComboNone.gameObject:SetActiveEx(false)
    self.BtnClose.gameObject:SetActiveEx(false)
    self:InitPropDynamicTable()
    self:InitGeniusDynamicTable()
    -- 冒险结算数据
    ---@type XTheatre4Adventure
    self.AdventureSettleData = self._Control:GetAdventureSettleData()
end

function XUiPanelTheatre4SettlementPageOne:Refresh(isPlayMoveBack)
    if XTool.IsTableEmpty(self.AdventureSettleData) then
        XLog.Error("AdventureSettleData is nil")
        return
    end
    self:RefreshAffix()
    self:RefreshProsperity()
    self:RefreshColorResource()
    self:SetupPropDynamicTable()
    self:SetupGeniusDynamicTable()
    if isPlayMoveBack then
        self.Parent:PlayAnimationWithMask("UiMoveBack")
    end
end

-- 刷新词缀
function XUiPanelTheatre4SettlementPageOne:RefreshAffix()
    local affix = self.AdventureSettleData:GetAffix()
    if affix == 0 then
        self.RImgIcon.transform.parent.gameObject:SetActiveEx(false)
        return
    end
    local icon = self._Control:GetAffixIcon(affix)
    if icon then
        self.RImgIcon:SetRawImage(icon)
    end
    self.TxtName.text = self._Control:GetAffixName(affix)
end

-- 刷新繁荣度
function XUiPanelTheatre4SettlementPageOne:RefreshProsperity()
    -- 繁荣度图片
    local prosperityIcon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.Prosperity)
    if prosperityIcon then
        self.ImgScore:SetRawImage(prosperityIcon)
    end
    -- 繁荣度数字
    self.TxtScoreNum.text = self.AdventureSettleData:GetProsperity()
end

-- 刷新颜色资源
function XUiPanelTheatre4SettlementPageOne:RefreshColorResource()
    local colorDataList = {}
    for _, colorId in pairs(XEnumConst.Theatre4.ColorType) do
        local colorData = self.AdventureSettleData:GetColorData(colorId)
        if colorData then
            table.insert(colorDataList, {
                Id = colorId,
                Resource = colorData:GetPoint(),
                Level = 0,
                TalentLevel = self._Control:GetColorTalentLevel(colorId, colorData:GetPoint())
            })
        end
    end
    if not self.PanelColour then
        ---@type XUiTheatre4ColorResource
        self.PanelColour = XUiTheatre4ColorResource.New(self.ListColour, self, nil, true)
    end
    self.PanelColour:Open()
    self.PanelColour:RefreshData(colorDataList)
end

-- 刷新藏品列表
function XUiPanelTheatre4SettlementPageOne:InitPropDynamicTable()
    self.PropDynamicTable = XDynamicTableNormal.New(self.PanelPropList)
    self.PropDynamicTable:SetProxy(XUiGridTheatre4Prop, self, handler(self, self.OnGridPropClick))
    self.PropDynamicTable:SetDelegate(self)
    self.PropDynamicTable:SetDynamicEventDelegate(function(event, index, grid)
        self:OnPropDynamicTableEvent(event, index, grid)
    end)
end

function XUiPanelTheatre4SettlementPageOne:SetupPropDynamicTable()
    self.PropDataList = self:GetPropDataList()
    if XTool.IsTableEmpty(self.PropDataList) then
        self.TxtItemNone.gameObject:SetActiveEx(true)
        return
    end
    self.PropDynamicTable:SetDataSource(self.PropDataList)
    self.PropDynamicTable:ReloadDataASync()
end

-- 获取藏品数据列表
function XUiPanelTheatre4SettlementPageOne:GetPropDataList()
    local PropDataList = {}
    local type = XEnumConst.Theatre4.AssetType.Item
    ---@type table<number, XTheatre4Item>[]
    local allItems = { self.AdventureSettleData:GetItems(), self.AdventureSettleData:GetProps() }
    for _, items in pairs(allItems) do
        for _, item in pairs(items) do
            if self._Control:CheckShowItem(item:GetItemId()) then
                table.insert(PropDataList, { UId = item:GetUid(), Id = item:GetItemId(), Type = type })
            end
        end
    end
    return PropDataList
end

---@param grid XUiGridTheatre4Prop
function XUiPanelTheatre4SettlementPageOne:OnPropDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.PropDataList[index])
    end
end

-- 选择藏品
---@param grid XUiGridTheatre4Prop
function XUiPanelTheatre4SettlementPageOne:OnGridPropClick(grid)
    grid:SetSelect(true)
    self.CurSelectPropGrid = grid
    self:OpenPropCard(grid:GetItemData())
end

-- 刷新天赋列表
function XUiPanelTheatre4SettlementPageOne:InitGeniusDynamicTable()
    self.GeniusDynamicTable = XDynamicTableNormal.New(self.PanelGeniusList)
    self.GeniusDynamicTable:SetProxy(XUiGridTheatre4Genius, self, handler(self, self.OnGridGeniusClick))
    self.GeniusDynamicTable:SetDelegate(self)
    self.GeniusDynamicTable:SetDynamicEventDelegate(function(event, index, grid)
        self:OnGeniusDynamicTableEvent(event, index, grid)
    end)
end

function XUiPanelTheatre4SettlementPageOne:SetupGeniusDynamicTable()
    self.GeniusDataList = self:GetGeniusDataList()
    if XTool.IsTableEmpty(self.GeniusDataList) then
        self.TxtComboNone.gameObject:SetActiveEx(true)
        return
    end
    self.GeniusDynamicTable:SetDataSource(self.GeniusDataList)
    self.GeniusDynamicTable:ReloadDataASync()
end

-- 获取天赋数据列表
function XUiPanelTheatre4SettlementPageOne:GetGeniusDataList()
    local activeTalentIds = self.AdventureSettleData:GetAllActiveTalentIds()
    local talentIds = {}
    for _, talentId in pairs(activeTalentIds) do
        if self._Control:CheckColorTalentJoinAdventureSettle(talentId) then
            table.insert(talentIds, talentId)
        end
    end
    return talentIds
end

---@param grid XUiGridTheatre4Genius
function XUiPanelTheatre4SettlementPageOne:OnGeniusDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.GeniusDataList[index])
    end
end

-- 选择天赋
---@param grid XUiGridTheatre4Genius
function XUiPanelTheatre4SettlementPageOne:OnGridGeniusClick(grid)
    grid:SetSelect(true)
    self.CurSelectGeniusGrid = grid
    self:OpenGeniusCard(grid:GetTalentId())
end

-- 打开天赋卡片
function XUiPanelTheatre4SettlementPageOne:OpenGeniusCard(talentId)
    if not self.PanelGeniusCard then
        ---@type XUiGridTheatre4GeniusCard
        self.PanelGeniusCard = XUiGridTheatre4GeniusCard.New(self.GridGeniusCard, self)
    end
    self.PanelGeniusCard:Open()
    self.PanelGeniusCard:Refresh(talentId)
    self.BtnClose.gameObject:SetActiveEx(true)
end

-- 关闭天赋卡片
function XUiPanelTheatre4SettlementPageOne:CloseGeniusCard()
    if self.CurSelectGeniusGrid then
        self.CurSelectGeniusGrid:SetSelect(false)
        self.CurSelectGeniusGrid = nil
    end
    if self.PanelGeniusCard then
        self.PanelGeniusCard:Close()
    end
end

-- 打开藏品卡片
function XUiPanelTheatre4SettlementPageOne:OpenPropCard(itemData)
    if not self.PanelPropCard then
        ---@type XUiGridTheatre4PropCard
        self.PanelPropCard = XUiGridTheatre4PropCard.New(self.GridPropCard, self)
    end
    self.PanelPropCard:Open()
    self.PanelPropCard:Refresh(itemData)
    self.BtnClose.gameObject:SetActiveEx(true)
end

-- 关闭藏品卡片
function XUiPanelTheatre4SettlementPageOne:ClosePropCard()
    if self.CurSelectPropGrid then
        self.CurSelectPropGrid:SetSelect(false)
        self.CurSelectPropGrid = nil
    end
    if self.PanelPropCard then
        self.PanelPropCard:Close()
    end
end

function XUiPanelTheatre4SettlementPageOne:OnBtnNextClick()
    self:OnBtnCloseClick()
    self.Parent:ShowPageTwo()
end

function XUiPanelTheatre4SettlementPageOne:OnBtnCloseClick()
    self:CloseGeniusCard()
    self:ClosePropCard()
    self.BtnClose.gameObject:SetActiveEx(false)
end

return XUiPanelTheatre4SettlementPageOne
