local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
---@class XUiMonsterCombatBattleRoleRoom : XUiBattleRoleRoomDefaultProxy
local XUiMonsterCombatBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiMonsterCombatBattleRoleRoom")

---@param monsterTeam XMonsterTeam
function XUiMonsterCombatBattleRoleRoom:Ctor(monsterTeam, stageId)
    self.MonsterTeam = monsterTeam
    self.StageId = stageId
end

function XUiMonsterCombatBattleRoleRoom:GetAutoCloseInfo()
    local endTime = XDataCenter.MonsterCombatManager.GetActivityEndTime()
    return true, endTime, function(isClose)
        if isClose then
            XDataCenter.MonsterCombatManager.OnActivityEnd(true)
        end
    end
end

function XUiMonsterCombatBattleRoleRoom:GetRoleDetailProxy()
    return require("XUi/XUiMonsterCombat/Battle/XUiMonsterCombatBattleRoomRoleDetail")
end

-- 获取是否能够进入战斗，主要检查队伍设置是否正确，是否满足关卡配置的强制性条件
---@param monsterTeam XMonsterTeam
function XUiMonsterCombatBattleRoleRoom:GetIsCanEnterFight(monsterTeam, stageId)
    -- 检查队长是否为空
    if monsterTeam:GetCaptainPosEntityId() == 0 then
        return false, CS.XTextManager.GetText("CharacterCheckTeamNil")
    end
    -- 检查怪物是否为空
    if monsterTeam:GetMonsterIsEmpty() then
        return false, CS.XTextManager.GetText("UiMonsterCombatCheckMonsterNil")
    end
    -- 检查关卡开启条件
    return self:CheckStageForceConditionWithTeamEntityId(monsterTeam, stageId)
end

-- 进入战斗
---@param monsterTeam XMonsterTeam
function XUiMonsterCombatBattleRoleRoom:EnterFight(monsterTeam, stageId, challengeCount, isAssist)
    local stageConfig = XDataCenter.FubenManager.GetStageCfg(stageId)
    local teamId = monsterTeam:GetId()
    XDataCenter.MonsterCombatManager.UpdateMonsterTeamCache(monsterTeam)
    -- bvb玩法不需要支援
    isAssist = false
    XDataCenter.FubenManager.EnterFight(stageConfig, teamId, isAssist, challengeCount)
end

---@param rootUi XUiMonsterCombatBattlePrepare
function XUiMonsterCombatBattleRoleRoom:AOPOnEnableAfter(rootUi)
    -- 总负重
    local totalCost = 0
    for _, monsterId in pairs(rootUi.MonsterTeam:GetMonsterIds()) do
        if XTool.IsNumberValid(monsterId) then
            local monsterEntity = XDataCenter.MonsterCombatManager.GetMonsterEntity(monsterId)
            totalCost = totalCost + monsterEntity:GetCost()
        end
    end
    -- 刷新编队负重
    self:RefreshMonsterCost(rootUi, totalCost)
    -- 刷新怪物信息
    self.GridImgStarList = self.GridImgStarList or {}
    self:RefreshMonsterInfo(rootUi, totalCost)
end

---@param rootUi XUiMonsterCombatBattlePrepare
function XUiMonsterCombatBattleRoleRoom:RefreshMonsterCost(rootUi, totalCost)
    -- 负重上限
    local costLimit = XDataCenter.MonsterCombatManager.GetActivityMonsterCostLimit()
    if totalCost < 0 or totalCost > costLimit then
        XLog.Error(string.format("怪物负重异常，总负重:%s, 负重上限:%s", totalCost, costLimit))
        return
    end
    -- 剩余负重
    local remianCost = costLimit - totalCost
    for i = 1, costLimit do
        local gridStar = rootUi["GridStar" .. i]
        if gridStar then
            local isActive = i <= remianCost
            gridStar:GetObject("ImgUnActive").gameObject:SetActiveEx(not isActive)
            gridStar:GetObject("ImgActive").gameObject:SetActiveEx(isActive)
        end
    end
end

---@param rootUi XUiMonsterCombatBattlePrepare
function XUiMonsterCombatBattleRoleRoom:RefreshMonsterInfo(rootUi, totalCost)
    rootUi.MonsterTeam:MonsterSort()
    local countLimit = XDataCenter.MonsterCombatManager.GetActivityMonsterCountLimit()
    local costLimit = XDataCenter.MonsterCombatManager.GetActivityMonsterCostLimit()
    local isCostLimit = totalCost >= costLimit
    for i = 1, countLimit do
        local monsterId = rootUi.MonsterTeam:GetMonsterIdByPos(i)
        local isActive = XTool.IsNumberValid(monsterId)
        local isLock = not isActive and isCostLimit or false
        self:RefreshMonsterStatus(rootUi, i, isActive, isLock)
        if isActive then
            self:RefreshMonsterView(rootUi, i, monsterId)
        end
    end
end

---@param rootUi XUiMonsterCombatBattlePrepare
function XUiMonsterCombatBattleRoleRoom:RefreshMonsterStatus(rootUi, i, isActive, isLock)
    rootUi["PanelUnActive" .. i].gameObject:SetActiveEx(not isActive and not isLock)
    rootUi["PanelActive" .. i].gameObject:SetActiveEx(isActive and not isLock)
    rootUi["PanelLock" .. i].gameObject:SetActiveEx(isLock)
    rootUi["BtnMonster" .. i].gameObject:SetActiveEx(not isLock)
end

---@param rootUi XUiMonsterCombatBattlePrepare
function XUiMonsterCombatBattleRoleRoom:RefreshMonsterView(rootUi, i, monsterId)
    self.GridImgStarList[i] = self.GridImgStarList[i] or {}
    local monsterEntity = XDataCenter.MonsterCombatManager.GetMonsterEntity(monsterId)
    -- 头像
    rootUi["IconMoster" .. i]:SetRawImage(monsterEntity:GetAchieveIcon())
    -- 名字
    rootUi["TxtName" .. i].text = monsterEntity:GetName()
    -- 负重
    local imgStar = rootUi["ImgStar" .. i]
    local panelStars = rootUi["PanelStars" .. i]
    local cost = monsterEntity:GetCost()
    for j = 1, cost do
        local grid = self.GridImgStarList[i][j]
        if not grid then
            grid = j == 1 and imgStar or XUiHelper.Instantiate(imgStar, panelStars)
            self.GridImgStarList[i][j] = grid
        end
        grid.gameObject:SetActiveEx(true)
    end
    for j = cost + 1, #self.GridImgStarList[i] do
        self.GridImgStarList[i][j].gameObject:SetActiveEx(false)
    end
    -- 播放动画
    if XTool.IsNumberValid(rootUi.PlayMonsterAnimId) and rootUi.PlayMonsterAnimId == monsterId then
        rootUi.PlayMonsterAnimId = 0
        rootUi:PlayAnimationWithMask(string.format("Consume%s%s", i, cost))
    end
end

return XUiMonsterCombatBattleRoleRoom