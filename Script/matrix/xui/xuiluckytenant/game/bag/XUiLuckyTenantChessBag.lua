local XUiLuckyTenantChessBagGroup = require("XUi/XUiLuckyTenant/Game/Bag/XUiLuckyTenantChessBagGroup")
local XUiLuckyTenantChessGrid = require("XUi/XUiLuckyTenant/Game/XUiLuckyTenantChessGrid")
local XLuckyTenantTool = require("XUi/XUiLuckyTenant/XLuckyTenantTool")
local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")
local XUiLuckyTenantTag = require("XUi/XUiLuckyTenant/Game/XUiLuckyTenantTag")

---注意事项： 这个界面和XUiLuckyTenantChess是共用一个ui的
---@class XUiLuckyTenantChessBag : XLuaUi
---@field _Control XLuckyTenantControl
local XUiLuckyTenantChessBag = XLuaUiManager.Register(XLuaUi, "UiLuckyTenantChessBag")

function XUiLuckyTenantChessBag:Ctor()
    self._Tags = {}
end

function XUiLuckyTenantChessBag:OnAwake()
    self._Grids = {}
    self.SelectPiecePanel.gameObject:SetActiveEx(false)
    self.BagPanel.gameObject:SetActiveEx(true)
    self.TopControlWhite.gameObject:SetActiveEx(true)
    self.BtnGroup.gameObject:SetActiveEx(false)
    self:BindExitBtns()
    ---@type XUiLuckyTenantChessGrid
    self._Detail = XUiLuckyTenantChessGrid.New(self.GirdLuckyLandlordChessDetail, self)
    XUiHelper.RegisterClickEvent(self, self.BtnDeleteNoFree, self._OnClickDelete, nil, true)
    self.BtnDeleteNoFree:SetNameByGroup(0, XLuckyTenantEnum.Cost)
    self.BtnDeleteFree.gameObject:SetActiveEx(false)
    self.BtnDeleteNoFree.gameObject:SetActiveEx(true)
    self.RewardTips.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangCloseBig, self.CloseRewardTips, nil, true)
    
    local XUiButton = require("XUi/XUiCommon/XUiButton")
    ---@type XUiButtonLua
    local button = XUiButton.New(self.BtnDeleteNoFree)
    local deletePropIcon = self._Control:GetDeletePropIcon()
    button:SetRawImage("ImgNoFreeIcon02", deletePropIcon)
end

function XUiLuckyTenantChessBag:OnStart(hideDelete)
    if hideDelete then
        self.BtnDeleteNoFree.gameObject:SetActiveEx(false)
        self.BtnDeleteFree.gameObject:SetActiveEx(false)
    end
end

function XUiLuckyTenantChessBag:OnEnable()
    self._Control:SelectBagPiece(false)
    self:UpdateBag()
    self:StartListen()
end

function XUiLuckyTenantChessBag:StartListen()
    XEventManager.AddEventListener(XEventId.EVENT_LUCKY_TENANT_UPDATE_BAG, self.UpdateBag, self)
    XEventManager.AddEventListener(XEventId.EVENT_LUCKY_TENANT_ON_CLICK_REWARD, self.OpenRewardTips, self)
end

function XUiLuckyTenantChessBag:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_LUCKY_TENANT_UPDATE_BAG, self.UpdateBag, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_LUCKY_TENANT_ON_CLICK_REWARD, self.OpenRewardTips, self)
end

function XUiLuckyTenantChessBag:UpdatePiecesAmount()
    local data = self._Control:GetUiData()
    local amount = data.PiecesAmount
    self.TxtBagNumber.text = amount
end

function XUiLuckyTenantChessBag:UpdateBag()
    self:UpdatePiecesAmount()
    self:UpdateProp()
    self:UpdateTag()

    self._Control:UpdateBag()
    local uiData = self._Control:GetUiData()
    local bagData = uiData.Bag
    XTool.UpdateDynamicItem(self._Grids, bagData, self.PanelProp, XUiLuckyTenantChessBagGroup, self)

    if uiData.SelectedBagPiece then
        self.PanelNotSelected.gameObject:SetActiveEx(false)
        self._Detail:Open()
        self._Detail:Update(uiData.SelectedBagPiece)
    else
        self.PanelNotSelected.gameObject:SetActiveEx(true)
        self._Detail:Close()
    end
end

function XUiLuckyTenantChessBag:UpdateProp()
    XLuckyTenantTool.UpdateProp(self, self._Control)
end

function XUiLuckyTenantChessBag:_OnClickDelete()
    if XMVCA.XLuckyTenant:IsRequesting() then
        return
    end
    local uiData = self._Control:GetUiData()
    if uiData.SelectedBagPiece then
        if uiData.SelectedBagPiece.IsCanDelete == 0 then
            XUiManager.TipText("LuckyTenantDeleteDenied")
            return
        end
        if self._Control:HasEnoughPropToDelete() then
            XLuaUiManager.Open("UiLuckyTenantDeleteDetail")
        else
            XUiManager.TipText("LuckyTenantPropNotEnough")
        end
    end
end

---@param data XUiLuckyTenantChessBagPropData
function XUiLuckyTenantChessBag:OpenRewardTips(data, worldPosition)
    self.RewardTips.gameObject:SetActiveEx(true)
    self.TxtRewardTips.text = data.Desc
    ---@type UnityEngine.RectTransform
    local transform = self.TxtRewardTips.transform.parent
    transform.anchorMin = Vector2(1, 1)
    transform.anchorMax = Vector2(1, 1)
    transform.pivot = Vector2(1, 1)
    transform.position = worldPosition
end

function XUiLuckyTenantChessBag:CloseRewardTips()
    self.RewardTips.gameObject:SetActiveEx(false)
end

function XUiLuckyTenantChessBag:UpdateTag()
    local tagData = self._Control:GetTag()
    XTool.UpdateDynamicItem(self._Tags, tagData, self.GridType, XUiLuckyTenantTag, self)
end

return XUiLuckyTenantChessBag