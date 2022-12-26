local XRpgMakerGameActivityDb = require("XEntity/XRpgMakerGame/XRpgMakerGameActivityDb")
local XRpgMakerGameEnterStageDb = require("XEntity/XRpgMakerGame/XRpgMakerGameEnterStageDb")
local XRpgMakerGameEndPoint = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameEndPoint")
local XRpgMakerGameMonsterData = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameMonsterData")
local XRpgMakerGamePlayer = require("XEntity/XRpgMakerGame/Object/XRpgMakerGamePlayer")
local XRpgMakerGameTriggerData = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameTriggerData")
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

    ---------------------本地接口 begin------------------
    local InitMonsetObj = function(mapId)
        GameMonsterObjDic = {}
        local monsterIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToMonsterIdList(mapId)
        local monsterObj
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
        local monsterObj
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

    local _CurrentReqMoveLock   --请求移动协议结果未处理之前不允许接着请求

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
        return stageDb and true or false
    end

    function XRpgMakerGameManager.CheckActivityIsOpen()
        local id = XRpgMakerGameConfigs.GetDefaultActivityId()
        local timeId = XRpgMakerGameConfigs.GetRpgMakerGameActivityTimeId(id)
        if not XFunctionManager.CheckInTimeByTimeId(timeId) then
            if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
                return false
            end

            XUiManager.TipText("ActivityMainLineEnd")
            XLuaUiManager.RunMain()
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
        XSaveTool.SaveData("RpgMakerGameCurrClearButtonGroupIndex" .. XPlayer.Id, CurrTabGroupIndexByUiMainTemp)
    end

    function XRpgMakerGameManager.GetCurrClearButtonGroupIndex()
        return XSaveTool.GetData("RpgMakerGameCurrClearButtonGroupIndex" .. XPlayer.Id)
    end
    -----------------主界面 end--------------------

    -----------------关卡内 begin------------------
    function XRpgMakerGameManager.InitStageMap(mapId, selectRoleId)
        PlayerObj:InitData(mapId, selectRoleId)
        EndPointObj:InitData(mapId)
        InitMonsetObj(mapId)
        InitTriggerObjDic(mapId)
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
        XRpgMakerGameManager.ResetActions()
    end

    function XRpgMakerGameManager.ClearStageMap()
        PlayerObj:Dispose()
        EndPointObj:Dispose()
        ClearMonsterObj()
        ClearTriggerObj()
        ResetStepCount()
    end

    function XRpgMakerGameManager.GetNextAction()
        local action = tableRemove(Actions, 1)
        XRpgMakerGameManager.UpdateActionData(action)
        return action
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

        if action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionKillMonster then
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

            if stageDb then
                if stageDb:GetStarCount() < starCount then
                    stageDb:SetRoleId(selectRoleId)
                    stageDb:SetStepCount(stepCount)
                    stageDb:SetStarCondition(action.StarCondition)
                end
            else
                RpgMakerGameActivityDb:UpdateStageDb({StageCfgId = stageId, RoleId = selectRoleId, StepCount = stepCount, StarCondition = action.StarCondition})
            end
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

        if action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionMonsterKillPlayer then
            PlayerObj:Die()
            return
        end

        if action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionTriggerStatusChange then
            local triggerObj = XRpgMakerGameManager.GetTriggerObj(action.TriggerId)
            if triggerObj then
                triggerObj:SetTriggerStatus(action.TriggerStatus)
            end
            return
        end

        if action.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionUnlockRole then
            RpgMakerGameActivityDb:UpdateUnlockRoleId(action.RoleId)
            return
        end
    end

    --地图某一时刻的状态
    function XRpgMakerGameManager.UpdateMapStatusDb(data)
        --玩家状态
        PlayerObj:UpdateData(data.GamePlayer)
        --终点状态
        EndPointObj:UpdateData(data.EndPoint)
        --怪物状态
        for _, monsterData in ipairs(data.GameMonsters) do
            local id = monsterData.Id
            local monsterObj = GameMonsterObjDic[id]
            if monsterObj then
                monsterObj:UpdateData(monsterData)
            end
        end
        --机关
        for _, triggerData in ipairs(data.Triggers) do
            local id = triggerData.Id
            local triggerObj = TriggerObjDic[id]
            if triggerObj then
                triggerObj:UpdateData(triggerData)
            end
        end

        XDataCenter.RpgMakerGameManager.SetCurrentCount(data.CurrentRound)
    end

    function XRpgMakerGameManager.SetCurrentCount(currentCount)
        CurrentCount = currentCount
    end

    function XRpgMakerGameManager.GetCurrentCount()
        return CurrentCount
    end

    function XRpgMakerGameManager.GetMonsterObj(monsterId)
        return XTool.IsNumberValid(monsterId) and GameMonsterObjDic[monsterId]
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
            end, "UiRpgMakerGamePlayMain")
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
            

            UnLockReqMove()

            if cb then
                cb()
            end
        end)
    end

    --重置游戏
    function XRpgMakerGameManager.RequestRpgMakerGameMapResetGame(mapId, cb)
        local req = { MapId = mapId }
        XNetwork.Call("RpgMakerGameMapResetGameRequest", req, function(res)
            if res.Code ~= XCode.Success then
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
    -----------------协议相关 end----------------

    return XRpgMakerGameManager
end