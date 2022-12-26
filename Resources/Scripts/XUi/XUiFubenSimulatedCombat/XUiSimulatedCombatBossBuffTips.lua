--词缀展示页面
local XUiSimulatedCombatBossBuffTips = XLuaUiManager.Register(XLuaUi, "UiSimulatedCombatBossBuffTips")
local XUiBuffTipsItem = require("XUi/XUiFubenSimulatedCombat/ChildItem/XUiBuffTipsItem")
function XUiSimulatedCombatBossBuffTips:OnAwake()
    XTool.InitUiObject(self)
    self.GridBuff.gameObject:SetActiveEx(false)
    self:RegisterUiButtonEvent()
end

function XUiSimulatedCombatBossBuffTips:OnStart(buffList)
    if not buffList then return end
    self.BuffList = buffList
    self:RefreshStageType()
    --self.TxtTitle.text = ""
end
 
function XUiSimulatedCombatBossBuffTips:RegisterUiButtonEvent()
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
end

function XUiSimulatedCombatBossBuffTips:OnBtnCloseClick()
    self:Close()
end

function XUiSimulatedCombatBossBuffTips:RefreshStageType()
    for _, buffId in pairs(self.BuffList) do
        local prefab = CS.UnityEngine.Object.Instantiate(self.GridBuff.gameObject)
        prefab.transform:SetParent(self.PanelContent.transform, false)
        local tipItem = XUiBuffTipsItem.New(prefab, self)
        tipItem:RefreshData(buffId)
        tipItem.GameObject:SetActiveEx(true)
    end
end