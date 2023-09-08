local XUiGridTRPGRole = require("XUi/XUiTRPG/XUiGridTRPGRole")
local XUiGridTRPGCard = require("XUi/XUiTRPG/XUiGridTRPGCard")
local XUiTRPGPanelTask = require("XUi/XUiTRPG/XUiTRPGPanel/XUiTRPGPanelTask")
local XUiTRPGPanelPlotTab = require("XUi/XUiTRPG/XUiTRPGPanel/XUiTRPGPanelPlotTab")
local XUiTRPGPanelLevel = require("XUi/XUiTRPG/XUiTRPGPanel/XUiTRPGPanelLevel")

local CSXTextManagerGetText = CS.XTextManager.GetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local CSXScheduleManagerUnSchedule = XScheduleManager.UnSchedule
local mathFloor = math.floor
local tableInsert = table.insert
local Lerp = CS.UnityEngine.Vector3.Lerp
local Vector3 = CS.UnityEngine.Vector3

local MAX_ROLE_NUM = 4
local MAX_NODE_NUM = 5 --地图中显示最大行数
local HORIZONTAL_ANIM_DURATION = 0.3 --* XScheduleManager.SECOND --卡牌水平移动动画时间
local LINE_ANIM_DURATION = 0.3 --* XScheduleManager.SECOND --卡牌换行推进动画时间

local XUiTRPGMaze = XLuaUiManager.Register(XLuaUi, "UiTRPGMaze")

function XUiTRPGMaze:OnAwake()
    self:AutoAddListener()

    self.PanelPlotTab = XUiTRPGPanelPlotTab.New(self.PanelPlotTab)
    self.TaskPanel = XUiTRPGPanelTask.New(self.PanelTask, self)
    self.LevelPanel = XUiTRPGPanelLevel.New(self.PanelLevel)

    self.ImgJindu = self.Transform:FindTransform("ImgJindu"):GetComponent("Image")
end

function XUiTRPGMaze:OnStart(mazeId)
    XDataCenter.TRPGManager.SaveIsAlreadyEnterMaze(mazeId)
    self.MazeId = mazeId
    self.RoleGrids = {}
    self.MapGridToCardIdDic = {}
    self.CardGridPool = {}

    self:InitMaze()

    XDataCenter.TRPGManager.TipCurrentMaze()
end

function XUiTRPGMaze:OnEnable()
    XDataCenter.TRPGManager.CheckActivityEnd()
    self:UpdateRoles()
    self:UpdateEndurance()
    self:UpdateMap()
    self:UpdateProgress()

    local toMoveCardIndex, toPlayMovieId = XDataCenter.TRPGManager.GetMazeNeedMoveNextCardIndex()
    if toMoveCardIndex then

        local moveFunc = function()
            self:MoveNext(toMoveCardIndex)
            XDataCenter.TRPGManager.CheckOpenNewMazeTips()
        end

        if toPlayMovieId then
            XDataCenter.MovieManager.PlayMovie(toPlayMovieId, moveFunc)
        else
            moveFunc()
        end

        XDataCenter.TRPGManager.ClearMazeNeedMoveNextCardIndex()
    elseif not toPlayMovieId then
        XDataCenter.TRPGManager.CheckOpenNewMazeTips()
    end

    local isMazeNeedRestart = XDataCenter.TRPGManager.IsMazeNeedRestart()
    if isMazeNeedRestart then
        self:RestartCurrentLayer()
        XDataCenter.TRPGManager.ClearMazeNeedRestart()
    end

    self.TaskPanel:OnEnable()
end

function XUiTRPGMaze:OnDisable()
    self:DestroyHTimer()
    self:DestroyLTimer()
    self.TaskPanel:OnDisable()
end

function XUiTRPGMaze:OnDestroy()
    self.TaskPanel:Delete()
    self.LevelPanel:Delete()
    self.PanelPlotTab:OnDestroy()
end

function XUiTRPGMaze:OnGetEvents()
    return { XEventId.EVENT_TRPG_MAZE_MOVE_NEXT
    , XEventId.EVENT_TRPG_MAZE_MOVE_TO
    , XEventId.EVENT_TRPG_MAZE_RECORD_CARD
    , XEventId.EVENT_TRPG_BASE_INFO_CHANGE
    , XEventId.EVENT_TRPG_MAZE_RESTART
    , XEventId.EVENT_TRPG_ROLES_DATA_CHANGE
    , XEventId.EVENT_ACTIVITY_MAINLINE_STATE_CHANGE }
end

function XUiTRPGMaze:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_TRPG_MAZE_MOVE_NEXT then
        local cardIndex = args[1]
        self:MoveNext(cardIndex)
    elseif evt == XEventId.EVENT_TRPG_MAZE_MOVE_TO then
        local layerId = args[1]
        local nodeId = args[2]
        local cardIndex = args[3]
        self:MoveTo(layerId, nodeId, cardIndex)
    elseif evt == XEventId.EVENT_TRPG_MAZE_RESTART then
        self:RestartCurrentLayer()
    elseif evt == XEventId.EVENT_TRPG_BASE_INFO_CHANGE then
        self:UpdateEndurance()
    elseif evt == XEventId.EVENT_TRPG_MAZE_RECORD_CARD then
        self:UpdateProgress()
    elseif evt == XEventId.EVENT_TRPG_ROLES_DATA_CHANGE then
        self:UpdateRoles()
    elseif evt == XEventId.EVENT_ACTIVITY_MAINLINE_STATE_CHANGE then
        XDataCenter.TRPGManager.OnActivityMainLineStateChange(...)
    end
end

function XUiTRPGMaze:InitMaze()
    local mazeId = self.MazeId
    self.TxtName.text = XTRPGConfigs.GetMazeName(mazeId)
end

function XUiTRPGMaze:UpdateRoles()
    local roleIds = XDataCenter.TRPGManager.GetOwnRoleIds()
    for index = 1, MAX_ROLE_NUM do
        local grid = self.RoleGrids[index]
        if not grid then
            local ui = index == 1 and self.GridRole or CSUnityEngineObjectInstantiate(self.GridRole, self.PanelRole)
            grid = XUiGridTRPGRole.New(ui)
            self.RoleGrids[index] = grid
        end
        grid:Refresh(roleIds[index])
    end
end

function XUiTRPGMaze:UpdateEndurance()
    local curEndurance = XDataCenter.TRPGManager.GetExploreCurEndurance()
    local maxEndurance = XDataCenter.TRPGManager.GetExploreMaxEndurance()

    self.ImgJindu.fillAmount = maxEndurance == 0 and 1 or curEndurance / maxEndurance
    self.TxtAction.text = CSXTextManagerGetText("TRPGExploreEndurance", curEndurance, maxEndurance)
end

function XUiTRPGMaze:UpdateProgress()
    local mazeId = self.MazeId
    local layerId = self.LayerId

    local mazeProgress = XDataCenter.TRPGManager.GetMazeProgress(mazeId, layerId)
    self.TxtLayerProgress.text = mathFloor(mazeProgress * 100)
    self.ImgLayerJindu.fillAmount = mazeProgress
end

function XUiTRPGMaze:UpdateMap()
    local mazeId = self.MazeId

    local layerId = XDataCenter.TRPGManager.GetMazeCurrentLayerId(mazeId)
    self.TxtLayer.text = XTRPGConfigs.GetMazeLayerName(layerId)

    local bgImage = XTRPGConfigs.GetMazeLayerBgImage(layerId)
    self.RImgChapterBg:SetRawImage(bgImage)

    local nodeIdList = XDataCenter.TRPGManager.GetMazeNodeIdList(mazeId, layerId)
    self.NodeIdList = nodeIdList

    for _, grid in pairs(self.CardGridPool) do
        grid.GameObject:SetActiveEx(false)
    end

    for nodeIndex = 1, MAX_NODE_NUM do
        local nodeId = nodeIdList[nodeIndex]
        if not nodeId then break end

        local cardBeginPos, cardEndPos = XDataCenter.TRPGManager.GetMazeCardBeginEndPos(mazeId, layerId, nodeId)

        local cardNum = XDataCenter.TRPGManager.GetMazeCardNum(mazeId, layerId, nodeId)
        for cardIndex = 1, cardNum do
            local cardId = XDataCenter.TRPGManager.GetMazeCardId(mazeId, layerId, nodeId, cardIndex)

            local nodeGridKey = self:GetNodeGridKey(nodeIndex, cardIndex)
            self.MapGridToCardIdDic[nodeGridKey] = cardId

            local grid = self:GetMapGrid(nodeIndex, cardIndex)
            local isNodeReachable = XDataCenter.TRPGManager.IsNodeReachable(mazeId, layerId, nodeId)
            local isCardReachable = XDataCenter.TRPGManager.IsCardReachable(mazeId, layerId, nodeId, cardIndex)
            local finishedCardId = XDataCenter.TRPGManager.GetCardFinishedId(mazeId, layerId, nodeId, cardIndex)
            local clickCb = function() XDataCenter.TRPGManager.SelectCard(cardIndex) end
            grid:Refresh(cardId, isNodeReachable, isCardReachable, clickCb, finishedCardId)

            local cardPos = cardBeginPos + cardIndex - 1
            local nodeParentKey = self:GetNodeGridKey(nodeIndex, cardPos)
            local cardParent = self[nodeParentKey]
            if not cardParent then
                XLog.Error("XUiTRPGMaze:UpdateMap Error: can not find cardParent, nodeIndex: " .. nodeIndex .. ", cardPos: " .. cardPos .. ", cardIndex: " .. cardIndex)
                return
            end
            grid.Transform:SetParent(cardParent, false)
            grid.Transform:Reset()

            local prefabPath = XTRPGConfigs.GetMazeCardPrefab(cardId)
            grid.GameObject.name = nodeIndex .. cardIndex
            grid.GameObject:SetActiveEx(true)
        end
    end
end

function XUiTRPGMaze:MoveNext(cardIndex)
    local asynPlayAnim = asynTask(self.PlayAnimation, self)
    local asynMoveHorizontal = asynTask(self.MoveHorizontal, self)
    local asynMoveNextLine = asynTask(self.MoveNextLine, self)

    RunAsyn(function()
        local mazeId = self.MazeId
        local layerId = XDataCenter.TRPGManager.GetMazeCurrentLayerId(mazeId)
        local nodeId = XDataCenter.TRPGManager.GetMazeCurrentNodeId(mazeId)
        local cardId = XDataCenter.TRPGManager.GetMazeCardId(mazeId, layerId, nodeId, cardIndex)
        local cardDelta = XDataCenter.TRPGManager.GetMazeCardMoveDelta(cardIndex)

        XLuaUiManager.SetMask(true)

        --框消失anim
        self:PlayAnimation("PanelSelectDisable")

        --move horizontal
        asynMoveHorizontal(cardDelta)

        --move line
        asynMoveNextLine(cardDelta)

        --框出现anim
        self:PlayAnimation("PanelSelectEnable")

        --data refresh
        XDataCenter.TRPGManager.MazeMoveNext(cardIndex)

        --ui refresh
        self:UpdateMap()

        XLuaUiManager.SetMask(false)
    end)
end

function XUiTRPGMaze:MoveTo(layerId, nodeId, cardIndex)
    coroutine.wrap(function()
        local co = coroutine.running()
        local callBack = function() coroutine.resume(co) end

        XLuaUiManager.SetMask(true)

        --maze disappear anim
        self:PlayAnimation("FubenTRPGMazeDisable", callBack)
        coroutine.yield()

        --data refresh
        XDataCenter.TRPGManager.MazeMoveTo(layerId, nodeId, cardIndex)

        --ui refresh
        self:UpdateMap()

        --maze appear anim
        self:PlayAnimation("FubenTRPGMazeEnable", callBack)
        coroutine.yield()

        XLuaUiManager.SetMask(false)

        XDataCenter.TRPGManager.TipCurrentMaze()
    end)()
end

function XUiTRPGMaze:RestartCurrentLayer()
    coroutine.wrap(function()
        local co = coroutine.running()
        local callBack = function() coroutine.resume(co) end

        XLuaUiManager.SetMask(true)

        --maze disappear anim
        self:PlayAnimation("FubenTRPGMazeDisable", callBack)
        coroutine.yield()

        --ui refresh
        self:UpdateMap()

        --maze appear anim
        self:PlayAnimation("FubenTRPGMazeEnable", callBack)
        coroutine.yield()

        XLuaUiManager.SetMask(false)

        XDataCenter.TRPGManager.TipCurrentMaze()
    end)()
end

function XUiTRPGMaze:AutoAddListener()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnMapDetails.CallBack = function() self:OnClickBtnMapDetails() end
end

function XUiTRPGMaze:OnBtnBackClick()
    XDataCenter.TRPGManager.TipQuitMaze(function()
        self:Close()
    end)
end

function XUiTRPGMaze:OnBtnMainUiClick()
    XDataCenter.TRPGManager.TipQuitMaze(function()
        XLuaUiManager.RunMain()
    end)
end

function XUiTRPGMaze:OnClickBtnMapDetails()
    XLuaUiManager.Open("UiTRPGMapTips", self.MazeId)
end

function XUiTRPGMaze:GetNodeGridKey(nodeIndex, cardPos)
    return nodeIndex .. "_" .. cardPos
end

function XUiTRPGMaze:MoveHorizontal(cardDelta, finishCb)
    local mazeId = self.MazeId
    local nodeIdList = self.NodeIdList
    local layerId = XDataCenter.TRPGManager.GetMazeCurrentLayerId(mazeId)
    local deltaH = cardDelta

    local toMoveGridInfos = {}

    for nodeIndex = 1, MAX_NODE_NUM do
        local nodeId = nodeIdList[nodeIndex]
        if not nodeId then break end

        local cardBeginPos, cardEndPos = XDataCenter.TRPGManager.GetMazeCardBeginEndPos(mazeId, layerId, nodeId)
        local cardNum = XDataCenter.TRPGManager.GetMazeCardNum(mazeId, layerId, nodeId)
        local targetNodeIndex = nodeIndex

        for cardIndex = 1, cardNum do
            local targetCardPos = cardBeginPos + cardIndex - 1 + deltaH

            local nodeParentKey = self:GetNodeGridKey(targetNodeIndex, targetCardPos)
            local cardParent = self[nodeParentKey]
            if not cardParent then
                XLog.Error("XUiTRPGMaze:MoveHorizontal Error: can not find cardParent, targetNodeIndex: " .. targetNodeIndex .. ", targetCardPos: " .. targetCardPos)
                return
            end

            local grid = self:GetMapGrid(nodeIndex, cardIndex)
            grid.Transform:SetParent(cardParent, true)
            tableInsert(toMoveGridInfos, {
                Transform = grid.Transform,
                StartPos = grid.Transform.localPosition,
            })
        end
    end

    local onRefreshFunc = function(time)
        local targetPos = Vector3.zero
        for _, toMoveGridInfo in pairs(toMoveGridInfos) do
            if XTool.UObjIsNil(toMoveGridInfo.Transform) then
                self:DestroyHTimer()
                return true
            end

            local tf = toMoveGridInfo.Transform
            if tf.localPosition == targetPos then
                return true
            end

            tf.localPosition = Lerp(toMoveGridInfo.StartPos, targetPos, time)
        end
    end

    self:DestroyHTimer()
    self.HTimer = XUiHelper.Tween(HORIZONTAL_ANIM_DURATION, onRefreshFunc, finishCb)
end

function XUiTRPGMaze:MoveNextLine(cardDelta, finishCb)
    local mazeId = self.MazeId
    local nodeIdList = self.NodeIdList
    local layerId = XDataCenter.TRPGManager.GetMazeCurrentLayerId(mazeId)
    local deltaH = cardDelta
    local deltaL = -1

    local toMoveGridInfos = {}

    for nodeIndex = 1, MAX_NODE_NUM do
        local nodeId = nodeIdList[nodeIndex]
        if not nodeId then break end

        local cardBeginPos, cardEndPos = XDataCenter.TRPGManager.GetMazeCardBeginEndPos(mazeId, layerId, nodeId)

        local cardNum = XDataCenter.TRPGManager.GetMazeCardNum(mazeId, layerId, nodeId)
        local targetNodeIndex = nodeIndex + deltaL

        for cardIndex = 1, cardNum do
            local targetCardPos = cardBeginPos + cardIndex - 1 + deltaH

            local nodeParentKey = self:GetNodeGridKey(targetNodeIndex, targetCardPos)
            local cardParent = self[nodeParentKey]
            if not cardParent then
                XLog.Error("XUiTRPGMaze:MoveNextLine Error: can not find cardParent, targetNodeIndex: " .. targetNodeIndex .. ", targetCardPos: " .. targetCardPos)
                return
            end

            local grid = self:GetMapGrid(nodeIndex, cardIndex)
            grid.Transform:SetParent(cardParent, true)
            tableInsert(toMoveGridInfos, {
                Transform = grid.Transform,
                StartPos = grid.Transform.localPosition,
                StartScale = grid.Transform.localScale,
            })
        end
    end

    local onRefreshFunc = function(time)
        local targetPos = Vector3.zero
        local targetScale = Vector3(1, 1, 1)
        for _, toMoveGridInfo in pairs(toMoveGridInfos) do
            if XTool.UObjIsNil(toMoveGridInfo.Transform) then
                self:DestroyLTimer()
                return
            end

            local tf = toMoveGridInfo.Transform

            if tf.localPosition == targetPos then
                return true
            end

            tf.localPosition = Lerp(toMoveGridInfo.StartPos, targetPos, time)
            tf.localScale = Lerp(toMoveGridInfo.StartScale, targetScale, time)
        end
    end

    self:DestroyLTimer()
    self.LTimer = XUiHelper.Tween(LINE_ANIM_DURATION, onRefreshFunc, finishCb)
end

function XUiTRPGMaze:DestroyHTimer()
    if self.HTimer then
        CSXScheduleManagerUnSchedule(self.HTimer)
        self.HTimer = nil
    end
end

function XUiTRPGMaze:DestroyLTimer()
    if self.LTimer then
        CSXScheduleManagerUnSchedule(self.LTimer)
        self.LTimer = nil
    end
end

function XUiTRPGMaze:GetMapGrid(nodeIndex, cardIndex)
    local nodeGridKey = self:GetNodeGridKey(nodeIndex, cardIndex)
    local gridCardId = self.MapGridToCardIdDic[nodeGridKey]
    if not gridCardId then return end
    return self:GetGridFromPool(gridCardId, nodeIndex, cardIndex)
end

function XUiTRPGMaze:GetGridFromPool(cardId, nodeIndex, cardIndex)
    local nodeParentKey = self:GetNodeGridKey(nodeIndex, cardIndex)
    local prefabPath = XTRPGConfigs.GetMazeCardPrefab(cardId)
    nodeParentKey = nodeParentKey .. prefabPath

    local grid = self.CardGridPool[nodeParentKey]
    if not grid then
        local ui = self[prefabPath]
        if not ui then
            XLog.Error("XUiTRPGMaze:GetGridFromPool error: prefab not exist, 请检查迷宫卡牌配置 Prefab 字段 ,prefabPath:", prefabPath)
            return
        end

        local prefab = CSUnityEngineObjectInstantiate(ui)
        grid = XUiGridTRPGCard.New(prefab, self)
        self.CardGridPool[nodeParentKey] = grid
    end
    return grid
end