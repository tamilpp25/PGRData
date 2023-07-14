
local XUiSSBCoreGrowthPanel = XClass(nil, "XUiSSBCoreGrowthPanel")

function XUiSSBCoreGrowthPanel:Ctor(uiPrefab, core)
    self.Core = core
    XTool.InitUiObjectByUi(self, uiPrefab)
    self:InitPanelGrowthAttack()
    self:InitPanelGrowthLife()
    self:InitPanelGrowthCost()
    self.BtnEnergyRecycle.CallBack = function() self:OnClickBtnEnergyRecycle() end
end

function XUiSSBCoreGrowthPanel:InitPanelGrowthAttack()
    self.AttackPanel = {}
    XTool.InitUiObjectByUi(self.AttackPanel, self.PanelAttack)
    self.AttackPanel.BtnReduce.CallBack = function() self:OnClickAttackReduce() end
    self.AttackPanel.BtnAdd.CallBack = function() self:OnClickAttackAdd() end
end

function XUiSSBCoreGrowthPanel:InitPanelGrowthLife()
    self.LifePanel = {}
    XTool.InitUiObjectByUi(self.LifePanel, self.PanelBlood)
    self.LifePanel.BtnReduce.CallBack = function() self:OnClickLifeReduce() end
    self.LifePanel.BtnAdd.CallBack = function() self:OnClickLifeAdd() end
end

function XUiSSBCoreGrowthPanel:InitPanelGrowthCost()
    self.CostPanel = {}
    XTool.InitUiObjectByUi(self.CostPanel, self.PanelCost)
    XUiHelper.RegisterClickEvent(self, self.CostPanel.RImgIcon, handler(self, self.OnClickCostImage))
end

function XUiSSBCoreGrowthPanel:OnClickCostImage()
    local itemId = XDataCenter.SuperSmashBrosManager.GetEnergyItemId()
    local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(itemId)
    local data = {
        IsTempItemData = true,
        Name = goodsShowParams.Name,
        Count = XDataCenter.SuperSmashBrosManager.GetCurrentEnergy(),
        Icon = goodsShowParams.Icon,
        Quality = goodsShowParams.QualityIcon,
        WorldDesc = XGoodsCommonManager.GetGoodsWorldDesc(itemId),
        Description = XGoodsCommonManager.GetGoodsDescription(itemId)
    }
    XLuaUiManager.Open("UiTip", data)
end

function XUiSSBCoreGrowthPanel:Refresh(core)
    self.Core = core or self.Core
    self:RefreshAttack()
    self:RefreshLife()
    self:RefreshCost()
    self.TxtDescription.text = XUiHelper.GetText("SSBCoreUpgradeDes", 
        self.Core:GetAtkLevel() * XDataCenter.SuperSmashBrosManager.GetAtkUpNumByLevel(), 
        self.Core:GetLifeLevel() * XDataCenter.SuperSmashBrosManager.GetLifeUpNumByLevel())
end

function XUiSSBCoreGrowthPanel:RefreshAttack()
    local level = self.Core:GetAtkLevel()
    self.AttackPanel.TxtNum.text = level
    self.AttackPanel.BtnReduce:SetButtonState(level == 0 and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    self.AttackPanel.BtnAdd:SetButtonState(self.Core:CheckAttrIsMax() and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
end

function XUiSSBCoreGrowthPanel:RefreshLife()
    local level = self.Core:GetLifeLevel()
    self.LifePanel.TxtNum.text = level
    self.LifePanel.BtnReduce:SetButtonState(level == 0 and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    self.LifePanel.BtnAdd:SetButtonState(self.Core:CheckAttrIsMax() and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
end

function XUiSSBCoreGrowthPanel:RefreshCost()
    self.CostPanel.RImgIcon:SetRawImage(XDataCenter.SuperSmashBrosManager.GetEnergyItemIcon())
    self.CostPanel.TxtNumStr.text = XUiHelper.GetText("SSBMainPointGetText", XDataCenter.SuperSmashBrosManager.GetNotUsedEnergy(), XDataCenter.SuperSmashBrosManager.GetCurrentEnergy())
end

function XUiSSBCoreGrowthPanel:OnClickAttackReduce()
    if self.Core:GetAtkLevel() < 1 then
        return
    end
    XDataCenter.SuperSmashBrosManager.UpgradeCoreAttack(self.Core, -1)
end

function XUiSSBCoreGrowthPanel:OnClickAttackAdd()
    if self.Core:CheckAttrIsMax() then
        return
    end
    XDataCenter.SuperSmashBrosManager.UpgradeCoreAttack(self.Core, 1)
end

function XUiSSBCoreGrowthPanel:OnClickLifeReduce()
    if self.Core:GetLifeLevel() < 1 then
        return
    end
    XDataCenter.SuperSmashBrosManager.UpgradeCoreLife(self.Core, -1)
end

function XUiSSBCoreGrowthPanel:OnClickLifeAdd()
    if self.Core:CheckAttrIsMax() then
        return
    end
    XDataCenter.SuperSmashBrosManager.UpgradeCoreLife(self.Core, 1)
end

function XUiSSBCoreGrowthPanel:OnClickBtnEnergyRecycle()
    XDataCenter.SuperSmashBrosManager.UpgradeCoreAttack(self.Core, -1 * self.Core:GetAtkLevel())
    XDataCenter.SuperSmashBrosManager.UpgradeCoreLife(self.Core, -1 * self.Core:GetLifeLevel())
end

return XUiSSBCoreGrowthPanel