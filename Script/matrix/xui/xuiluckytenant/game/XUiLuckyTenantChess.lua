local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")
local XUiLuckyTenantChessSelectGrid = require("XUi/XUiLuckyTenant/Game/XUiLuckyTenantChessSelectGrid")
local XUiLuckyTenantChessBag = require("XUi/XUiLuckyTenant/Game/Bag/XUiLuckyTenantChessBag")
local Tab = {
    None = 0,
    AddPiece = 1,
    Bag = 2,
}

---@class XUiLuckyTenantChess : XUiLuckyTenantChessBag
---@field _Control XLuckyTenantControl
local XUiLuckyTenantChess = XLuaUiManager.Register(XUiLuckyTenantChessBag, "UiLuckyTenantChess")

function XUiLuckyTenantChess:Ctor()
    self._Tab = Tab.None
end

function XUiLuckyTenantChess:OnAwake()
    self.Super.OnAwake(self)
    ---@type XUiLuckyTenantChessSelectGrid[]
    self._ChessGrids = {}
    self:BindExitBtns()
    XUiHelper.RegisterClickEvent(self, self.BtnRefreshFree, self.OnClickRefresh, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnRefreshNoFree, self.OnClickRefresh, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnSupply, self.SetTabAddPiece, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnDelete, self.SetTabBag, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnBag, self.OpenBag, nil, true)
    self.TopControlWhite.gameObject:SetActiveEx(false)
    self.BtnGroup.gameObject:SetActiveEx(true)
    self:SetTab(Tab.AddPiece)
    local uiData = self._Control:GetUiData()
    self.BtnDelete.gameObject:SetActiveEx(uiData.IsShowDeleteOption)
    self.BtnDeleteNoFree.gameObject:SetActiveEx(false)
    self.BtnDeleteFree.gameObject:SetActiveEx(true)
    self.BtnDeleteFree:SetNameByGroup(0, XLuckyTenantEnum.Cost)
    self.BtnRefreshNoFree:SetNameByGroup(0, XLuckyTenantEnum.Cost)
    --self.BtnRefreshFree:SetNameByGroup(0, XLuckyTenantEnum.Cost)
    XUiHelper.RegisterClickEvent(self, self.BtnDeleteFree, self._OnClickDelete, nil, true)

    local XUiButton = require("XUi/XUiCommon/XUiButton")
    ---@type XUiButtonLua
    local button = XUiButton.New(self.BtnRefreshNoFree)
    local refreshPropIcon = self._Control:GetRefreshPropIcon()
    button:SetRawImage("ImgNoFreeIcon02", refreshPropIcon)
end

function XUiLuckyTenantChess:OnEnable()
    -- 不在OnEnable时update
    self:StartListen()
    self:UpdateFreeRefreshTimes()
end

function XUiLuckyTenantChess:UpdateRefreshTimes()
    self:UpdateFreeRefreshTimes()
    local uiData = self._Control:GetUiData()
    if uiData.FreeRefreshTimes > 0 then
        self.BtnRefreshFree.gameObject:SetActiveEx(true)
        self.BtnRefreshNoFree.gameObject:SetActiveEx(false)
        self.BtnRefreshFree:SetNameByGroup(0, uiData.FreeRefreshTimes)
    else
        self.BtnRefreshFree.gameObject:SetActiveEx(false)
        self.BtnRefreshNoFree.gameObject:SetActiveEx(true)
    end
end

function XUiLuckyTenantChess:UpdateAddPiece()
    local uiData = self._Control:GetUiData()
    self.PanelSupply.gameObject:SetActiveEx(true)
    self.PanelChess.gameObject:SetActiveEx(false)
    XTool.UpdateDynamicItem(self._ChessGrids, uiData.SelectPiecesData.Pieces, self.PanelChess, XUiLuckyTenantChessSelectGrid, self)
    if XMain.IsZlbDebug then
        if #uiData.SelectPiecesData.Pieces <= 0 then
            XUiManager.TipMsg("no pieces to select, error")
            XLuaUiManager.SafeClose("UiLuckyTenantGame")
            self:Close()
            return false
        end
    end
    return true
end

function XUiLuckyTenantChess:OnClickRefresh()
    if XMVCA.XLuckyTenant:IsRequesting() then
        return
    end
    if self._Control:RefreshSelectPiecesByProp() then
        self:UpdateRefreshTimes()
        if not self:UpdateAddPiece() then
            return
        end
        self:UpdateProp()
    end
end

function XUiLuckyTenantChess:SetTab(tab)
    if self._Tab == tab then
        return
    end
    self:PlayAnimation("Switch")
    self._Tab = tab
    if tab == Tab.AddPiece then
        self.SelectPiecePanel.gameObject:SetActiveEx(true)
        for i = 1, #self._Grids do
            local grid = self._Grids[i]
            grid:Close()
        end
        self._Detail:Close()
        self.BagPanel.gameObject:SetActiveEx(false)
        self.PanelDelete.gameObject:SetActiveEx(false)
        self:UpdateRefreshTimes()
        self:UpdateTag()
        if not self:UpdateAddPiece() then
            return
        end
        self:UpdateProp()
        if self.BtnBag then
            self.BtnBag:SetNameByGroup(0, self._Control:GetUiData().PiecesAmount)
        end
        return
    end
    if tab == Tab.Bag then
        self.SelectPiecePanel.gameObject:SetActiveEx(false)
        self.BagPanel.gameObject:SetActiveEx(true)
        self.PanelDelete.gameObject:SetActiveEx(true)
        self:UpdateBag()
        return
    end
    XLog.Error("[XUiLuckyTenantChess] 未定义的页签")
end

function XUiLuckyTenantChess:SetTabAddPiece()
    self:SetTab(Tab.AddPiece)
end

function XUiLuckyTenantChess:SetTabBag()
    self:SetTab(Tab.Bag)
end

function XUiLuckyTenantChess:OpenBag()
    local hideDelete = true
    XLuaUiManager.Open("UiLuckyTenantChessBag", hideDelete)
end

function XUiLuckyTenantChess:_OnClickDelete()
    if XMVCA.XLuckyTenant:IsRequesting() then
        return
    end
    local uiData = self._Control:GetUiData()
    if uiData.SelectedBagPiece then
        XLuaUiManager.Open("UiLuckyTenantDeleteDetail")
    end
end

function XUiLuckyTenantChess:UpdateFreeRefreshTimes()
    local remainFreeTimes = self._Control:GetUiData().FreeRefreshTimes
    self.BtnRefreshFree:SetNameByGroup(0, remainFreeTimes)
end

return XUiLuckyTenantChess