-- 建筑卡片
---@class XUiGridRogueSimBuild : XUiNode
---@field private _Control XRogueSimControl
local XUiGridRogueSimBuild = XClass(XUiNode, "XUiGridRogueSimBuild")

function XUiGridRogueSimBuild:OnStart(buyCallBack)
    XUiHelper.RegisterClickEvent(self, self.BtnGoBuy, self.OnBtnGoBuyClick)
    self.BuyCallBack = buyCallBack
    self.PanelBuy.gameObject:SetActiveEx(false)
    self.PanelProfit.gameObject:SetActiveEx(false)
    self.PanelLock.gameObject:SetActiveEx(false)
end

---@param id number 自增id
function XUiGridRogueSimBuild:Refresh(id)
    self.Id = id
    self.BuildId = self._Control.MapSubControl:GetBuildingConfigIdById(id)
    self:RefreshView()
    self:RefreshRedPoint()
end

---@param buildId number 配置表id
function XUiGridRogueSimBuild:RefreshByBuildId(buildId)
    self.Id = nil
    self.BuildId = buildId
    self:RefreshView()
end

function XUiGridRogueSimBuild:RefreshView()
    -- 建筑图标
    self.RImgProp:SetSprite(self._Control.MapSubControl:GetBuildingIcon(self.BuildId))
    -- 建筑名称
    self.TxtName.text = self._Control.MapSubControl:GetBuildingName(self.BuildId)
    -- 建筑描述
    self.TxtDetail.text = self._Control.MapSubControl:GetBuildingDesc(self.BuildId)
    -- 建筑标志
    local tagIcon = self._Control.MapSubControl:GetBuildingTag(self.BuildId)
    self.ImgTag:SetSprite(tagIcon)
end

function XUiGridRogueSimBuild:RefreshRedPoint()
    local isShow = self._Control.MapSubControl:CheckBuildingRedPoint(self.Id)
    self.BtnGoBuy:ShowReddot(isShow)
end

function XUiGridRogueSimBuild:SetProfitActive(isActive)
    self.PanelProfit.gameObject:SetActiveEx(isActive)
    if isActive then
        -- 售价
        self.TxtProfit.text = self._Control.MapSubControl:GetBuyBuildingCostGoldCount(self.BuildId)
        -- 金币图标
        self.RImgCoin:SetRawImage(self._Control.ResourceSubControl:GetResourceIcon(XEnumConst.RogueSim.ResourceId.Gold))
    end
end

function XUiGridRogueSimBuild:SetBuyActive()
    local isBuy = self._Control.MapSubControl:CheckBuildingIsBuyById(self.Id)
    self.PanelBuy.gameObject:SetActiveEx(not isBuy)
end

-- 前往购买
function XUiGridRogueSimBuild:OnBtnGoBuyClick()
    if self.BuyCallBack then
        self.BuyCallBack(self.Id)
    end
end

function XUiGridRogueSimBuild:ShowLock(isLock)
    self.PanelLock.gameObject:SetActiveEx(isLock)
end

function XUiGridRogueSimBuild:ShowNew(isNew)
    self.PanelNew.gameObject:SetActiveEx(isNew)
end

return XUiGridRogueSimBuild
