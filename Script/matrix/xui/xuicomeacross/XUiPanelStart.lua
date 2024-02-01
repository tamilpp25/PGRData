local XUiPanelStart = XClass(nil, "XUiPanelStart")

local PanelState = {
    START = 1,
    END = 2
}

function XUiPanelStart:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    self:InitAutoScript()
    self.State = PanelState.START
end

function XUiPanelStart:SetupContent(data)
    if not data then
        return
    end
    self.State = PanelState.START

    self.Data = data
    local character = data.Character
    local gameType = data.GameConfig.Type
    local gameTypeCfg = XComeAcrossConfig.GetComeAcrossTypeConfigById(gameType)
    self.TxtSelect.text = gameTypeCfg.Title
    self.TxtWords.text = gameTypeCfg.Desc
    self.TxtName.text = XMVCA.XCharacter:GetCharacterName(character.Id)
    self.Parent:SetUiSprite(self.ImgRole, XMVCA.XCharacter:GetCharHalfBodyBigImage(character.Id))
end


function XUiPanelStart:SetupResult()
    if not self.Data then
        return
    end

    self.State = PanelState.END

    local gameType = self.Data.GameConfig.Type
    local gameTypeCfg = XComeAcrossConfig.GetComeAcrossTypeConfigById(gameType)
    self.TxtSelect.text = gameTypeCfg.ResultTitle
    self.TxtWords.text = gameTypeCfg.ResultDesc
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelStart:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiPanelStart:AutoInitUi()
    self.ImgRole = self.Transform:Find("ImgRole"):GetComponent("Image")
    self.Panelselectoption = self.Transform:Find("Panelselectoption")
    self.BtnSelect = self.Transform:Find("Panelselectoption/GameObject/BtnSelect"):GetComponent("Button")
    self.TxtSelect = self.Transform:Find("Panelselectoption/GameObject/BtnSelect/TxtSelect"):GetComponent("Text")
    self.PanelDialog = self.Transform:Find("PanelDialog")
    self.PanelText = self.Transform:Find("PanelDialog/PanelText")
    self.ImgTxtWordBg = self.Transform:Find("PanelDialog/PanelText/ImgTxtWordBg"):GetComponent("Image")
    self.TxtName = self.Transform:Find("PanelDialog/PanelText/TxtName"):GetComponent("Text")
    self.TxtWords = self.Transform:Find("PanelDialog/PanelText/TxtWords"):GetComponent("Text")
end

function XUiPanelStart:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelStart:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelStart:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelStart:AutoAddListener()
    self:RegisterClickEvent(self.BtnSelect, self.OnBtnSelectClick)
end
-- auto
function XUiPanelStart:OnBtnSelectClick()
    if self.State == PanelState.START then
        self.Parent:OnBtnSelectClick()
    elseif self.State == PanelState.END then
        self.Parent:SetupReward()
    end

    self.State = PanelState.START
end

return XUiPanelStart