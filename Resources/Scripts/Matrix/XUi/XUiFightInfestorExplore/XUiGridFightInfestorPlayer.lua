local XUiGridFightInfestorPlayer = XClass(nil, "XUiGridFightInfestorPlayer")

function XUiGridFightInfestorPlayer:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:InitComponent()
end

function XUiGridFightInfestorPlayer:InitComponent()
end

function XUiGridFightInfestorPlayer:Refresh(data)
    self.ImgIcon:SetRawImage(data:GetIcon())
    self.Name.text = data:GetName()
    self.Num.text = data:GetScoreStr()
end

function XUiGridFightInfestorPlayer:GetRawImage()
    return self.ImgIcon
end

return XUiGridFightInfestorPlayer