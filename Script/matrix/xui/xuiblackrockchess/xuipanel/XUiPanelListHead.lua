local UltimateSkillMap = {
    [CS.XBlackRockChess.XWeaponSkillType.VERA_SKILL3:GetHashCode()] = true,
}

---@class XUiPanelListHead : XUiNode
---@field _Control XBlackRockChessControl
local XUiPanelListHead = XClass(XUiNode, "XUiPanelListHead")

local MASTER = XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.MASTER
local EnterFight = XMVCA.XBlackRockChess.GrowlsTriggerType.EnterFight

function XUiPanelListHead:OnStart()
    self._MasterId = self._Control:GetMasterRoleId()

    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_GROWLS, self.ShowGrowls, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_HIDE_GROWLS, self.HideGrowls, self)

    self:PlayEnterGrowls()
end

function XUiPanelListHead:PlayEnterGrowls()
    self._Control:PlayGrowls(MASTER, EnterFight, self._MasterId, 0)
end

function XUiPanelListHead:OnDestroy()
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_GROWLS, self.ShowGrowls, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_HIDE_GROWLS, self.HideGrowls, self)
end

function XUiPanelListHead:ShowGrowls(text, triggerArg, duration)
    if string.IsNilOrEmpty(text) or duration <= 0 then
        self:HideGrowls(triggerArg)
        return
    end
    
    local isUltimate = false
    if triggerArg then
        isUltimate = UltimateSkillMap[triggerArg]
    end

    self.RImgUltimate.gameObject:SetActiveEx(isUltimate)
    self.PanelTalk.gameObject:SetActiveEx(not isUltimate)
    if isUltimate then
        self._Control:SetWaitingCv(true)
    else
        self.TxtContent.text = text
    end
    if duration > 0 then
        self:HideCountDown(duration, triggerArg)
    end
end

function XUiPanelListHead:HideGrowls(triggerArg)
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

function XUiPanelListHead:HideCountDown(duration, triggerArg)
    self:StopTimer()
    self.Timer = XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            self:StopTimer()
            return
        end
        self:HideGrowls(triggerArg)
    end, duration)
end

function XUiPanelListHead:StopTimer()
    if not self.Timer then
        return
    end
    XScheduleManager.UnSchedule(self.Timer)
    self.Timer = nil
end

return XUiPanelListHead