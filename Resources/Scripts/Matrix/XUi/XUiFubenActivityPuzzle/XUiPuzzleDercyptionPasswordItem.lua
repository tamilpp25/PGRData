local XUiPuzzleDercyptionPasswordItem = XClass(nil, "XUiPuzzleDercyptionPasswordItem")

function XUiPuzzleDercyptionPasswordItem:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:Init()
end

function XUiPuzzleDercyptionPasswordItem:Init()
    self:AutoRegisterListener()
end

function XUiPuzzleDercyptionPasswordItem:AutoRegisterListener()
    self.BtnUp.CallBack = function () self:OnBtnUpClick() end
    self.BtnDown.CallBack = function () self:OnBtnDownClick() end
end

function XUiPuzzleDercyptionPasswordItem:OnCreate(data)
    self.Index = data.Index
    self.TxtPassword.text = data.Password
end

function XUiPuzzleDercyptionPasswordItem:OnBtnUpClick()
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_DRAG_PUZZLE_GAME_CHANGE_PASSWORD, self.Index, "Up")
end

function XUiPuzzleDercyptionPasswordItem:OnBtnDownClick()
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_DRAG_PUZZLE_GAME_CHANGE_PASSWORD, self.Index, "Down")
end

function XUiPuzzleDercyptionPasswordItem:SetActiveEx(bool)
    self.GameObject:SetActiveEx(bool)
end

function XUiPuzzleDercyptionPasswordItem:SetTextPassword(password)
    self.TxtPassword.text = password
end

return XUiPuzzleDercyptionPasswordItem