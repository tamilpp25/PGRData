---@class XUiArenaNewActivityResult : XLuaUi
---@field BtnClose XUiComponent.XUiButton
---@field RImgArenaLevelOld UnityEngine.UI.RawImage
---@field TxtInfo UnityEngine.UI.Text
---@field RImgArenaLevelNew UnityEngine.UI.RawImage
---@field _Control XArenaControl
local XUiArenaNewActivityResult = XLuaUiManager.Register(XLuaUi, "UiArenaNewActivityResult")

--region 生命周期

function XUiArenaNewActivityResult:OnAwake()
    self:_RegisterButtonClicks()
end

function XUiArenaNewActivityResult:OnEnable()
    self:_Refresh()
end

--endregion

function XUiArenaNewActivityResult:OnBtnCloseClick()
    self._Control:ClearBeforeChallengeAndArenaId()
    self._Control:CheckOpenActivityResultUi()
    self:Close()
end

--region 私有方法

function XUiArenaNewActivityResult:_RegisterButtonClicks()
    --在此处注册按钮事件
	self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick, true)
end

function XUiArenaNewActivityResult:_Refresh()
    local arenaLevel = self._Control:GetActivityCurrentLevel()
    local beforeLevel = self._Control:GetActivityBeforeArenaLevel()

    self.RImgArenaLevelOld:SetRawImage(self._Control:GetArenaLevelWordIconById(beforeLevel))
    self.RImgArenaLevelNew:SetRawImage(self._Control:GetArenaLevelWordIconById(arenaLevel))
    self.TxtInfo.text = XUiHelper.GetText("ArenaRankConversionDesc", self._Control:GetArenaLevelNameById(arenaLevel))
end

--endregion

return XUiArenaNewActivityResult
