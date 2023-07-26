local XUiGridBuff = XClass(nil, "XUiGridBuff")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiGridBuff:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiGridBuff:SetButtonCallBack()
    self.BtnBuff.CallBack = function()
        self:OnBtnBuffClick()
    end
end

function XUiGridBuff:UpdateGrid(buffEntity)
   self.BuffEntity = buffEntity
    if buffEntity then
        self.RImgIcon:SetRawImage(self.BuffEntity:GetBuffIcon())
        self.TxtLv.text = buffEntity:GetBuffName()
    end
end

function XUiGridBuff:OnBtnBuffClick()
    XLuaUiManager.Open("UiCommonBuffDetail", self.BuffEntity:GetBuffName(), self.BuffEntity:GetBuffIcon(), self.BuffEntity:GetBuffDesc())
end

return XUiGridBuff