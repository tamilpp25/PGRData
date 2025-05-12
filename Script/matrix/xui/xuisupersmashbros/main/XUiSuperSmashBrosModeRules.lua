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
    ---@type XSmashBMode
    self.Mode = mode
    self:InitPanels()
end
--==============
--初始化面板
--==============
function XUiSuperSmashBrosModeRules:InitPanels()
    self.BtnTanchuangCloseBig.CallBack = function() self:OnClickBtnClose() end
    self.TxtDescription.text = self.Mode:GetDescription()
    local coreList = self.Mode:GetCore()
    for i = 1, #coreList do
        local uiCore = CS.UnityEngine.Object.Instantiate(self.CorePanel, self.CorePanel.transform.parent)
        local gridCore = {
            Transform = uiCore.transform,
            GameObject = uiCore.gameObject
        }
        XTool.InitUiObject(gridCore)
        local core = coreList[i]
        gridCore.RImgCoreIcon:SetRawImage(core:GetIcon())
    end
    --self.TxtTitle.text = "" --标题可配置(现在不用配置)
    self.CorePanel.gameObject:SetActiveEx(false)
end
--==============
--点击关闭按钮
--==============
function XUiSuperSmashBrosModeRules:OnClickBtnClose()
    self:Close()
end