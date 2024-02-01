---@class XUiPanelChessHead : XUiNode
---@field _Control XBlackRockChessControl
---@field BtnHead XUiComponent.XUiButton
local XUiPanelChessHead = XClass(XUiNode, "XUiPanelChessHead")

local UltimateSkillMap = {
    [CS.XBlackRockChess.XWeaponSkillType.LUNA_SKILL3:GetHashCode()] = "LunaDazhaoEnable",
    [CS.XBlackRockChess.XWeaponSkillType.LUCIA_SKILL2:GetHashCode()] = "LuciaDazhaoEnable",
}

function XUiPanelChessHead:OnStart(roleId, animName)
    self.RoleId = roleId
    self.AnimName = animName
    self.BtnHead:SetRawImage(self._Control:GetRoleCircleIcon(roleId))
    self:HideGrowls()
    
    self.BtnHead.CallBack = function()
        self:OnBtnHeadClick()
    end
end

function XUiPanelChessHead:RefreshView(selectRoleId)
    local roleId = self.RoleId
    local isSelect = selectRoleId == roleId
    local actor = self._Control:GetChessGamer():GetRole(roleId)
    local isInBroad = actor and actor:IsInBoard() or false
    --未在场上
    local state = CS.UiButtonState.Normal
    if not isInBroad then
        state = CS.UiButtonState.Disable
    elseif isSelect then
        state = CS.UiButtonState.Select
    else
        state = CS.UiButtonState.Normal
    end
    self.BtnHead:SetButtonState(state)
    self.BtnHead:ShowTag(isInBroad and actor:IsOperaEnd())
    self.PanelCount.gameObject:SetActiveEx(isInBroad)
    self.BtnHead:SetNameByGroup(0, actor:GetSurvivalCount())
end

function XUiPanelChessHead:ShowGrowls(text, triggerArg, duration)
    
    local isUltimate = false
    if triggerArg then
        isUltimate = UltimateSkillMap[triggerArg] ~= nil
    end
   
    self.RImgUltimate.gameObject:SetActiveEx(isUltimate)
    self.PanelTalk.gameObject:SetActiveEx(not isUltimate)
    if isUltimate then
        self._Control:SetWaitingCv(true)
        self.Parent:PlayAnimation(UltimateSkillMap[triggerArg])
    else
        self.TxtContent.text = text
    end
    if duration > 0 then
        self:HideCountDown(duration, triggerArg)
    end
end

function XUiPanelChessHead:HideGrowls(triggerArg)
    local isUltimate = false
    if triggerArg then
        isUltimate = UltimateSkillMap[triggerArg]
    end
    self.RImgUltimate.gameObject:SetActiveEx(false)
    self.PanelTalk.gameObject:SetActiveEx(false)
    if isUltimate then
        self._Control:SetWaitingCv(false)
    end
end

function XUiPanelChessHead:PlaySwitchAnim()
    if string.IsNilOrEmpty(self.AnimName) then
        return
    end
    
    self.Parent:PlayAnimation(self.AnimName)
end

function XUiPanelChessHead:IsOperate()
    return (self._Control:IsEnterMove() or self._Control:IsEnterSkill()) and self
            ._Control:IsOperate()
end

function XUiPanelChessHead:OnBtnHeadClick()
    --拦截操作
    if not self:IsOperate() then
        return
    end
    local actor = self._Control:GetChessGamer():GetRole(self.RoleId)
    if not actor or not actor:CheckCouldSelect() then
        return
    end

    actor:CallCOnClick()
end

function XUiPanelChessHead:StopTimer()
    if not self.Timer then
        return
    end
    XScheduleManager.UnSchedule(self.Timer)
    self.Timer = nil
end

function XUiPanelChessHead:HideCountDown(duration, triggerArg)
    self:StopTimer()
    self.Timer = XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            self:StopTimer()
            return
        end
        self:HideGrowls(triggerArg)
    end, duration)
end


---@class XUiPanelListHead : XUiNode
---@field HeadViewDict table<number, XUiPanelChessHead>
---@field _Control XBlackRockChessControl
local XUiPanelListHead = XClass(XUiNode, "XUiPanelListHead")

function XUiPanelListHead:OnStart()
    local masterId = self._Control:GetMasterRoleId()
    local assistId = self._Control:GetAssistantRoleId()
    self.HeadViewDict = {
        [masterId] = XUiPanelChessHead.New(self.PanelLunaTalk, self.Parent, masterId, "QieHuanSkill1"),
        [assistId] = XUiPanelChessHead.New(self.PanelLuxiyaTalk, self.Parent, assistId, "QieHuanSkill2"),
    }
    
    self._Control:RegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.REFRESH_SELECT_ROLE, 
            handler(self, self.RefreshView))
    
    self._Control:RegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.SHOW_GROWLS, handler(self, self.ShowGrowls))
    self._Control:RegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.HIDE_GROWLS, handler(self, self.HideGrowls))
    
    self:PlayEnterGrowls()
end

function XUiPanelListHead:PlayEnterGrowls()
    for roleId, _ in pairs(self.HeadViewDict) do
        self._Control:PlayGrowls(XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.MASTER,
                XMVCA.XBlackRockChess.GrowlsTriggerType.EnterFight, roleId, 0)
    end
end

function XUiPanelListHead:OnDestroy()
    self._Control:UnRegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.REFRESH_SELECT_ROLE)
    self._Control:UnRegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.HIDE_GROWLS)
    self._Control:UnRegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.SHOW_GROWLS)
end

function XUiPanelListHead:OnSelectRole(selectRoleId)
    local bind = self.HeadViewDict[selectRoleId]
    if not bind then
        return
    end

    bind:OnBtnHeadClick()
end

function XUiPanelListHead:RefreshView(selectRoleId)
    for _, bind in pairs(self.HeadViewDict) do
        bind:RefreshView(selectRoleId)
    end
    if self.SelectId and self.SelectId ~= selectRoleId then
        local bind = self.HeadViewDict[selectRoleId]
        if bind then
            bind:PlaySwitchAnim()
        end
    end
    self.SelectId = selectRoleId
    self.Parent:ChangeState(true, true)
end

function XUiPanelListHead:ShowGrowls(roleId, text, triggerArg, duration)
    local bind = self.HeadViewDict[roleId]
    if not bind then
        return
    end
    bind:ShowGrowls(text, triggerArg, duration)
end

function XUiPanelListHead:HideGrowls(roleId, triggerArg)
    local bind = self.HeadViewDict[roleId]
    if not bind then
        return
    end
    bind:HideGrowls(triggerArg)
end

return XUiPanelListHead