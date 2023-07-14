local XRpgMakerGameActivityDb = require("XEntity/XRpgMakerGame/XRpgMakerGameActivityDb")
local XRpgMakerGameEnterStageDb = require("XEntity/XRpgMakerGame/XRpgMakerGameEnterStageDb")
local XRpgMakerGameEndPoint = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameEndPoint")
local XRpgMakerGameMonsterData = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameMonsterData")
local XRpgMakerGamePlayer = require("XEntity/XRpgMakerGame/Object/XRpgMakerGamePlayer")
local XRpgMakerGameTriggerData = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameTriggerData")
local XRpgMakerGameShadow = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameShadow")
local XRpgMakerGameElectricFence = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameElectricFence")
local XRpgMakerGameTrasfer = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameTrasfer")
local XRpgMakerGameGrassData = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameGrassData")
local XRpgMakerGameSteelData = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameSteelData")
local XRpgMakerGameWaterData = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameWaterData")
local XUiRpgMakerGamePlayScene = require("XUi/XUiRpgMakerGame/PlayMain/XUiRpgMakerGamePlayScene")

XRpgMakerGameManagerCreator = function()
    local tableInsert = table.insert
    local tableSort = table.sort
    local tableRemove = table.remove
    local tonumber = tonumber
    local pairs = pairs
    local CSXTextManagerGetText = CS.XTextManager.GetText
    local stringFormat = string.format

    local RpgMakerGameActivityDb = XRpgMakerGameActivityDb.New()
    local RpgMakerGameEnterStageDb = XRpgMakerGameEnterStageDb.New()
    local PlayerObj = XRpgMakerGamePlayer.New()
    local EndPointObj = XRpgMakerGameEndPoint.New()
    local GameMonsterObjDic = {}    --怪物对象字典
    local TriggerObjDic = {}        --机关对象字典
    local Actions = {}          --状态列表
    local CurrentCount = 0      --当前回合数
    local CurrentScene = XUiRpgMakerGamePlayScene.New()
    local CurrTabGroupIndexByUiMainTemp     --缓存主界面选择的chapter对应的TabGroupIndex
    local HaveOpenChapterIdList = {}        --缓存章节开启情况
    local HaveOpenChapterGroupIdList = {}   --缓存章节组开启情况
    local _CurrentLockReqReset       --重置协议锁
    local _CurrentReqMoveLock   --请求移动协议结果未处理之前不允许接着请求
    local ClickObjectCallback       --点击场景对象回调
    local PointerDownObjectCallback     --按下场景对象回调
    local PointerUpObjectCallback       --松开按下的场景对象回调
    local ShadowObjDic = {}     --影子对象字典
    local ElectricFenceObjDic = {}     --电网对象
    local GrassObjDic = {}  --草圃对象字典
    local TransferPointObjDic = {} --传送点对象字典
    local SteelObjDic = {}  --钢板对象字典
    local WaterObjDic = {}  --水、冰对象字典

    ---------------------本地接口 begin------------------
    local InitMonsetObj = function(mapId)
        GameMonsterObjDic = {}
        local monsterIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToMonsterIdList(mapId)
        for _, monsterId in ipairs(monsterIdList) do
            GameMonsterObjDic[monsterId] = XRpgMakerGameMonsterData.New(monsterId)
        end
    end

    local ClearMonsterObj = function()
        for _, monsterObj in pairs(GameMonsterObjDic) do
            monsterObj:Dispose()
        end
        GameMonsterObjDic = {}
    end

    local ResetMonsetObj = function()
        for _, monsterObj in pairs(GameMonsterObjDic) do
            monsterObj:InitData()
        end
    end

    local InitTriggerObjDic = function(mapId)
        TriggerObjDic = {}
        local triggerIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToTriggerIdList(mapId)
        for _, triggerId in ipairs(triggerIdList) do
            TriggerObjDic[triggerId] = XRpgMakerGameTriggerData.New(triggerId)
        end
    end

    local ClearTriggerObj = function()
        for _, triggerObj in pairs(TriggerObjDic) do
            triggerObj:Dispose()
        end
        TriggerObjDic = {}
    end

    local ResetTriggerObj = function()
        for _, triggerObj in pairs(TriggerObjDic) do
            triggerObj:InitData()
        end
    end

    local LockReqMove = function()
        _CurrentReqMoveLock = true
    end

    local UnLockReqMove = function()
        _CurrentReqMoveLock = nil
    end

    local IsLockReqMove = function()
        return _CurrentReqMoveLock or false
    end

    local ResetStepCount = function()
        XDataCenter.RpgMakerGameManager.SetCurrentCount(0)
    end

    local InsertAction = function(action)
        tableInsert(Actions, action)
    end

    --检查设置播放电网机关音效（多个电网机关状态改变只播放一次音效）
    local CheckSetPlayElectricStatusSwitchSound = function(actions)
        local triggerObj
        local triggerId
        for _, action in ipairs(actions or {}) do
            triggerId = action.TriggerId or action.Id
            triggerObj = XDataCenter.RpgMakerGameManager.GetTriggerObj(triggerId)
            if triggerObj and XRpgMakerGameConfigs.GetRpgMakerGameTriggerType(triggerId) == XRpgMakerGameConfigs.XRpgMakerGameTriggerType.TriggerElectricFence then
                triggerObj:SetIsPlayElectricStatusSwitchSound(true)
                return
            end
        end
    end
    
    local LockReqReset = function()
        _CurrentLockReqReset = true
    end

    local UnLockReqReset = function()
        _CurrentLockReqReset = nil
    end

    local IsLockReqReset = function()
        return _CurrentLockReqReset or false
    end

    local InitShadowObj = function(mapId)
        ShadowObjDic = {}
        local shadowIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToShadowIdList(mapId)
        for _, shadowId in ipairs(shadowIdList) do
            ShadowObjDic[shadowId] = XRpgMakerGameShadow.New(shadowId)
        end
    end

    local ClearShadowObj = function()
        for _, shadowObj in pairs(ShadowObjDic) do
            shadowObj:Dispose()
        end
        ShadowObjDic = {}
    end

    local ResetShadowObj = function()
        for _, shadowObj in pairs(ShadowObjDic) do
            shadowObj:InitData()
        end
    end

    local InitElectricFenceObj = function(mapId)
        ElectricFenceObjDic = {}
        local idList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToElectricFenceIdList(mapId)
        for _, id in ipairs(idList) do
            ElectricFenceObjDic[id] = XRpgMakerGameElectricFence.New(id)
        end
    end

    local SetElectricFenceStatus = function(electricStatus)
        for _, obj in pairs(ElectricFenceObjDic) do
            obj:SetElectricStatus(electricStatus)
        end
    end

    local ClearElectricFencebj = function()
        for _, obj in pairs(ElectricFenceObjDic) do
            obj:Dispose()
        end
        ElectricFenceObjDic = {}
    end

    local ResetElectricFenceObj = function()
        for _, obj in pairs(ElectricFenceObjDic) do
            obj:InitData()
        end
    end

    --传送点
    local InitTransferPointObj = function(mapId)
        TransferPointObjDic = {}
        local idList = XRpgMakerGameConfigs.GetMapIdToTransferPointIdList(mapId)
        for _, id in ipairs(idList) do
            TransferPointObjDic[id] = XRpgMakerGameTrasfer.New(id)
        end
    end

    local ClearTransferPointObj = function()
        for _, obj in pairs(TransferPointObjDic) do
            obj:Dispose()
        end
        TransferPointObjDic = {}
    end

    --实体对象
    local InitEntityObj = function(mapId)
        GrassObjDic = {}
        SteelObjDic = {}
        WaterObjDic = {}
        local entityType
        local idList = XRpgMakerGameConfigs.GetMapIdToEntityIdList(mapId)
        for _, id in ipairs(idList) do
            entityType = XRpgMakerGameConfigs.GetEntityType(id)
            if entityType == XRpgMakerGameConfigs.XRpgMakerGameEntityType.Water or entityType == XRpgMakerGameConfigs.XRpgMakerGameEntityType.Ice then
                WaterObjDic[id] = XRpgMakerGameWaterData.New(id)
                WaterObjDic[id]:SetStatus(entityType == XRpgMakerGameConfigs.XRpgMakerGameEntityType.Water and
                    XRpgMakerGameConfigs.XRpgMakerGameWaterType.Water or
                    XRpgMakerGameConfigs.XRpgMakerGameWaterType.Ice)
            elseif entityType == XRpgMakerGameConfigs.XRpgMakerGameEntityType.Grass then
                GrassObjDic[id] = XRpgMakerGameGrassData.New(id)
            elseif entityType == XRpgMakerGameConfigs.XRpgMakerGameEntityType.Steel then
                SteelObjDic[id] = XRpgMakerGameSteelData.New(id)
            end
        end
    end

    local ClearEntityObj = function()
        for _, obj in pairs(GrassObjDic) do
            obj:Dispose()
        end
        for _, obj in pairs(SteelObjDic) do
            obj:Dispose()
        end
        for _, obj in pairs(WaterObjDic) do
            obj:Dispose()
        end
        GrassObjDic = {}
        SteelObjDic = {}
        WaterObjDic = {}
    end

    local ResetEntityObj = function()
        for _, obj in pairs(GrassObjDic) do
            obj:InitData()
        end
        for _, obj in pairs(SteelObjDic) do
            obj:InitData()
        end
        for _, obj in pairs(WaterObjDic) do
            obj:InitData()
        end
    end

    local GetCurrClearButtonGroupIndexCookieKey = function()
        local activityId = XRpgMakerGameConfigs.GetDefaultActivityId()
        return "RpgMakerGameCurrClearButtonGroupIndex" .. XPlayer.Id .. activityId
    end

    local GetHaveOpenChapterIdListCookieKey = function ()
        local activityId = XRpgMakerGameConfigs.GetDefaultActivityId()
        return "RpgMakerGameChapterIdList" .. XPlayer.Id .. activityId
    end

    local GetHaveOpenChapterGroupIdListCookieKey = function ()
        local activityId = XRpgMakerGameConfigs.GetDefaultActivityId()
        return "RpgMakerGameChapterGroupIdList" .. XPlayer.Id .. activityId
    end
    ---------------------本地接口 end--------------------

    local XRpgMakerGameManager = {}
    -----------------功能入口 begin----------------
    function XRpgMakerGameManager.GetRpgMakerGameStageStatus(rpgMakerGameStageId)
        local stageIsClear = XRpgMakerGameManager.IsStageClear(rpgMakerGameStageId)
        if stageIsClear then
            return XRpgMakerGameConfigs.RpgMakerGameStageStatus.Clear
        end

        local preStage = XRpgMakerGameConfigs.GetRpgMakerGameStagePreStage(rpgMakerGameStageId)
        local preStageIsClear = not XTool.IsNumberValid(preStage) and true or XRpgMakerGameManager.IsStageClear(preStage)
        if preStageIsClear then
            return XRpgMakerGameConfigs.RpgMakerGameStageStatus.UnLock
        end

        return XRpgMakerGameConfigs.RpgMakerGameStageStatus.Lock
    end

    function XRpgMakerGameManager.IsStageClear(stageId)
        local stageDb = XRpgMakerGameManager.GetRpgMakerActivityStageDb(stageId)
        return stageDb:IsStageClear()
    end

    function XRpgMakerGameManager.CheckActivityIsOpen(isNotShowTips)
        local id = XRpgMakerGameConfigs.GetDefaultActivityId()
        local timeId = XRpgMakerGameConfigs.GetRpgMakerGameActivityTimeId(id)
        if not XFunctionManager.CheckInTimeByTimeId(timeId) then
            if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
                return false
            end

            if not isNotShowTips then
                XUiManager.TipText("ActivityMainLineEnd")
                XLuaUiManager.RunMain()
            end
            return false
        end
        return true
    end

    function XRpgMakerGameManager.GetActivityTime()
        local id = XRpgMakerGameConfigs.GetDefaultActivityId()
        local timeId = XRpgMakerGameConfigs.GetRpgMakerGameActivityTimeId(id)
        return XFunctionManager.GetTimeByTimeId(timeId)
    end

    function XRpgMakerGameManager.CheckActivityCondition()
        local functionId = XFunctionManager.FunctionName.RpgMakerActivity
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        local desc = XFunctionManager.GetFunctionOpenCondition(functionId)
        if not isOpen then
            XUiManager.TipMsg(desc)
        end
        return isOpen, desc
    end
    
    function XRpgMakerGameManager.CheckRedPoint()
        local groupId = XRpgMakerGameManager.GetCurrTaskTimeLimitId()
        return XDataCenter.TaskManager.CheckLimitTaskList(groupId)
    end

    --所有章节组小红点
    function XRpgMakerGameManager.CheckAllChapterGroupRedPoint()
        local haveChapterGroupIdList = XRpgMakerGameManager.GetHaveOpenChapterGroupIdList()
        local groupIdList = XRpgMakerGameConfigs.GetRpgMakerGameChapterGroupIdList()
        local openListCount = 0
        local timeId, isOpen
        for _, groupId in ipairs(groupIdList) do
            timeId = XRpgMakerGameConfigs.GetChapterGroupOpenTimeId(groupId)
            isOpen = XFunctionManager.CheckInTimeByTimeId(timeId)
            openListCount = openListCount + (isOpen and 1 or 0)
        end
        
        return #haveChapterGroupIdList < openListCount
    end

    --章节组小红点
    function XRpgMakerGameManager.CheckChapterGroupBtnRedPoint(chapterGroupId)
        local haveChapterGroupIdList = XRpgMakerGameManager.GetHaveOpenChapterGroupIdList()
        local timeId = XRpgMakerGameConfigs.GetChapterGroupOpenTimeId(chapterGroupId)
        local isOpen = XFunctionManager.CheckInTimeByTimeId(timeId)
        for _,v in ipairs(haveChapterGroupIdList) do
            if chapterGroupId == v or not isOpen then return false end
        end
        return true
    end

    --春节章节小红点
    function XRpgMakerGameManager.CheckFirstChapterGroupRedPoint()
        local groupIdList = XRpgMakerGameConfigs.GetRpgMakerGameChapterGroupIdList()
        local flag
        
        for _,v in ipairs(groupIdList) do
            if XRpgMakerGameConfigs.GetChapterGroupIsFirstShow(v) then
                flag = v
            end
        end
        local haveChapterIdList = XRpgMakerGameConfigs.GetRpgMakerGameChapterIdList(flag)
        
        for _, v in ipairs(haveChapterIdList) do
            if XRpgMakerGameManager.CheckChapterBtnRedPoint(v) then return true end
        end
        return false
    end

    --单个章节小红点
    function XRpgMakerGameManager.CheckChapterBtnRedPoint(chapterId)
        local haveChapterIdList = XRpgMakerGameManager.GetHaveOpenChapterIdList()
        for _,v in ipairs(haveChapterIdList) do
            if chapterId == v then return false end
        end
        return XRpgMakerGameManager.IsChapterUnLock(chapterId)
    end

    function XRpgMakerGameManager.GetActivityChapters()
        local chapters = {}
        if XRpgMakerGameManager.CheckActivityIsOpen(true) then
            local temp = {}
            local activityId = XRpgMakerGameConfigs.GetDefaultActivityId()
            temp.Id = activityId
            temp.Name = XRpgMakerGameConfigs.GetActivityName(activityId)
            temp.BannerBg = XRpgMakerGameConfigs.GetActivityBannerBg(activityId)
            temp.Type = XDataCenter.FubenManager.ChapterType.RpgMakerGame
            table.insert(chapters, temp)
        end
        return chapters
    end
    -----------------功能入口 end------------------

    -----------------主界面 begin------------------
    function XRpgMakerGameManager.GetRpgMakerActivityStageDb(stageCfgId)
        return RpgMakerGameActivityDb:GetStageDb(stageCfgId)
    end

    function XRpgMakerGameManager.GetRpgMakerChapterClearStarCount(chapterId)
        local stageIdList = XRpgMakerGameConfigs.GetRpgMakerGameStageIdList(chapterId)
        local stageDb
        local starCount = 0
        for _, stageId in ipairs(stageIdList) do
            stageDb = XRpgMakerGameManager.GetRpgMakerActivityStageDb(stageId)
            if stageDb then
                starCount = starCount + stageDb:GetStarCount()
            end
        end
        return starCount
    end

    function XRpgMakerGameManager.IsChapterUnLock(chapterId)
        if not XTool.IsNumberValid(chapterId) then
            return true
        end
        local timeId = XRpgMakerGameConfigs.GetRpgMakerGameChapterOpenTimeId(chapterId)
        return XFunctionManager.CheckInTimeByTimeId(timeId)
    end

    function XRpgMakerGameManager.IsStageUnLock(stageId)
        local stageStatus = XRpgMakerGameManager.GetRpgMakerGameStageStatus(stageId)
        if stageStatus ~= XRpgMakerGameConfigs.RpgMakerGameStageStatus.Lock then
            return true
        end

        local preStage = XRpgMakerGameConfigs.GetRpgMakerGameStagePreStage(stageId)
        local preStageName = XRpgMakerGameConfigs.GetRpgMakerGameStageName(preStage)
        local desc = CS.XTextManager.GetText("RpgMakerGameStageNotOpen", preStageName)
        return false, desc
    end

    function XRpgMakerGameManager.GetCurrTaskTimeLimitId()
        local activityId = XRpgMakerGameConfigs.GetDefaultActivityId()
        return XRpgMakerGameConfigs.GetRpgMakerGameActivityTaskTimeLimitId(activityId)
    end

    function XRpgMakerGameManager.GetTimeLimitTask()
        local groupId = XRpgMakerGameManager.GetCurrTaskTimeLimitId()
        return XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(groupId)
    end

    function XRpgMakerGameManager.SetCurrTabGroupIndexByUiMainTemp(currTabGroupIndexByUiMainTemp)
        CurrTabGroupIndexByUiMainTemp = currTabGroupIndexByUiMainTemp
    end

    function XRpgMakerGameManager.SetCurrClearButtonGroupIndex()
        local cookieKey = GetCurrClearButtonGroupIndexCookieKey()
        XSaveTool.SaveData(cookieKey, CurrTabGroupIndexByUiMainTemp)
    end

    function XRpgMakerGameManager.GetCurrClearButtonGroupIndex()
        local cookieKey = GetCurrClearButtonGroupIndexCookieKey()
        return XSaveTool.GetData(cookieKey)
    end

    function XRpgMakerGameManager.GetDefaultChapterGroupId()
        local chapterGroupId = XRpgMakerGameConfigs.GetDefaultChapterGroupId()
        local timeId = XRpgMakerGameConfigs.GetChapterGroupOpenTimeId(chapterGroupId)
        
        if XFunctionManager.CheckInTimeByTimeId(timeId, true) then
            return chapterGroupId
        end
        
        --返回最新且已开启的章节组Id
        local chapterGroupIdList = XRpgMakerGameConfigs.GetRpgMakerGameChapterGroupIdList()
        local totalCount = #chapterGroupIdList
        for i = totalCount, 1, -1 do
            chapterGroupId = chapterGroupIdList[i]
            timeId = XRpgMakerGameConfigs.GetChapterGroupOpenTimeId(chapterGroupId)
            if XFunctionManager.CheckInTimeByTimeId(timeId, true) then
                return chapterGroupId
            end
        end
        return chapterGroupIdList[totalCount]
    end

    function XRpgMakerGameManager.GetActivityEndTime()
        local activityId = XRpgMakerGameConfigs.GetDefaultActivityId()
        if not XTool.IsNumberValid(activityId) then return 0 end
        local timeId = XRpgMakerGameConfigs.GetRpgMakerGameActivityTimeId(activityId)
        return XFunctionManager.GetEndTimeByTimeId(timeId)
    end

    --章节组小红点缓存
    function XRpgMakerGameManager.SetChapterGroupIdOpen(chapterGroupId)
        HaveOpenChapterGroupIdList = XRpgMakerGameManager.GetHaveOpenChapterGroupIdList() or {}
        for _,v in ipairs(HaveOpenChapterGroupIdList) do
            if chapterGroupId == v then return end
        end
        table.insert(HaveOpenChapterGroupIdList, chapterGroupId)
        local haveOpenChapterGroupIdList = GetHaveOpenChapterGroupIdListCookieKey()
        return XSaveTool.SaveData(haveOpenChapterGroupIdList, HaveOpenChapterGroupIdList)
    end

    function XRpgMakerGameManager.GetHaveOpenChapterGroupIdList()
        local haveOpenChapterGroupIdList = GetHaveOpenChapterGroupIdListCookieKey()
        return XSaveTool.GetData(haveOpenChapterGroupIdList) or {}
    end

    --章节小红点缓存
    function XRpgMakerGameManager.SetChapterIdOpen(chapterId)
        HaveOpenChapterIdList = XRpgMakerGameManager.GetHaveOpenChapterIdList()
        for _,v in ipairs(HaveOpenChapterIdList) do
            if chapterId == v then return end
        end
        table.insert(HaveOpenChapterIdList, chapterId)
        local haveOpenChapterIdList = GetHaveOpenChapterIdListCookieKey()
        return XSaveTool.SaveData(haveOpenChapterIdList, HaveOpenChapterIdList)
    end

    function XRpgMakerGameManager.GetHaveOpenChapterIdList()
        local haveOpenChapterIdList = GetHaveOpenChapterIdListCookieKey()
        return XSaveTool.GetData(haveOpenChapterIdList) or {}
    end

    --缓存当前的活动组Id
    local _CurChapterGroupId
    function XRpgMakerGameManager.SetCurChapterGroupId(chapterGroupId)
        _CurChapterGroupId = chapterGroupId
        XRpgMakerGameManager.SetChapterGroupIdOpen(chapterGroupId)
    end

    function XRpgMakerGameManager.GetCurChapterGroupId()
        return _CurChapterGroupId
    end
    -----------------主界面 end--------------------

    -----------------关卡内 begin------------------
    function XRpgMakerGameManager.InitStageMap(mapId, selectRoleId)
        PlayerObj:InitData(mapId, selectRoleId)
        EndPointObj:InitData(mapId)
        InitMonsetObj(mapId)
        InitTriggerObjDic(mapId)
        InitShadowObj(mapId)
        InitElectricFenceObj(mapId)
        InitTransferPointObj(mapId)
        InitEntityObj(mapId)
        ResetStepCount()
    end

    function XRpgMakerGameManager.ResetStageMap()
        local enterStageDb = XRpgMakerGameManager:GetRpgMakerGameEnterStageDb()
        local mapId = enterStageDb:GetMapId()
        local selectRoleId = enterStageDb:GetSelectRoleId()
        PlayerObj:InitData(mapId, selectRoleId)
        EndPointObj:InitData(mapId)
        ResetTriggerObj()
        ResetMonsetObj()
        ResetStepCount()
        ResetShadowObj()
        ResetElectricFenceObj()
        ResetEntityObj()
        XRpgMakerGameManager.ResetActions()
    end

    function XRpgMakerGameManager.ClearStageMap()
        PlayerObj:Dispose()
        EndPointObj:Dispose()
        ClearMonsterObj()
        ClearTriggerObj()
        ClearShadowObj()
        ClearElectricFencebj()
        ClearTransferPointObj()
        ClearEntityObj()
        ResetStepCount()
    end

    function XRpgMakerGameManager.GetNextAction(isNotRemove)
        if isNotRemove then
            return Actions[1]
        end

        local action = tableRemove(Actions, 1)
        XRpgMakerGameManager.UpdateActionData(action)
        return action
    end

    --需要并列执行动作的用该方法
    function XRpgMakerGameManager.GetActions(actionType)
        local actions = {}
        for i = #Actions, 1, -1 do
            if Actions[i].ActionType == actionType then
                local action = tableRemove(Actions, i)
                XRpgMakerGameManager.UpdateActionData(action)
                tableInsert(actions, action)
            end
        end

        return actions
    end

    function XRpgMakerGameManager.IsActionsEmpty()
        return XTool.IsTableEmpty(Actions)
    end

    --更新状态数据，不播放动画
    function XRpgMakerGameManager.UpdateActionData(action)
        if action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionPlayerMove then
            XRpgMakerGameManager.SetCurrentCount(action.CurrentCount)
            PlayerObj:SetFaceDirection(action.Direction)
            PlayerObj:UpdatePosition(action.EndPosition)
            return
        end

        if action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionKillMonster
            or action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionMonsterDieByTrap
            or action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionMonsterKillByElectricFence
            or action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionHumanKill
            or action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionMonsterDrown then
            local monsterObj = XRpgMakerGameManager.GetMonsterObj(action.MonsterId)
            if monsterObj then
                monsterObj:Die()
            end
            return
        end

        if action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionStageWin then
            local enterStageDb = XRpgMakerGameManager:GetRpgMakerGameEnterStageDb()
            local stageId = enterStageDb:GetStageId()
            local selectRoleId = enterStageDb:GetSelectRoleId()
            local stepCount = XRpgMakerGameManager.GetCurrentCount()
            local stageDb = XRpgMakerGameManager.GetRpgMakerActivityStageDb(stageId)
            local starCount = action.StarCondition and #action.StarCondition or 0
            stageDb:SetRoleId(selectRoleId)
            if stepCount < stageDb:GetStepCount() then
                stageDb:SetStepCount(stepCount)
            end

            if stageDb:GetStarCount() <= starCount then
                stageDb:SetStarCondition(action.StarCondition)
            end
            stageDb:SetStarReward(action.StarReward, true)
            return
        end

        if action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionEndPointOpen then
            EndPointObj:EndPointOpen()
            return
        end

        if action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionMonsterRunAway
            or action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionMonsterPatrol then
            local monsterObj = XRpgMakerGameManager.GetMonsterObj(action.MonsterId)
            if monsterObj then
                monsterObj:SetFaceDirection(action.Direction)
                monsterObj:UpdatePosition(action.EndPosition)
            end
            return
        end

        if action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionMonsterChangeDirection then
            local monsterObj = XRpgMakerGameManager.GetMonsterObj(action.MonsterId)
            if monsterObj then
                monsterObj:SetFaceDirection(action.Direction)
            end
            return
        end

        if action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionMonsterKillPlayer
            or action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionPlayerDieByTrap
            or action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionPlayerKillByElectricFence
            or action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionPlayerDrown then
            PlayerObj:Die()
            return
        end

        if action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionTriggerStatusChange then
            local triggerObj = XRpgMakerGameManager.GetTriggerObj(action.TriggerId)
            if triggerObj then
                triggerObj:SetTriggerStatus(action.TriggerStatus)
                triggerObj:SetElectricStatus(action.ElectricStatus)
            end
            return
        end

        if action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionUnlockRole then
            RpgMakerGameActivityDb:UpdateUnlockRoleId(action.RoleId)
            return
        end

        if action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionShadowMove then
            local shadowObj = XRpgMakerGameManager.GetShadowObj(action.ShadowId)
            if shadowObj then
                shadowObj:SetFaceDirection(action.Direction)
                shadowObj:UpdatePosition(action.EndPosition)
            end
            return
        end

        if action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionShadowDieByTrap then
            local shadowObj = XRpgMakerGameManager.GetShadowObj(action.ShadowId)
            if shadowObj then
                shadowObj:Die()
            end
            return
        end

        if action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionElectricStatusChange then
            SetElectricFenceStatus(action.ElectricStatus)
            return
        end

        if action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionSentrySign then
            local monsterObj = XRpgMakerGameManager.GetMonsterObj(action.MonsterId)
            if monsterObj then
                monsterObj:UpdateSentrySignAction(action)
            end
            return
        end

        if action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionSteelBrokenToTrap
            or XRpgMakerGameConfigs.RpgMakerGameActionType.ActionSteelBrokenToFlat then
            local entityId = action.EntityId
            local entityObj = XRpgMakerGameManager.GetEntityObj(entityId)
            if entityObj and entityObj.SetStatus then
                entityObj:SetStatus(XRpgMakerGameConfigs.XRpgMakerGameSteelBrokenType.Flat)
            end
            return
        end
    end

    --地图某一时刻的状态
    function XRpgMakerGameManager.UpdateMapStatusDb(data)
        XDataCenter.RpgMakerGameManager.SetCurrentCount(data.CurrentRound)

        --玩家状态
        PlayerObj:UpdateData(data.GamePlayer)

        --终点状态
        EndPointObj:UpdateData(data.EndPoint)

        --怪物状态
        for _, monsterData in ipairs(data.GameMonsters) do
            local id = monsterData.Id
            local monsterObj = XRpgMakerGameManager.GetMonsterObj(id)
            if monsterObj then
                monsterObj:UpdateData(monsterData)
            end
        end

        --机关
        CheckSetPlayElectricStatusSwitchSound(data.Triggers)
        for _, triggerData in ipairs(data.Triggers) do
            local id = triggerData.Id
            local triggerObj = XRpgMakerGameManager.GetTriggerObj(id)
            if triggerObj then
                triggerObj:UpdateData(triggerData)
            end
        end

        --影子
        for _, shadowData in ipairs(data.Shadows) do
            local id = shadowData.Id
            local obj = XRpgMakerGameManager.GetShadowObj(id)
            if obj then
                obj:UpdateData(shadowData)
            end
        end
        
        --电网
        local electricStatus = data.ElectricFence and data.ElectricFence.ElectricStatus
        SetElectricFenceStatus(electricStatus)

        --水，冰
        local waterObj
        for _, water in ipairs(data.Water) do
            waterObj = XRpgMakerGameManager.GetEntityObj(water.Id)
            if waterObj and waterObj.SetStatus then
                waterObj:SetStatus(water.WaterStatus)
            end
        end

        --草圃
        local grassObj
        for _, grass in ipairs(data.Grass) do
            grassObj = XRpgMakerGameManager.GetEntityObj(grass.Id)
            if grassObj and grassObj.SetIsGrow then
                grassObj:SetIsGrow(true)
            end
        end

        --钢板
        local steelObj
        for _, steel in ipairs(data.Steel) do
            steelObj = XRpgMakerGameManager.GetEntityObj(steel.Id)
            if steelObj and steelObj.SetStatus then
                steelObj:SetStatus(steel.SteelStatus)
            end
        end
    end

    function XRpgMakerGameManager.SetCurrentCount(currentCount)
        CurrentCount = currentCount
    end

    function XRpgMakerGameManager.GetCurrentCount()
        return CurrentCount
    end

    function XRpgMakerGameManager.GetShadowObj(shadowId)
        return XTool.IsNumberValid(shadowId) and ShadowObjDic[shadowId]
    end

    function XRpgMakerGameManager.GetMonsterObj(monsterId)
        return XTool.IsNumberValid(monsterId) and GameMonsterObjDic[monsterId]
    end

    function XRpgMakerGameManager.GetMonsterObjDic()
        return GameMonsterObjDic
    end

    function XRpgMakerGameManager.GetElectricFenceObjDic()
        return ElectricFenceObjDic
    end

    function XRpgMakerGameManager.GetElectricFenceObj(electricFenceId)
        return XTool.IsNumberValid(electricFenceId) and ElectricFenceObjDic[electricFenceId]
    end

    --获得怪物死亡的数量
    function XRpgMakerGameManager.GetMonsterDeathCount()
        local normalMonsterDeathCount = 0
        local bossDeathCount = 0
        local totalDeathCount = 0
        local monsterTypeCfg
        for _, obj in pairs(GameMonsterObjDic) do
            monsterTypeCfg = XRpgMakerGameConfigs.GetRpgMakerGameMonsterType(obj:GetId())
            if monsterTypeCfg == XRpgMakerGameConfigs.XRpgMakerGameMonsterType.Normal and obj:IsDeath() then
                normalMonsterDeathCount = normalMonsterDeathCount + 1
            elseif monsterTypeCfg == XRpgMakerGameConfigs.XRpgMakerGameMonsterType.BOSS and obj:IsDeath() then
                bossDeathCount = bossDeathCount + 1
            end
        end

        totalDeathCount = normalMonsterDeathCount + bossDeathCount
        return totalDeathCount, normalMonsterDeathCount, bossDeathCount
    end

    function XRpgMakerGameManager.GetTriggerObj(triggerId)
        return XTool.IsNumberValid(triggerId) and TriggerObjDic[triggerId]
    end

    function XRpgMakerGameManager.GetRpgMakerGameEnterStageDb()
        return RpgMakerGameEnterStageDb
    end

    function XRpgMakerGameManager.GetPlayerObj()
        return PlayerObj
    end

    function XRpgMakerGameManager.GetEndPointObj()
        return EndPointObj
    end

    function XRpgMakerGameManager.ResetActions()
        Actions = {}
    end

    function XRpgMakerGameManager.GetCurrentScene()
        return CurrentScene
    end

    --获得一个随机对话内容的id
    function XRpgMakerGameManager.GetRandomDialogBoxId()
        --设置随机数种子
        math.randomseed(os.time())

        local idList = XRpgMakerGameConfigs.GetRpgMakerGameRandomDialogBoxIdList()
        local clearStageIdList = {}
        local preStageId
        local isStageClear
        local weight
        local sum = 0
        local randomDialogBoxId

        --获取权重总和
        for _, id in ipairs(idList) do
            preStageId = XRpgMakerGameConfigs.GetRpgMakerGameRandomDialogBoxPreStage(id)
            isStageClear = not XTool.IsNumberValid(preStageId) and true or XRpgMakerGameManager.IsStageClear(preStageId)
            weight = XRpgMakerGameConfigs.GetRpgMakerGameRandomDialogBoxWeight(id)
            if isStageClear then
                table.insert(clearStageIdList, id)
                sum = sum + weight
            end
        end

        --随机数加上权重，越大的权重，数值越大
        local maxRand = 0
        local rand
        for _, id in ipairs(clearStageIdList) do
            rand = math.random(0, sum)
            weight = XRpgMakerGameConfigs.GetRpgMakerGameRandomDialogBoxWeight(id)
            if rand + weight > maxRand then
                maxRand = rand + weight
                randomDialogBoxId = id
            end
        end

        return randomDialogBoxId
    end

    function XRpgMakerGameManager.GetSceneCubeObj(row, col)
        local currentScene = XRpgMakerGameManager.GetCurrentScene()
        return currentScene and currentScene:GetCubeObj(row, col)
    end

    function XRpgMakerGameManager.GetSceneCubeUpCenterPosition(row, col)
        local cubeObj = XRpgMakerGameManager.GetSceneCubeObj(row, col)
        return cubeObj and cubeObj:GetGameObjUpCenterPosition()
    end

    function XRpgMakerGameManager.GetSceneCubeTransform(row, col)
        local cubeObj = XRpgMakerGameManager.GetSceneCubeObj(row, col)
        return cubeObj and cubeObj:GetTransform()
    end

    --是否满足激活星星条件，不使用服务端下发的数据
    --isWin：通关才计算行走步数，为nil时不考虑是否通关
    function XRpgMakerGameManager.IsStarConditionClear(starConditionId, isWin)
        local currentCount = XRpgMakerGameManager.GetCurrentCount()
        local totalDeathCount, normalMonsterDeathCount, bossDeathCount = XRpgMakerGameManager.GetMonsterDeathCount()
        local stepCount = XRpgMakerGameConfigs.GetRpgMakerGameStarConditionStepCount(starConditionId)
        local monsterCount = XRpgMakerGameConfigs.GetRpgMakerGameStarConditionMonsterCount(starConditionId)
        local monsterBossCount = XRpgMakerGameConfigs.GetRpgMakerGameStarConditionMonsterBossCount(starConditionId)
        local monsterTotalCount = monsterCount + monsterBossCount

        if currentCount <= stepCount then
            if isWin ~= nil then
                return isWin
            end
            return true
        end
        if XTool.IsNumberValid(monsterCount) and XTool.IsNumberValid(monsterBossCount) then
            return monsterTotalCount <= totalDeathCount
        end
        if XTool.IsNumberValid(monsterCount) then
            return monsterCount <= normalMonsterDeathCount
        end
        if XTool.IsNumberValid(monsterBossCount) then
            return monsterBossCount <= bossDeathCount
        end

        return false
    end

    function XRpgMakerGameManager.SetClickObjectCallback(cb)
        ClickObjectCallback = cb
    end

    function XRpgMakerGameManager.FireClickObjectCallback(modelKey, modelName)
        if ClickObjectCallback then
            ClickObjectCallback(modelKey, modelName)
        end
    end

    function XRpgMakerGameManager.SetPointerDownObjectCallback(cb)
        PointerDownObjectCallback = cb
    end

    function XRpgMakerGameManager.FirePointerDownObjectCallback()
        if PointerDownObjectCallback then
            PointerDownObjectCallback()
        end
    end

    function XRpgMakerGameManager.SetPointerUpObjectCallback(cb)
        PointerUpObjectCallback = cb
    end

    function XRpgMakerGameManager.FirePointerUpObjectCallback()
        if PointerUpObjectCallback then
            PointerUpObjectCallback()
        end
    end

    --是否能在当前坐标中设置模型或特效
    function XRpgMakerGameManager.IsCurPositionSet(posX, posY, direction)
        local isCurSet = true       --是否能在当前的坐标中设置
        local isNextSet = true      --是否能继续在下一个坐标中判断能否设置

        local currentScene = XRpgMakerGameManager.GetCurrentScene()
        local blockObj = currentScene:GetBlockObj(posY, posX)
        if blockObj then
            isCurSet, isNextSet = false, false
            return isCurSet, isNextSet
        end

        for _, obj in pairs(TriggerObjDic or {}) do
            if obj:IsSamePoint(posX, posY) and obj:IsBlock() then
                isCurSet, isNextSet = false, false
                return isCurSet, isNextSet
            end
        end
        
        for _, obj in pairs(ShadowObjDic or {}) do
            if obj:IsSamePoint(posX, posY) then
                isCurSet, isNextSet = false, false
                return isCurSet, isNextSet
            end
        end

        for _, obj in pairs(GameMonsterObjDic or {}) do
            if obj:IsSamePoint(posX, posY) and not obj:IsDeath() then
                isCurSet, isNextSet = false, false
                return isCurSet, isNextSet
            end
        end

        isNextSet = XRpgMakerGameManager.IsCurGapSet(posX, posY, direction)

        return isCurSet, isNextSet
    end

    --是否能在缝隙或电墙所在的下一个坐标中设置模型或特效
    function XRpgMakerGameManager.IsCurGapSet(posX, posY, direction)
        local currentScene = XRpgMakerGameManager.GetCurrentScene()
        local getGapObjs = currentScene:GetGapObjs()
        local nextPosX = (direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveLeft and posX - 1) or (direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveRight and posX + 1) or posX
        local nextPosY = (direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveUp and posY + 1) or (direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveDown and posY - 1) or posY
        local isBlock

        for _, obj in pairs(getGapObjs or {}) do
            isBlock = obj:IsGapInMiddle(posX, posY, direction, nextPosX, nextPosY)
            if isBlock then
                return false
            end
        end

        for _, obj in pairs(ElectricFenceObjDic or {}) do
            isBlock = obj:IsElectricFenceInMiddle(posX, posY, direction, nextPosX, nextPosY)
            if isBlock then
                return false
            end
        end

        return true
    end

    function XRpgMakerGameManager.GetTransferPointObj(transferPointId)
        return TransferPointObjDic[transferPointId]
    end

    function XRpgMakerGameManager.GetEntityObj(entityId)
        local obj = GrassObjDic[entityId]
        if obj then
            return obj
        end

        obj = SteelObjDic[entityId]
        if obj then
            return obj
        end

        obj = WaterObjDic[entityId]
        if obj then
            return obj
        end
    end

    function XRpgMakerGameManager.GetWaterObjDic()
        return WaterObjDic
    end

    --是否会被草埔遮挡
    function XRpgMakerGameManager.IsGrassShelter(x, y)
        local currentScene = XRpgMakerGameManager.GetCurrentScene()
        local mapId = currentScene:GetMapId()
        local entityIdList = XRpgMakerGameConfigs.GetEntityIdListByDic(mapId, x, y)
        local obj

        for _, entityId in ipairs(entityIdList) do
            if XRpgMakerGameConfigs.GetEntityType(entityId) == XRpgMakerGameConfigs.XRpgMakerGameEntityType.Grass then
                obj = XRpgMakerGameManager.GetEntityObj(entityId)
                if obj and obj:IsActive() then
                    return true
                end
            end
        end

        obj = currentScene:GetGrass(x, y)
        return obj and obj:IsActive() or false
    end
    -----------------关卡内 end--------------------

    -----------------角色相关 begin----------------
    function XRpgMakerGameManager.GetOnceUnLockRoleId()
        local roleIdList = XRpgMakerGameConfigs.GetRpgMakerGameRoleIdList()
        for _, roleId in ipairs(roleIdList) do
            if XRpgMakerGameManager.IsUnlockRole(roleId) then
                return roleId
            end
        end
        return roleIdList[1]
    end

    function XRpgMakerGameManager.IsUnlockRole(roleId)
        if not XTool.IsNumberValid(roleId) then
            return false
        end

        local unlockRoleIdList = XRpgMakerGameManager.GetUnlockRoleIdList()
        for _, unlockRoleId in ipairs(unlockRoleIdList) do
            if unlockRoleId == roleId then
                return true
            end
        end

        return false, XRpgMakerGameConfigs.GetRpgMakerGameRoleLockTipsDesc(roleId)
    end

    function XRpgMakerGameManager.GetUnlockRoleIdList()
        return RpgMakerGameActivityDb:GetUnlockRoleIdList()
    end
    -----------------角色相关 end------------------

    -----------------协议相关 begin----------------
    --进入活动请求
    function XRpgMakerGameManager.RequestRpgMakerGameEnter()
        if not XDataCenter.RpgMakerGameManager.CheckActivityCondition() then
            return
        end

        XNetwork.Call("RpgMakerGameEnterRequest", {}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            RpgMakerGameActivityDb:UpdateData(res.ActivityDb or res.ActivityData)   --中途改了名字，防止出错
            if not XLuaUiManager.IsUiLoad("UiRpgMakerGameMain") then
                XLuaUiManager.Open("UiRpgMakerGameMain")
            end
        end)
    end

    --进入一个TileMap
    function XRpgMakerGameManager.RequestRpgMakerGameEnterStage(stageId, selectRoleId, cb)
        local req = { StageId = stageId, SelectRoleId = selectRoleId }
        XNetwork.Call("RpgMakerGameEnterStageRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            CurrentScene:RemoveScene()
            XRpgMakerGameManager.ResetActions()

            RpgMakerGameEnterStageDb:UpdateData(res)
            for _, action in ipairs(res.Actions or {}) do
                InsertAction(action)
            end
            XRpgMakerGameManager.InitStageMap(res.MapId, res.SelectRoleId)

            XLuaUiManager.Open("UiFubenRpgMakerGameMovie", stageId)
            CurrentScene:LoadScene(res.MapId, function()
                local delay = CS.XGame.ClientConfig:GetInt("RpgMakerGameLoadingDelayClose")     --延迟Loading界面关闭的时间

                XScheduleManager.ScheduleOnce(function()
                    XLuaUiManager.Close("UiFubenRpgMakerGameMovie")
                    CurrentScene:SetSceneActive(false)      --处理光照异常
                    CurrentScene:SetSceneActive(true)
                    if cb then
                        cb()
                    end
                end, delay)
            end)
        end)
    end

    --玩家移动
    function XRpgMakerGameManager.RequestRpgMakerGameMapMove(mapId, direction, cb)
        if IsLockReqMove() then return end

        local req = { MapId = mapId, Direction = direction }
        LockReqMove()
        XNetwork.Call("RpgMakerGameMapMoveRequest", req, function(res)
            if res.Code ~= XCode.Success then
                UnLockReqMove()
                XUiManager.TipCode(res.Code)
                return
            end

            for _, action in ipairs(res.Actions) do
                InsertAction(action)
            end
            CheckSetPlayElectricStatusSwitchSound(res.Actions)

            UnLockReqMove()

            if cb then
                cb()
            end
        end)
    end

    --重置游戏
    function XRpgMakerGameManager.RequestRpgMakerGameMapResetGame(mapId, cb)
        if IsLockReqReset() then
            return
        end

        LockReqReset()
        local req = { MapId = mapId }
        XNetwork.Call("RpgMakerGameMapResetGameRequest", req, function(res)
            if res.Code ~= XCode.Success then
                UnLockReqReset()
                XUiManager.TipCode(res.Code)
                return
            end

            XRpgMakerGameManager.ResetStageMap()
            for _, action in ipairs(res.Actions or {}) do
                InsertAction(action)
            end

            if cb then
                cb()
            end
            UnLockReqReset()
        end)
    end

    --后退
    function XRpgMakerGameManager.RequestRpgMakerGameMapBackUp(mapId, cb)
        local currCount = XRpgMakerGameManager.GetCurrentCount()
        if currCount == 0 then
            return
        end

        local req = { MapId = mapId }
        XNetwork.Call("RpgMakerGameMapBackUpRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XRpgMakerGameManager.UpdateMapStatusDb(res.GameMapStatusDb)
            for _, action in ipairs(res.Actions or {}) do
                InsertAction(action)
            end

            local currentRound = res.GameMapStatusDb.CurrentRound
            if cb then
                cb(currentRound)
            end
        end)
    end

    --解锁提示
    function XRpgMakerGameManager.RequestRpgMakerGameMapUnlockHint(stageId, type, cb)
        local req = {
            StageId = stageId,
            Type = type,    --1提示，2答案
        }
        XNetwork.Call("RpgMakerGameMapUnlockHintRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local stageDb = XRpgMakerGameManager.GetRpgMakerActivityStageDb(stageId)
            if stageDb then
                if type == XRpgMakerGameConfigs.XRpgMakerGameRoleAnswerType.Hint then
                    stageDb:SetHint(1)
                else
                    stageDb:SetAnswer(1)
                end
            end

            if cb then
                cb()
            end
        end)
    end
    -----------------协议相关 end----------------

    return XRpgMakerGameManager
end