---@class XUiPanelTheatre4GameStartCard : XUiNode
---@field private _Control XTheatre4Control
local XUiPanelTheatre4GameStartCard = XClass(XUiNode, "XUiPanelTheatre4GameStartCard")

function XUiPanelTheatre4GameStartCard:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnGold, self.OnBtnGoldClick)
end

function XUiPanelTheatre4GameStartCard:Refresh(callback)
    self.Callback = callback
    self:RefreshInfo()
    self:RefreshGold()
    self:RefreshAddGold()
    self:RefreshBlood()
end

-- 刷新信息
function XUiPanelTheatre4GameStartCard:RefreshInfo()
    -- 名称
    self.TxtName.text = self._Control:GetClientConfig("StartGridName")
    -- 描述
    self.TxtDetail.text = self:GetDetailInfo()
    -- 图标
    local icon = self._Control:GetBlockIconDefaultIcon(1)
    if icon then
        self.RImgTypeIcon:SetRawImage(icon)
    end
end

-- 获取详细的描述信息
function XUiPanelTheatre4GameStartCard:GetDetailInfo()
    local desc = self._Control:GetClientConfig("StartGridDesc")
    desc = XUiHelper.ConvertLineBreakSymbol(desc)
    -- 单次利息需要金币
    local interestNeedCount = self._Control:GetConfig("InterestNeedCount")
    -- 单次利息奖励
    local interestAwardCount = self._Control:GetConfig("InterestAwardCount")
    -- 当前利息，利息上限
    local interest, interestAwardLimit = self._Control.EffectSubControl:GetInterestAndLimit()
    return XUiHelper.FormatText(desc, interestNeedCount, interestAwardCount, interest, interestAwardLimit)
end

-- 刷新金币
function XUiPanelTheatre4GameStartCard:RefreshGold()
    -- 金币图片
    local goldIcon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.Gold)
    if goldIcon then
        self.RImgGold:SetRawImage(goldIcon)
    end
    -- 金币数量
    self.TxtGoldNum.text = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.Gold)
end

-- 刷新每回合开始时增加的金币
function XUiPanelTheatre4GameStartCard:RefreshAddGold()
    local addGold = self._Control.AssetSubControl:GetTotalRecoverGold()
    self.TxtAddNum.gameObject:SetActiveEx(addGold > 0)
    if addGold > 0 then
        self.TxtAddNum.text = string.format("+%d", addGold)
    end
end

-- 刷新血量
function XUiPanelTheatre4GameStartCard:RefreshBlood()
    -- 血量图片
    local hpIcon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.Hp)
    if hpIcon then
        self.ImgBlood:SetSprite(hpIcon)
    end
    -- 血量数量
    local hp = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.Hp)
    self.TxtBloodNum.text = string.format("×%s", hp)
end

function XUiPanelTheatre4GameStartCard:OnBtnGoldClick()
    -- 打开金币详情
    XLuaUiManager.Open("UiTheatre4PopupItemDetail", nil, XEnumConst.Theatre4.AssetType.Gold)
end

function XUiPanelTheatre4GameStartCard:OnCloseClick()
    if self.Callback then
        self.Callback()
    end
    self:Close()
end

return XUiPanelTheatre4GameStartCard
