local XUiGridLikeInfo = require("XUi/XUiDormCharacterDetail/XUiGridLikeInfo")

local XUiPanelCharacterLikeInfo = XClass(nil, "XUiPanelCharacterLikeInfo")

function XUiPanelCharacterLikeInfo:Ctor(ui, characterId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.CharacterId = characterId
    XTool.InitUiObject(self)
    self:AutoAddListener()
    self:Init()
    self.GameObject:SetActive(false)
end

function XUiPanelCharacterLikeInfo:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelCharacterLikeInfo:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelCharacterLikeInfo:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelCharacterLikeInfo:AutoAddListener()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end

function XUiPanelCharacterLikeInfo:OnBtnCloseClick()
    self.GameObject:SetActive(false)
end

function XUiPanelCharacterLikeInfo:Init()
    local recoveryConfigs = XDormConfig.GetCharRecoveryConfig(self.CharacterId)
    self.GridLikeInfo.gameObject:SetActive(false)

    for i = 1, #recoveryConfigs do
        local grid = CS.UnityEngine.Object.Instantiate(self.GridLikeInfo)
        local gridLikeInfo = XUiGridLikeInfo.New(grid)
        gridLikeInfo:Refresh(recoveryConfigs[i])
        grid.transform:SetParent(self.PanelRecycle, false)
        gridLikeInfo.GameObject:SetActive(true)
    end
end

function XUiPanelCharacterLikeInfo:Open()
    self.GameObject:SetActive(true)
end

return XUiPanelCharacterLikeInfo