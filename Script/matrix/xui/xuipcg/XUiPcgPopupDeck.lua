local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiPcgPopupDeck : XLuaUi
---@field private _Control XPcgControl
local XUiPcgPopupDeck = XLuaUiManager.Register(XLuaUi, "UiPcgPopupDeck")

function XUiPcgPopupDeck:OnAwake()
    self.UiPcgGridCard.gameObject:SetActiveEx(false)
    
    self.CardIds = {}
    self.GridCards = {}
    self:RegisterUiEvents()
    self:InitDynamicTable()
end

function XUiPcgPopupDeck:OnStart(isDrawPool)
    self.IsDrawPool = isDrawPool -- 是否是抽牌堆
    if self.IsDrawPool then
        XMVCA.XPcg:PcgDrawPoolRequest(function(cardIds)
            self.CardIds = cardIds
            table.sort(self.CardIds)
            self:Refresh()
        end)
    else
        XMVCA.XPcg:PcgDropPoolRequest(function(cardIds)
            self.CardIds = cardIds
            self:Refresh()
        end)
    end
end

function XUiPcgPopupDeck:OnEnable()
    self:Refresh()
end

function XUiPcgPopupDeck:OnDisable()
    
end

function XUiPcgPopupDeck:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end

function XUiPcgPopupDeck:OnBtnCloseClick()
    self:Close()
end

-- 刷新界面
function XUiPcgPopupDeck:Refresh()
    self:RefreshInfo()
    self:RefreshCardList()
end

function XUiPcgPopupDeck:RefreshInfo()
    local paramIndex = self.IsDrawPool and 1 or 2
    local title = self._Control:GetClientConfig("CardPos", paramIndex)
    local key = self.IsDrawPool and "DrawPoolTips" or "DropPoolTips"
    self.TxtTitle.text = title
    self.TxtDesc.text = self._Control:GetClientConfig(key)
    
    local txt = tostring(# self.CardIds)
    self.BtnDiscard.gameObject:SetActiveEx(not self.IsDrawPool)
    self.BtnCard.gameObject:SetActiveEx(self.IsDrawPool)
    self.TxtDiscardNum.text = txt
    self.TxtCardNum.text = txt
end

function XUiPcgPopupDeck:InitDynamicTable()
    local XUiGridPcgCard = require("XUi/XUiPcg/XUiGrid/XUiGridPcgCard")
    self.DynamicTable = XDynamicTableNormal.New(self.ScrollView)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridPcgCard, self)
end

-- 刷新代币列表
function XUiPcgPopupDeck:RefreshCardList()
    self.DynamicTable:SetDataSource(self.CardIds)
    self.DynamicTable:ReloadDataASync()
end

---@param grid XUiGridPcgCard
function XUiPcgPopupDeck:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local cardId = self.CardIds[index]
        grid:SetCardData(cardId, nil, nil, true)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        -- 必杀牌点击显示详情
        local cardId = self.CardIds[index]
        local cardCfg = self._Control:GetConfigCards(cardId)
        if cardCfg.Color == XEnumConst.PCG.COLOR_TYPE.WHITE then
            XLuaUiManager.Open("UiPcgPopupCardDetail", cardId)
        end
    end
end


return XUiPcgPopupDeck
