---@class XUiChildPanelReformHiddenModel
---@field PanelHiddenMode XUiComponent.XUiButton
local XUiChildPanelReformHiddenModel = XClass(nil, "XUiChildPanelReformHiddenModel")

function XUiChildPanelReformHiddenModel:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self:RegisterUiEvents()
    self:HidePanelModeSelection();
    self.PanelNormalMode.ExitCheck = false
    self.PanelHiddenMode.ExitCheck = false
end

---@param team XTeam
function XUiChildPanelReformHiddenModel:SetData(stageId, team, rootUi)
    self.StageId = stageId
    self.Team = team
    self.RootUi = rootUi

    -- 刷新隐藏关卡
    self:RefreshPanelModel()
end

function XUiChildPanelReformHiddenModel:RefreshPanelModel()
    local stageCfg = XMVCA.XFuben:GetStageCfg(self.StageId)
    local haveHideAction = stageCfg.HideAction == 1 and #stageCfg.RobotId > 0
    local isHideAction = XMVCA.XFuben:GetIsHideAction()
    self.PanelMode.gameObject:SetActiveEx(haveHideAction)
    if haveHideAction then
        self.ModeNormal.gameObject:SetActiveEx(not isHideAction)
        self.ModeHidden.gameObject:SetActiveEx(isHideAction)

        if isHideAction then
            self.ModeHiddenText.text = XUiHelper.GetText("MultiplayerRoomRecommendAbility", stageCfg.Ability)
        end
    end
end

function XUiChildPanelReformHiddenModel:OnDestroy()
    -- 退出后还原设置
    XMVCA.XFuben:SetIsHideAction(false)
    -- 移除隐藏模式切换提示的定时器
    if self.HideActionTipsTimer then
        XScheduleManager.UnSchedule(self.HideActionTipsTimer)
        self.HideActionTipsTimer = nil
    end
end

function XUiChildPanelReformHiddenModel:ShowPanelMode()
    local isHideAction = XMVCA.XFuben:GetIsHideAction()
    -- 普通视角
    local normalState = isHideAction and CS.UiButtonState.Normal or CS.UiButtonState.Select
    self.PanelNormalMode:SetButtonState(normalState)
    -- 全息视角
    local stageCfg = XMVCA.XFuben:GetStageCfg(self.StageId)
    local tips = XUiHelper.GetText("MultiplayerRoomRecommendAbility", stageCfg.Ability)
    self.PanelHiddenMode:SetName(tips)
    local isHideDisable = self:IsOwnRobot2Char()
    self.PanelHiddenMode:SetDisable(not isHideDisable)
    if isHideDisable then
        local hiddenState = isHideAction and CS.UiButtonState.Select or CS.UiButtonState.Normal
        self.PanelHiddenMode:SetButtonState(hiddenState)
    end
end

-- 是否拥有机器人对应的角色(部分拥有)
function XUiChildPanelReformHiddenModel:IsOwnRobot2Char(isShowTip)
    local stageCfg = XMVCA.XFuben:GetStageCfg(self.StageId)
    local isOwnChar = false
    for _, robotId in ipairs(stageCfg.RobotId) do
        local charId = XRobotManager.GetCharacterId(robotId)
        local isOwn = XMVCA.XCharacter:IsOwnCharacter(charId)
        if isOwn then
            isOwnChar = true
            break
        end
    end

    if isShowTip and not isOwnChar then
        XUiManager.TipText("UiFubenQxmsNotOwnRoleTips")
    end

    return isOwnChar
end

function XUiChildPanelReformHiddenModel:GetRoles(isHideAction)
    local charIdList = {}

    local stageCfg = XMVCA.XFuben:GetStageCfg(self.StageId)
    if isHideAction then
        for index, robotId in pairs(stageCfg.RobotId) do
            local charId = XRobotManager.GetCharacterId(robotId)
            if XMVCA.XCharacter:IsOwnCharacter(charId) then
                charIdList[index] = charId
            else
                charIdList[index] = robotId
            end
        end
    else
        charIdList = XTool.Clone(stageCfg.RobotId)
    end

    return charIdList
end

function XUiChildPanelReformHiddenModel:ShowModeRemind()
    local isHideAction = XMVCA.XFuben:GetIsHideAction()
    local remindGo = isHideAction and self.RemindHidden or self.RemindNormal
    remindGo.gameObject:SetActiveEx(true)

    local delaySecond = isHideAction and self.RemindHiddenEnable.duration or self.RemindNormalEnable.duration
    local delayTime = math.ceil(delaySecond * 1000)
    self.HideActionTipsTimer = XScheduleManager.ScheduleOnce(function()
        remindGo.gameObject:SetActiveEx(false)
    end, delayTime)
end

function XUiChildPanelReformHiddenModel:ChangeHideActionCb(isHideAction)
    if XMVCA.XFuben:GetIsHideAction() == isHideAction then
        self:HidePanelModeSelection();
        -- 打开三级界面
        self:OpenFubenQxms()
        return
    end
    -- 未拥有角色
    if isHideAction and not self:IsOwnRobot2Char(true) then
        return
    end
    -- 更新队伍
    local charIdList = self:GetRoles(isHideAction)
    self.Team:UpdateEntityIds(charIdList)
    -- 保存模式
    XMVCA.XFuben:SetIsHideAction(isHideAction)
    -- 刷新信息
    self:RefreshPanelModel()
    self.RootUi:RefreshRoleInfos()
    -- 关闭当前界面
    self:HidePanelModeSelection();
    -- 打开三级界面
    self:OpenFubenQxms()
end

function XUiChildPanelReformHiddenModel:OpenFubenQxms()
    XLuaUiManager.Open("UiFubenQxms", self.Team:GetEntityIds(), self.StageId, function(entitiyIds, isHidden)
        XMVCA.XFuben:SetIsHideAction(isHidden)
        self.Team:UpdateEntityIds(entitiyIds)
        self:RefreshPanelModel()
        self.RootUi:RefreshRoleInfos()
        self:ShowModeRemind()
    end)
end

function XUiChildPanelReformHiddenModel:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.PanelMode, self.OnPanelModeClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCloseDifficulty, self.OnBtnCloseDifficultyClick)
    XUiHelper.RegisterClickEvent(self, self.PanelNormalMode, self.OnPanelNormalModeClick)
    XUiHelper.RegisterClickEvent(self, self.PanelHiddenMode, self.OnPanelHiddenModeClick)
end

function XUiChildPanelReformHiddenModel:OnPanelModeClick()
    self:ShowPanelMode()
    self:ShowPanelModeSelection();
end
    
function XUiChildPanelReformHiddenModel:OnBtnCloseDifficultyClick()
    self:HidePanelModeSelection();    
end

function XUiChildPanelReformHiddenModel:ShowPanelModeSelection()
    self.PanelModeSelection.gameObject:SetActiveEx(true)
    XDataCenter.UiPcManager.OnUiEnable(self, "OnBtnCloseDifficultyClick")
end

function XUiChildPanelReformHiddenModel:HidePanelModeSelection()
    XDataCenter.UiPcManager.OnUiDisableAbandoned(true, self)
    self.PanelModeSelection.gameObject:SetActiveEx(false)
end

function XUiChildPanelReformHiddenModel:OnPanelNormalModeClick()
    self:ChangeHideActionCb(false)
end

function XUiChildPanelReformHiddenModel:OnPanelHiddenModeClick()
    self:ChangeHideActionCb(true)
end

return XUiChildPanelReformHiddenModel