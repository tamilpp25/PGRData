local IsWindowsEditor = XMain.IsWindowsEditor
local CSTextManagerGetText = CS.XTextManager.GetText
local ProcessFunc = XEnumConst.FuBen.ProcessFunc
local StageType = XEnumConst.FuBen.StageType
local METHOD_NAME = {
    PreFight = "PreFightRequest",
    FightSettle = "FightSettleRequest",
    FightWin = "FightWinRequest",
    FightLose = "FightLoseRequest",
    BuyActionPoint = "BuyActionPointRequest",
    RefreshFubenList = "RefreshFubenListRequest",
    EnterChallenge = "EnterChallengeRequest",
    CheckChallengeCanEnter = "CheckChallengeCanEnterRequest",
    GetTowerInfo = "GetTowerInfoRequest",
    GetTowerRecommendedList = "GetTowerRecommendedListRequest",
    GetTowerChapterReward = "GetTowerChapterRewardRequest",
    CheckResetTower = "CheckResetTowerRequest",
    GuideComplete = "GuideCompleteRequest",
    GetFightData = "GetFightDataRequest",
    BOGetBossDataRequest = "BOGetBossDataRequest",
    FightReboot = "FightRebootRequest",
    FightRestart = "FightRestartRequest"
}
local XFubenBaseAgency = require("XModule/XBase/XFubenBaseAgency")

---@class XFubenAgency : XAgency
---@field private _Model XFubenModel
local XFubenAgency = XClass(XAgency, "XFubenAgency")
function XFubenAgency:OnInit()
    --初始化一些变量
    --注册的副本
    self._RegFubenDict = {}
    --用来记录有自定义函数的id
    ---@type table<string, table<number, string>>
    self._CustomFuncIds = {}
    --{
    --    [XEnumConst.FuBen.ProcessFunc.InitStageInfo] = {}
    --}
    self:InitCustomFuncIdsTab()
    --用于存储传输给C#层封装的Handler
    self._TempCustomFunc = {}


    -------
    self._NeedCheckUiConflict = false
    self._AssistSuccess = false
    
    self.SettleFightHandler = function(result)
        return self:SettleFight(result)
    end
    self.CallFinishFightHandler = function()
        return self:CallFinishFight()
    end
end

function XFubenAgency:InitCustomFuncIdsTab()
    --local funcKeys = ProcessFunc
    --for key, _ in pairs(funcKeys) do
    --    self._CustomFuncIds[key] = {}
    --end
end

function XFubenAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    --先注释
    --XRpc.NotifyStageData = Handler(self, self.NotifyStageData)
    --XRpc.OnEnterFight = Handler(self, self.NotifyOnEnterFight)
    --XRpc.NotifyUnlockHideStage = Handler(self, self.OnSyncUnlockHideStage)
    --XRpc.FightSettleNotify = Handler(self, self.OnFightSettleNotify)
    --XRpc.NotifyRemoveStageData = Handler(self, self.OnNotifyRemoveStageData)
end

function XFubenAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
    --角色升级
    self:AddAgencyEvent(XEventId.EVENT_PLAYER_LEVEL_CHANGE, self.InitStageData, self)
end

----------public start----------
---返回是否有注册玩法, 用来兼容老模块判定
function XFubenAgency:HasRegisterAgency(fubenType)
    if self._RegFubenDict[fubenType] then
        return true
    end
    return false
end

---@param fubenType number
---@param moduleId string
function XFubenAgency:RegisterFuben(fubenType, moduleId)
    if not self._RegFubenDict[fubenType] then
        local agency = XMVCA:GetAgency(moduleId)
        if agency then
            if IsWindowsEditor then
                if not CheckClassSuper(agency, XFubenBaseAgency) then
                    XLog.Error(string.format("%s Agency 需要继承 XFubenBaseAgency", agency:GetId()))
                    return
                end
            end
            self._RegFubenDict[fubenType] = moduleId
        else
            XLog.Error("注册副本模块Agency不存在: "..tostring(fubenType) .. " " ..tostring(moduleId))
        end
    else
        XLog.Error("请勿重复注册副本: "..tostring(fubenType) .. " " .. tostring(moduleId))
    end
end

---返回是否有自定义函数
---@param fubenType number 副本类型
---@param funcKey string
---@return boolean
function XFubenAgency:HasCustomFunc(fubenType, funcKey)
    if self._RegFubenDict[fubenType] then
        local agency = XMVCA:GetAgency(self._RegFubenDict[fubenType])
        return agency[funcKey] --返回有这个方法
    end
end

---副本尝试调用各个玩法的自定义战斗函数
---@param fubenType number 副本类型
---@param funcKey string
---@return boolean 是否有执行到自定义方法
---@return any 方法返回值
function XFubenAgency:CallCustomFunc(fubenType, funcKey, ...)
    if self._RegFubenDict[fubenType] then
        local agency = XMVCA:GetAgency(self._RegFubenDict[fubenType])
        local func = agency[funcKey]
        if func then
            return true, func(agency, ...)
        end
    end
    return false, nil
end

---获取返回给C#层通过Handler封装的函数
---@param fubenType number 副本类型
---@param funcKey string 函数key
---@return function
function XFubenAgency:GetTempCustomFunc(fubenType, funcKey)
    --已经存在的直接return
    if self._TempCustomFunc[funcKey] and self._TempCustomFunc[funcKey][fubenType] then
        return self._TempCustomFunc[funcKey][fubenType]
    end

    if self._RegFubenDict[fubenType] then
        local agency = XMVCA:GetAgency(self._RegFubenDict[fubenType])
        local func = agency[funcKey]
        if func then
            local handler = Handler(agency, func)
            local tempFuncs = self._TempCustomFunc[funcKey]
            if not tempFuncs then
                tempFuncs = {}
                self._TempCustomFunc[funcKey] = tempFuncs
            end
            tempFuncs[fubenType] = handler
            return handler
        end
    end
    return nil
end

---调用所有子模块的一个自定义函数
---@param funcKey string 函数名
function XFubenAgency:CallAllCustomFunc(funcKey, ...)
    for _, moduleId in pairs(self._RegFubenDict) do
        local agency = XMVCA:GetAgency(moduleId)
        if agency[funcKey] then
            agency[funcKey](agency, ...)
        end
    end
end

function XFubenAgency:GetFightBeginData()
    return self._Model:GetBeginData()
end

function XFubenAgency:GetFubenSettleResult()
    return self._Model:GetFubenSettleResult()
end

---------进入战斗相关接口
--服务器下发的副本数据处理
function XFubenAgency:InitFubenData(fubenData)
    if fubenData then
        if fubenData.StageData then
            for key, value in pairs(fubenData.StageData) do
                self._Model:SetPlayerStageData(key, value)
            end
        end

        if fubenData.UnlockHideStages then
            for _, v in pairs(fubenData.UnlockHideStages) do
                self._Model:SetUnlockHideStages(v)
            end
        end
    end

    self:InitData()
    self._Model:InitStageInfoNextStageId()
end

function XFubenAgency:InitData(checkNewUnlock)
    self._Model:InitStageInfo()

    self:CallAllCustomFunc(ProcessFunc.InitStageInfo, checkNewUnlock)

    -- 发送关卡刷新事件
    XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_REFRESH_STAGE_DATA)
end

-- 联机副本进入战斗
function XFubenAgency:OnEnterFight(fightData)
    -- 进入战斗前关闭所有弹出框
    XLuaUiManager.Remove("UiDialog")

    local role
    for i = 1, #fightData.RoleData do
        if fightData.RoleData[i].Id == XPlayer.Id then
            role = fightData.RoleData[i]
            break
        end
    end

    if not role then
        XLog.Error("XFubenAgency:OnEnterFight函数出错, 联机副本RoleData列表中没有找到自身数据")
        return
    end

    local preFightData = {}
    preFightData.StageId = fightData.StageId
    preFightData.CardIds = {}
    for _, v in pairs(role.NpcData) do
        table.insert(preFightData.CardIds, v.Character.Id)
    end
    self:EnterRealFight(preFightData, fightData)
end

---进入战斗
function XFubenAgency:EnterFightByStageId(stageId, teamId, isAssist, challengeCount, challengeId, callback)
    local stage = self._Model:GetStageCfg(stageId)
    if not stage then
        return
    end
    self:EnterFight(stage, teamId, isAssist, challengeCount, challengeId, callback)
end

---进入战斗
function XFubenAgency:EnterFight(stage, teamId, isAssist, challengeCount, challengeId, callback)
    local enter = function()
        self:DoEnterFight(stage, teamId, isAssist, challengeCount, challengeId, callback)
    end
    -- v1.29 协同作战联机中不给跳转，防止跳出联机房间
    if XDataCenter.RoomManager.RoomData then
        -- 如果在房间中，需要先弹确认框
        local title = CsXTextManagerGetText("TipTitle")
        local cancelMatchMsg
        local stageId = XDataCenter.RoomManager.RoomData.StageId
        local stageType = self:GetStageType(stageId)
        if stageType == StageType.ArenaOnline then
            cancelMatchMsg = CsXTextManagerGetText("ArenaOnlineInstanceQuitRoom")
        else
            cancelMatchMsg = CsXTextManagerGetText("OnlineInstanceQuitRoom")
        end

        XUiManager.DialogTip(
                title,
                cancelMatchMsg,
                XUiManager.DialogType.Normal,
                nil,
                function()
                    XDataCenter.RoomManager.Quit(enter)
                end
        )
    else
        enter()
    end
end

---检测是否能进入战斗
---@param conditionIds number[] 条件id列表
---@param teamData any 组队数据
---@param showTip boolean 是否提示错误
---@return boolean
function XFubenAgency:CheckFightConditionByTeamData(conditionIds, teamData, showTip)
    if showTip == nil then showTip = true end
    if #conditionIds <= 0 then
        return true
    end

    for _, id in pairs(conditionIds) do
        local ret, desc = XConditionManager.CheckCondition(id, teamData)
        if not ret then
            if showTip then
                XUiManager.TipError(desc)
            end
            return false
        end
    end
    return true
end

---@return XTableStage
function XFubenAgency:GetStageCfg(stageId)
    local config = self._Model:GetStageCfg(stageId)
    return config
end

function XFubenAgency:GetStageInfo(stageId)
    local stageInfo = self._Model:GetStageInfo(stageId)
    return stageInfo
end

----------基础信息接口

function XFubenAgency:GetStageTypeRobot(stageType)
    local config = self._Model:GetStageTypeCfg(stageType)
    return (config or {}).RobotId
end

function XFubenAgency:IsAllowRepeatChar(stageType)
    local config = self._Model:GetStageTypeCfg(stageType)
    return (config or {}).MatchCharIdRepeat
end

---返回stage对应的类型
function XFubenAgency:GetStageType(stageId)
    local config = self._Model:GetStageCfg(stageId)
    if config and XTool.IsNumberValid(config.Type) then --增加多一列, 优先读取配置的
        return config.Type
    end
    local stageInfo = self._Model:GetStageInfo(stageId)
    if stageInfo then
        return stageInfo.Type
    end
end

function XFubenAgency:GetStageName(stageId)
    local config = self._Model:GetStageCfg(stageId)
    return config.Name
end

function XFubenAgency:GetStageIcon(stageId)
    local config = self._Model:GetStageCfg(stageId)
    return config.Icon
end

function XFubenAgency:GetStageDes(stageId)
    local config = self._Model:GetStageCfg(stageId)
    return config.Description
end

function XFubenAgency:ResetSettle()
    self._Model:SetFubenSettling(false)
    self._Model:SetFubenSettleResult(nil)
end

function XFubenAgency:IsStageCute(stageId)
    local stageType = self:GetStageType(stageId)
    if stageType == XEnumConst.FuBen.StageType.TaikoMaster
            or stageType == XEnumConst.FuBen.StageType.MoeWarParkour
            or stageType == XEnumConst.FuBen.StageType.Maze
    then
        return true
    end
    return XFubenSpecialTrainConfig.CheckIsSpecialTrainBreakthroughStage(stageId)
            or XFubenSpecialTrainConfig.CheckIsYuanXiaoStage(stageId)
            or XFubenSpecialTrainConfig.CheckIsSnowGameStage(stageId)
end

----------public end----------

----------private start----------
function XFubenAgency:InitStageData()

end

---按键冲突检测
function XFubenAgency:CheckCustomUiConflict()
    if self._NeedCheckUiConflict then
        CS.XCustomUi.Instance:GetData()
        self._NeedCheckUiConflict = false
    end
    if CS.XRLFightSettings.UiConflict then
        self._NeedCheckUiConflict = true
        -- 在新手引导时不提示冲突
        if XDataCenter.GuideManager.CheckIsInGuide() then return end
        local title = CSTextManagerGetText("TipTitle")
        local content = CSTextManagerGetText("FightUiCustomConflict")
        local extraData = { sureText = CSTextManagerGetText("TaskStateSkip") }
        local sureCallback = function()
            XLuaUiManager.Open("UiFightCustom", CS.XFight.Instance)
        end
        XUiManager.DialogTip(title, content, XUiManager.DialogType.OnlySure, nil, sureCallback, extraData)
        return true
    end
    return false
end

function XFubenAgency:CheckStageIsUnlock(stageId)
    local stageInfo = self._Model:GetStageInfo(stageId)
    if not stageInfo then
        return false
    end

    local stageType = self:GetStageType(stageId)
    local ok, result = self:CallCustomFunc(stageType, ProcessFunc.CheckUnlockByStageId, stageId)
    if ok then
        return result
    end
    return stageInfo.Unlock or false
end

function XFubenAgency:CheckStageOpen(stageId)
    local stageInfo = self._Model:GetStageInfo(stageId)
    if stageInfo then
        return stageInfo.IsOpen
    else
        return false
    end
end

function XFubenAgency:CheckStageIsPass(stageId)
    local stageInfo = self._Model:GetStageInfo(stageId)
    if not stageInfo then
        return false
    end
    local stageType = self:GetStageType(stageId)
    if stageType == StageType.Bfrt then
        return XDataCenter.BfrtManager.IsGroupPassedByStageId(stageId)
    elseif stageType == StageType.Assign then
        return XDataCenter.FubenAssignManager.IsStagePass(stageId)
    elseif stageType == StageType.TRPG then
        return XDataCenter.TRPGManager.IsStagePass(stageId)
    elseif stageType == StageType.Pokemon then
        return XDataCenter.PokemonManager.CheckStageIsPassed(stageId)
    elseif stageType == StageType.Maverick2 then
        return XDataCenter.Maverick2Manager.IsStagePassed(stageId)
    else
        local ok, result = self:CallCustomFunc(stageType, ProcessFunc.CheckPassedByStageId, stageId)
        if ok then
            return result
        end
    end
    return stageInfo.Passed
end

function XFubenAgency:CheckIsStageAllowRepeatChar(stageId)
    local stageInfo = self._Model:GetStageInfo(stageId)
    if not stageInfo then
        return false
    end
    local stageType = self:GetStageType(stageId)
    return XFubenConfigs.IsAllowRepeatChar(stageType)
end

function XFubenAgency:GetStageLevelControl(stageId, playerLevel)
    playerLevel = playerLevel or XPlayer.Level
    local levelList = self._Model:GetStageLevelMap()[stageId]
    if levelList == nil or #levelList == 0 then
        return nil
    end
    for i = 1, #levelList do
        if playerLevel <= levelList[i].MaxLevel then
            return levelList[i]
        end
    end
    return levelList[#levelList]
end

---建议等级
function XFubenAgency:GetStageProposedLevel(stageId, level)
    local levelList = self._Model:GetStageLevelMap()[stageId]
    if levelList == nil or #levelList == 0 then
        return 1
    end
    for i = 1, #levelList do
        if level <= levelList[i].MaxLevel then
            return levelList[i].RecommendationLevel or 1
        end
    end
    return levelList[#levelList].RecommendationLevel or 1
end

function XFubenAgency:GetStageMultiplayerLevelControl(stageId, difficulty)
    local stageMultiplayerLevelMap = self._Model:GetStageMultiplayerLevelMap()
    return stageMultiplayerLevelMap[stageId] and stageMultiplayerLevelMap[stageId][difficulty]
end

function XFubenAgency:CheckMultiplayerLevelControl(stageId)
    local stageMultiplayerLevelMap = self._Model:GetStageMultiplayerLevelMap()
    return stageMultiplayerLevelMap[stageId]
end


function XFubenAgency:GetFubenTitle(stageId)
    local stageInfo = self._Model:GetStageInfo(stageId)
    local stageCfg = self._Model:GetStageCfg(stageId)
    local stageType = self:GetStageType(stageId)
    local res
    if stageInfo and stageType == StageType.Mainline then
        local diffMsg = ""
        local chapterCfg = XDataCenter.FubenMainLineManager.GetChapterCfg(stageInfo.ChapterId)
        if stageInfo.Difficult == self._Model:GetDifficultNormal() then
            diffMsg = CSTextManagerGetText("FubenDifficultyNormal", chapterCfg.OrderId, stageCfg.OrderId)
        elseif stageInfo.Difficult == self._Model:GetDifficultHard() then
            diffMsg = CSTextManagerGetText("FubenDifficultyHard", chapterCfg.OrderId, stageCfg.OrderId)
        end
        res = diffMsg
    elseif stageInfo and stageType == StageType.ExtraChapter then
        local diffMsg = ""
        local chapterCfg = XDataCenter.ExtraChapterManager.GetChapterDetailsCfg(stageInfo.ChapterId)
        if stageInfo.Difficult == self._Model:GetDifficultNormal() then
            diffMsg = CSTextManagerGetText("FubenDifficultyNormal", chapterCfg.StageTitle, stageCfg.OrderId)
        elseif stageInfo.Difficult == self._Model:GetDifficultHard() then
            diffMsg = CSTextManagerGetText("FubenDifficultyHard", chapterCfg.StageTitle, stageCfg.OrderId)
        end
        res = diffMsg
    elseif stageInfo and stageType == StageType.ShortStory then
        local diffMsg = ""
        local stageTitle = XFubenShortStoryChapterConfigs.GetStageTitleByChapterId(stageInfo.ChapterId)
        if stageInfo.Difficult == self._Model:GetDifficultNormal() then
            diffMsg = CSTextManagerGetText("FubenDifficultyNormal", stageTitle, stageCfg.OrderId)
        elseif stageInfo.Difficult == self._Model:GetDifficultHard() then
            diffMsg = CSTextManagerGetText("FubenDifficultyHard", stageTitle, stageCfg.OrderId)
        end
        res = diffMsg
    elseif stageInfo and stageType == StageType.Bfrt then
        local chapterCfg = XDataCenter.FubenMainLineManager.GetChapterCfg(stageInfo.ChapterId)
        res = CSTextManagerGetText("FubenDifficultyNightmare", chapterCfg.OrderId, stageCfg.OrderId)
    else
        res = stageCfg.Name
    end
    return res
end

function XFubenAgency:GetFubenNames(stageId)
    local stage = self._Model:GetStageCfg(stageId)
    local stageInfo = self._Model:GetStageInfo(stageId)
    local chapterName, stageName
    local curStageType = self:GetStageType(stageId)

    if curStageType == StageType.Mainline then
        local tmpStage = self._Model:GetStageCfg(stageId)
        local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfo(stageInfo.ChapterId)
        local chapterMain = XDataCenter.FubenMainLineManager.GetChapterMainTemplate(chapterInfo.ChapterMainId)
        chapterName = chapterMain.ChapterName
        stageName = tmpStage.Name
    elseif curStageType == StageType.Urgent then
        chapterName = ""
        stageName = stage.Name
    elseif curStageType == StageType.Daily then
        local tmpStageInfo = self._Model:GetStageCfg(stageId)
        chapterName = tmpStageInfo.stageDataName
        stageName = stage.Name
    elseif curStageType == StageType.BossSingle then
        chapterName, stageName = XDataCenter.FubenBossSingleManager.GetBossNameInfo(stageInfo.BossSectionId, stageId)
    elseif curStageType == StageType.Arena then
        local areaStageInfo = XDataCenter.ArenaManager.GetEnterAreaStageInfo()
        chapterName = areaStageInfo.ChapterName
        stageName = areaStageInfo.StageName
    elseif curStageType == StageType.ArenaOnline then
        stageName = stage.Name
        local arenaOnlineCfg = XDataCenter.ArenaOnlineManager.GetCurChapterCfg()
        chapterName = arenaOnlineCfg and arenaOnlineCfg.Name or ""
    elseif curStageType == StageType.ExtraChapter then
        local tmpStage = self._Model:GetStageCfg(stageId)
        local chapterId = XDataCenter.ExtraChapterManager.GetChapterByChapterDetailsId(stageInfo.ChapterId)
        local chapterDetail = XDataCenter.ExtraChapterManager.GetChapterCfg(chapterId)
        chapterName = chapterDetail.ChapterName
        stageName = tmpStage.Name
    elseif curStageType == StageType.ShortStory then
        local tmpStage = self._Model:GetStageCfg(stageId)
        local chapterId = XFubenShortStoryChapterConfigs.GetChapterMainIdByChapterId(stageInfo.ChapterId)
        chapterName = XFubenShortStoryChapterConfigs.GetChapterNameById(chapterId)
        stageName = tmpStage.Name
    elseif curStageType == StageType.WorldBoss then
        chapterName = stage.ChapterName
        stageName = stage.Name
    elseif curStageType == StageType.TRPG then
        chapterName = stage.ChapterName
        stageName = stage.Name
    elseif curStageType == StageType.Stronghold then
        chapterName = stage.ChapterName
        stageName = stage.Name
    elseif curStageType == StageType.KillZone then
        chapterName = ""
        stageName = XKillZoneConfigs.GetStageName(stageId)
    elseif curStageType == StageType.MemorySave then
        chapterName = stage.ChapterName
        stageName = stage.Name
    elseif curStageType == StageType.PivotCombat then
        chapterName = stage.ChapterName
        stageName = stage.Name
    elseif curStageType == StageType.TaikoMaster then
        chapterName = stage.ChapterName
        stageName = stage.Name
    end

    return chapterName, stageName
end

function XFubenAgency:GetDifficultIcon(stageId)
    local stageInfo = self._Model:GetStageInfo(stageId)
    local stageType = self:GetStageType(stageId)
    if stageInfo then
        if stageType == StageType.Mainline then
            if stageInfo.Difficult == self._Model:GetDifficultNormal() then
                return CS.XGame.ClientConfig:GetString("StageNormalIcon")
            elseif stageInfo.Difficult == self._Model:GetDifficultHard() then
                return CS.XGame.ClientConfig:GetString("StageHardIcon")
            end
        elseif stageType == StageType.Bfrt then
            return CS.XGame.ClientConfig:GetString("StageFortress")
        elseif stageType == StageType.Resource then
            return CS.XGame.ClientConfig:GetString("StageResourceIcon")
        elseif stageType == StageType.Daily then
            return CS.XGame.ClientConfig:GetString("StageDailyIcon")
        end
    end
    return CS.XGame.ClientConfig:GetString("StageNormalIcon")
end

function XFubenAgency:GetFubenOpenTips(stageId, default)
    local curStageCfg = self._Model:GetStageCfg(stageId)

    local preStageIds = curStageCfg.PreStageId
    if #preStageIds > 0 then
        for _, preStageId in pairs(preStageIds) do
            local stageInfo = self._Model:GetStageInfo(preStageId)
            local stageType = self:GetStageType(stageId)
            if not stageInfo.Passed then
                if stageType == StageType.Mainline then
                    local title = self:GetFubenTitle(preStageId)
                    return CSTextManagerGetText("FubenPreMainLineStage", title)
                elseif stageType == StageType.ExtraChapter then
                    local title = self:GetFubenTitle(preStageId)
                    return CSTextManagerGetText("FubenPreExtraChapterStage", title)
                elseif stageType == StageType.ShortStory then
                    local title = self:GetFubenTitle(preStageId)
                    return CSTextManagerGetText("FubenPreShortStoryChapterStage", title)
                elseif stageType == StageType.ZhouMu then
                    local title = self:GetFubenTitle(preStageId)
                    return CSTextManagerGetText("AssignStageUnlock", title)
                elseif stageType == StageType.NieR then
                    local title = self:GetFubenTitle(preStageId)
                    return CSTextManagerGetText("NieRStageUnLockByPer", title)
                end
            end
        end
    end

    if XDataCenter.BfrtManager.CheckStageTypeIsBfrt(stageId) then
        local groupId = XDataCenter.BfrtManager.GetGroupIdByBaseStage(stageId)
        local preGroupUnlock, preGroupId = XDataCenter.BfrtManager.CheckPreGroupUnlock(groupId)
        if not preGroupUnlock then
            local preStageId = XDataCenter.BfrtManager.GetBaseStage(preGroupId)
            local title = self:GetFubenTitle(preStageId)
            return CSTextManagerGetText("FubenPreStage", title)
        end
    end

    if XPlayer.Level < curStageCfg.RequireLevel then
        return CSTextManagerGetText("FubenNeedLevel", curStageCfg.RequireLevel)
    end

    if default then
        return default
    end
    return CSTextManagerGetText("NotUnlock")
end

---------------战斗流程-----------------

-- 获取体力值 新增首通体力值和非首通体力值
function XFubenAgency:GetRequireActionPoint(stageId)
    local stageCfg = self._Model:GetStageCfg(stageId)
    -- 体力消耗
    local actionPoint = stageCfg.RequireActionPoint or 0

    -- 当原字段为0时 返回新增字段数据
    if actionPoint == 0 then
        local stageInfo = self._Model:GetStageInfo(stageId)
        actionPoint = not stageInfo.Passed and stageCfg.FirstRequireActionPoint or stageCfg.FinishRequireActionPoint
    end

    return actionPoint or 0
end

--进入副本前的条件检测
function XFubenAgency:CheckPreFightBase(stage, challengeCount)
    challengeCount = challengeCount or 1

    -- 检测前置副本
    local stageId = stage.StageId

    if not self:CheckStageIsUnlock(stageId) then
        XUiManager.TipMsg(self:GetFubenOpenTips(stageId))
        return false
    end

    -- 翻牌额外体力

    local flopRewardConfig = self._Model:GetFlopRewardTemplates()

    local flopRewardId = stage.FlopRewardId
    local flopRewardTemplate = flopRewardConfig[flopRewardId]
    local actionPoint = self:GetRequireActionPoint(stageId)
    if flopRewardTemplate and XDataCenter.ItemManager.CheckItemCountById(flopRewardTemplate.ConsumeItemId, flopRewardTemplate.ConsumeItemCount) then
        if flopRewardTemplate.ExtraActionPoint > 0 then
            local cost = challengeCount * (actionPoint + flopRewardTemplate.ExtraActionPoint)
            if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(XDataCenter.ItemManager.ItemId.ActionPoint,
                    cost,
                    1,
                    function() self:CheckPreFightBase(stage) end,
                    "FubenActionPointNotEnough") then
                return false
            end
        end
    end

    -- 检测体力
    if actionPoint > 0 then
        local cost = challengeCount * actionPoint
        if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(XDataCenter.ItemManager.ItemId.ActionPoint,
                cost,
                1,
                function() self:CheckPreFightBase(stage) end,
                "FubenActionPointNotEnough") then
            return false
        end
    end

    return true
end

function XFubenAgency:CheckPreFight(stage, challengeCount, autoFight)
    -- 当自动作战时，无需检测自定义按键冲突
    if not autoFight and self:CheckCustomUiConflict() then return end
    challengeCount = challengeCount or 1
    if not self:CheckPreFightBase(stage, challengeCount) then
        return false
    end

    local stageId = stage.StageId
    local stageType = self:GetStageType(stageId)

    local ok, result = self:CallCustomFunc(stageType, ProcessFunc.CheckPreFight, stage, challengeCount)
    if ok then
        return result
    end
    return true
end

-- 在进入战斗前，构建PreFightData请求XFightData
function XFubenAgency:PreFight(stage, teamId, isAssist, challengeCount, challengeId)
    local preFight = {}
    preFight.CardIds = {}
    preFight.StageId = stage.StageId
    preFight.IsHasAssist = isAssist and true or false
    preFight.ChallengeCount = challengeCount or 1
    local isArenaOnline = XDataCenter.ArenaOnlineManager.CheckStageIsArenaOnline(stage.StageId)
    local isSimulatedCombat = XDataCenter.FubenSimulatedCombatManager.CheckStageIsSimulatedCombat(stage.StageId)
    local stageType = self:GetStageType(stage.StageId)
    -- 如果有试玩角色且没有隐藏模式，则不读取玩家队伍信息
    if not stage.RobotId or #stage.RobotId <= 0 then
        local teamData = XDataCenter.TeamManager.GetTeamData(teamId)
        for _, v in pairs(teamData) do
            table.insert(preFight.CardIds, v)
        end
        preFight.CaptainPos = XDataCenter.TeamManager.GetTeamCaptainPos(teamId)
        preFight.FirstFightPos = XDataCenter.TeamManager.GetTeamFirstFightPos(teamId)
    end
    if isArenaOnline then
        preFight.StageLevel = XDataCenter.ArenaOnlineManager.GetSingleModeDifficulty(challengeId, true)
    end
    if isSimulatedCombat then
        preFight.RobotIds = {}
        for i, v in ipairs(preFight.CardIds) do
            local data = XDataCenter.FubenSimulatedCombatManager.GetCurStageMemberDataByCharId(v)
            if data then
                preFight.RobotIds[i] = data.RobotId
            else
                preFight.RobotIds[i] = 0
            end
        end
        preFight.CardIds = nil
    end

    return preFight
end


function XFubenAgency:DoEnterFight(stage, teamId, isAssist, challengeCount, challengeId, callback)
    if not self:CheckPreFight(stage, challengeCount) then
        return
    end
    --检测是否赏金前置战斗
    local isBountyTaskFight, task = XDataCenter.BountyTaskManager.CheckBountyTaskPreFightWithStatus(stage.StageId)
    if isBountyTaskFight then
        XDataCenter.BountyTaskManager.RecordPreFightData(task.Id, teamId)
    end
    local stageType = self:GetStageType(stage.StageId)
    local preFight

    local ok, result = self:CallCustomFunc(stageType, ProcessFunc.PreFight, stage, teamId, isAssist, challengeCount, challengeId)
    if ok then
        preFight = result
    else
        preFight = self:PreFight(stage, teamId, isAssist, challengeCount, challengeId)
    end

    if not self:CallCustomFunc(stageType, ProcessFunc.CustomOnEnterFight, preFight, callback) then
        XNetwork.Call(METHOD_NAME.PreFight, { PreFightData = preFight }, function(res)
            if callback then callback(res) end
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local fightData = res.FightData
            local stageInfo = self._Model:GetStageInfo(fightData.StageId)
            local isKeepPlayingStory = stage and XFubenConfigs.IsKeepPlayingStory(stage.StageId) and (stage.BeginStoryId)
            local isNotPass = stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed)
            if isKeepPlayingStory or isNotPass then
                -- 播放剧情，进入战斗
                self:EnterRealFight(preFight, fightData, stage.BeginStoryId)
            else
                -- 直接进入战斗
                self:EnterRealFight(preFight, fightData)
            end
        end)
    end
end

function XFubenAgency:GetCurrentStageId()
    local beginData = self._Model:GetBeginData()
    if beginData and beginData.StageId then
        return beginData.StageId
    end
end

function XFubenAgency:GetCurrentStageType()
    local beginData = self._Model:GetBeginData()
    if beginData and beginData.StageId then
        local stageInfo = self._Model:GetStageInfo(beginData.StageId)
        if stageInfo then
            return stageInfo.Type
        end
    end
end

function XFubenAgency:RecordFightBeginData(stageId, charList, isHasAssist, assistPlayerData, challengeCount, roleData)
    local beginData = {
        CharExp = {},
        RoleExp = 0,
        RoleCoins = 0,
        LastPassed = false,
        AssistPlayerData = nil,
        IsHasAssist = false,
        CharList = charList,
        StageId = stageId,
        ChallengeCount = challengeCount, -- 记录挑战次数
        RoleData = roleData
    }
    self._Model:SetBeginData(beginData)

    if not self:IsStageCute(stageId) then
        for _, charId in pairs(charList) do
            local isRobot = XRobotManager.CheckIsRobotId(charId)
            local char = isRobot and XRobotManager.GetRobotTemplate(charId) or XDataCenter.CharacterManager.GetCharacter(charId)
            if char ~= nil then
                if isRobot then
                    table.insert(beginData.CharExp, { Id = charId, Quality = char.CharacterQuality, Exp = 0, Level = char.CharacterLevel })
                else
                    table.insert(beginData.CharExp, { Id = charId, Quality = char.Quality, Exp = char.Exp, Level = char.Level })
                end
            end
        end
    end

    beginData.RoleLevel = XPlayer.GetLevelOrHonorLevel()
    beginData.RoleExp = XPlayer.Exp
    beginData.RoleCoins = XDataCenter.ItemManager.GetCoinsNum()
    local stageInfo = self._Model:GetStageInfo(stageId)
    local stageType = self:GetStageType(stageId)
    beginData.LastPassed = stageInfo.Passed
    beginData.AssistPlayerData = assistPlayerData
    beginData.IsHasAssist = isHasAssist

    -- 联机相关
    local roomData = XDataCenter.RoomManager.RoomData
    if roomData then
        beginData.PlayerList = {}
        for _, v in pairs(roomData.PlayerDataList) do
            local playerData = {
                Id = v.Id,
                Name = v.Name,
                Character = v.FightNpcData.Character,
                CharacterId = v.FightNpcData.Character.Id,
                MedalId = v.MedalId,
                HeadPortraitId = v.HeadPortraitId,
                HeadFrameId = v.HeadFrameId,
                RankScore = v.RankScore
            }
            if stageType == StageType.ArenaOnline then
                playerData.StageType = StageType.ArenaOnline
                playerData.IsFirstPass = v.IsFirstPass
            end
            beginData.PlayerList[v.Id] = playerData
        end
    end
    self:CallCustomFunc(stageType, ProcessFunc.CustomRecordFightBeginData, stageId)
end

function XFubenAgency:CtorFightArgs(stageId, roleData)
    local stageCfg = self._Model:GetStageCfg(stageId)
    local stageType = self:GetStageType(stageId)
    local args = CS.XFightClientArgs()

    args.IsReconnect = false
    args.RoleId = XPlayer.Id
    args.FinishCb = self:GetTempCustomFunc(stageType, ProcessFunc.CallFinishFight) or self.CallFinishFightHandler

    args.ProcessCb = XDataCenter.RoomManager.RoomData and function(progress)
        XDataCenter.RoomManager.UpdateLoadProcess(progress)
    end or nil

    local roleNum = 0
    args.CloseLoadingCb = function()

        self:CallCloseFightLoading(stageId)
        local loadingTime = CS.UnityEngine.Time.time - self._Model:GetEnterFightStartTime()
        local roleIdStr = ""
        if roleData[1] then
            for i = 0, #roleData[1].NpcData do
                if roleData[1].NpcData[i] then
                    roleIdStr = roleIdStr .. roleData[1].NpcData[i].Character.Id .. ","
                    roleNum = roleNum + 1
                end
            end
        end
        local msgtab = {}
        msgtab.stageId = stageId
        msgtab.loadingTime = loadingTime
        msgtab.roleIdStr = roleIdStr
        msgtab.roleNum = roleNum
        CS.XRecord.Record(msgtab, "24034", "BdcEnterFightLoadingTime")
        CS.XHeroBdcAgent.BdcEnterFightLoadingTime(stageId, loadingTime, roleIdStr)
    end
    local list = CS.System.Collections.Generic.List(CS.System.String)()
    for _, v in pairs(stageCfg.StarDesc) do
        list:Add(v)
    end
    args.StarTips = list

    if self:HasCustomFunc(stageType, ProcessFunc.ShowSummary) then
        local summaryHander = self:GetTempCustomFunc(stageType, ProcessFunc.ShowSummary)
        args.ShowSummaryCb = function()
            summaryHander(stageId)
        end
    end

    local ok, result = self:CallCustomFunc(stageType, ProcessFunc.CheckAutoExitFight)
    if ok then
        args.AutoExitFight = result
    end

    local settleHandler = self:GetTempCustomFunc(stageType, ProcessFunc.SettleFight)
    if settleHandler then
        args.SettleCb = settleHandler
    else
        args.SettleCb = self.SettleFightHandler
    end

    local ok, result = self:CallCustomFunc(stageType, ProcessFunc.CheckReadyToFight)
    if ok then
        args.IsReadyToFight = result
    end

    return args
end

--进入战斗
function XFubenAgency:DoEnterRealFight(preFightData, fightData)
    local assistInfo
    if preFightData.IsHasAssist then
        for i = 1, #fightData.RoleData do
            local role = fightData.RoleData[i]
            if role.Id == XPlayer.Id then
                assistInfo = role.AssistNpcData
                break
            end
        end
    end

    local roleData = {}
    for i = 1, #fightData.RoleData do
        local role = fightData.RoleData[i]
        roleData[i] = role.Id
    end

    local charList = {}
    local charDic = {} --已在charList中的Robot对应的CharId
    for _, cardId in ipairs(preFightData.RobotIds or {}) do
        table.insert(charList, cardId)

        local charId = XRobotManager.GetCharacterId(cardId)
        charDic[charId] = true
    end
    for _, cardId in ipairs(preFightData.CardIds or {}) do
        if not charDic[cardId] then
            table.insert(charList, cardId)
        end
    end

    self:RecordFightBeginData(fightData.StageId, charList, preFightData.IsHasAssist, assistInfo, preFightData.ChallengeCount, roleData)

    -- 提示加锁
    XTipManager.Suspend()

    -- 功能开启&新手加锁
    XDataCenter.FunctionEventManager.LockFunctionEvent()

    self._Model:SetFubenSettleResult(nil)

    local args = self:CtorFightArgs(fightData.StageId, fightData.RoleData)
    --args.ChallengeCount = preFightData.ChallengeCount or 0 --向XFight传入连战次数 方便作弊实现功能
    XEventManager.DispatchEvent(XEventId.EVENT_PRE_ENTER_FIGHT)

    CS.XFight.Enter(fightData, args)
    self._Model:SetEnterFightStartTime(CS.UnityEngine.Time.time)
    XEventManager.DispatchEvent(XEventId.EVENT_ENTER_FIGHT)
end

--异步进入战斗
function XFubenAgency:EnterRealFight(preFightData, fightData, movieId, endCb)
    if self:CheckCustomUiConflict() then return end

    local asynPlayMovie = movieId and asynTask(XDataCenter.MovieManager.PlayMovie) or nil

    RunAsyn(function()
        --战前剧情
        if movieId then
            XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE)

            --UI栈从战斗结束的逻辑还原，无需从剧情系统还原UI栈
            CsXUiManager.Instance:SetRevertAllLock(true)

            asynPlayMovie(movieId)

            --剧情已经释放了UI栈，无需从战斗释放UI栈
            CsXUiManager.Instance:SetReleaseAllLock(true)
        end

        --剧情过程中强制下线
        if not XLoginManager.IsLogin() then
            return
        end

        if endCb then
            endCb()
        end

        --打开Loading图
        self:CallOpenFightLoading(preFightData.StageId)

        --等待0.5秒，第一时间先把load图加载进来，然后再加载战斗资源
        asynWaitSecond(0.5)

        CsXBehaviorManager.Instance:Clear()
        XTableManager.ReleaseAll(true)
        CS.BinaryManager.OnPreloadFight(true)
        collectgarbage("collect")

        CS.XUiSceneManager.Clear() -- ui场景提前释放，不等ui销毁
        CsXUiManager.Instance:ReleaseAll(CsXUiType.Normal)

        CsXUiManager.Instance:SetRevertAndReleaseLock(false)

        --进入战斗
        self:DoEnterRealFight(preFightData, fightData)
    end)

end

--战斗结算统计
function XFubenAgency:StatisticsFightResultDps(result)
    -- 初始化Dps数据
    local dpsTable = {}

    --Dps数据
    if result.Data.NpcDpsTable and result.Data.NpcDpsTable.Count > 0 then
        local damageTotalMvp = -1
        local hurtMvp = -1
        local cureMvp = -1
        local breakEndureMvp = -1

        local damageTotalMvpValue = -1
        local hurtMvpValue = -1
        local cureMvpValue = -1
        local breakEndureValue = -1

        XTool.LoopMap(result.Data.NpcDpsTable, function(_, v)
            dpsTable[v.RoleId] = {}
            dpsTable[v.RoleId].DamageTotal = v.DamageTotal
            dpsTable[v.RoleId].Hurt = v.Hurt
            dpsTable[v.RoleId].Cure = v.Cure
            dpsTable[v.RoleId].BreakEndure = v.BreakEndure
            dpsTable[v.RoleId].RoleId = v.RoleId

            if damageTotalMvpValue == -1 or v.DamageTotal > damageTotalMvpValue then
                damageTotalMvpValue = v.DamageTotal
                damageTotalMvp = v.RoleId
            end

            if cureMvpValue == -1 or v.Cure > cureMvpValue then
                cureMvpValue = v.Cure
                cureMvp = v.RoleId
            end

            if hurtMvpValue == -1 or v.Hurt > hurtMvpValue then
                hurtMvpValue = v.Hurt
                hurtMvp = v.RoleId
            end

            if breakEndureValue == -1 or v.BreakEndure > breakEndureValue then
                breakEndureValue = v.BreakEndure
                breakEndureMvp = v.RoleId
            end
        end)

        if damageTotalMvp ~= -1 and dpsTable[damageTotalMvp] then
            dpsTable[damageTotalMvp].IsDamageTotalMvp = true
        end

        if cureMvp ~= -1 and dpsTable[cureMvp] then
            dpsTable[cureMvp].IsCureMvp = true
        end

        if hurtMvp ~= -1 and dpsTable[hurtMvp] then
            dpsTable[hurtMvp].IsHurtMvp = true
        end

        if breakEndureMvp ~= -1 and dpsTable[breakEndureMvp] then
            dpsTable[breakEndureMvp].IsBreakEndureMvp = true
        end
        self._Model:SetLastDpsTable(dpsTable)
    end
end

--结束战斗(包含手动结束和战斗结束)
function XFubenAgency:CallFinishFight()
    local res = self._Model:GetFubenSettleResult()
    self:ResetSettle()

    --通知战斗结束，关闭战斗设置页面
    CS.XGameEventManager.Instance:Notify(XEventId.EVENT_FIGHT_FINISH)
    -- 恢复回系统音声设置 避免战斗里将BGM音量设置为0导致结算后没有声音
    XSoundManager.ResetSystemAudioVolume()

    if not res then
        -- 强退
        self:ChallengeLose()
        return
    end

    if res.Code ~= XCode.Success then
        XUiManager.TipCode(res.Code)
        self:ChallengeLose()
        CS.XGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_SETTLE_FAIL, res.Code)
        return
    end

    local stageId = res.Settle.StageId

    local stageType = self:GetStageType(stageId)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_FIGHT_RESULT, res.Settle)

    XSoundManager.StopCurrentBGM()
    if not self:CallCustomFunc(stageType, ProcessFunc.FinishFight, res.Settle) then
        self:FinishFight(res.Settle)
    end
end

--结束战斗(正常结束)
function XFubenAgency:FinishFight(settle)
    if settle.IsWin then
        self:ChallengeWin(settle)
    else
        self:ChallengeLose(settle)
    end
end

function XFubenAgency:ChallengeWin(settleData)
    -- 据点战关卡处理
    local stageType = self:GetStageType(settleData.StageId)
    if stageType == StageType.Bfrt then
        XDataCenter.BfrtManager.FinishStage(settleData.StageId)
    end

    local beginData = self._Model:GetBeginData()

    local winData = self:GetChallengeWinData(beginData, settleData)
    local stage = self._Model:GetStageCfg(settleData.StageId)
    local isKeepPlayingStory = stage and XFubenConfigs.IsKeepPlayingStory(stage.StageId) and (stage.EndStoryId)
    local isNotPass = stage and stage.EndStoryId and not beginData.LastPassed

    if isKeepPlayingStory or isNotPass then
        -- 播放剧情
        CsXUiManager.Instance:SetRevertAndReleaseLock(true)
        XDataCenter.MovieManager.PlayMovie(stage.EndStoryId, function()
            -- 弹出结算
            CsXUiManager.Instance:SetRevertAndReleaseLock(false)
            -- 防止带着bgm离开战斗
            -- XSoundManager.StopAll()
            XSoundManager.StopCurrentBGM()
            self:CallShowReward(winData, true)
        end)
    else
        -- 弹出结算
        self:CallShowReward(winData, false)
    end

    -- XDataCenter.GuideManager.CompleteEvent(XDataCenter.GuideManager.GuideEventType.PassStage, settleData.StageId)
    XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_RESULT_WIN)
end


function XFubenAgency:GetChallengeWinData(beginData, settleData)
    local stageData = self._Model:GetPlayerStageDataById(settleData.StageId)

    local starsMap = {}
    local starsMark = stageData and stageData.StarsMark or settleData.StarsMark
    if starsMark then
        local _, tmpStarsMap = self._Model:GetStarsCount(starsMark)
        starsMap = tmpStarsMap
    end

    return {
        SettleData = settleData,
        StageId = settleData.StageId,
        RewardGoodsList = settleData.RewardGoodsList,
        CharExp = beginData.CharExp,
        RoleExp = beginData.RoleExp,
        RoleLevel = beginData.RoleLevel,
        RoleCoins = beginData.RoleCoins,
        StarsMap = starsMap,
        UrgentId = settleData.UrgentEnventId,
        ClientAssistInfo = self._AssistSuccess and beginData.AssistPlayerData or nil,
        FlopRewardList = settleData.FlopRewardList,
        PlayerList = beginData.PlayerList,
    }
end


function XFubenAgency:CallShowReward(winData, playEndStory)
    if not winData then
        XLog.Warning("XFubenAgency:CallShowReward warning, winData is nil")
        return
    end
    local stageType = self:GetStageType(winData.StageId)
    if not self:CallCustomFunc(stageType, ProcessFunc.ShowReward, winData, playEndStory) then
        self:ShowReward(winData, playEndStory)
    end
end

-- 胜利 & 奖励界面
function XFubenAgency:ShowReward(winData)
    if winData.SettleData.ArenaResult then
        XLuaUiManager.Open("UiArenaFightResult", winData)
        return
    end
    if self:CheckHasFlopReward(winData) then
        XLuaUiManager.Open("UiFubenFlopReward", function()
            XLuaUiManager.PopThenOpen("UiSettleWin", winData)
        end, winData)
    else
        XLuaUiManager.Open("UiSettleWin", winData)
    end
end

function XFubenAgency:CheckHasFlopReward(winData, needMySelf)
    for _, v in pairs(winData.FlopRewardList) do
        if v.PlayerId ~= 0 then
            if not needMySelf or v.PlayerId == XPlayer.Id then
                return true
            end
        end
    end
    return false
end

-- 失败界面
function XFubenAgency:ChallengeLose(settleData)
    XLuaUiManager.Open("UiSettleLose", settleData)
end

-- 请求战斗通用结算
function XFubenAgency:SettleFight(result)
    if self._Model:GetFubenSettling() then
        --有副本正在结算中
        XLog.Warning("XFubenAgency:SettleFight Warning, fuben is settling!")
        return
    end

    self:StatisticsFightResultDps(result)
    self._Model:SetFubenSettling(true) --正在结算
    local fightResBytes = result:GetFightsResultsBytes()

    self._Model:SetCurFightResult(result:GetFightResult())

    if result.FightData.Online then
        if not result.Data.IsForceExit then
            if self._Model:GetFubenSettleResult() then
                XLuaUiManager.SetMask(true)
                self._Model:SetIsWaitingResult(true)
            end
        end
    else
        XNetwork.Call(METHOD_NAME.FightSettle, fightResBytes, function(res)
            --战斗结算清除数据的判断依据
            self._Model:SetFubenSettleResult(res)
            XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SETTLE_REWARD, res.Settle)
        end, true)
    end
end

---结束剧情
function XFubenAgency:FinishStoryRequest(stageId, cb)
    XNetwork.Call("EnterStoryRequest", { StageId = stageId }, function(res)
        cb = cb or function() end
        if res.Code == XCode.Success then
            cb(res)
        else
            XUiManager.TipCode(res.Code)
        end
    end)
end

--打开战斗loading界面
function XFubenAgency:OpenFightLoading(stageId)
    XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_LOADINGFINISHED)

    local stageCfg = self._Model:GetStageCfg(stageId)

    if stageCfg and stageCfg.LoadingType then
        XLuaUiManager.Open("UiLoading", stageCfg.LoadingType)
    else
        XLuaUiManager.Open("UiLoading", LoadingType.Fight)
    end
end

--打开loading界面支持自定义
function XFubenAgency:CallOpenFightLoading(stageId)
    local stageType = self:GetStageType(stageId)
    if not self:CallCustomFunc(stageType, ProcessFunc.OpenFightLoading, stageId) then
        self:OpenFightLoading(stageId)
    end
end

function XFubenAgency:CallCloseFightLoading(stageId)
    local stageType = self:GetStageType(stageId)
    if not self:CallCustomFunc(stageType, ProcessFunc.CloseFightLoading, stageId) then
        self:CloseFightLoading(stageId)
    end
end

function XFubenAgency:CloseFightLoading()
    XLuaUiManager.Remove("UiLoading")
end

function XFubenAgency:ExitFight()
    if self._Model:GetFubenSettleResult() then
        CS.XFight.ExitForClient(false)
        return true
    end
    return false
end

function XFubenAgency:ReadyToFight()
    CS.XFight.ReadyToFight()
end

---------------战斗流程-----------------

---副本界面跳转
function XFubenAgency:GoToFuben(param)
    if param == StageType.Mainline or param == StageType.Daily then
        if param == StageType.Daily then
            if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenChallenge) then
                return
            end
        end
        self:OpenFuben(param)
    else
        self:OpenFubenByStageId(param)
    end
end

function XFubenAgency:OpenFubenByStageId(stageId)
    local stageInfo = self._Model:GetStageInfo(stageId)
    if not stageInfo then
        XLog.ErrorTableDataNotFound("XFubenAgency:OpenFubenByStageId", "stageInfo", "Share/Fuben/Stage.tab", "stageId", tostring(stageId))
        return
    end
    if not stageInfo.Unlock then
        XUiManager.TipMsg(self:GetFubenOpenTips(stageId))
        return
    end

    local stageType = self:GetStageType(stageId)
    if stageType == StageType.Mainline then
        if stageInfo.Difficult == self._Model:GetDifficultHard() and (not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenDifficulty)) then
            local openTips = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.FubenDifficulty)
            XUiManager.TipMsg(openTips)
            return
        end
        local chapter = XDataCenter.FubenMainLineManager.GetChapterCfg(stageInfo.ChapterId)
        if not XDataCenter.FubenMainLineManager.CheckChapterCanGoTo(chapter.ChapterId) then
            XUiManager.TipMsg(CSTextManagerGetText("FubenMainLineNoneOpen"))
            return
        end
        XLuaUiManager.Open("UiFubenMainLineChapter", chapter, stageId)
    elseif stageType == StageType.Bfrt then
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenNightmare) then
            return
        end

        local chapter = XDataCenter.BfrtManager.GetChapterCfg(stageInfo.ChapterId)
        XLuaUiManager.Open("UiFubenMainLineChapter", chapter, stageId)
    elseif stageType == StageType.ActivtityBranch then
        if not XDataCenter.FubenActivityBranchManager.IsOpen() then
            XUiManager.TipText("ActivityBranchNotOpen")
            return
        end

        local sectionId = XDataCenter.FubenActivityBranchManager.GetCurSectionId()
        XLuaUiManager.Open("UiActivityBranch", sectionId)
    elseif stageType == StageType.ActivityBossSingle then
        XDataCenter.FubenActivityBossSingleManager.ExOpenMainUi()
    elseif stageType == StageType.Assign then
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenAssign) then
            XLog.Debug("Assign Stage not open ", stageId)
            return
        end
        XLuaUiManager.Open("UiPanelAssignMain", stageId)
    end
end


function XFubenAgency:OpenFuben(type, stageId)
    if type == StageType.Mainline then
        type = XFubenConfigs.ChapterType.MainLine
    elseif type == StageType.Daily then
        type = XFubenConfigs.ChapterType.Daily
    end
    XLuaUiManager.Open("UiNewFuben", type)
end


---C# Call Lua
---支援信息
function XFubenAgency:GetAssistTemplateInfo()
    local info = {
        IsHasAssist = false
    }

    local beginData = self._Model:GetBeginData()
    if beginData and beginData.IsHasAssist then
        info.IsHasAssist = beginData.IsHasAssist
        if beginData.AssistPlayerData == nil then
            info.FailAssist = CSTextManagerGetText("GetAssistFail")
        end
    end

    if beginData and beginData.AssistPlayerData then
        local template = XAssistConfig.GetAssistRuleTemplate(beginData.AssistPlayerData.RuleTemplateId)
        if template then
            info.Title = template.Title
            if beginData.AssistPlayerData.NpcData and beginData.AssistPlayerData.Id > 0 then
                info.Sign = beginData.AssistPlayerData.Sign
                info.Name = XDataCenter.SocialManager.GetPlayerRemark(beginData.AssistPlayerData.Id, beginData.AssistPlayerData.Name)

                local headPortraitInfo = XPlayerManager.GetHeadPortraitInfoById(beginData.AssistPlayerData.HeadPortraitId)
                if (headPortraitInfo ~= nil) then
                    info.Image = headPortraitInfo.ImgSrc
                end
                local headFrameInfo = XPlayerManager.GetHeadPortraitInfoById(beginData.AssistPlayerData.HeadFrameId)
                if (headFrameInfo ~= nil) then
                    info.HeadFrameImage = headFrameInfo.ImgSrc
                end
                self._AssistSuccess = true
            end
            if info.Sign == "" or info.Sign == nil then
                info.Sign = CSTextManagerGetText("CharacterSignTip")
            end
        end
    end

    return info
end

function XFubenAgency:GetStageOnlineMsgId(stageId)
    local stageCfg = self._Model:GetStageCfg(stageId)
    if not stageCfg then
        return 0
    end
    return stageCfg.OnlineMsgId
end

function XFubenAgency:GetStageForceAllyEffect(stageId)
    local stageCfg = self._Model:GetStageCfg(stageId)
    if not stageCfg then
        return false
    end
    return stageCfg.ForceAllyEffect
end

function XFubenAgency:GetStageResetHpCounts(stageId)
    local stageCfg = self._Model:GetStageCfg(stageId)
    if not stageCfg then
        return {}
    end
    if #stageCfg.ResetHpCount == 1 or #stageCfg.ResetHpCount == 2 then
        XLog.Error("XFubenAgency 修改怪物血条数量数组长度异常！stageId " .. tostring(stageId))
    end
    local resetHpCount = {}
    for i = 1, #stageCfg.ResetHpCount do
        resetHpCount[i] = stageCfg.ResetHpCount[i]
    end
    return resetHpCount
end

function XFubenAgency:GetStageBgmId(stageId)
    local stageCfg = self._Model:GetStageCfg(stageId)
    if not stageCfg then
        return 0
    end
    return stageCfg.BgmId
end

function XFubenAgency:GetStageAmbientSound(stageId)
    local stageCfg = self._Model:GetStageCfg(stageId)
    if not stageCfg then
        return 0
    end
    return stageCfg.AmbientSound
end

function XFubenAgency:CheckSettleFight()
    return self._Model:GetFubenSettleResult() ~= nil
end

----------private end----------

----------协议相关
function XFubenAgency:NotifyStageData(data)
    self:RefreshStageInfo(data.StageList)
end

function XFubenAgency:RefreshStageInfo(stageList)
    local PlayerStageData = self._Model:GetPlayerStageData()
    local StageRelationInfos = self._Model:GetStageRelationInfos()

    local updateStagetypes = {}

    for _, v in pairs(stageList) do
        local stageId = v.StageId
        self._Model:SetPlayerStageData(stageId, v)
        XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_STAGE_SYNC, v.StageId)

        local stageInfo = self._Model:GetStageInfo(stageId)

        stageInfo.Passed = v.Passed
        stageInfo.Stars, stageInfo.StarsMap = self._Model:GetStarsCount(v.StarsMark)
    end

    for _, v in pairs(stageList) do
        local stageId = v.StageId
        local relationStages = StageRelationInfos[stageId]
        local stageInfo = self._Model:GetStageInfo(stageId)
        local stageType = self:GetStageType(stageId)

        if stageInfo and stageType then
            updateStagetypes[stageType] = true
        end

        if relationStages then
            for i = 1, #relationStages do
                local nextStageId = relationStages[i]
                local nextStageInfo = self._Model:GetStageInfo(nextStageId)
                local nextStageCfg = self._Model:GetStageCfg(nextStageId)
                local nextStageType = self:GetStageType(stageId)

                if nextStageInfo and nextStageType then
                    updateStagetypes[nextStageType] = true
                end

                local isUnlock = true
                for _, preStageId in pairs(nextStageCfg.PreStageId or {}) do
                    if preStageId > 0 then
                        if not PlayerStageData[preStageId] or not PlayerStageData[preStageId].Passed then
                            isUnlock = false
                            nextStageInfo.Unlock = false
                            nextStageInfo.IsOpen = false
                            break
                        end
                    end
                end


                local stageCfg = self._Model:GetStageCfg(nextStageId)
                local isLevelLimit = false
                if stageCfg.RequireLevel > 0 and XPlayer.Level < stageCfg.RequireLevel then
                    isLevelLimit = true
                end

                if isUnlock and not isLevelLimit then
                    nextStageInfo.Unlock = true
                    nextStageInfo.IsOpen = true
                end

            end
        end
    end

    for _, v in pairs(updateStagetypes) do
        self:CallCustomFunc(_, ProcessFunc.InitStageInfo, true)
    end

    -- 发送关卡刷新事件
    XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_REFRESH_STAGE_DATA)
end


function XFubenAgency:NotifyOnEnterFight(data)
    -- 进入战斗前关闭所有弹出框
    self:OnEnterFight(data.FightData)
end


function XFubenAgency:OnSyncUnlockHideStage(data)
    if not data then return end
    self._Model:SetUnlockHideStages(data.UnlockHideStage)
    self._Model:SetNewHideStage(data.UnlockHideStage)
end

function XFubenAgency:OnFightSettleNotify(response)
    if self._Model:GetIsWaitingResult() then
        XLuaUiManager.SetMask(false)
    end
    self._Model:SetIsWaitingResult(false)
    self._Model:SetFubenSettleResult(response)
    XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SETTLE_REWARD, response.Settle)
end

function XFubenAgency:OnNotifyRemoveStageData(data)
    self:ResetStagePassedStatus(data.StageIds)
end

function XFubenAgency:ResetStagePassedStatus(stageIds)
    local playerStageData = self._Model:GetPlayerStageData()
    for _, stageId in pairs(stageIds) do
        local stageInfo = self._Model:GetStageInfo(stageId)
        if playerStageData[stageId] then
            playerStageData[stageId].Passed = false
        end
        stageInfo.Passed = false
    end
    for _, stageId in pairs(stageIds) do
        local stageCfg = self._Model:GetStageCfg(stageId)
        local stageInfo = self._Model:GetStageInfo(stageId)
        stageInfo.Unlock = true
        stageInfo.IsOpen = true
        stageInfo.Passed = false
        stageInfo.Stars = 0
        stageInfo.StarsMap = { false, false, false }
        if stageCfg.RequireLevel > 0 and XPlayer.Level < stageCfg.RequireLevel then
            stageInfo.Unlock = false
        end
        for _, preStageId in pairs(stageCfg.PreStageId or {}) do
            if preStageId > 0 then
                if not playerStageData[preStageId] or not playerStageData[preStageId].Passed then
                    stageInfo.Unlock = false
                    stageInfo.IsOpen = false
                    break
                end
            end
        end
    end
end


return XFubenAgency