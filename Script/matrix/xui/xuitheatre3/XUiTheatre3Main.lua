---@class XUiTheatre3Main : XLuaUi
---@field ImgLuckBar UnityEngine.UI.Image
---@field _Control XTheatre3Control
local XUiTheatre3Main = XLuaUiManager.Register(XLuaUi, "UiTheatre3Main")

function XUiTheatre3Main:OnAwake()
    self:InitLineChange()
    self:AddEventListener()
end

function XUiTheatre3Main:OnStart()
    local XUiTheatre3PanelMain = require("XUi/XUiTheatre3/XUiTheatre3PanelMain")
    ---@type XUiTheatre3PanelMain
    self.PanelStyle1 = XUiTheatre3PanelMain.New(self.Style1, self, true)
    ---@type XUiTheatre3PanelMain
    self.PanelStyle2 = XUiTheatre3PanelMain.New(self.Style2, self, false)
    if not self.EffectCommon then
        self.EffectCommon = XUiHelper.TryGetComponent(self.Transform, "FullScreenBackground/EffectCommon")
    end
end

function XUiTheatre3Main:OnEnable()
    local isTip = self._Control:CheckAndOpenQuantumOpen(function()
        self._IsA = false
        self:_RefreshStyleByAnim(self._IsA)
        self:StartLineChangeTimer()
    end)
    if self._Control:IsHaveAdventure() then
        self:_RefreshStyle(self._Control:IsAdventureALine())
    else
        self:_RefreshStyle(self._IsA)
        if not isTip then
            self:StartLineChangeTimer()
        end
    end
    if isTip and self.EffectCommon then
        self.EffectCommon.gameObject:SetActiveEx(false)
    end
end

function XUiTheatre3Main:OnDisable()
    self:StopLineChangeTimer()
end

function XUiTheatre3Main:OnDestroy()
    -- 销毁后关闭音乐
    if self._Control:IsAdventureALine() then
        return
    end
    self._Control:PlayQuantumBGM(true)
end

--region Ui - LineChange
function XUiTheatre3Main:InitLineChange()
    self._IsA = true
    self._LineTimer = nil
end

function XUiTheatre3Main:StartLineChangeTimer()
    local conditionId = self._Control:GetClientConfigNumber("QuantumOpenTipCondition")
    if not XTool.IsNumberValid(conditionId) then
        return
    end
    local isTrue, _ = XConditionManager.CheckCondition(conditionId)
    if not isTrue then
        return
    end
    self:StopLineChangeTimer()
    self._LineTimer = XScheduleManager.ScheduleForever(function()
        self._IsA = not self._IsA
        self:_RefreshStyleByAnim(self._IsA)
    end, self._Control:GetClientConfigNumber("QuantumMainChangeCD") or 10000,0)
end

function XUiTheatre3Main:StopLineChangeTimer()
    if self._LineTimer then
        XScheduleManager.UnSchedule(self._LineTimer)
    end
    self._LineTimer = nil
end

function XUiTheatre3Main:_RefreshStyle(isA)
    if self.EffectCommon then
        self.EffectCommon.gameObject:SetActiveEx(true)
    end
    if isA then
        self.PanelStyle1:Open()
        self.PanelStyle1:RefreshCanvasGroup()
        self.PanelStyle2:Close()
        self.BgStyle1.gameObject:SetActiveEx(true)
        self.BgStyle2.gameObject:SetActiveEx(false)
        self._Control:PlayQuantumBGM(true)
    else
        self.PanelStyle1:Close()
        self.PanelStyle2:Open()
        self.PanelStyle2:RefreshCanvasGroup()
        self.BgStyle1.gameObject:SetActiveEx(false)
        self.BgStyle2.gameObject:SetActiveEx(true)
        self._Control:PlayQuantumBGM(false)
    end
end

function XUiTheatre3Main:_RefreshStyleByAnim(isA)
    if isA then
        self:PlayAnimation("QieHuanStyle1", function()
            self.PanelStyle2:Close()
        end)
        self.PanelStyle1:Open()
        self.BgStyle1.gameObject:SetActiveEx(true)
        self.BgStyle2.gameObject:SetActiveEx(false)
        self._Control:PlayQuantumBGM(true)
    else
        self:PlayAnimation("QieHuanStyle2", function()
            self.PanelStyle1:Close()
        end)
        self.PanelStyle2:Open()
        self.BgStyle1.gameObject:SetActiveEx(false)
        self.BgStyle2.gameObject:SetActiveEx(true)
        self._Control:PlayQuantumBGM(false)
    end
end
--endregion

--region Ui - BtnListener
function XUiTheatre3Main:AddEventListener()
    self._Control:RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    self._Control:RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientConfig("HelpKey"))
end

function XUiTheatre3Main:OnBtnBackClick()
    self:Close()
end

function XUiTheatre3Main:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
--endregion

return XUiTheatre3Main