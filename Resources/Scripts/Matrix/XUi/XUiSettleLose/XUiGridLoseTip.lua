local XUiGridLoseTip = XClass(nil, "XUiGridLoseTip")

---
--- 'params'结构：{ TipDesc:string, SkipId:int }
function XUiGridLoseTip:Ctor(ui, rootUi, params)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    if params == nil then
        XLog.Error("XUiGridLoseTip:Ctor函数错误，参数params为空")
        self.Params = {}
    else
        self.Params = params
    end

    if params.SkipId and params.SkipId ~= 0 then
        self.IsCanSkip = true
    else
        self.IsCanSkip = false
    end

    XTool.InitUiObject(self)
    self:InitComponent()
    self:AddListener()
    self:Refresh()
end

function XUiGridLoseTip:InitComponent()
    self.BtnSkip.gameObject:SetActiveEx(self.IsCanSkip)
end

function XUiGridLoseTip:Refresh()
    -- 提示描述
    if self.Params.TipDesc then
        self.TxtTip.text = self.Params.TipDesc
    else
        XLog.Error("XUiGridLoseTip:Refresh函数错误，self.Params没有TipDesc数据")
        self.TxtTip.gameObject:SetActiveEx(false)
    end

    -- 跳转按钮名称
    if self.IsCanSkip then
        self.BtnSkip:SetName(XFunctionConfig.GetExplain(self.Params.SkipId))
    end
end

function XUiGridLoseTip:AddListener()
    if self.IsCanSkip then
        self.BtnSkip.CallBack = function()
            self:OnBtnSkipClick()
        end
    end
end

function XUiGridLoseTip:OnBtnSkipClick()
    local title = CsXTextManagerGetText("SettleLoseSkipConfirmTitle")
    local content = CsXTextManagerGetText("SettleLoseSkipConfirmContent")

    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil,
            function()
                XLuaUiManager.RunMain()
                XFunctionManager.SkipInterface(self.Params.SkipId)
            end)
end

return XUiGridLoseTip