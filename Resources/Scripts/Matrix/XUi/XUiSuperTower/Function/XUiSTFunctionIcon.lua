--=====================
--解锁特权弹窗 特权图标控件
--=====================
local XUiSTFunctionIcon = XClass(nil, "XUiSTFunctionIcon")

function XUiSTFunctionIcon:Ctor(uiGameObject, func)
    XTool.InitUiObjectByUi(self, uiGameObject)
    self.Func = func
    self:Init()
end

function XUiSTFunctionIcon:Init()
    self.RImgIcon:SetRawImage(self.Func:GetIcon())
    self.TxtName.text = self.Func:GetName()
    XUiHelper.RegisterClickEvent(self, self.RImgIcon, function() self:OnClick() end)
end

function XUiSTFunctionIcon:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiSTFunctionIcon:OnClick()
    if self.Func then
        XLuaUiManager.Open("UiTip", self.Func:GetItemId())
    end
end

return XUiSTFunctionIcon