--- Grid Class
local DefaultIndex = 1
local XUiMultiDimEnvironmentGrid = XClass(nil, "XUiMultiDimEnvironmentGrid")

function XUiMultiDimEnvironmentGrid:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.RootUi = rootUi
    self.Index = nil
    self.BtnSelf.CallBack = function() self:OnBtnSelfClicked() end
end

function XUiMultiDimEnvironmentGrid:SetData(buffId, index)
    self.Index = index
    local buffConfigs = XMultiDimConfig.GetMultiDimBuffDetailsConfig(buffId)
    -- 描述
    self.TxtAmbien.text = buffConfigs.Desc
    -- 序号
    self.TxtNumber.text = (index > 9) and index or string.format("0%d", index)
    self.TxtName.text = buffConfigs.Name
    self:SetSelectStatus(index == DefaultIndex)
end

function XUiMultiDimEnvironmentGrid:SetSelectStatus(value)
    self.ImgSelected.gameObject:SetActiveEx(value)
end

function XUiMultiDimEnvironmentGrid:OnBtnSelfClicked()
    self.RootUi:OnBuffGridClicked(self.Index)
    self:SetSelectStatus(true)
end

return XUiMultiDimEnvironmentGrid
---