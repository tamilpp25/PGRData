local XUiSignNewYearDrawActivity = XClass(nil, "XUiSignNewYearDrawActivity")

function XUiSignNewYearDrawActivity:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
    self:InitAddListen()
end

function XUiSignNewYearDrawActivity:InitAddListen()
    self.BtnGo.CallBack = function()
        self:OnBtnGoClick()
    end
end

function XUiSignNewYearDrawActivity:Refresh(signId, isShow)
    self.SignId = signId or self.SignId
    XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true)
end

function XUiSignNewYearDrawActivity:OnBtnGoClick()
    local gachaId = XSignInConfigs.GetSignDrawNewYearConfig(self.SignId).GaChaId
    XDataCenter.GachaManager.GetGachaRewardInfoRequest(gachaId, function()
        XLuaUiManager.Open("UiDrawNewYear", gachaId, self.SignId)
    end)
end

function XUiSignNewYearDrawActivity:OnShow()
end

function XUiSignNewYearDrawActivity:OnHide()
end

return XUiSignNewYearDrawActivity