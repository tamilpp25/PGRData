local XUiGridTeamCharacter = XClass(nil, "XUiGridTeamCharacter")

function XUiGridTeamCharacter:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self:InitAutoScript()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiGridTeamCharacter:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiGridTeamCharacter:AutoInitUi()
    self.PanelSelected = self.Transform:Find("PanelSelected")
    self.ImgSelected = self.Transform:Find("PanelSelected/ImgSelected"):GetComponent("Image")
    self.PanelHead = self.Transform:Find("PanelHead")
    self.ImgeHeadIconBg = self.Transform:Find("PanelHead/ImgeHeadIconBg"):GetComponent("Image")
    self.ImgHeadIcon = self.Transform:Find("PanelHead/ImgHeadIcon"):GetComponent("Image")
    self.PanelLevel = self.Transform:Find("PanelLevel")
    self.TxtLevelA = self.Transform:Find("PanelLevel/TxtLevel"):GetComponent("Text")
    self.ImgInTeam = self.Transform:Find("ImgInTeam"):GetComponent("Image")
    self.ImgQualityA = self.Transform:Find("ImgQuality"):GetComponent("Image")
    self.BtnCharacter = self.Transform:Find("BtnCharacter"):GetComponent("Button")
end

function XUiGridTeamCharacter:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridTeamCharacter:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridTeamCharacter:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridTeamCharacter:AutoAddListener()
    self:RegisterClickEvent(self.BtnCharacter, self.OnBtnCharacterClick)
end
-- auto

function XUiGridTeamCharacter:OnBtnCharacterClick()

end

return XUiGridTeamCharacter