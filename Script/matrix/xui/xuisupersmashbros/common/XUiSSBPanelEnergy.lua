--===========================
--超限乱斗剩余能量面板控件
--===========================
local XUiSSBPanelEnergy = XClass(nil, "XUiSSBPanelEnergy")
local ItemGridScript = require("XUi/XUiSuperSmashBros/Common/XUiSSBIconGrid")
function XUiSSBPanelEnergy:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self:InitPanel()
end
--=============
--初始化面板
--=============
function XUiSSBPanelEnergy:InitPanel()
    self:SetItemIcon()
    self:Refresh()
end
--=============
--刷新
--=============
function XUiSSBPanelEnergy:Refresh()
    self:SetLeftEn()
    self:SetCurrentEn()
    self:SetUsedEn()
end
--=============
--设置能量图标
--=============
function XUiSSBPanelEnergy:SetItemIcon()
    local itemId = XDataCenter.SuperSmashBrosManager.GetEnergyItemId()
    if self.PanelItem then
        self.IconGrid = ItemGridScript.New(self.PanelItem, handler(self, self.OnClickItemIcon))
        self.IconGrid:Refresh(itemId)
    end
end
--=============
--设置能量图标点击事件
--=============
function XUiSSBPanelEnergy:OnClickItemIcon()
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
--=============
--设置剩余还能获取的能量
--=============
function XUiSSBPanelEnergy:SetLeftEn()
    if not self.TxtLeftEnergy then return end
    self.TxtLeftEnergy.text = XUiHelper.GetText("SSBMainLeftEnergy", XDataCenter.SuperSmashBrosManager.GetLeftEnergy())
end
--=============
--设置已获取的能量值
--=============
function XUiSSBPanelEnergy:SetCurrentEn()
    if not self.TxtCurrentEnergy then return end
    self.TxtCurrentEnergy.text = XDataCenter.SuperSmashBrosManager.GetCurrentEnergy()
end
--=============
--设置已使用的能量值
--=============
function XUiSSBPanelEnergy:SetUsedEn()  
    if not self.TxtUsedEnergy then return end
    self.TxtUsedEnergy.text = XDataCenter.SuperSmashBrosManager.GetUsedEnergy()
end

return XUiSSBPanelEnergy