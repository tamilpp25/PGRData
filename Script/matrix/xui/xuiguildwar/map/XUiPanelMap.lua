local XUiPanelMap = XClass(nil, "XUiPanelMap")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiPanelMap:Ctor(ui, base, battleManager)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.BattleManager = battleManager
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiPanelMap:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_PATHEDIT_PATHCHANGE, self.ShowButton, self)
end

function XUiPanelMap:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_PATHEDIT_PATHCHANGE, self.ShowButton, self)
end

function XUiPanelMap:SetButtonCallBack()
    self.BtnConfirm.CallBack = function()
        self:OnBtnConfirmClick()
    end
end

function XUiPanelMap:ShowButton(IsShow)
    self.BtnConfirm.gameObject:SetActiveEx(IsShow)
end

function XUiPanelMap:ShowPanel()
    self.GameObject:SetActiveEx(true)
    self.Base:PlayAnimationWithMask("PanelMapEnable")
end

function XUiPanelMap:HidePanel()
    self.Base:PlayAnimationWithMask("PanelMapDisable", function ()
            self.GameObject:SetActiveEx(false)
        end)
end

function XUiPanelMap:OnBtnConfirmClick()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_PATHEDIT_OVER, true)
end

return XUiPanelMap