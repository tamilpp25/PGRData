local XUiGridPhotographOtherBtn = XClass(nil, "XUiGridPhotographOtherBtn")

function XUiGridPhotographOtherBtn:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui:GetComponent("RectTransform")
    XTool.InitUiObject(self)
end

function XUiGridPhotographOtherBtn:Init(rootUi)
    self.rootUi = rootUi
end

function XUiGridPhotographOtherBtn:RefrashFashion(data)
    local fashionName = XDataCenter.FashionManager.GetFashionName(data)
    self.TxtNor.text = fashionName
    self.TxtSel.text = fashionName
    self.TxtLock.text = fashionName
    if not XDataCenter.FashionManager.CheckHasFashion(data) then
        self:SetLock()
    end
end

function XUiGridPhotographOtherBtn:RefrashAction(data, charData)
    self.TxtNor.text = data.Name
    self.TxtSel.text = data.Name
    self.TxtLock.text = data.Name
    self.Txtcondition.text = data.ConditionDescript
    if charData.TrustLv < data.UnlockLv then
        self:SetLock()
    end
end

function XUiGridPhotographOtherBtn:OnFashionTouched(charId, fashionId)
    self:SetSelect(true)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_PHOTO_CHANGE_MODEL, charId, fashionId)
end

function XUiGridPhotographOtherBtn:OnActionTouched(data)
    self:SetSelect(true)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_PHOTO_PLAY_ACTION, data.SignBoardActionId)
end

function XUiGridPhotographOtherBtn:SetSelect(bool)
    self.Sel.gameObject:SetActiveEx(bool)
    self.ImageCheck.gameObject:SetActiveEx(bool)
    self.Nor.gameObject:SetActiveEx(not bool)
end

function XUiGridPhotographOtherBtn:SetLock()
    self.Nor.gameObject:SetActiveEx(false)
    self.Sel.gameObject:SetActiveEx(false)
    self.Lock.gameObject:SetActiveEx(true)
end

function XUiGridPhotographOtherBtn:Reset()
    self.Nor.gameObject:SetActiveEx(true)
    self.Sel.gameObject:SetActiveEx(false)
    self.Lock.gameObject:SetActiveEx(false)
    self.ImageCheck.gameObject:SetActiveEx(false)
    self.Txtcondition.text = ""
end

return XUiGridPhotographOtherBtn