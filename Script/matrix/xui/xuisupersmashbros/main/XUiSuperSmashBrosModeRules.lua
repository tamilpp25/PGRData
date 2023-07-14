--==============
--超限乱斗模式说明页面
--==============
local XUiSuperSmashBrosModeRules = XLuaUiManager.Register(XLuaUi, "UiSuperSmashBrosModeRules")
--==============
--OnStart
--@param
--mode : 模式对象
--==============
function XUiSuperSmashBrosModeRules:OnStart(mode)
    self.Mode = mode
    self:InitPanels()
end
--==============
--初始化面板
--==============
function XUiSuperSmashBrosModeRules:InitPanels()
    self.BtnTanchuangCloseBig.CallBack = function() self:OnClickBtnClose() end
    self.TxtDescription.text = self.Mode:GetDescription()
    local core = self.Mode:GetCore()
    self.RImgCoreIcon:SetRawImage(core and core:GetIcon())
    --self.TxtTitle.text = "" --标题可配置(现在不用配置)
end
--==============
--点击关闭按钮
--==============
function XUiSuperSmashBrosModeRules:OnClickBtnClose()
    self:Close()
end