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
local NotRobotId = 1000000

local XFubenBaseAgency = require("XModule/XBase/XFubenBaseAgency")
local XFubenConfigAgency = require("XModule/XFuben/XFubenConfigAgency")

---@class XFubenAgency : XFubenConfigAgency
---@field private _Model XFubenModel
local XFubenAgency = XClass(XFubenConfigAgency, "XFubenAgency")
function XFubenAgency:OnInit()
    --初始化一些变量
    --注册的副本
    --self._Model._RegFubenDict = {}
    --用来记录有自定义函数的id
    ---@type table<string, table<number, string>>
    self._CustomFuncIds = {}
    --{
    --    [XEnumConst.FuBen.ProcessFunc.InitStageInfo] = {}
    --}
    self:InitCustomFuncIdsTab()
    --用于存储传输给C#层封装的Handler
    --self._TempCustomFunc = {}

    -------
    self._NeedCheckUiConflict = false
    self._AssistSuccess = false
    
    self.SettleFightHandler = function(result)
        return self:SettleFight(result)
    end
    self.CallFinishFightHandler = function()
        return self:CallFinishFight()
    end

    self.ChapterType = XFubenConfigs.ChapterType
    self.NewChallengeInit = false
    self.NewChallengeRedPointTable = {}
    self.DefaultCharacterTypeConvert = {
        [XFubenConfigs.CharacterLimitType.All] = XEnumConst.CHARACTER.CharacterType.Normal,
        [XFubenConfigs.CharacterLimitType.Normal] = XEnumConst.CHARACTER.CharacterType.Normal,
        [XFubenConfigs.CharacterLimitType.Isomer] = XEnumConst.CHARACTER.CharacterType.Isomer,
        [XFubenConfigs.CharacterLimitType.IsomerDebuff] = XEnumConst.CHARACTER.CharacterType.Normal,
        [XFubenConfigs.CharacterLimitType.NormalDebuff] = XEnumConst.CHARACTER.CharacterType.Isomer,
    }
    --由于每种入战需要的数据不一样，这里完整存储上次客户端入战数据,方便重新开始战斗参数的构造
    self.BeginClientPreData = {}
    self.UiFubenMainLineChapterInst = nil

    self.ChapterFunctionName = {
        [self.ChapterType.Trial] = XFunctionManager.FunctionName.FubenChallengeTrial,
        [self.ChapterType.Explore] = XFunctionManager.FunctionName.FubenExplore,
        [self.ChapterType.Practice] = XFunctionManager.FunctionName.Practice,
        [self.ChapterType.ARENA] = XFunctionManager.FunctionName.FubenArena,
        [self.ChapterType.BossSingle] = XFunctionManager.FunctionName.FubenChallengeBossSingle,
        [self.ChapterType.Assign] = XFunctionManager.FunctionName.FubenAssign,
        [self.ChapterType.InfestorExplore] = XFunctionManager.FunctionName.FubenInfesotorExplore,
        [self.ChapterType.MaintainerAction] = XFunctionManager.FunctionName.MaintainerAction,
        [self.ChapterType.Stronghold] = XFunctionManager.FunctionName.Stronghold,
        [self.ChapterType.PartnerTeaching] = XFunctionManager.FunctionName.PartnerTeaching,
        -- v1.30-考级-Todo-功能判定FunctionName索引
        [self.ChapterType.Course] = XFunctionManager.FunctionName.Course,
    }
    self.StageMultiplayerLevelMap = { }

    self.StageType = XEnumConst.FuBen.StageType

    self.ModeType = {
        SINGLE = 1,
        MULTI = 2,
    }


    -- 是否是全息模式
    self._IsHideAction = false

    self.LastPrologueStageId = 10010003
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
    if self._Model.RegFubenDict[fubenType] then
        return true
    end
    return false
end

---@param fubenType number
---@param moduleId string
function XFubenAgency:RegisterFuben(fubenType, moduleId)
    if not self._Model.RegFubenDict[fubenType] then
        local agency = XMVCA:GetAgency(moduleId)
        if agency then
            if IsWindowsEditor then
                if not CheckClassSuper(agency, XFubenBaseAgency) then
                    XLog.Error(string.format("%s Agency 需要继承 XFubenBaseAgency", agency:GetId()))
                    return
                end
            end
            self._Model.RegFubenDict[fubenType] = moduleId
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
    if self._Model.RegFubenDict[fubenType] then
        local agency = XMVCA:GetAgency(self._Model.RegFubenDict[fubenType])
        return agency[funcKey] --返回有这个方法
    end
end

---副本尝试调用各个玩法的自定义战斗函数
---@param fubenType number 副本类型
---@param funcKey string
---@return boolean 是否有执行到自定义方法
---@return any 方法返回值
function XFubenAgency:CallCustomFunc(fubenType, funcKey, ...)
    local outdate = self._Model.OutdateRegFubenDict[fubenType]
    if outdate then
        local func = outdate[funcKey]
        if func then
            return true, func(...)
        end
    end
    
    if self._Model.RegFubenDict[fubenType] then
        local agency = XMVCA:GetAgency(self._Model.RegFubenDict[fubenType])
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
    --self.

    --已经存在的直接return
    if self._Model.TempCustomFunc[funcKey] and self._Model.TempCustomFunc[funcKey][fubenType] then
        return self._Model.TempCustomFunc[funcKey][fubenType]
    end

    local agency = self._Model.OutdateRegFubenDict[fubenType]
    if not agency and self._Model.RegFubenDict[fubenType] then
        agency = XMVCA:GetAgency(self._Model.RegFubenDict[fubenType])
    end
    if not agency then
        return nil
    end
    local func = agency[funcKey]
    if func then
        local handler = Handler(agency, func)
        local tempFuncs = self._Model.TempCustomFunc[funcKey]
        if not tempFuncs then
            tempFuncs = {}
            self._Model.TempCustomFunc[funcKey] = tempFuncs
        end
        tempFuncs[fubenType] = handler
        return handler
    end
    return nil
end

---调用所有子模块的一个自定义函数
---@param funcKey string 函数名
function XFubenAgency:CallAllCustomFunc(funcKey, ...)
    for stageType, outData in pairs(self._Model.OutdateRegFubenDict) do
        local func = outData[funcKey]
        if func then
            func(...)
        end
    end
    for _, moduleId in pairs(self._Model.RegFubenDict) do
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

function XFubenAgency:SetFubenSettleResult(value)
    return self._Model:SetFubenSettleResult(value)
end

function XFubenAgency:SetFubenSettling(value)
    return self._Model:SetFubenSettling(value)
end

---------进入战斗相关接口
--服务器下发的副本数据处理
function XFubenAgency:InitFubenData(fubenData, fubenEventData)
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

    if fubenEventData and fubenEventData.FubenEventInfos then 
        for _, eventInfo in ipairs(fubenEventData.FubenEventInfos) do
            self._Model:SetStageEventInfo(eventInfo)
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
    local config = self._Model:GetStageCfg(stageId, true)
    return config
end

function XFubenAgency:GetStageInfo(stageId)
    local stageInfo = self._Model:GetStageInfo(stageId)
    return stageInfo
end

function XFubenAgency:GetGeneralSkillIds(stageId)
    local generalSkillIds = string.Split(self:GetStageCfg(stageId).GeneralSkillIds)
    for i = 1, #generalSkillIds, 1 do
        generalSkillIds[i] = tonumber(generalSkillIds[i])
    end
    return generalSkillIds
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
    --local config = self._Model:GetStageCfg(stageId)
    --if config and XTool.IsNumberValid(config.Type) then --增加多一列, 优先读取配置的
    --    return config.Type
    --end
    local stageInfo = self._Model:GetStageInfo(stageId)
    if stageInfo then
        return stageInfo.Type
    end
end

--function XFubenAgency:GetStageName(stageId)
--    local config = self._Model:GetStageCfg(stageId)
--    return config.Name
--end

--function XFubenAgency:GetStageIcon(stageId)
--    local config = self._Model:GetStageCfg(stageId)
--    return config.Icon
--end

--function XFubenAgency:GetStageDes(stageId)
--    local config = self._Model:GetStageCfg(stageId)
--    return config.Description
--end

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
        chapterName, stageName = XMVCA.XFubenBossSingle:GetBossNameInfo(stageInfo.BossSectionId, stageId)
    elseif curStageType == StageType.Arena then
        local areaStageInfo = XDataCenter.ArenaManager.GetEnterAreaStageInfo()
        chapterName = areaStageInfo.ChapterName
        stageName = areaStageInfo.StageName
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
    --elseif curStageType == StageType.KillZone then
    --    chapterName = ""
    --    stageName = XKillZoneConfigs.GetStageName(stageId)
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
    --local isSimulatedCombat = XDataCenter.FubenSimulatedCombatManager.CheckStageIsSimulatedCombat(stage.StageId)
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
    --if isSimulatedCombat then
    --    preFight.RobotIds = {}
    --    for i, v in ipairs(preFight.CardIds) do
    --        local data = XDataCenter.FubenSimulatedCombatManager.GetCurStageMemberDataByCharId(v)
    --        if data then
    --            preFight.RobotIds[i] = data.RobotId
    --        else
    --            preFight.RobotIds[i] = 0
    --        end
    --    end
    --    preFight.CardIds = nil
    --end

    return preFight
end


function XFubenAgency:DoEnterFight(stage, teamId, isAssist, challengeCount, challengeId, callback)
    if not self:CheckPreFight(stage, challengeCount) then
        return
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
            local isKeepPlayingStory = stage and self:IsKeepPlayingStory(stage.StageId)
            local isNotPass = stage and (not stageInfo or not stageInfo.Passed)
            if stage.BeginStoryId and (isKeepPlayingStory or isNotPass) then
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

function XFubenAgency:RecordFightBeginData(stageId, charList, isHasAssist, assistPlayerData, challengeCount, roleData, fightData, firstFightPos)
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
        RoleData = roleData,
        FightData = fightData,
        FirstFightPos = firstFightPos,
    }
    self._Model:SetBeginData(beginData)

    if not self:IsStageCute(stageId) then
        for _, charId in pairs(charList) do
            local isRobot = XRobotManager.CheckIsRobotId(charId)
            local char = isRobot and XRobotManager.GetRobotTemplate(charId) or XMVCA.XCharacter:GetCharacter(charId)
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

    self:RecordFightBeginData(fightData.StageId, charList, preFightData.IsHasAssist, assistInfo, preFightData.ChallengeCount, roleData, fightData, preFightData.FirstFightPos)

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
    -- 生成关卡跳转信息
    self.StageTeleportInfo = self:GenFightStageTeleportInfo()

    -- 据点战关卡处理
    local stageType = self:GetStageType(settleData.StageId)
    if stageType == StageType.Bfrt then
        XDataCenter.BfrtManager.FinishStage(settleData.StageId)
    end

    local beginData = self._Model:GetBeginData()

    local winData = self:GetChallengeWinData(beginData, settleData)
    local stage = self._Model:GetStageCfg(settleData.StageId)
    local isKeepPlayingStory = stage and self:IsKeepPlayingStory(stage.StageId)
    local isNotPass = stage and not beginData.LastPassed
    if stage.EndStoryId and (isKeepPlayingStory or isNotPass) then
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
        XLog.Debug("gjl 请求战斗通用结算")
        XNetwork.Call(METHOD_NAME.FightSettle, fightResBytes, function(res)
            XLog.Debug("gjl 下发战斗通用结算")
            --战斗结算清除数据的判断依据
            self._Model:SetFubenSettleResult(res)
            self._Model:UpdateStageEventInfo()
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

    -- 跳转配置loading图
    if self.StageTeleportInfo and self.StageTeleportInfo.SkipStageId == stageId and self.StageTeleportInfo.SkipLoadingType then
        XLuaUiManager.Open("UiLoading", self.StageTeleportInfo.SkipLoadingType)
        return
    end

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

--- 生成本次战斗关卡跳转信息，关卡行为树传参跳转关卡
--- 2.11之后的关卡，关卡行为树跳转功能存值使用DoSetCustomData接口，存值的Key为跳转StageId
function XFubenAgency:GenFightStageTeleportInfo()
    local result = self:GetCurFightResult()
    if result and result.IsWin and result.CustomData and result.CustomData:ContainsKey(XPlayer.Id) then
        local teleportCfg = self._Model:GetConfigStageTeleport(result.StageId)
        if teleportCfg then
            local customData = result.CustomData[XPlayer.Id]
            local eventIdMap = XTool.CsMap2LuaTable(customData.Dict)
            for i, stageId in ipairs(teleportCfg.SkipStageIds) do
                -- 关卡行为树传值包含跳转关卡
                if eventIdMap[stageId] then
                    return { 
                        StageId = result.StageId, 
                        SkipStageId = stageId,
                        SkipLoadingType = teleportCfg.SkipLoadingTypes[i],
                        IsKeepPlayingStory = teleportCfg.KeepPlayingStory == 1,
                    }
                end
            end
        end
    end

    return
end
--- 获取关卡跳转信息
function XFubenAgency:GetStageTeleportInfo()
    return self.StageTeleportInfo
end

--- 是否保持播放剧情
function XFubenAgency:IsKeepPlayingStory(stageId)
    if self.StageTeleportInfo and (self.StageTeleportInfo.StageId == stageId or self.StageTeleportInfo.SkipStageId == stageId) then
        return self.StageTeleportInfo.IsKeepPlayingStory
    else
        return self._Model:IsKeepPlayingStory(stageId)
    end
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
        if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.FuBen.ChapterType.MainLine, chapter.ChapterId) then
            return
        end
        XLuaUiManager.Open("UiFubenMainLineChapter", chapter, stageId)
    elseif stageType == StageType.Bfrt then
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenNightmare) then
            return
        end

        local chapter = XDataCenter.BfrtManager.GetChapterCfg(stageInfo.ChapterId)

        if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.FuBen.ChapterType.Bfrt, chapter.ChapterId) then
            return
        end
        XLuaUiManager.Open("UiFubenMainLineChapter", chapter, stageId)
    elseif stageType == StageType.ActivityBossSingle then
        XDataCenter.FubenActivityBossSingleManager.ExOpenMainUi()
    elseif stageType == StageType.Assign then
        XDataCenter.FubenAssignManager.OpenUi(stageId)
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
                local nextStageType = self:GetStageType(nextStageId)

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


function XFubenAgency:OnSyncUnlockHideStage(unlockHideStage)
    self._Model:SetUnlockHideStages(unlockHideStage)
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

---@return XFightResultData
function XFubenAgency:GetCurFightResult()
    return self._Model:GetCurFightResult()
end

function XFubenAgency:GetLastDpsTable()
    return self._Model:GetLastDpsTable()
end

-- 调色板战争战斗
function XFubenAgency:EnterColorTableFight(xTeam, stageId)
    local characterIds = {}
    local robotIds = {}
    for k, roleId in pairs(xTeam:GetEntityIds()) do
        if XTool.IsNumberValid(roleId) then
            local isRobot = XEntityHelper.GetIsRobot(roleId)
            robotIds[k] = not isRobot and 0 or roleId
            characterIds[k] = isRobot and 0 or roleId
        else
            robotIds[k] = 0
            characterIds[k] = 0
        end
    end

    local preFight = {}
    preFight.CardIds = characterIds
    preFight.RobotIds = robotIds
    preFight.StageId = stageId
    preFight.CaptainPos = xTeam:GetCaptainPos()
    preFight.FirstFightPos = xTeam:GetFirstFightPos()

    local req = { PreFightData = preFight }
    XNetwork.Call(METHOD_NAME.PreFight, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local fightData = res.FightData
        local stageInfo = self:GetStageInfo(fightData.StageId)
        local stage = self:GetStageCfg(stageId)
        if stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed) then
            -- 播放剧情，进入战斗
            self:EnterRealFight(preFight, fightData, stage.BeginStoryId)
        else
            -- 直接进入战斗
            self:EnterRealFight(preFight, fightData)
        end
    end)
end

function XFubenAgency:InitStageLevelMap()
    self._Model:InitStageLevelMap()
end

function XFubenAgency:EnterSkillTeachFight(characterId)
    local stageId = XMVCA.XCharacter:GetCharTeachStageIdById(characterId)

    local fightData = {}
    fightData.RoleData = {}
    fightData.FightId = 1
    fightData.Online = false
    fightData.Seed = 1
    fightData.StageId = stageId

    local roleData = {}
    roleData.NpcData = {}
    table.insert(fightData.RoleData, roleData)
    roleData.Id = XPlayer.Id
    roleData.Name = CSTextManagerGetText("Aha")
    roleData.Camp = 1

    local npcData = {}
    roleData.NpcData[0] = npcData

    npcData.Character = XMVCA.XCharacter:GetCharacter(characterId)
    npcData.Equips = XDataCenter.EquipManager.GetCharacterWearingEquips(characterId)
    npcData.WeaponFashionId = XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)

    local stage = self:GetStageCfg(stageId)
    fightData.RebootId = stage.RebootId
    local endFightCb = function()
        if stage.EndStoryId then
            XDataCenter.MovieManager.PlayMovie(stage.EndStoryId)
        end
    end

    local enterFightFunc = function()
        self:CallOpenFightLoading(stageId)
        local args = CS.XFightClientArgs()
        args.RoleId = XPlayer.Id
        args.CloseLoadingCb = function()
            self:CallCloseFightLoading(stageId)
        end
        args.FinishCbAfterClear = function()
            endFightCb()
        end
        args.ClientOnly = true

        -- CS.XUiManager.Instance:ReleaseUiScene("UiActivityBriefBase")
        CS.XFight.Enter(fightData, args)
    end

    if stage.BeginStoryId then
        XDataCenter.MovieManager.PlayMovie(stage.BeginStoryId, enterFightFunc)
    else
        enterFightFunc()
    end
end

function XFubenAgency:RequestArenaOnlineCreateRoom(stageinfo, stageid, cb)
    if self:CheckPreFight(stageinfo) then
        XDataCenter.RoomManager.ArenaOnlineCreateRoom(stageid, cb)
    end
end

function XFubenAgency:InitStageInfoNextStageId()
    for _, v in pairs(self:GetStageCfgs()) do
        for _, preStageId in pairs(v.PreStageId) do
            local preStageInfo = self:GetStageInfo(preStageId)
            if preStageInfo then
                if not (v.StageType == XFubenConfigs.STAGETYPE_STORYEGG or v.StageType == XFubenConfigs.STAGETYPE_FIGHTEGG) then
                    preStageInfo.NextStageId = v.StageId
                end
            else
                XLog.Error("XFubenAgency.InitStageInfoNextStageId error:初始化前置关卡信息失败, 请检查Stage.tab, preStageId: " .. preStageId)
            end
        end
    end
end

function XFubenAgency:GetDailyDungeonRules()
    local dailyDungeonRules = XDailyDungeonConfigs.GetDailyDungeonRulesList()

    local tmpDataList = {}

    for _, v in pairs(dailyDungeonRules) do
        local tmpData = {}
        local tmpDay = XDataCenter.FubenDailyManager.IsDayLock(v.Id)
        local tmpCon = XDataCenter.FubenDailyManager.GetConditionData(v.Id).IsLock
        local tmpOpen = XDataCenter.FubenDailyManager.GetEventOpen(v.Id).IsOpen
        tmpData.Lock = tmpCon or (tmpDay and not tmpOpen)
        tmpData.Rule = v
        tmpData.Open = tmpOpen and not tmpCon
        if not XFunctionManager.CheckFunctionFitter(XDataCenter.FubenDailyManager.GetConditionData(v.Id).functionNameId) then
            table.insert(tmpDataList, tmpData)
        end
    end

    table.sort(tmpDataList, function(a, b)
        if not a.Lock and not b.Lock then
            if (a.Open and b.Open) or (not a.Open and not b.Open) then
                return a.Rule.Priority < b.Rule.Priority
            else
                return a.Open and not b.Open
            end
        elseif a.Lock and b.Lock then
            return a.Rule.Priority < b.Rule.Priority
        else
            return not a.Lock and b.Lock
        end
    end)

    dailyDungeonRules = {}
    for _, v in pairs(tmpDataList) do
        table.insert(dailyDungeonRules, v.Rule)
    end

    return dailyDungeonRules
end

-- 意识公约战斗
function XFubenAgency:EnterAwarenessFight(stageId, charIdList, captainPos, startCb, errorCb, firstFightPos)
    local stage = self:GetStageCfg(stageId)
    local preFight = {}
    preFight.CardIds = {}
    preFight.StageId = stage.StageId
    preFight.CaptainPos = captainPos or XDataCenter.FubenAssignManager.CAPTIAN_MEMBER_INDEX
    preFight.FirstFightPos = firstFightPos or XDataCenter.FubenAssignManager.FIRSTFIGHT_MEMBER_INDEX

    for _, charId in ipairs(charIdList) do
        if charId ~= 0 then
            table.insert(preFight.CardIds, charId)
        end
    end
    local req = { PreFightData = preFight }
    XNetwork.Call(METHOD_NAME.PreFight, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if errorCb then
                errorCb()
            end
            return
        end
        local fightData = res.FightData
        local stageInfo = self:GetStageInfo(fightData.StageId)
        if stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed) then
            -- 播放剧情，进入战斗
            self:EnterRealFight(preFight, fightData, stage.BeginStoryId, startCb)
        else
            -- 直接进入战斗
            self:EnterRealFight(preFight, fightData, nil, startCb)
        end
    end)
end

function XFubenAgency:GetStageExCost(stageId)
    local stageExCfg = self:GetMultiChallengeStageConfig(stageId)
    local itemId = stageExCfg.ConsumeId and stageExCfg.ConsumeId[1] or 0
    local itemNum = stageExCfg.ConsumeNum and stageExCfg.ConsumeNum[1] or 0
    return itemId, itemNum
end

function XFubenAgency:GetFlopShowId(stageId)
    local stage = self:GetStageCfg(stageId)
    local flopRewardId = stage.FlopRewardId
    local flopRewardTemplate = self:GetFlopRewardTemplates()[flopRewardId]
    return flopRewardTemplate and flopRewardTemplate.ShowRewardId or 0
end

function XFubenAgency:InitStageInfoRelation()
    self._Model:InitStageInfoRelation()
end

function XFubenAgency:GetStageNameLevel(stageId)
    local stageInfo = self:GetStageInfo(stageId)
    local stageCfg = self:GetStageCfg(stageId)
    if not stageInfo or not stageCfg then
        return nil
    end
    local chapter = XDataCenter.FubenMainLineManager.GetChapterCfg(stageInfo.ChapterId)
    local orderStr = (chapter and chapter.OrderId or 0) .. "-" .. (stageCfg.OrderId or 0)
    return orderStr, stageCfg.Name
end

-- 区域联机匹配
function XFubenAgency:RequestAreanaOnlineMatchRoom(stage, stageId, cb)
    if self:CheckPreFight(stage) then
        XDataCenter.RoomManager.AreanaOnlineMatch(stageId, cb)
    end
end

function XFubenAgency:InitNewChallengeRedPointTable()
    -- 读取本地存储数据初始化新挑战红点纪录
    if self.NewChallengeInit then
        return
    end
    self.NewChallengeInit = true
    self.NewChallengeRedPointTable = {}
    local localData = XSaveTool.GetData(XPlayer.Id .. "NewChallengeRedPoint")
    if not localData or type(localData) ~= "table" then
        return
    end
    for i in pairs(localData) do
        -- 若还没到新的开始时间，不采用之前的纪录
        if self:IsNewChallengeStartById(localData[i].Id) and
                localData[i].EndTime and localData[i].EndTime > XTime.GetServerNowTimestamp() then
            self.NewChallengeRedPointTable[localData[i].Id] = localData[i]
        end
    end
end

function XFubenAgency:RefreshNewChallengeRedPoint()
    -- 点击挑战页签时刷新新挑战红点状态
    local challengeLength = self:GetNewChallengeConfigsLength()
    if not challengeLength or challengeLength == 0 then
        return
    end
    local needSave = false
    for i = 1, challengeLength do
        if XFunctionManager.JudgeCanOpen(self:GetNewChallengeFunctionId(i))
                and self:IsNewChallengeStartByIndex(i) then
            -- 若时间还未到达开始时间，不纪录
            local id = self:GetNewChallengeId(i)
            if not self.NewChallengeRedPointTable[id] then
                local newMessage = {
                    Id = id,
                    IsClicked = true,
                    EndTime = self:GetNewChallengeEndTimeStamp(i),
                }
                self.NewChallengeRedPointTable[id] = newMessage
                needSave = true
            elseif not self.NewChallengeRedPointTable[id].IsClicked then
                self.NewChallengeRedPointTable[id].IsClicked = true
                self.NewChallengeRedPointTable[id].EndTime = self:GetNewChallengeEndTimeStamp(i)
                needSave = true
            end
        end
    end
    if needSave then
        self:SaveNewChallengeRedPoint()
    end
end

function XFubenAgency:GetStageDes(stageId)
    local config = self:GetStageCfg(stageId)
    return config.Description
end

function XFubenAgency:EnterPracticeBoss(stage, curTeam, simulateTrainInfo)
    if not self:CheckPreFight(stage) then
        return
    end
    local preFight = {}
    preFight.CardIds = {}
    preFight.StageId = stage.StageId
    preFight.CaptainPos = curTeam.CaptainPos
    preFight.FirstFightPos = curTeam.FirstFightPos
    preFight.SimulateTrainInfo = simulateTrainInfo
    for _, v in pairs(curTeam.TeamData or {}) do
        table.insert(preFight.CardIds, v)
    end
    XNetwork.Call(METHOD_NAME.PreFight, { PreFightData = preFight }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self:RecordBeginClientPreData(stage, curTeam, simulateTrainInfo)
        local fightData = res.FightData
        self:EnterRealFight(preFight, fightData)
    end)
end

function XFubenAgency:GetFightChallengeCount()
    local beginData = self:GetFightBeginData()
    return beginData and beginData.ChallengeCount or 1
end

-- 据点战斗
function XFubenAgency:EnterBfrtFight(stageId, team, captainPos, firstFightPos)
    local stage = self:GetStageCfg(stageId)
    if not self:CheckPreFight(stage) then
        return
    end

    local preFight = {}
    preFight.CardIds = {}
    preFight.StageId = stage.StageId
    preFight.CaptainPos = captainPos
    preFight.FirstFightPos = firstFightPos

    for _, v in pairs(team) do
        table.insert(preFight.CardIds, v)
    end
    local req = { PreFightData = preFight }
    XNetwork.Call(METHOD_NAME.PreFight, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local fightData = res.FightData
        local stageInfo = self:GetStageInfo(fightData.StageId)
        if stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed) then
            -- 播放剧情，进入战斗
            self:EnterRealFight(preFight, fightData, stage.BeginStoryId)
        else
            -- 直接进入战斗
            self:EnterRealFight(preFight, fightData)
        end
    end)
end

-- 将旧战斗房间NewRoomSingle删除，全部改为BattleRoleRoom
function XFubenAgency:OpenBattleRoom(stage, data)
    if self:CheckPreFight(stage) then
        XLuaUiManager.Open("UiBattleRoleRoom", stage.StageId, data)
        return true
    end
    return false
end

-- 口袋妖怪战斗
function XFubenAgency:EnterPokemonFight(stageId)
    local stage = self:GetStageCfg(stageId)
    if not self:CheckPreFight(stage) then
        return
    end

    local preFight = {}
    preFight.StageId = stage.StageId

    local req = { PreFightData = preFight }
    XNetwork.Call(METHOD_NAME.PreFight, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local fightData = res.FightData
        local stageInfo = self:GetStageInfo(fightData.StageId)
        if stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed) then
            -- 播放剧情，进入战斗
            self:EnterRealFight(preFight, fightData, stage.BeginStoryId)
        else
            -- 直接进入战斗
            self:EnterRealFight(preFight, fightData)
        end
    end)
end

-- 口袋妖怪战斗
function XFubenAgency:EnterPokemonFight(stageId)
    local stage = self:GetStageCfg(stageId)
    if not self:CheckPreFight(stage) then
        return
    end

    local preFight = {}
    preFight.StageId = stage.StageId

    local req = { PreFightData = preFight }
    XNetwork.Call(METHOD_NAME.PreFight, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local fightData = res.FightData
        local stageInfo = self:GetStageInfo(fightData.StageId)
        if stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed) then
            -- 播放剧情，进入战斗
            self:EnterRealFight(preFight, fightData, stage.BeginStoryId)
        else
            -- 直接进入战斗
            self:EnterRealFight(preFight, fightData)
        end
    end)
end

-- 萌战战斗
function XFubenAgency:EnterMoeWarFight(stage, curTeam, isNewTeam)
    if not self:CheckPreFight(stage) then
        return
    end
    local preFight = {}
    preFight.CardIds = {}
    preFight.StageId = stage.StageId
    preFight.CaptainPos = curTeam.CaptainPos
    preFight.FirstFightPos = curTeam.FirstFightPos
    preFight.RobotIds = {}

    local charId
    if isNewTeam then
        charId = curTeam:GetEntityIdByTeamPos(curTeam:GetFirstFightPos())
    else
        charId = curTeam.TeamData[1]
    end
    if XRobotManager.CheckIsRobotId(charId) then
        table.insert(preFight.RobotIds, charId)
    else
        table.insert(preFight.CardIds, charId)
    end

    XNetwork.Call(METHOD_NAME.PreFight, { PreFightData = preFight }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local fightData = res.FightData
        local stageInfo = self:GetStageInfo(fightData.StageId)
        local isKeepPlayingStory = stage and self:IsKeepPlayingStory(stage.StageId) and (stage.BeginStoryId)
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

--带有机器人的队伍构造入口
function XFubenAgency:EnterStageWithRobot(stage, curTeam)
    if not self:CheckPreFight(stage) then
        return
    end
    local preFight = {}
    preFight.CardIds = {}
    preFight.StageId = stage.StageId
    preFight.CaptainPos = curTeam.CaptainPos
    preFight.FirstFightPos = curTeam.FirstFightPos
    preFight.RobotIds = {}
    for _, v in pairs(curTeam.TeamData or {}) do
        if not XRobotManager.CheckIsRobotId(v) then
            table.insert(preFight.CardIds, v)
            table.insert(preFight.RobotIds, 0)
        else
            table.insert(preFight.CardIds, 0)
            table.insert(preFight.RobotIds, v)
        end
    end

    XNetwork.Call(METHOD_NAME.PreFight, { PreFightData = preFight }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local fightData = res.FightData
        self:EnterRealFight(preFight, fightData)
    end)
end

function XFubenAgency:GetFlopConsumeItemId(stageId)
    local stage = self:GetStageCfg(stageId)
    local flopRewardId = stage.FlopRewardId
    local flopRewardTemplate = self:GetFlopRewardTemplates()[flopRewardId]
    return flopRewardTemplate and flopRewardTemplate.ConsumeItemId or 0
end

function XFubenAgency:GetConditonByMapId(stageId)
    local suggestedConditionIds, forceConditionIds = {}, {}
    local stageConfig = self:GetStageCfg(stageId)
    if stageConfig then
        suggestedConditionIds = stageConfig.SuggestedConditionId
        forceConditionIds = stageConfig.ForceConditionId
    end
    return suggestedConditionIds, forceConditionIds
end

function XFubenAgency:IsPreStageIdContains(preStageId, stageId)
    for _, v in pairs(preStageId or {}) do
        if v == stageId then
            return true
        end
    end
    return false
end

-- 追击玩法
function XFubenAgency:EnterChessPursuitFight(stage, preFight, callBack)
    XNetwork.Call(METHOD_NAME.PreFight, { PreFightData = preFight }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local fightData = res.FightData
        local stageInfo = self:GetStageInfo(fightData.StageId)
        local isKeepPlayingStory = stage and self:IsKeepPlayingStory(stage.StageId) and (stage.BeginStoryId)
        local isNotPass = stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed)

        CsXUiManager.Instance:SetRevertAndReleaseLock(true)
        if isKeepPlayingStory or isNotPass then
            -- 播放剧情，进入战斗
            self:EnterRealFight(preFight, fightData, stage.BeginStoryId, callBack)
        else
            -- 直接进入战斗
            self:EnterRealFight(preFight, fightData, nil, callBack)
        end
    end)
end

-- 获取编队类型限制对应的默认角色类型
function XFubenAgency:GetDefaultCharacterTypeByCharacterLimitType(characterLimitType)
    return self.DefaultCharacterTypeConvert[characterLimitType]
end

function XFubenAgency:RecordBeginClientPreData(...)
    self.BeginClientPreData = { ... }
end

-- Rpc相关
function XFubenAgency:OnSyncStageData(stageList)
    self:RefreshStageInfo(stageList)
    for _, v in pairs(stageList) do
        self._Model:SetPlayerStageData(v.StageId, v)
        XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_STAGE_SYNC, v.StageId)
    end
end

function XFubenAgency:GetStageData(stageId)
    return self._Model:GetPlayerStageDataById(stageId)
end

-- 巴别塔战斗
function XFubenAgency:EnterBabelTowerFight(stageId, team, captainPos, firstFightPos)
    local stage = self:GetStageCfg(stageId)
    if not self:CheckPreFight(stage) then
        return
    end

    local preFight = {}
    preFight.CardIds = {}
    preFight.RobotIds = {}
    preFight.StageId = stageId
    preFight.CaptainPos = captainPos
    preFight.FirstFightPos = firstFightPos

    for i, v in pairs(team) do
        local isRobot = XEntityHelper.GetIsRobot(v)
        preFight.CardIds[i] = isRobot and 0 or v
        preFight.RobotIds[i] = isRobot and v or 0
    end

    local rep = { PreFightData = preFight }
    XNetwork.Call(METHOD_NAME.PreFight, rep, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local fightData = res.FightData
        local stageInfo = self._Model:GetStageInfo(fightData.StageId)
        if stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed) then
            self:EnterRealFight(preFight, fightData, stage.BeginStoryId)
        else
            self:EnterRealFight(preFight, fightData)
        end
    end)
end

function XFubenAgency:RequestRestart(fightId, cb)
    XNetwork.Call(METHOD_NAME.FightRestart, { FightId = fightId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
        end
        cb(res.Seed)
    end)
end

function XFubenAgency:GetStageActionPointConsume(stageId)
    local stage = self:GetStageCfg(stageId)
    local flopRewardId = stage.FlopRewardId
    local flopRewardTemplate = self:GetFlopRewardTemplates()[flopRewardId]
    local actionPoint = self:GetRequireActionPoint(stageId)
    -- 没配翻牌
    if not flopRewardTemplate then
        return actionPoint
    end

    -- 翻牌道具不足
    if not self:CheckCanFlop(stageId) then
        return actionPoint
    end

    return actionPoint + flopRewardTemplate.ExtraActionPoint
end

function XFubenAgency:GoToCurrentMainLine(stageId)
    if not self.UiFubenMainLineChapterInst then
        XLog.Error("XFubenAgency.GoToCurrentMainLine : UiFubenMainLineChapterInst为空")
        return
    end
    local stageInfo = self:GetStageInfo(stageId)
    if not stageInfo then
        XLog.ErrorTableDataNotFound("XFubenAgency.GoToCurrentMainLine", "stageInfo", "Share/Fuben/Stage.tab", "stageId", tostring(stageId))
        return
    end
    if not stageInfo.Unlock then
        XUiManager.TipMsg(self:GetFubenOpenTips(stageId))
        return
    end

    if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.FuBen.ChapterType.MainLine, stageInfo.ChapterId) then
        return
    end

    self.UiFubenMainLineChapterInst:OpenStage(stageId, true)
end

-- 爬塔战斗
function XFubenAgency:EnterRogueLikeFight(stage, curTeam, isAssist, nodeId, func)
    if not self:CheckPreFight(stage) then
        return
    end

    local preFight = {}
    preFight.CardIds = {}
    preFight.StageId = stage.StageId
    preFight.RogueLikeNodeId = nodeId
    preFight.IsHasAssist = false
    preFight.AssistType = isAssist
    preFight.CaptainPos = curTeam.CaptainPos
    preFight.FirstFightPos = curTeam.FirstFightPos
    for _, v in pairs(curTeam.TeamData or {}) do
        table.insert(preFight.CardIds, v)
    end

    -- 助战机器人、调换队长位置
    if isAssist == 1 then
        local captainPos = curTeam.CaptainPos
        if captainPos ~= nil and captainPos > 0 then
            local tempCardIds = preFight.CardIds[captainPos]
            preFight.CardIds[captainPos] = preFight.CardIds[1]
            preFight.CardIds[1] = tempCardIds
        end
    end

    local req = { PreFightData = preFight }
    XNetwork.Call(METHOD_NAME.PreFight, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if func then
            func()
        end

        local fightData = res.FightData
        local stageInfo = self:GetStageInfo(fightData.StageId)
        local isKeepPlayingStory = stage and self:IsKeepPlayingStory(stage.StageId) and (stage.BeginStoryId)
        local isNotPass = stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed)
        if isKeepPlayingStory or isNotPass then
            self:EnterRealFight(preFight, fightData, stage.BeginStoryId)
        else
            self:EnterRealFight(preFight, fightData)
        end
    end)
end

function XFubenAgency:CheckCanFlop(stageId)
    local stage = self:GetStageCfg(stageId)
    local flopRewardId = stage.FlopRewardId
    local flopRewardTemplate = self:GetFlopRewardTemplates()[flopRewardId]
    if not flopRewardTemplate then
        return false
    end

    if flopRewardTemplate.ConsumeItemId > 0 then
        if not XDataCenter.ItemManager.CheckItemCountById(flopRewardTemplate.ConsumeItemId, flopRewardTemplate.ConsumeItemCount) then
            return false
        end
    end

    return true
end

-- 边界公约战斗
function XFubenAgency:EnterAssignFight(stageId, charIdList, captainPos, startCb, errorCb, firstFightPos)
    local stage = self:GetStageCfg(stageId)
    local preFight = {}
    preFight.CardIds = {}
    preFight.StageId = stage.StageId
    preFight.CaptainPos = captainPos or XDataCenter.FubenAssignManager.CAPTIAN_MEMBER_INDEX
    preFight.FirstFightPos = firstFightPos or XDataCenter.FubenAssignManager.FIRSTFIGHT_MEMBER_INDEX

    for _, charId in ipairs(charIdList) do
        if charId ~= 0 then
            table.insert(preFight.CardIds, charId)
        end
    end
    local req = { PreFightData = preFight }
    XNetwork.Call(METHOD_NAME.PreFight, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if errorCb then
                errorCb()
            end
            return
        end
        local fightData = res.FightData
        -- -- 战力不足  不能复活 (改为服务器处理，读取FightReboot.tab字段RebootCondition)
        -- if not XDataCenter.FubenAssignManager.IsAbilityMatch(stageId, charIdList) then
        --     fightData.RebootId = 0
        -- end
        local stageInfo = self:GetStageInfo(fightData.StageId)
        if stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed) then
            -- 播放剧情，进入战斗
            self:EnterRealFight(preFight, fightData, stage.BeginStoryId, startCb)
        else
            -- 直接进入战斗
            self:EnterRealFight(preFight, fightData, nil, startCb)
        end
    end)
end

function XFubenAgency:GetStageOrderId(stageId)
    local cfg = self:GetStageCfg(stageId)
    if not cfg then
        return
    end
    return cfg.OrderId
end

function XFubenAgency:EnterPrequelFight(stageId)
    local stageCfg = self:GetStageCfg(stageId)
    local stageInfo = self:GetStageInfo(stageId)
    if stageCfg and stageInfo then
        if stageInfo.Unlock then
            local actionPoint = self:GetRequireActionPoint(stageId)
            if actionPoint > 0 then
                if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(XDataCenter.ItemManager.ItemId.ActionPoint,
                        actionPoint,
                        1,
                        function()
                            self:EnterPrequelFight(stageId)
                        end,
                        "FubenActionPointNotEnough") then
                    return
                end
            end
            --
            for _, conditionId in pairs(stageCfg.ForceConditionId or {}) do
                local ret, desc = XConditionManager.CheckCondition(conditionId)
                if not ret then
                    XUiManager.TipError(desc)
                    return
                end
            end
            XDataCenter.PrequelManager.UpdateShowChapter(stageId)
            self:EnterFight(stageCfg, nil, false)
        else
            XUiManager.TipMsg(self:GetFubenOpenTips(stageId))
        end
    end
end

function XFubenAgency:GetChallengeChapters()
    local list = {}
    local isTrialFinish = false
    local isExploreFinishAll = false
    local exploreChapters = nil
    local arenaChapters
    local bossSingleChapters
    local practiceChapters
    local trialChapters
    local assignChapter
    local isOpen
    --如果完成了全部探索需要把探索拍到最后
    isOpen = not self:CheckFunctionFitter(XFunctionManager.FunctionName.FubenExplore)
    if isOpen then
        exploreChapters = self:GetChapterBannerByType(self.ChapterType.Explore)
        if exploreChapters.IsOpen and exploreChapters.IsOpen == 1 then
            if not XDataCenter.FubenExploreManager.IsFinishAll() then
                table.insert(list, exploreChapters)
            else
                isExploreFinishAll = true
            end
        end
    end

    isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.FubenArena)
    if isOpen then
        arenaChapters = self:GetChapterBannerByType(self.ChapterType.ARENA)
        if arenaChapters.IsOpen and arenaChapters.IsOpen == 1 then
            table.insert(list, arenaChapters)
        end
    end

    isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.FubenChallengeBossSingle)
    if isOpen then
        bossSingleChapters = self:GetChapterBannerByType(self.ChapterType.BossSingle)
        if bossSingleChapters.IsOpen and bossSingleChapters.IsOpen == 1 then
            table.insert(list, bossSingleChapters)
        end
    end

    isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Practice)
    if isOpen then
        practiceChapters = self:GetChapterBannerByType(self.ChapterType.Practice)
        if practiceChapters.IsOpen and practiceChapters.IsOpen == 1 then
            table.insert(list, practiceChapters)
        end
    end

    isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.FubenChallengeTrial)
    if isOpen then
        trialChapters = self:GetChapterBannerByType(self.ChapterType.Trial)
        if trialChapters and trialChapters.IsOpen and trialChapters.IsOpen == 1 then
            if XDataCenter.TrialManager.EntranceOpen() then
                table.insert(list, trialChapters)
            else
                isTrialFinish = true
            end
        end
    end

    isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.FubenAssign)
    if isOpen then
        assignChapter = self:GetChapterBannerByType(self.ChapterType.Assign)
        if assignChapter and assignChapter.IsOpen == 1 then
            table.insert(list, assignChapter)
        end
    end

    --isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.FubenInfesotorExplore)
    --        and XDataCenter.FubenInfestorExploreManager.IsOpen()
    --if isOpen then
    --    local chapter = self:GetChapterBannerByType(XFubenManager.ChapterType.InfestorExplore)
    --    if chapter and chapter.IsOpen == 1 then
    --        table.insert(list, chapter)
    --    end
    --end

    isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.MaintainerAction) and not XUiManager.IsHideFunc
    if isOpen then
        --要时间控制
        local IsStart = XDataCenter.MaintainerActionManager.IsStart()
        local chapter = self:GetChapterBannerByType(self.ChapterType.MaintainerAction)
        if IsStart and chapter and chapter.IsOpen == 1 then
            table.insert(list, chapter)
        end
    end

    isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Stronghold)
            and XDataCenter.StrongholdManager.IsOpen()
    if isOpen then
        local chapter = self:GetChapterBannerByType(self.ChapterType.Stronghold)
        if chapter and chapter.IsOpen == 1 then
            table.insert(list, chapter)
        end
    end

    isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.PartnerTeaching)
    if isOpen then
        local chapter = self:GetChapterBannerByType(self.ChapterType.PartnerTeaching)
        if chapter and chapter.IsOpen == 1 then
            table.insert(list, chapter)
        end
    end

    isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Theatre)
    if isOpen then
        local chapter = self:GetChapterBannerByType(self.ChapterType.Theatre)
        if chapter and chapter.IsOpen == 1 then
            table.insert(list, chapter)
        end
    end

    isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.PivotCombat)
    if isOpen then
        local chapter = self:GetChapterBannerByType(self.ChapterType.PivotCombat)
        if chapter and chapter.IsOpen == 1 then
            table.insert(list, chapter)
        end
    end

    -- v1.30-考级-Todo-考级功能进入挑战功能入口队列
    isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Course)
    if isOpen then
        local chapter = self:GetChapterBannerByType(self.ChapterType.Course)
        if chapter and chapter.IsOpen == 1 then
            table.insert(list, chapter)
        end
    end

    isOpen = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Transfinite)
    if isOpen then
        local chapter = self:GetChapterBannerByType(self.ChapterType.Transfinite)
        if chapter and chapter.IsOpen == 1 then
            table.insert(list, chapter)
        end
    end

    table.sort(list, function(chapterA, chapterB)
        local weightA = XFunctionManager.JudgeCanOpen(self.ChapterFunctionName[chapterA.Type]) and 1 or 0
        local weightB = XFunctionManager.JudgeCanOpen(self.ChapterFunctionName[chapterB.Type]) and 1 or 0
        if weightA == weightB then
            return chapterA.Priority < chapterB.Priority
        end
        return weightA > weightB
    end)

    if isTrialFinish then
        table.insert(list, trialChapters)
    end

    --如果完成了全部探索需要把探索排到最后
    if isExploreFinishAll then
        table.insert(list, exploreChapters)
    end
    return list
end

function XFubenAgency:GetStageMaxChallengeNums(stageId)
    local stageCfg = self:GetStageCfg(stageId)
    return stageCfg and stageCfg.MaxChallengeNums or 0
end

--返回战前数据
function XFubenAgency:GetFightBeginClientPreData()
    return self.BeginClientPreData or {}
end

function XFubenAgency:GetStageMultiplayerLevelMap()
    return self.StageMultiplayerLevelMap
end

function XFubenAgency:CtorPreFight(stage, teamId)
    local preFight = {}
    preFight.CardIds = {}
    preFight.StageId = stage.StageId
    if not stage.RobotId or #stage.RobotId <= 0 then
        local teamData = XDataCenter.TeamManager.GetTeamData(teamId)
        for _, v in pairs(teamData) do
            table.insert(preFight.CardIds, v)
        end
    end
    return preFight
end

function XFubenAgency:SaveNewChallengeRedPoint()
    -- 保存新挑战红点状态到本地
    XSaveTool.SaveData(XPlayer.Id .. "NewChallengeRedPoint", self.NewChallengeRedPointTable)
    XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_NEW_CHALLEGE)
end

function XFubenAgency:GetDailyDungeonRules()
    local dailyDungeonRules = XDailyDungeonConfigs.GetDailyDungeonRulesList()

    local tmpDataList = {}

    for _, v in pairs(dailyDungeonRules) do
        local tmpData = {}
        local tmpDay = XDataCenter.FubenDailyManager.IsDayLock(v.Id)
        local tmpCon = XDataCenter.FubenDailyManager.GetConditionData(v.Id).IsLock
        local tmpOpen = XDataCenter.FubenDailyManager.GetEventOpen(v.Id).IsOpen
        tmpData.Lock = tmpCon or (tmpDay and not tmpOpen)
        tmpData.Rule = v
        tmpData.Open = tmpOpen and not tmpCon
        if not XFunctionManager.CheckFunctionFitter(XDataCenter.FubenDailyManager.GetConditionData(v.Id).functionNameId) then
            table.insert(tmpDataList, tmpData)
        end
    end

    table.sort(tmpDataList, function(a, b)
        if not a.Lock and not b.Lock then
            if (a.Open and b.Open) or (not a.Open and not b.Open) then
                return a.Rule.Priority < b.Rule.Priority
            else
                return a.Open and not b.Open
            end
        elseif a.Lock and b.Lock then
            return a.Rule.Priority < b.Rule.Priority
        else
            return not a.Lock and b.Lock
        end
    end)

    dailyDungeonRules = {}
    for _, v in pairs(tmpDataList) do
        table.insert(dailyDungeonRules, v.Rule)
    end

    return dailyDungeonRules
end

-- 购买体力，作为测试的暂时工具
function XFubenAgency:BuyActionPoint(cb)
    XNetwork.Call(METHOD_NAME.BuyActionPoint, nil, function()
        local val = XDataCenter.ItemManager.GetActionPointsNum()
        cb(val)
    end)
end

-- stageType优化: 
-- 新增的stage由策划配置type, 弃用InitStageInfo赋值的方式;
-- 旧的功能如果有测试跟进,  在此处增加stageType, 并删除旧Manager的InitStageInfo
function XFubenAgency:IsConfigToInitStageInfo(stageType)
    return stageType == self.StageType.TwoSideTower
            or stageType == self.StageType.Bfrt
            or stageType == self.StageType.TaikoMaster
            or stageType == self.StageType.CerberusGame
            or stageType == self.StageType.Reform
    --or stageType == self.StageType.GuildWar
    --or stageType == self.StageType.Rift
    --or stageType == self.StageType.Transfinite
end

function XFubenAgency:SetFightBeginData(value)
    self._Model:SetBeginData(value)
end

function XFubenAgency:GetTeamExp(stageId, isAuto)
    local stageCfg = self:GetStageCfg(stageId)
    -- 队伍经验
    local teamExp = stageCfg.TeamExp or 0

    -- 当原字段为0时 返回新增字段数据
    if teamExp == 0 then
        local beginData = self._Model:GetBeginData()
        if beginData.StageId == stageId and not isAuto then
            teamExp = not beginData.LastPassed and stageCfg.FirstTeamExp or stageCfg.FinishTeamExp
        else
            local stageInfo = self:GetStageInfo(stageId)
            teamExp = not stageInfo.Passed and stageCfg.FirstTeamExp or stageCfg.FinishTeamExp
        end
    end

    return teamExp or 0
end

-- 异构阵线2.0战斗
function XFubenAgency:EnterMaverick2Fight(stageId, robotId, talentGroupId, talentId)
    local robotIds = { 0, 0, 0 }
    robotIds[1] = robotId

    local preFight = {}
    preFight.CardIds = { 0, 0, 0 }
    preFight.RobotIds = robotIds
    preFight.StageId = stageId
    preFight.CaptainPos = 1
    preFight.FirstFightPos = 1
    preFight.Maverick2Info = {}
    preFight.Maverick2Info.AssistTalentGroupId = talentGroupId
    preFight.Maverick2Info.AssistTalentId = talentId

    local req = { PreFightData = preFight }
    XNetwork.Call(METHOD_NAME.PreFight, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local fightData = res.FightData
        local stageInfo = self:GetStageInfo(fightData.StageId)
        local stage = self:GetStageCfg(stageId)
        if stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed) then
            -- 播放剧情，进入战斗
            self:EnterRealFight(preFight, fightData, stage.BeginStoryId)
        else
            -- 直接进入战斗
            self:EnterRealFight(preFight, fightData)
        end
    end)
end

function XFubenAgency:EnterChallenge(cb)
    XNetwork.Call(METHOD_NAME.EnterChallenge, nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then
            cb()
        end
    end)
end

function XFubenAgency:AfterInitManager()
    self:InitOutdateManager()
end

function XFubenAgency:InitOutdateManager()
    --StageCfg = XFubenConfigs.GetStageCfgs()
    --StageLevelControlCfg = XFubenConfigs.GetStageLevelControlCfg()
    --StageTransformCfg = XFubenConfigs.GetStageTransformCfg()
    --FlopRewardTemplates = XFubenConfigs.GetFlopRewardTemplates()
    --MultiChallengeConfigs = XFubenConfigs.GetMultiChallengeStageConfigs()

    self.DifficultNormal = self._Model.DifficultNormal
    self.DifficultHard = self._Model.DifficultHard
    self.DifficultVariations = self._Model.DifficultVariations
    self.DifficultNightmare = self._Model.DifficultNightmare
    self.StageStarNum = self._Model.StageStarNum
    self.NotGetTreasure = self._Model.NotGetTreasure
    self.GetTreasure = self._Model.GetTreasure
    self.FubenFlopCount = self._Model.FubenFlopCount

    self.SettleRewardAnimationDelay = self._Model.SettleRewardAnimationDelay
    self.SettleRewardAnimationInterval = self._Model.SettleRewardAnimationInterval

    XEventManager.AddEventListener(XEventId.EVENT_PLAYER_LEVEL_CHANGE, self.InitData, self)

    --region register
    self:RegisterFubenManager(self.StageType.Mainline, XDataCenter.FubenMainLineManager)
    self:RegisterFubenManager(self.StageType.Daily, XDataCenter.FubenDailyManager)
    --self:RegisterFubenManager(self.StageType.Urgent, XDataCenter.FubenUrgentEventManager)
    self:RegisterFubenManager(self.StageType.Resource, XDataCenter.FubenResourceManager)
    self:RegisterFubenManager(self.StageType.Bfrt, XDataCenter.BfrtManager)
    self:RegisterFubenManager(self.StageType.BountyTask, XDataCenter.BountyTaskManager)
    self:RegisterFubenManager(self.StageType.BossOnline, XDataCenter.FubenBossOnlineManager)
    self:RegisterFubenManager(self.StageType.Prequel, XDataCenter.PrequelManager)
    self:RegisterFubenManager(self.StageType.Trial, XDataCenter.TrialManager)
    self:RegisterFubenManager(self.StageType.Arena, XDataCenter.ArenaManager)
    self:RegisterFubenManager(self.StageType.Explore, XDataCenter.FubenExploreManager)
    --self:RegisterFubenManager(self.StageType.ActivtityBranch, XDataCenter.FubenActivityBranchManager)
    self:RegisterFubenManager(self.StageType.ActivityBossSingle, XDataCenter.FubenActivityBossSingleManager)
    self:RegisterFubenManager(self.StageType.Practice, XDataCenter.PracticeManager)
    self:RegisterFubenManager(self.StageType.Festival, XDataCenter.FubenFestivalActivityManager)
    self:RegisterFubenManager(self.StageType.BabelTower, XDataCenter.FubenBabelTowerManager)
    self:RegisterFubenManager(self.StageType.RepeatChallenge, XDataCenter.FubenRepeatChallengeManager)
    --self:RegisterFubenManager(self.StageType.RogueLike, XDataCenter.FubenRogueLikeManager)
    self:RegisterFubenManager(self.StageType.Assign, XDataCenter.FubenAssignManager)
    self:RegisterFubenManager(self.StageType.Awareness, XDataCenter.FubenAwarenessManager)
    --self:RegisterFubenManager(self.StageType.ArenaOnline, XDataCenter.ArenaOnlineManager)
    --self:RegisterFubenManager(self.StageType.UnionKill, XDataCenter.FubenUnionKillManager)
    self:RegisterFubenManager(self.StageType.ExtraChapter, XDataCenter.ExtraChapterManager)
    self:RegisterFubenManager(self.StageType.SpecialTrain, XDataCenter.FubenSpecialTrainManager)
    --self:RegisterFubenManager(self.StageType.InfestorExplore, XDataCenter.FubenInfestorExploreManager)
    self:RegisterFubenManager(self.StageType.GuildBoss, XDataCenter.GuildBossManager)
    --self:RegisterFubenManager(self.StageType.Expedition, XDataCenter.ExpeditionManager)
    --self:RegisterFubenManager(self.StageType.WorldBoss, XDataCenter.WorldBossManager)
    self:RegisterFubenManager(self.StageType.RpgTower, XDataCenter.RpgTowerManager)
    self:RegisterFubenManager(self.StageType.MaintainerAction, XDataCenter.MaintainerActionManager)
    self:RegisterFubenManager(self.StageType.TRPG, XDataCenter.TRPGManager)
    self:RegisterFubenManager(self.StageType.NieR, XDataCenter.NieRManager)
    self:RegisterFubenManager(self.StageType.ZhouMu, XDataCenter.FubenZhouMuManager)
    self:RegisterFubenManager(self.StageType.Experiment, XDataCenter.FubenExperimentManager)
    self:RegisterFubenManager(self.StageType.NewCharAct, XDataCenter.FubenNewCharActivityManager)
    self:RegisterFubenManager(self.StageType.Pokemon, XDataCenter.PokemonManager)
    --self:RegisterFubenManager(self.StageType.ChessPursuit, XDataCenter.ChessPursuitManager)
    --self:RegisterFubenManager(self.StageType.SimulatedCombat, XDataCenter.FubenSimulatedCombatManager)
    self:RegisterFubenManager(self.StageType.Stronghold, XDataCenter.StrongholdManager)
    self:RegisterFubenManager(self.StageType.Reform, XDataCenter.Reform2ndManager)
    self:RegisterFubenManager(self.StageType.PartnerTeaching, XDataCenter.PartnerTeachingManager)
    --self:RegisterFubenManager(self.StageType.Hack, XDataCenter.FubenHackManager)
    --self:RegisterFubenManager(self.StageType.CoupleCombat, XDataCenter.FubenCoupleCombatManager)
    --self:RegisterFubenManager(self.StageType.KillZone, XDataCenter.KillZoneManager)
    self:RegisterFubenManager(self.StageType.FashionStory, XDataCenter.FashionStoryManager)
    self:RegisterFubenManager(self.StageType.SuperTower, XDataCenter.SuperTowerManager)
    --self:RegisterFubenManager(self.StageType.SuperSmashBros, XDataCenter.SuperSmashBrosManager)
    --self:RegisterFubenManager(self.StageType.LivWarRace, XDataCenter.LivWarmRaceManager)
    self:RegisterFubenManager(self.StageType.AreaWar, XDataCenter.AreaWarManager)
    self:RegisterFubenManager(self.StageType.MemorySave, XDataCenter.MemorySaveManager)
    self:RegisterFubenManager(self.StageType.SpecialTrainMusic, XDataCenter.FubenSpecialTrainManager)
    self:RegisterFubenManager(self.StageType.SpecialTrainSnow, XDataCenter.FubenSpecialTrainManager)
    self:RegisterFubenManager(self.StageType.SpecialTrainRhythmRank, XDataCenter.FubenSpecialTrainManager)
    self:RegisterFubenManager(self.StageType.FubenPhoto, XDataCenter.FubenSpecialTrainManager)
    --self:RegisterFubenManager(self.StageType.Maverick, XDataCenter.MaverickManager)
    self:RegisterFubenManager(self.StageType.Theatre, XDataCenter.TheatreManager)
    self:RegisterFubenManager(self.StageType.ShortStory, XDataCenter.ShortStoryChapterManager)
    self:RegisterFubenManager(self.StageType.PivotCombat, XDataCenter.PivotCombatManager)
    self:RegisterFubenManager(self.StageType.Escape, XDataCenter.EscapeManager)
    self:RegisterFubenManager(self.StageType.GuildWar, XDataCenter.GuildWarManager)
    --self:RegisterFubenManager(self.StageType.DoubleTowers, XDataCenter.DoubleTowersManager)
    self:RegisterFubenManager(self.StageType.MultiDimSingle, XDataCenter.MultiDimManager)
    self:RegisterFubenManager(self.StageType.MultiDimOnline, XDataCenter.MultiDimManager)
    --self:RegisterFubenManager(self.StageType.MoeWarParkour, XDataCenter.MoeWarManager)
    self:RegisterFubenManager(self.StageType.SpecialTrainBreakthrough, XDataCenter.FubenSpecialTrainManager)
    self:RegisterFubenManager(self.StageType.Course, XDataCenter.CourseManager)
    self:RegisterFubenManager(self.StageType.BiancaTheatre, XDataCenter.BiancaTheatreManager)
    self:RegisterFubenManager(self.StageType.Rift, XDataCenter.RiftManager)
    self:RegisterFubenManager(self.StageType.CharacterTower, XDataCenter.CharacterTowerManager)
    self:RegisterFubenManager(self.StageType.ColorTable, XDataCenter.ColorTableManager)
    self:RegisterFubenManager(self.StageType.Maverick2, XDataCenter.Maverick2Manager)
    self:RegisterFubenManager(self.StageType.Maze, XDataCenter.MazeManager)
    self:RegisterFubenManager(self.StageType.MonsterCombat, XDataCenter.MonsterCombatManager)

    self:RegisterFubenManager(self.StageType.BrillientWalk, XDataCenter.BrilliantWalkManager)
    self:RegisterFubenManager(self.StageType.Transfinite, XDataCenter.TransfiniteManager)
    --endregion 注意：manager有初始化顺序问题，在XDataCenter创建时，副本相关的manager请放到FubenManager初始化之前

    self:InitStageLevelMap()
    self:InitStageMultiplayerLevelMap()
end

function XFubenAgency:CollectAllStageType()
    if XMain.IsWindowsEditor then
        --编辑器状态下对所有stageInfo.Type 进行收集
        local stageInfoCollect = {}
        local unUseStageIds = {}
        local stageId2Type = {}
        local stageCount = 0
        local unUseCount = 0
        for id, stageInfo in pairs(self._Model:GetStageInfos()) do
            if not XTool.IsNumberValid(stageInfo.Type) then
                unUseStageIds[#unUseStageIds + 1] = tostring(id)
                unUseCount = unUseCount + 1
            else
                stageId2Type[tostring(id)] = stageInfo.Type
                stageCount = stageCount + 1
            end
        end
        stageInfoCollect.unUseStageIds = unUseStageIds
        stageInfoCollect.stageId2Type = stageId2Type
        stageInfoCollect.stageCount = stageCount
        stageInfoCollect.unUseCount = unUseCount
        local Json = require("XCommon/Json")
        CS.System.IO.File.WriteAllText(CS.System.IO.Path.Combine(CS.UnityEngine.Application.dataPath, "StageInfo.txt"), Json.encode(stageInfoCollect))
    end
end

function XFubenAgency:RequestReboot(fightId, rebootCount, cb)
    XNetwork.Call(METHOD_NAME.FightReboot, { FightId = fightId, RebootCount = rebootCount }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
        end
        cb(res.Code == XCode.Success)
    end)
end

-- 单次挑战也能安全调用
function XFubenAgency:GetStageMaxChallengeCountSafely(stageId)
    if self:IsCanMultiChallenge(stageId) then
        return self:GetStageMaxChallengeCount(stageId)
    end

    local maxChallengeNum = self:GetStageMaxChallengeNums(stageId)
    local csInfo = XDataCenter.PrequelManager.GetUnlockChallengeStagesByStageId(stageId)
    if csInfo then
        return maxChallengeNum - csInfo.Count
    end
    return maxChallengeNum
end

-- 尼尔玩法
function XFubenAgency:EnterNieRFight(stage, curTeam)
    if not self:CheckPreFight(stage) then
        return
    end
    local preFight = {}
    preFight.CardIds = {}
    preFight.StageId = stage.StageId
    preFight.CaptainPos = curTeam.CaptainPos
    preFight.FirstFightPos = curTeam.FirstFightPos
    preFight.RobotIds = {}
    for _, v in pairs(curTeam.TeamData or {}) do
        table.insert(preFight.RobotIds, v)
    end
    XNetwork.Call(METHOD_NAME.PreFight, { PreFightData = preFight }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local fightData = res.FightData
        local stageInfo = self:GetStageInfo(fightData.StageId)
        local isKeepPlayingStory = stage and self:IsKeepPlayingStory(stage.StageId) and (stage.BeginStoryId)
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

function XFubenAgency:SetIsHideAction(value)
    self._IsHideAction = value
end

function XFubenAgency:GetIsHideAction()
    return self._IsHideAction
end

-- 多重挑战相关
function XFubenAgency:GetMultiChallengeStageConfig(stageId)
    local stageCfg = self:GetStageCfg(stageId)
    local multiChallengeId = stageCfg.MultiChallengeId
    if not multiChallengeId then
        XLog.ErrorTableDataNotFound("XFubenAgency.GetMultiChallengeStageConfig",
                "multiChallengeId", "Share/Fuben/Stage.tab", "stageId", tostring(stageId))
        return
    end

    local activityCfg = self:GetMultiChallengeStageConfigs()[multiChallengeId]
    if not activityCfg then
        XLog.ErrorTableDataNotFound("XFubenAgency.GetMultiChallengeStageConfig",
                "activityCfg", "Share/Fuben/MultiChallengeStage.tab", "multiChallengeId", tostring(multiChallengeId))
        return
    end
    return activityCfg
end

-- 获取编队类型限制对应的强制角色类型
function XFubenAgency:GetForceCharacterTypeByCharacterLimitType(characterLimitType)
    if characterLimitType == XEnumConst.FuBen.CharacterLimitType.All
            or characterLimitType == XEnumConst.FuBen.CharacterLimitType.IsomerDebuff
            or characterLimitType == XEnumConst.FuBen.CharacterLimitType.NormalDebuff then
        return
    end
    return self.DefaultCharacterTypeConvert[characterLimitType]
end

function XFubenAgency:IsNewChallengeRedPoint()
    -- 检查挑战页签的新玩法红点
    local challengeLength = self:GetNewChallengeConfigsLength()
    if not challengeLength or challengeLength <= 0 then
        return false
    end
    for i = 1, challengeLength do
        if self:JudgeCanOpen(self:GetNewChallengeFunctionId(i))
                and self:IsNewChallengeStartByIndex(i) then
            -- 检测是否新挑战已经开始
            local temp = self.NewChallengeRedPointTable[self:GetNewChallengeId(i)]
            if temp == nil then
                return true
            elseif temp ~= nil and not temp.IsClicked then
                return true
            end
        end
    end
    return false
end

-- 异聚迷宫战斗
function XFubenAgency:EnterInfestorExploreFight(stageId, team, captainPos, infestorGridId, firstFightPos)
    local stage = self:GetStageCfg(stageId)
    if not self:CheckPreFight(stage) then
        return
    end

    local preFight = {}
    preFight.CardIds = {}
    preFight.StageId = stage.StageId
    preFight.CaptainPos = captainPos
    preFight.InfestorGridId = infestorGridId
    preFight.FirstFightPos = firstFightPos

    for _, v in pairs(team) do
        table.insert(preFight.CardIds, v)
    end
    local req = { PreFightData = preFight }
    XNetwork.Call(METHOD_NAME.PreFight, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local fightData = res.FightData
        local stageInfo = self:GetStageInfo(fightData.StageId)
        if stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed) then
            -- 播放剧情，进入战斗
            self:EnterRealFight(preFight, fightData, stage.BeginStoryId)
        else
            -- 直接进入战斗
            self:EnterRealFight(preFight, fightData)
        end
    end)
end

function XFubenAgency:CheckHasNewHideStage()
    --检查是否有新的隐藏关卡
    --todo by zlb
    if self._Model._NewHideStageId then
        local cfg = self._Model:GetStageCfg(self._Model._NewHideStageId)
        local msg = CSTextManagerGetText("HideStageIsOpen", cfg.Name)
        XUiManager.TipMsg(msg, XUiManager.UiTipType.Success, function()
            self:ClearNewHideStage()
            XEventManager.DispatchEvent(XEventId.EVENT_FUNCTION_EVENT_COMPLETE)
        end)
        return true
    end
    return false
end

function XFubenAgency:GetCardExp(stageId, isAuto)
    local stageCfg = self:GetStageCfg(stageId)
    -- 角色经验
    local cardExp = stageCfg.CardExp or 0

    -- 当原字段为0时 返回新增字段数据
    if cardExp == 0 then
        local beginData = self:GetFightBeginData()
        if beginData.StageId == stageId and not isAuto then
            cardExp = not beginData.LastPassed and stageCfg.FirstCardExp or stageCfg.FinishCardExp
        else
            local stageInfo = self:GetStageInfo(stageId)
            cardExp = not stageInfo.Passed and stageCfg.FirstCardExp or stageCfg.FinishCardExp
        end
    end

    return cardExp or 0
end

--==============================--
--desc: 进入新手战斗，构造战斗数据
--time:2018-06-19 04:11:30
--@stageId:
--@charId:
--@return
--==============================--
function XFubenAgency:EnterGuideFight(guiId, stageId, chars, weapons)
    local fightData = {}
    fightData.RoleData = {}
    fightData.FightId = 1
    fightData.Online = false
    fightData.Seed = 1
    fightData.StageId = stageId

    local roleData = {}
    roleData.NpcData = {}
    table.insert(fightData.RoleData, roleData)
    roleData.Id = XPlayer.Id
    roleData.Name = CSTextManagerGetText("Aha")
    roleData.Camp = 1

    local npcData = {}
    npcData.Equips = {}
    roleData.NpcData[0] = npcData

    for _, v in pairs(chars) do
        local character = {}
        npcData.Character = character
        character.Id = v
        character.Level = 1
        character.Quality = 1
        character.Star = 1
    end

    for _, v in pairs(weapons) do
        local equipData = {}
        table.insert(npcData.Equips, equipData)
        equipData.Id = 1
        equipData.TemplateId = v
        equipData.Level = 1
        equipData.Star = 0
        equipData.Breakthrough = 0
    end

    local stage = self:GetStageCfg(stageId)
    fightData.RebootId = stage.RebootId
    fightData.DisableJoystick = stage.DisableJoystick
    fightData.DisableDeadEffect = stage.DisableDeadEffect
    local endFightCb = function()
        if stage.EndStoryId then
            XDataCenter.MovieManager.PlayMovie(stage.EndStoryId, function()
                local guideFight = XDataCenter.GuideManager.GetNextGuideFight()
                if guideFight then
                    self:EnterGuideFight(guideFight.Id, guideFight.StageId, guideFight.NpcId, guideFight.Weapon)
                else
                    XLoginManager.SetFirstOpenMainUi(true)
                    XLuaUiManager.RunMain()
                end
            end)
        else
            local guideFight = XDataCenter.GuideManager.GetNextGuideFight()
            if guideFight then
                self:EnterGuideFight(guideFight.Id, guideFight.StageId, guideFight.NpcId, guideFight.Weapon)
            else
                XLoginManager.SetFirstOpenMainUi(true)
                XLuaUiManager.RunMain()
            end
        end
    end

    local enterFightFunc = function()
        self:CallOpenFightLoading(stageId)
        local args = CS.XFightClientArgs()
        args.HideCloseButton = true
        args.RoleId = XPlayer.Id
        args.CloseLoadingCb = function()
            self:CallCloseFightLoading(stageId)
        end
        args.FinishCbAfterClear = function()
            local req = { GuideGroupId = guiId }
            XNetwork.Call(METHOD_NAME.GuideComplete, req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                endFightCb()
            end)
        end
        args.ClientOnly = true

        -- CS.XUiManager.Instance:ReleaseUiScene("UiActivityBriefBase")
        CS.XFight.Enter(fightData, args)
    end

    if stage.BeginStoryId then
        XDataCenter.MovieManager.PlayMovie(stage.BeginStoryId, enterFightFunc)
    else
        enterFightFunc()
    end
end

function XFubenAgency:GetStageRelationInfos()
    return self._Model:GetStageRelationInfos()
end

function XFubenAgency:IsCanMultiChallenge(stageId)
    local stageCfg = self:GetStageCfg(stageId)
    return XTool.IsNumberValid(stageCfg.MultiChallengeId)
end

function XFubenAgency:InitStageMultiplayerLevelMap()
    self._Model:InitStageMultiplayerLevelMap()
end

--杀戮无双
function XFubenAgency:EnterKillZoneFight(stage, curTeam)
    if not self:CheckPreFight(stage) then
        return
    end
    local preFight = {}
    preFight.CardIds = {}
    preFight.StageId = stage.StageId
    preFight.CaptainPos = curTeam.CaptainPos
    preFight.FirstFightPos = curTeam.FirstFightPos
    preFight.RobotIds = {}
    for _, v in pairs(curTeam.TeamData or {}) do
        if not XRobotManager.CheckIsRobotId(v) then
            table.insert(preFight.CardIds, v)
            table.insert(preFight.RobotIds, 0)
        else
            table.insert(preFight.CardIds, 0)
            table.insert(preFight.RobotIds, v)
        end
    end

    XNetwork.Call(METHOD_NAME.PreFight, { PreFightData = preFight }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local fightData = res.FightData
        self:EnterRealFight(preFight, fightData)
    end)
end

function XFubenAgency:RequestCreateRoom(stage, cb)
    if self:CheckPreFight(stage) then
        XDataCenter.RoomManager.CreateRoom(stage.StageId, cb)
    end
end

function XFubenAgency:GetUnlockHideStageById(stageId)
    -- todo by zlb
    return self._Model._UnlockHideStages[stageId]
end

function XFubenAgency:CheckChallengeCount(stageId, count)
    local stageExCfg = self:GetMultiChallengeStageConfig(stageId)
    return stageExCfg.MultiChallengeMin <= count and count <= stageExCfg.MultiChallengeMax
end

function XFubenAgency:HandleBeforeFinishFight()
    --todo by zlb
    self._Model._FubenSettling = false
    self._Model._FubenSettleResult = nil

    --通知战斗结束，关闭战斗设置页面
    CS.XGameEventManager.Instance:Notify(XEventId.EVENT_FIGHT_FINISH)
    -- 恢复回系统音声设置 避免战斗里将BGM音量设置为0导致结算后没有声音
    XSoundManager.ResetSystemAudioVolume()
end

function XFubenAgency:ClearNewHideStage()
    --消除新的隐藏关卡记录
    self._Model._NewHideStageId = nil
end

function XFubenAgency:RegisterFubenManager(type, manager)
    if not manager then
        XLog.Error("[XFubenAgency] manager is removed:", type)
        return
    end
    if manager.InitStageInfo then
        if not self:IsConfigToInitStageInfo(type) then
            if type > XEnumConst.FuBen.StageType.Transfinite then
                XLog.Error("[XFubenAgency] stageType从83以后，请策划配置，不要增加initStageInfo:" .. type)
            end
        end
    end

    for k, processFunc in pairs(XEnumConst.FuBen.ProcessFunc) do
        local handler = manager[k]
        if handler then
            self._Model:RegisterOldRegFubenDict(type, processFunc, handler)
        end
    end

    if manager.SettleFight then
        XLog.Error("不要重写 SettleFight ")
    end
end

--2.10:新增log参数输出异常情况下的计算信息
function XFubenAgency:GetStageMaxChallengeCount(stageId,enableLog)
    local log={}

    local stageExCfg = self:GetMultiChallengeStageConfig(stageId)
    local maxTimes = stageExCfg.MultiChallengeMax
    
    local requirePoint = self:GetRequireActionPoint(stageId)

    local ownActionPoint = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.ActionPoint)

    local times1 = requirePoint ~= 0 and math.floor(ownActionPoint / requirePoint) or maxTimes

    local exItemId, exItemCount = self:GetStageExCost(stageId)

    local ownExItemCount = exItemId ~= 0 and XDataCenter.ItemManager.GetCount(exItemId) or 0

    local times2 = exItemCount ~= 0 and math.floor(ownExItemCount / exItemCount) or maxTimes
    
    --2.10追加log输出
    if enableLog then
        XLog.Error('--------------------开始一次最大挑战计算-------------------------')
        table.insert(log,'--->当前关卡配置的挑战上限为:'..maxTimes..'\n')
        table.insert(log,'--->当前关卡配置的单次挑战行动点消耗数:'..requirePoint..'\n')
        table.insert(log,'--->玩家拥有的行动点数:'..ownActionPoint..'\n')
        table.insert(log,'--->根据行动点数计算的玩家可挑战最大次数为:'..times1..'\n')
        table.insert(log,'--->判断该关卡是否有额外消耗: 道具Id:'..exItemId..'单次消耗:'..exItemCount..'玩家拥有数:'..ownExItemCount..'\n')
        table.insert(log,'--->根据可能存在的额外消耗计算的最大可挑战次数:'..times2..'\n')
        table.insert(log,'--->两者取最小得到的最终可挑战次数'..math.min(times1, math.min(times2, maxTimes))..'\n')
        XLog.Error(table.concat(log))
    end

    return math.min(times1, math.min(times2, maxTimes))
end

-- 挑战进入前检查是否结算中
function XFubenAgency:CheckChallengeCanEnter(cb, challengeId)
    local req = { ChallengeId = challengeId }
    XNetwork.Call(METHOD_NAME.CheckChallengeCanEnter, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then
            cb()
        end
    end)
end

-- 超级据点战斗
function XFubenAgency:EnterStrongholdFight(stageId, characterIds, captainPos, firstFightPos)
    local stage = self:GetStageCfg(stageId)
    if not self:CheckPreFight(stage) then
        return
    end

    local preFight = {}
    preFight.CardIds = characterIds
    preFight.StageId = stage.StageId
    preFight.CaptainPos = captainPos
    preFight.FirstFightPos = firstFightPos

    local req = { PreFightData = preFight }
    XNetwork.Call(METHOD_NAME.PreFight, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local fightData = res.FightData
        local stageInfo = self:GetStageInfo(fightData.StageId)
        if stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed) then
            -- 播放剧情，进入战斗
            self:EnterRealFight(preFight, fightData, stage.BeginStoryId)
        else
            -- 直接进入战斗
            self:EnterRealFight(preFight, fightData)
        end
    end)
end

function XFubenAgency:NewHideStage(id)
    --记录新的隐藏关卡
    self._Model:SetNewHideStage(id)
end

function XFubenAgency:CheckPrologueIsPass()
    return self.CheckStageIsPass(self.LastPrologueStageId)
end

function XFubenAgency:CheckFightCondition(conditionIds, teamId)
    if #conditionIds <= 0 then
        return true
    end

    local teamData = nil
    if teamId then
        teamData = XDataCenter.TeamManager.GetTeamData(teamId)
    end

    for _, id in pairs(conditionIds) do
        local ret, desc = XConditionManager.CheckCondition(id, teamData)
        if not ret then
            XUiManager.TipError(desc)
            return false
        end
    end
    return true
end

function XFubenAgency:RequestMatchRoom(stage, cb)
    if self:CheckPreFight(stage) then
        XDataCenter.RoomManager.Match(stage.StageId, cb)
    end
end

function XFubenAgency:UpdateStageStarsInfo(data)
    if data == nil or type(data) ~= "table" then
        return
    end
    for _, v in pairs(data) do
        local stageInfo = self._Model:GetStageInfo(v.StageId)
        stageInfo.Stars, stageInfo.StarsMap = self._Model:GetStarsCount(v.StarsMark)
    end
end

function XFubenAgency:DebugGetStageInfos()
    return self._Model:GetStageInfos()
end

function XFubenAgency:GetStageBuyChallengeCount(stageId)
    local stageCfg = self._Model:GetStageCfg(stageId, true)
    return stageCfg and stageCfg.BuyChallengeCount or 0
end

function XFubenAgency:ReconnectFight()
    -- 获取fightData
    XNetwork.Call(METHOD_NAME.GetFightData, nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        -- 构造preFightData
        local fightData = res.FightData
        local preFightData = {}
        preFightData.CardIds = {}
        preFightData.StageId = fightData.StageId
        for i = 1, #fightData.RoleData do
            local role = fightData.RoleData[i]
            if role.Id == XPlayer.Id then
                for j = 1, #role.NpcData do
                    local npc = role.NpcData[j]
                    table.insert(preFightData.CardIds, npc.Character.Id)
                end
                break
            end
        end

        self:EnterRealFight(preFightData, fightData, nil, nil, true)
    end)
end

-- 战斗黑幕关调试面板调用
function XFubenAgency:GetStageRebootId(stageId)
    local stageCfg = self._Model:GetStageCfg(stageId, true)
    if not stageCfg then
        return 0
    end
    return stageCfg.RebootId
end

-- 大秘境战斗
---@param xTeam XRiftTeam
function XFubenAgency:EnterRiftFight(xTeam, xStageGroup, index)
    local xRiftStage = xStageGroup:GetAllEntityStages()[index]
    local stage = self:GetStageCfg(xRiftStage.StageId)
    if not self:CheckPreFight(stage) then
        return
    end

    local captainPos = xTeam:GetCaptainPos()
    local firstFightPos = xTeam:GetFirstFightPos()
    local characterIds = {}
    local robotIds = {}
    for k, roleId in pairs(xTeam:GetEntityIds()) do
        if XTool.IsNumberValid(roleId) then
            local xRole = XDataCenter.RiftManager.GetEntityRoleById(roleId)
            robotIds[k] = not xRole:GetIsRobot() and 0 or roleId
            characterIds[k] =  xRole:GetIsRobot() and 0 or roleId
        else
            robotIds[k] = 0
            characterIds[k] = 0
        end
    end
    local preFight = {}
    preFight.CardIds = characterIds
    preFight.RobotIds = robotIds
    preFight.StageId = xTeam:IsLuckyStage() and XDataCenter.RiftManager:GetLuckStageId() or stage.StageId
    preFight.CaptainPos = captainPos
    preFight.FirstFightPos = firstFightPos
    preFight.RiftInfo =
    {
        ChapterId = xStageGroup:GetParent():GetParent():GetId(),
        LayerId = xStageGroup:GetParent():GetId(),
        -- 节点对应位置, -1表示幸运节点
        NodeIdx = xTeam:IsLuckyStage() and -1 or xStageGroup:GetId(),
        StageIdx = index,
    }

    local req = { PreFightData = preFight }
    XNetwork.Call(METHOD_NAME.PreFight, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local fightData = res.FightData
        local stageInfo = self:GetStageInfo(fightData.StageId)
        if stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed) then
            -- 播放剧情，进入战斗
            self:EnterRealFight(preFight, fightData, stage.BeginStoryId)
        else
            -- 直接进入战斗
            self:EnterRealFight(preFight, fightData)
        end
    end)
end

function XFubenAgency:GetPlayerStageData()
    return self._Model._PlayerStageData
end

--- 获取关卡传出参数的值
---@param stageId number 关卡Id
---@param eventId number 参数Id
function XFubenAgency:GetStageEventValue(stageId, eventId)
    return self._Model:GetStageEventValue(stageId, eventId)
end

function XFubenAgency:InitStageInfo()
    self._Model:InitStageInfo()
end

-- 跑团世界boss
function XFubenAgency:EnterTRPGWorldBossFight(stage, curTeam)
    if not XFubenAgency:CheckPreFight(stage) then
        return
    end
    local preFight = {}
    preFight.CardIds = {}
    preFight.StageId = stage.StageId
    preFight.CaptainPos = curTeam.CaptainPos
    preFight.FirstFightPos = curTeam.FirstFightPos
    preFight.RobotIds = {}
    for _, v in pairs(curTeam.TeamData or {}) do
        if v > NotRobotId then
            table.insert(preFight.CardIds, v)
            table.insert(preFight.RobotIds, 0)
        else
            local cardId = XRobotManager.GetCharacterId(v)
            table.insert(preFight.CardIds, cardId)
            table.insert(preFight.RobotIds, v)
        end
    end

    XNetwork.Call(METHOD_NAME.PreFight, { PreFightData = preFight }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local fightData = res.FightData
        self.EnterRealFight(preFight, fightData)
    end)
end

-- 世界boss
function XFubenAgency:EnterWorldBossFight(stage, curTeam, stageLevel)
    local preFight = {}
    preFight.CardIds = {}
    preFight.StageId = stage.StageId
    preFight.CaptainPos = curTeam.CaptainPos
    preFight.FirstFightPos = curTeam.FirstFightPos
    preFight.RobotIds = {}
    preFight.StageLevel = stageLevel
    for _, v in pairs(curTeam.TeamData or {}) do
        if not XRobotManager.CheckIsRobotId(v) then
            table.insert(preFight.CardIds, v)
            table.insert(preFight.RobotIds, 0)
        else
            local cardId = XRobotManager.GetCharacterId(v)
            table.insert(preFight.CardIds, cardId)
            table.insert(preFight.RobotIds, v)
        end
    end

    XNetwork.Call(METHOD_NAME.PreFight, { PreFightData = preFight }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local fightData = res.FightData
        local stageInfo = self:GetStageInfo(fightData.StageId)
        local isKeepPlayingStory = stage and self:IsKeepPlayingStory(stage.StageId) and (stage.BeginStoryId)
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

function XFubenAgency:GetActivityChaptersBySort()
    local chapters = XTool.MergeArray(
            XDataCenter.FubenBossOnlineManager.GetBossOnlineChapters()--联机boss
    --, XDataCenter.FubenActivityBranchManager.GetActivitySections()--副本支线活动
    , XDataCenter.FubenActivityBossSingleManager.GetActivitySections()--单挑BOSS活动
    , XDataCenter.FubenFestivalActivityManager.GetAvailableFestivals()--节日活动副本
    , XDataCenter.FubenBabelTowerManager.GetBabelTowerSection()--巴别塔计划
    , XDataCenter.FubenRepeatChallengeManager.GetActivitySections()--复刷本
    --, XDataCenter.FubenRogueLikeManager.GetRogueLikeSection()--爬塔系统
    -- , XDataCenter.ArenaOnlineManager.GetArenaOnlineChapters() --  删除合众战局玩法
    --, XDataCenter.FubenUnionKillManager.GetUnionKillActivity()--狙击战
    , XDataCenter.FubenSpecialTrainManager.GetSpecialTrainAcitity()--特训关
    --, XDataCenter.ExpeditionManager.GetActivityChapters()--虚像地平线
    --, XDataCenter.WorldBossManager.GetWorldBossSection()--世界Boss
    , XDataCenter.RpgTowerManager.GetActivityChapters()--兵法蓝图
    , XDataCenter.NieRManager.GetActivityChapters()--尼尔玩法
    , XDataCenter.FubenNewCharActivityManager.GetAvailableActs()-- 新角色预热活动
    --, XDataCenter.FubenSimulatedCombatManager.GetAvailableActs()-- 模拟作战
    --, XDataCenter.FubenHackManager.GetAvailableActs()-- 骇入玩法
    , XDataCenter.PokemonManager.GetActivityChapters()--口袋战双
    --, XDataCenter.ChessPursuitManager.GetActivityChapters()--追击玩法
    --, XDataCenter.MoeWarManager.GetActivityChapter()-- 萌战玩法
    , XMVCA.XReform:GetAvailableChapters()-- 改造玩法
    , XDataCenter.PokerGuessingManager.GetChapters()--翻牌猜大小
    --, XDataCenter.KillZoneManager.GetActivityChapters()--杀戮无双
    , XDataCenter.FashionStoryManager.GetActivityChapters()-- 系列涂装剧情活动
    , XDataCenter.SuperTowerManager.GetActivityChapters()--超级爬塔活动
    --, XDataCenter.FubenCoupleCombatManager.GetAvailableActs()-- 双人玩法
    , XDataCenter.SameColorActivityManager.GetAvailableChapters()
    --, XDataCenter.SuperSmashBrosManager.GetActivityChapters()--超限乱斗
    , XDataCenter.AreaWarManager.GetActivityChapters()--全服决战
    , XDataCenter.MemorySaveManager.GetActivityChapters()-- 周年意识营救战
    --, XDataCenter.MaverickManager.GetActivityChapters()--射击玩法
    , XDataCenter.NewYearLuckManager.GetActivityChapters()--奖券小游戏
    , XDataCenter.PivotCombatManager.GetActivityChapters()--sp枢纽作战
    , XDataCenter.EscapeManager.GetActivityChapters()--大逃杀玩法
    --, XDataCenter.DoubleTowersManager.GetActivityChapters()--动作塔防
    , XDataCenter.RpgMakerGameManager.GetActivityChapters()--推箱子小游戏
    , XDataCenter.MultiDimManager.GetActivityChapters()--多维挑战
    , XMVCA:GetAgency(ModuleId.XTaikoMaster):GetActivityChapters()--音游
    , XDataCenter.DoomsdayManager.GetActivityChapters()--模拟经营
    )
    table.sort(chapters, function(a, b)
        local priority1 = self._Model:GetActivityPriorityByActivityIdAndType(a.Id, a.Type)
        local priority2 = self._Model:GetActivityPriorityByActivityIdAndType(b.Id, b.Type)
        return priority1 > priority2
    end)

    return chapters
end

--光辉同行
function XFubenAgency:EnterBrilliantWalkFight(stage)
    if not self:CheckPreFight(stage) then
        return
    end
    local preFight = self._Model.PreFightHandler[self.StageType.BrillientWalk](stage)
    self._Model.CustomOnEnterFightHandler[self.StageType.BrillientWalk](preFight,
            function(response)
                if response.Code ~= XCode.Success then
                    XUiManager.TipCode(response.Code)
                    return
                end
                local fightData = response.FightData
                local stageInfo = self:GetStageInfo(fightData.StageId)
                if stage and stage.BeginStoryId and (not stageInfo or not stageInfo.Passed) then
                    -- 播放剧情，进入战斗
                    self:EnterRealFight(preFight, fightData, stage.BeginStoryId)
                else
                    -- 直接进入战斗
                    self:EnterRealFight(preFight, fightData)
                end
            end)
end

function XFubenAgency:GetStageLevelMap()
    return self._Model:GetStageLevelMap()
end

return XFubenAgency