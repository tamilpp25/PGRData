local XUiFightMaze = XLuaUiManager.Register(XLuaUi, "UiFightMaze")
local tostring = tostring

function XUiFightMaze:OnAwake()
    self.FxObj = self.ImgProgress.transform:Find("FxObj").gameObject
    self.FxObj:SetActiveEx(false)
end

function XUiFightMaze:OnDisable()
    self.FxObj:SetActiveEx(false)
end

function XUiFightMaze:SetProcess(process)
    local fillAmount = process / 100.0
    if fillAmount < self.ImgProgress.fillAmount then
        local fxPos = self.FxObj.transform.anchoredPosition
        fxPos.x = fillAmount * self.ImgProgress.transform.rect.width
        self.FxObj.transform.anchoredPosition = fxPos
        self.FxObj:SetActiveEx(false)
        self.FxObj:SetActiveEx(true)
    end
    self.ImgProgress.fillAmount = fillAmount
    self.TxtProgress.text = tostring(process)
end