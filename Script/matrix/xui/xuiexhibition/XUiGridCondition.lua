local XUiGridCondition = XClass(nil, "XUiGridCondition")

function XUiGridCondition:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    if self.BtnGo then
        XUiHelper.RegisterClickEvent(self, self.BtnGo, self.OnBtnGoClick)
    end
end

function XUiGridCondition:Refresh(conditionId, characterId, skipId)
    if not conditionId or conditionId == 0 then
        self.GameObject:SetActive(false)
        return true
    end
    self.CharacterId = characterId
    self.SkipId = skipId
    self.GameObject:SetActive(true)

    local passed, desc = XConditionManager.CheckCondition(conditionId, characterId)
    self.TxtPass.text = desc
    self.TxtNotPass.text = desc
    self.TxtPass.gameObject:SetActive(passed)
    self.TxtNotPass.gameObject:SetActive(not passed)

    local showSkipId = not passed and XTool.IsNumberValid(skipId)
    if self.BtnGo then
        self.BtnGo.gameObject:SetActiveEx(showSkipId)
    end

    return passed
end

function XUiGridCondition:OnBtnGoClick()
    if not XTool.IsNumberValid(self.SkipId) then
        return
    end
    XFunctionManager.SkipInterface(self.SkipId, self.CharacterId)
end

return XUiGridCondition