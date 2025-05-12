local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
---@class XUiBossInshotBattleRoleRoom : XUiBattleRoleRoomDefaultProxy
local XUiBossInshotBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiBossInshotBattleRoleRoom")

---@param team XTeam
function XUiBossInshotBattleRoleRoom:Ctor(team, stageId)
    self.Team = team
    self.StageId = stageId
end

function XUiBossInshotBattleRoleRoom:AOPOnStartAfter(rootUi)
    self.RootUi = rootUi
    rootUi.BtnTeamPrefab.gameObject:SetActiveEx(false)
    
    -- 隐藏UI上的2号位、3号位
    local canvasGroup2 = rootUi.BtnChar2.gameObject:AddComponent(typeof(CS.UnityEngine.CanvasGroup))
    canvasGroup2.alpha = 0
    local raycast2 = rootUi.BtnChar2.gameObject:GetComponent("XEmpty4Raycast")
    raycast2.raycastTarget = false
    local canvasGroup3 = rootUi.BtnChar3.gameObject:AddComponent(typeof(CS.UnityEngine.CanvasGroup))
    canvasGroup3.alpha = 0
    local raycast3 = rootUi.BtnChar3.gameObject:GetComponent("XEmpty4Raycast")
    raycast3.raycastTarget = false
    -- 隐藏场景上的2号位、3号位
    local sceneRoot = rootUi.UiSceneInfo.Transform
    sceneRoot:FindTransform("PanelRoleEffect2").gameObject:SetActiveEx(false)
    sceneRoot:FindTransform("PanelRoleEffect3").gameObject:SetActiveEx(false)
    -- 隐藏其他UI
    rootUi.PanelTeamLeader.gameObject:SetActiveEx(false)
    rootUi.PanelSkill.gameObject:SetActiveEx(false)
end

function XUiBossInshotBattleRoleRoom:AOPOnCharacterClickBefore(rootUi, index)
    local isStop = false
    local maxCharCnt = XMVCA.XBossInshot:GetBattleTeamMaxCharCount() -- 最大上阵人数
    local isCharCntLimit = self.Team:GetEntityCount() >= maxCharCnt -- 角色数量达到上限
    local isSelectedChar = self.Team:GetEntityIdByTeamPos(index) ~= 0 -- 已选择角色
    if isCharCntLimit and not isSelectedChar then
        isStop = true
        local tips = XUiHelper.GetText("BossInshotTeamCharLimitTips", maxCharCnt)
        XUiManager.TipError(tips)
    end
    return isStop
end

function XUiBossInshotBattleRoleRoom:AOPOnClickFight()
    local canEnterFight, errorTip = self:GetIsCanEnterFight(self.Team, self.StageId)
    if not canEnterFight then
        if errorTip then
            XUiManager.TipError(errorTip)
        end
        return
    end
    
    local isAssist = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.AssistSwitch .. XPlayer.Id) == 1
    self:EnterFight(self.Team, self.StageId, nil, isAssist)
    return true
end

function XUiBossInshotBattleRoleRoom:GetRoleDetailProxy()
    return require("XUi/XUiBossInshot/XUiBossInshotBattleRoleDetailProxy")
end

function XUiBossInshotBattleRoleRoom:GetChildPanelData()
    if self.ChildPanelData == nil then
        self.ChildPanelData = {
            assetPath = XUiConfigs.GetComponentUrl("PanelBossInshotTeam"),
            proxy = require("XUi/XUiBossInshot/XUiPanelBossInshotTeam"),
            proxyArgs = { "Team", "StageId", self.RootUi }
        }
    end
    return self.ChildPanelData
end

-- 检查是否开启效应选择
function XUiBossInshotBattleRoleRoom:CheckIsEnableGeneralSkillSelection()
    return false
end

function XUiBossInshotBattleRoleRoom:CheckStageRobotIsUseCustomProxy()
    return true
end

function XUiBossInshotBattleRoleRoom:CheckShowAnimationSet()
    return false
end

return XUiBossInshotBattleRoleRoom
