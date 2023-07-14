---@class XUiTransfiniteEnvironmentDetailGrid
local XUiTransfiniteEnvironmentDetailGrid = XClass(nil, "XUiTransfiniteEnvironmentDetailGrid")

function XUiTransfiniteEnvironmentDetailGrid:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.RootUi = rootUi
    self.BtnSelf.enabled = false
    self._Data = false
end

---@param data XTransfiniteEnvironmentData
function XUiTransfiniteEnvironmentDetailGrid:Update(data)
    self._Data = data
    -- 描述
    self.TxtAmbien.text = data.Desc
    -- 序号
    local index = data.Index
    self.TxtNumber.text = (index > 9) and index or string.format("0%d", index)
    self.TxtName.text = data.Name
end

function XUiTransfiniteEnvironmentDetailGrid:UpdateSelected(index)
    self.ImgSelected.gameObject:SetActiveEx(self._Data.Index == index)
end

--function XUiTransfiniteEnvironmentDetailGrid:OnBtnSelfClicked()
--self.RootUi:OnBuffGridClicked(self.Index)
--self:SetSelectStatus(true)
--end

return XUiTransfiniteEnvironmentDetailGrid
