--- 背包列表项
---@class XUiGridBagOrganizeBag: XUiNode
---@field private _Control XBagOrganizeActivityControl
---@field private _GameControl XBagOrganizeActivityGameControl
local XUiGridBagOrganizeBag = XClass(XUiNode, 'XUiGridBagOrganizeBag')
local BagCostLabelNormal = nil
local BagCostLabelDiscount = nil

function XUiGridBagOrganizeBag:OnStart()
    self._GameControl = self._Control.GameControl

    BagCostLabelNormal = self._Control:GetClientConfigText('BagCostLabel', 1)
    BagCostLabelDiscount = self._Control:GetClientConfigText('BagCostLabel', 2)

end

function XUiGridBagOrganizeBag:OnEnable()
    self.GridBtn:SetButtonState(CS.UiButtonState.Normal)
end

function XUiGridBagOrganizeBag:Refresh(mapId, bagDiscount)
    self.MapId = mapId
    
    ---@type XTableBagOrganizeBags
    local cfg = self._Control:GetBagOrganizeBagCfgById(self.MapId)
    
    if cfg then
        if bagDiscount < 1 then
            self.GridBtn:SetNameByGroup(0, XUiHelper.FormatText(BagCostLabelDiscount, math.ceil(cfg.Cost * bagDiscount)))
        else
            self.GridBtn:SetNameByGroup(0, XUiHelper.FormatText(BagCostLabelNormal, cfg.Cost))
        end
        self.GridBtn:SetRawImage(cfg.IconAddress)
        self.GridBtn:SetNameByGroup(1, XUiHelper.FormatText(self._Control:GetClientConfigText('BagSizeLabel'), cfg.MaxWidth, cfg.MaxHeight))
    end

    self.GridBtn:SetButtonState(self._IsSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiGridBagOrganizeBag:RefreshSelectState(isSelect)
    self._IsSelect = isSelect
    self.GridBtn:SetButtonState(self._IsSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiGridBagOrganizeBag:RefreshCost(bagDiscount)
    ---@type XTableBagOrganizeBags
    local cfg = self._Control:GetBagOrganizeBagCfgById(self.MapId)

    if cfg then
        if bagDiscount < 1 then
            self.GridBtn:SetNameByGroup(0, XUiHelper.FormatText(BagCostLabelDiscount, math.ceil(cfg.Cost * bagDiscount)))
        else
            self.GridBtn:SetNameByGroup(0, XUiHelper.FormatText(BagCostLabelNormal, cfg.Cost))
        end
    end
end

function XUiGridBagOrganizeBag:OnBagSelected()
    self.Parent:RefreshAllBagGridUnSelect()
    self:RefreshSelectState(true)
    self._GameControl.MapControl:LoadMapByMapId(self.MapId)
    self._GameControl.MapControl:RecheckAllPlacedGoodsIsValid()
    self._GameControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_REFRESH_MAP_SHOW)
    self._GameControl:RefreshValidTotalScore()
end


return XUiGridBagOrganizeBag