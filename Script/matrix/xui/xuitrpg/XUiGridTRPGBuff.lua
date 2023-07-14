local handler = handler

local XUiGridTRPGBuff = XClass(nil, "XUiGridTRPGBuff")

function XUiGridTRPGBuff:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)

    if self.BtnClick then
        self.BtnClick.CallBack = handler(self, self.OnClickBtnClick)
    end
end

function XUiGridTRPGBuff:Refresh(buffId)
    self.BuffId = buffId

    if self.ImgIcon then
        local icon = XTRPGConfigs.GetBuffIcon(buffId)
        self.RootUi:SetUiSprite(self.ImgIcon, icon)
    end
end

function XUiGridTRPGBuff:OnClickBtnClick()
    local buffId = self.BuffId
    XLuaUiManager.Open("UiTRPGBuffDetail", buffId)
end

return XUiGridTRPGBuff