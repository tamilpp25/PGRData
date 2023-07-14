---==============================
   ---@desc: 接头霸王-胜利界面
---==============================
local XUiBodyCombineGameSuccess = XLuaUiManager.Register(XLuaUi, "UiBodyCombineGameSuccess")

function XUiBodyCombineGameSuccess:OnAwake()
    self.RImgQ = self.TxtMassage.transform.parent:Find("RImgQ"):GetComponent("RawImage")
    self:InitCB()
end

function XUiBodyCombineGameSuccess:OnStart(stage)
    local tips = stage:GetPassDesc()
    local passIcon = stage:GetWinnerQIcon()
    self.TxtMassage.text = tips
    if passIcon and passIcon ~= "" then
        self.RImgQ:SetRawImage(passIcon)
    end
end

function XUiBodyCombineGameSuccess:OnGetEvents()
    return {
        XEventId.EVENT_BODYCOMBINEGAME_ACTIVITY_END,
    }
end

function XUiBodyCombineGameSuccess:OnNotify(evt, ...)
    local args = {...}
    if evt == XEventId.EVENT_BODYCOMBINEGAME_ACTIVITY_END then
        XDataCenter.BodyCombineGameManager.OnActivityEnd()
    end
end

function XUiBodyCombineGameSuccess:InitCB()
    self.BtnMask.CallBack = function ()
        self:Close()
    end

    self.BtnTcanchaungBlack.CallBack = function ()
        self:Close()
    end
end

function XUiBodyCombineGameSuccess:Close()
    if XLuaUiManager.IsUiShow("UiBodyCombineGamePlay") then
        XLuaUiManager.Remove("UiBodyCombineGamePlay")
    end
    self.Super.Close(self)
end