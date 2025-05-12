-- 新矿区
local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")
---@class XScoreTowerAgency : XFubenActivityAgency
---@field private _Model XScoreTowerModel
local XScoreTowerAgency = XClass(XFubenActivityAgency, "XScoreTowerAgency")
function XScoreTowerAgency:OnInit()
    --初始化一些变量
    self:RegisterActivityAgency()
    self:RegisterFuben(XEnumConst.FuBen.StageType.ScoreTower)
end

function XScoreTowerAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyScoreTowerActivityData = handler(self, self.NotifyScoreTowerActivityData)
    XRpc.NotifyScoreTowerAutoSetTeam = handler(self, self.NotifyScoreTowerAutoSetTeam)
    XRpc.NotifyScoreTowerStageUpdate = handler(self, self.NotifyScoreTowerStageUpdate)
end

function XScoreTowerAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

--region 服务端通知

--- 通知积分塔活动数据
function XScoreTowerAgency:NotifyScoreTowerActivityData(data)
    if not data or not XTool.IsNumberValid(data.ActivityNo) then
        return
    end

    self._Model:NotifyScoreTowerActivityData(data)
end

--- 通知积分塔自动设置队伍
function XScoreTowerAgency:NotifyScoreTowerAutoSetTeam(data)
    if not data or not XTool.IsNumberValid(data.ChapterId) or not XTool.IsNumberValid(data.TowerId) or not XTool.IsNumberValid(data.StageCfgId) then
        return
    end
    local towerData = self._Model:GetTowerData(data.ChapterId, data.TowerId)
    if towerData then
        -- 更新关卡数据
        towerData:AddStageData(data.StageData)
    end
    if self._Model.ActivityData then
        -- 更新关卡记录
        self._Model.ActivityData:AddStageRecord(data.StageRecord)
        -- 更新关卡队伍
        self._Model:SyncStageTeamServerData(data.TowerId, data.StageCfgId)
    end
end

--- 通知积分塔关卡更新
function XScoreTowerAgency:NotifyScoreTowerStageUpdate(data)
    if not data or not XTool.IsNumberValid(data.ChapterId) or not XTool.IsNumberValid(data.TowerId) then
        return
    end
    local towerData = self._Model:GetTowerData(data.ChapterId, data.TowerId)
    if not towerData then
        return
    end
    towerData:AddStageData(data.StageData)
end

--endregion

--region 活动相关

--- 活动是否开启
---@param noTips boolean 是否不弹出提示
---@return boolean 是否开启
function XScoreTowerAgency:GetIsOpen(noTips)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ScoreTower, false, noTips) then
        return false
    end

    if not self._Model.ActivityData or not self:ExCheckInTime() then
        if not noTips then
            XUiManager.TipErrorWithKey("CommonActivityNotStart")
        end
        return false
    end

    return true
end

--- 获取活动结束时间
function XScoreTowerAgency:GetActivityEndTime()
    local timeId = self._Model:GetActivityTimeId()
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

--- 处理活动结束
function XScoreTowerAgency:HandleActivityEnd()
    XLuaUiManager.RunMain()
    XUiManager.TipText("ActivityAlreadyOver")
end

--- 获取塔层关卡类型
---@param stageCfgId number 关卡配置ID ScoreTowerStage表的ID
function XScoreTowerAgency:GetStageType(stageCfgId)
    return self._Model:GetStageType(stageCfgId)
end

--- 获取客户端配置
function XScoreTowerAgency:GetClientConfig(key, index)
    return self._Model:GetClientConfig(key, XTool.IsNumberValid(index) and index or 1)
end

--- 获取当前层Id
---@param chapterId number 章节Id
function XScoreTowerAgency:GetCurrentFloorId(chapterId)
    local chapterData = self._Model:GetChapterData(chapterId)
    if not chapterData then
        return 0
    end

    local curTowerId = chapterData:GetCurTowerId() or 0
    if not XTool.IsNumberValid(curTowerId) then
        return 0
    end

    local towerData = self._Model:GetTowerData(chapterId, curTowerId)
    return towerData and towerData:GetCurFloorId() or 0
end

--- 获取角色战力
---@param entityId number 角色Id
function XScoreTowerAgency:GetCharacterPower(entityId)
    local ability = XMVCA.XCharacter:GetCharacterHaveRobotAbilityById(entityId) or 0
    local power = self._Model:CalStrengthenFightAbility() or 0
    return ability + power
end

--endregion

--region Fight 副本相关

--- 战前准备
---@param stage XTableStage 关卡
function XScoreTowerAgency:PreFight(stage, teamId, isAssist, challengeCount)
    local team = self._Model:GetStageTeamByTeamId(teamId)
    if not team then
        XLog.Error("找不到teamId为%s的队伍", teamId)
        return
    end
    local preFight = {}
    preFight.RobotIds = team:GetRobotIdsOrder()
    preFight.CardIds = team:GetCharacterIdsOrder()
    preFight.StageId = stage.StageId
    preFight.IsHasAssist = isAssist
    preFight.ChallengeCount = challengeCount
    preFight.CaptainPos = team:GetCaptainPos()
    preFight.FirstFightPos = team:GetFirstFightPos()
    preFight.GeneralSkill = team:GetCurGeneralSkill()
    preFight.EnterCgIndex = team:GetEnterCgIndex()
    preFight.SettleCgIndex = team:GetSettleCgIndex()
    return preFight
end

-- 进入战斗
---@param team XScoreTowerStageTeam 队伍
function XScoreTowerAgency:EnterFight(stageId, team, isAssist, challengeCount)
    self._Model:SetStageTeamRequestByTeam(team, true, function()
        -- 进入战斗
        XMVCA.XFuben:EnterFightByStageId(stageId, team:GetId(), isAssist, challengeCount)
    end)
end

-- 胜利 & 奖励界面
function XScoreTowerAgency:ShowReward(winData)
    if not winData or not winData.SettleData then
        XMVCA.XFuben:ShowReward(winData)
        return
    end

    local result = winData.SettleData.ScoreTowerSettleResult
    if not result then
        XMVCA.XFuben:ShowReward(winData)
        return
    end

    local stageType = self:GetStageType(result.StageCfgId)
    if stageType == XEnumConst.ScoreTower.StageType.Boss then
        XLuaUiManager.Open("UiScoreTowerSettlement", winData)
    else
        XMVCA.XFuben:ShowReward(winData)
    end
end

--endregion

--region 副本扩展入口

function XScoreTowerAgency:ExOpenMainUi()
    if not self:GetIsOpen() then
        return
    end

    --打开主界面
    XLuaUiManager.Open("UiScoreTowerMain")
end

function XScoreTowerAgency:ExGetConfig()
    if XTool.IsTableEmpty(self.ExConfig) then
        ---@type XTableFubenActivity
        self.ExConfig = XFubenConfigs.GetFubenActivityConfigByManagerName(self.__cname)
    end
    return self.ExConfig
end

function XScoreTowerAgency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.ScoreTower
end

function XScoreTowerAgency:ExCheckInTime()
    local timeId = self._Model:GetActivityTimeId()
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

function XScoreTowerAgency:ExCheckIsShowRedPoint()
    if not self:GetIsOpen(true) then
        return false
    end
    if self._Model:IsShowChapterRedPoint() then
        return true
    end
    if self._Model:IsShowTaskRedPoint() then
        return true
    end
    if self._Model:IsShowRankRedPoint() then
        return true
    end
    return false
end

function XScoreTowerAgency:ExGetProgressTip()
    local chapterIds = self._Model:GetActivityChapterIds()
    local curCount, totalCount = 0, 0
    for _, chapterId in pairs(chapterIds) do
        curCount = curCount + self._Model:GetChapterCurStar(chapterId)
        totalCount = totalCount + self._Model:GetChapterTotalStar(chapterId)
    end
    return string.format("%s/%s", curCount, totalCount)
end

--endregion

--region 编队相关

-- 获取塔编队实体
---@param team XScoreTowerTowerTeam 编队
function XScoreTowerAgency:GetTowerEntities(team, characterType)
    -- 已拥有的角色
    local entities = XMVCA.XCharacter:GetOwnCharacterList(characterType)
    -- 章节Id
    local chapterId = team and team:GetChapterId() or 0
    -- 机器人
    local robotIds = self._Model:GetAllRobotIds(chapterId)
    for _, robotId in pairs(robotIds) do
        local entity = XRobotManager.GetRobotById(robotId)
        if entity then
            table.insert(entities, entity)
        end
    end
    return entities
end

-- 获取关卡编队实体
---@param team XScoreTowerStageTeam 编队
function XScoreTowerAgency:GetStageEntities(team)
    local towerId = team and team:GetTowerId() or 0
    if not XTool.IsNumberValid(towerId) then
        return {}
    end
    local characterInfos = self._Model:GetTowerRecordCharacterInfos(towerId)
    local entities = {}
    for _, info in ipairs(characterInfos) do
        local entityId = info:GetEntityId()
        if XTool.IsNumberValid(entityId) then
            local entity = XRobotManager.CheckIsRobotId(entityId) and XRobotManager.GetRobotById(entityId) or XMVCA.XCharacter:GetCharacter(entityId)
            if entity then
                table.insert(entities, entity)
            else
                XLog.Warning(string.format("找不到id%s的角色", entityId))
            end
        end
    end
    return entities
end

--- 获取塔角色过滤排序
---@param towerId number 塔Id
function XScoreTowerAgency:GetTowerCharacterFilterSort(towerId)
    return self._Model:GetTowerCharacterFilterSort(towerId)
end

--- 获取关卡角色过滤排序
---@param stageCfgId number 关卡配置ID ScoreTowerStage表的ID
function XScoreTowerAgency:GetStageCharacterFilterSort(stageCfgId)
    return self._Model:GetStageCharacterFilterSort(stageCfgId)
end

--- 检查是否是塔推荐Tag
---@param towerId number 塔ID
---@param entityId number 实体ID
function XScoreTowerAgency:IsTowerSuggestTag(towerId, entityId)
    if not XTool.IsNumberValid(towerId) or not XTool.IsNumberValid(entityId) then
        return false
    end
    return self._Model:IsTowerSuggestTag(towerId, entityId)
end

--- 检查是否是关卡推荐Tag
---@param cfgId number ScoreTowerStage表Id
---@param entityId number 实体ID
function XScoreTowerAgency:IsStageSuggestTag(cfgId, entityId)
    if not XTool.IsNumberValid(cfgId) or not XTool.IsNumberValid(entityId) then
        return false
    end
    return self._Model:IsStageSuggestTag(cfgId, entityId)
end

--- 在角色上单击之前
---@param team XScoreTowerStageTeam 队伍
---@param pos number 位置
function XScoreTowerAgency:OnCharacterClickBefore(team, pos)
    local entityId = team:GetEntityIdByTeamPos(pos)
    if XTool.IsNumberValid(entityId) then
        local chapterId = team:GetChapterId() or 0
        local towerId = team:GetTowerId() or 0
        local stageCfgId = team:GetStageCfgId() or 0
        if not XTool.IsNumberValid(chapterId) or not XTool.IsNumberValid(towerId) or not XTool.IsNumberValid(stageCfgId) then
            return true
        end
        -- 检查关卡是否通关
        if self._Model:IsStagePass(chapterId, towerId, stageCfgId) then
            XUiManager.TipMsg(self:GetClientConfig("StageTeamRelatedTips", 2))
            return true
        end
        return false
    end
    if team:GetIsFullMember() then
        local limit = team:GetCurrentEntityLimit()
        XUiManager.TipMsg(XUiHelper.FormatText(self:GetClientConfig("StageTeamRoleNumberLimitDesc"), limit))
        return true
    end
    return false
end

--- 获取塔层关卡显示的角色信息列表
---@param team XScoreTowerStageTeam 队伍
---@return { Id:number, Pos:number, IsUsed:boolean, IsNow:boolean, StageId:number }[]
function XScoreTowerAgency:GetStageShowCharacterInfoList(team)
    if not team then
        return nil
    end
    local chapterId = team:GetChapterId() or 0
    local towerId = team:GetTowerId() or 0
    local floorId = team:GetFloorId() or 0
    local stageCfgId = team:GetStageCfgId() or 0
    if not XTool.IsNumberValid(chapterId) or not XTool.IsNumberValid(towerId) or not XTool.IsNumberValid(floorId) or not XTool.IsNumberValid(stageCfgId) then
        return nil
    end
    return self._Model:GetStageShowCharacterInfoList(chapterId, towerId, floorId, stageCfgId)
end

--endregion

--region condition

--- 检查是否通关章节
---@param chapterId number 章节ID
function XScoreTowerAgency:CheckPassChapter(chapterId)
    local curStar = self._Model:GetChapterCurStar(chapterId)
    return curStar > 0
end

--- 检查是否通关塔
---@param chapterId number 章节ID
---@param towerId number 塔ID
function XScoreTowerAgency:CheckPassTower(chapterId, towerId)
    local towerData = self._Model:GetTowerData(chapterId, towerId)
    if not towerData then
        return false
    end
    local curStar = towerData:GetCurStar() or 0
    return curStar > 0
end

--- 检查循环是否强化到X级
---@param configId number 配置ID
---@param level number 等级
function XScoreTowerAgency:CheckStrengthenLevel(configId, level)
    local strengthenData = self._Model:GetStrengthenData(configId)
    if not strengthenData then
        return false
    end
    local curLevel = strengthenData:GetLv() or 0
    return curLevel >= level
end

--- 检查当前是否位于X章节X层
---@param chapterId number 章节ID
---@param floorId number 层ID
function XScoreTowerAgency:CheckInFloor(chapterId, floorId)
    local curChapterId = self._Model:GetCurrentChapterId()
    if not XTool.IsNumberValid(curChapterId) or curChapterId ~= chapterId then
        return false
    end
    local curFloorId = self:GetCurrentFloorId(chapterId)
    return XTool.IsNumberValid(curFloorId) and curFloorId == floorId
end

--- 检查当前是否位于X章节的选人界面
---@param chapterId number 章节ID
function XScoreTowerAgency:CheckInSelectCharacterInterface(chapterId)
    local targetUiName = "UiScoreTowerChapterDetail"
    local isUiShow = XLuaUiManager.IsUiShow(targetUiName)
    if not isUiShow then
        return false
    end
    ---@type XUiScoreTowerChapterDetail
    local luaUi = XLuaUiManager.GetTopLuaUi(targetUiName)
    if not luaUi then
        return false
    end
    local curChapterId = luaUi:GetChapterId() or 0
    return XTool.IsNumberValid(curChapterId) and curChapterId == chapterId
end

--endregion

--region 红点相关
function XScoreTowerAgency:IsShowChapterRedPoint()
    return self._Model:IsShowChapterRedPoint()
end

function XScoreTowerAgency:IsShowRankRedPoint()
    return self._Model:IsShowRankRedPoint()
end

function XScoreTowerAgency:IsShowTaskRedPoint()
    return self._Model:IsShowTaskRedPoint()
end

--endregion

return XScoreTowerAgency
