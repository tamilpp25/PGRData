local XUiGridColorTableBuffDetail = XClass(nil, "UiGridColorTableBuffDetail")

function XUiGridColorTableBuffDetail:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.Index = nil

    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiGridColorTableBuffDetail:SetButtonCallBack()
    self.BtnSelf.CallBack = function() self:OnBtnSelfClicked() end
end

function XUiGridColorTableBuffDetail:SetData(buffConfig, index)
    self.Index = index
    -- 描述
    self.TxtAmbien.text = buffConfig.Desc
    -- 序号
    self.TxtNumber.text = (index > 9) and index or string.format("0%d", index)
    self.TxtName.text = buffConfig.Name
end

function XUiGridColorTableBuffDetail:SetSelectStatus(value)
    self.ImgSelected.gameObject:SetActiveEx(value)
end

function XUiGridColorTableBuffDetail:OnBtnSelfClicked()
    self.RootUi:OnBuffGridClicked(self.Index)
end

return XUiGridColorTableBuffDetail