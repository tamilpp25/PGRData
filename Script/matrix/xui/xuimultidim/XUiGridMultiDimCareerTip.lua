local XUiGridMultiDimCareerTip = XClass(nil,"XUiGridMultiDimCareerTip")

---@param transform UnityEngine.RectTransform
function XUiGridMultiDimCareerTip:Ctor(transform,careerCfg, callBack)
    self.Transform = transform
    self.GameObject = transform.gameObject
    self.CareerCfg = careerCfg
    XTool.InitUiObject(self)
    self.BtnSel.CallBack = function()
        if callBack then
            callBack(self.CareerCfg.Career)
        end
    end
    self:Refresh()
end

function XUiGridMultiDimCareerTip:Refresh()
    self.RImgIcon:SetRawImage(self.CareerCfg.Icon)
    self.TxtCareerDes.text = XUiHelper.ConvertLineBreakSymbol(self.CareerCfg.Des)
    self.TxtCareerName.text = self.CareerCfg.Name
end

function XUiGridMultiDimCareerTip:SetGridState(curCareer)
    if curCareer == self.CareerCfg.Career then
        self.BtnSel:SetButtonState(CS.UiButtonState.Select)
    else
        self.BtnSel:SetButtonState(CS.UiButtonState.Normal)
    end
end

return XUiGridMultiDimCareerTip