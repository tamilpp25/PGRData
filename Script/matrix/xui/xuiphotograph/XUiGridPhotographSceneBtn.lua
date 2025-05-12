local XUiGridPhotographSceneBtn = XClass(nil, "XUiGridPhotographSceneBtn")

function XUiGridPhotographSceneBtn:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui:GetComponent("RectTransform")
    XTool.InitUiObject(self)
end

function XUiGridPhotographSceneBtn:Init(rootUi)
    self.rootUi = rootUi
end

function XUiGridPhotographSceneBtn:Refrash(data)
    self.ImgScene:SetSprite(data.IconPath)
    self.TxSceneName.text = data.Name
    self.TxtLock.text = data.LockDec
    self:SetLock(not XDataCenter.PhotographManager.CheckSceneIsHaveById(data.Id))
end

function XUiGridPhotographSceneBtn:OnTouched(data)
    self:SetSelect(true)
    if self.rootUi then
        self.rootUi:PlayAnimation("Loading", function()
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_PHOTO_CHANGE_SCENE, data.Id)
        end)
        self.rootUi.CurrSeleSceneId = data.Id
    end
end

function XUiGridPhotographSceneBtn:SetSelect(bool)
    self.Sel.gameObject:SetActiveEx(bool)
end

function XUiGridPhotographSceneBtn:SetLock(bool)
    self.Lock.gameObject:SetActiveEx(bool)
end

function XUiGridPhotographSceneBtn:Reset()
    self:SetSelect(false)
    self:SetLock(false)
end

return XUiGridPhotographSceneBtn