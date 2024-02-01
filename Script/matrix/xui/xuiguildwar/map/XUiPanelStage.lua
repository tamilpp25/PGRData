---@class XUiGuildWarPanelStage
local XUiPanelStage = XClass(nil, "XUiPanelStage")

local XUiGridStage = require("XUi/XUiGuildWar/Map/XUiGridStage/XUiGridStage")
local XUiGridMonster = require("XUi/XUiGuildWar/Map/XUiGridMonster")
local XUiGridLine = require("XUi/XUiGuildWar/Map/XUiGridLine")
local XUiGridMapBg = require("XUi/XUiGuildWar/Map/XUiGridMapBg")
local CSTextManagerGetText = CS.XTextManager.GetText
local PanelDragFocusTime = 1.5
local BornWaitTime = 0.5
local Vector3 = CS.UnityEngine.Vector3
--基地节点UI索引
local BASENODE_INDEX = "1_1"
--BOSS节点UI索引
local BOSSNODE_INDEX = "2_1"
--隐藏节点UI索引
local SECRETNODE_INDEX = "101_1"
--当前界面的Action播放类型表
local PlayTypeList = {
    XGuildWarConfig.GWActionUiType.GWMap,
    XGuildWarConfig.GWActionUiType.NodeDestroyed,
    UiParam = {
        CanZoom = true
    }
}
--节点类型对应的节点代码 没写的默认是XUiGridStage
local NodeType2StageGrid = {
    [XGuildWarConfig.NodeType.PandaRoot] = require("XUi/XUiGuildWar/Map/XUiGridStage/XUiGridStagePanda"),
    [XGuildWarConfig.NodeType.TwinsRoot] = require("XUi/XUiGuildWar/Map/XUiGridStage/XUiGridStageTwins"),
    [XGuildWarConfig.NodeType.Term3SecretRoot] = require("XUi/XUiGuildWar/Map/XUiGridStage/XUiGridStageSecret"),
    [XGuildWarConfig.NodeType.Blockade] = require("XUi/XUiGuildWar/Map/XUiGridStage/XUiGridStageBlock"),
    [XGuildWarConfig.NodeType.Term4BossRoot] = require("XUi/XUiGuildWar/Map/XUiGridStage/XUiGridStageTerm4"),
    [XGuildWarConfig.NodeType.Resource] = require("XUi/XUiGuildWar/Map/XUiGridStage/XUiGridStageResource")
}
--类型节点对应的预制体路径
local NodeType2StagePerfabPath = {
    [XGuildWarConfig.NodeType.Resource] = "GuildWarStageType1",
    [XGuildWarConfig.NodeType.Normal] = "GuildWarStageType2",
    [XGuildWarConfig.NodeType.Buff] = "GuildWarStageType3",
    [XGuildWarConfig.NodeType.Sentinel] = "GuildWarStageType4",
    [XGuildWarConfig.NodeType.Guard] = "GuildWarStageType5",
    [XGuildWarConfig.NodeType.Infect] = "GuildWarStageType6",
    [XGuildWarConfig.NodeType.PandaRoot] = "GuildWarStageType7",
    [XGuildWarConfig.NodeType.TwinsRoot] = "GuildWarStageType8",
    [XGuildWarConfig.NodeType.SecondarySentinel] = "GuildWarStageType9",
    [XGuildWarConfig.NodeType.Term3SecretRoot] = "GuildWarStageType10",
    [XGuildWarConfig.NodeType.Blockade] = "GuildWarStageType16",
    [XGuildWarConfig.NodeType.Term4BossRoot] = "GuildWarStageType10",
}

--region 初始化
function XUiPanelStage:Ctor(ui, base, battleManager)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)

    ---@type XGWBattleManager
    self.BattleManager = battleManager
    self.FinishCountDic = {}

    self.IsPathEdit = false
    self.PathList = {}
    self.OldPathList = {}

    self:SetButtonCallBack()
    self:GroupInit()
    self:StageInit()
    self:MonsterInit()
    self:HideBeHitEffect()

    self.TimerBaseBeHitByBoss1 = false
    self.TimerBaseBeHitByBoss2 = false
end
--关卡地图和路线引用初始化
function XUiPanelStage:GroupInit()
    --关卡组列表
    self.StageGroupObjList = {
        [1] = self.StageGroupBase, --1 基地组
        [2] = self.StageGroupBoss, --2 敌人基地组
        [3] = self.StageGroupLine1, --3 路线1组
        [4] = self.StageGroupLine2, --4 路线2组
        [5] = self.StageGroupLine3, --5 路线3组
        [101] = self.StageGroupConceal, --101 隐藏区域
    }
    --关卡路线UIObject列表
    ---@type XUiGridLine[]
    self.GridLineList = {}
    --关卡地图背景的UIObject列表
    self.GridMapBgList = {}
    --关卡UITransform字典 Key关卡名(例 3-1)
    self.StagePosDic = {}
    --获取当前轮次所有节点列表
    self.AllNodesList = self.BattleManager:GetMainMapNodes()
    --关卡跟路线节点的字典 Key1关卡索引名1 key2关卡索引名2 Value XUiGridLine
    self.NodeNameToGridLineDic = {}
    --正在使用的关卡组哈希表 纯粹记录有哪些组被使用了
    local UsedStageGroupDic = {}
    for _, node in pairs(self.AllNodesList or {}) do
        UsedStageGroupDic[node:GetGroupIndex()] = true
    end
    --初始化关卡和路线的引用
    for groupIndex, stageGroup in pairs(self.StageGroupObjList) do
        if UsedStageGroupDic[groupIndex] then
            local groupUiObject = {}
            XUiHelper.InitUiClass(groupUiObject, stageGroup)
            local panelLine = groupUiObject.PanelLine
            local panelStage = groupUiObject.PanelStage
            local lineBg = groupUiObject.LineBg
            stageGroup.gameObject:SetActiveEx(true)

            --路线
            local index = 1
            while true do
                local line = panelLine.transform:FindTransform(string.format("Line%d", index))
                ---@type XUiGridLine
                local lineUiObject = line and XUiGridLine.New(line, self)
                if not lineUiObject then
                    break
                end
                table.insert(self.GridLineList, lineUiObject)
                if not self.NodeNameToGridLineDic[lineUiObject.StageName1] then
                    self.NodeNameToGridLineDic[lineUiObject.StageName1] = {}
                end
                self.NodeNameToGridLineDic[lineUiObject.StageName1][lineUiObject.StageName2] = lineUiObject
                if not self.NodeNameToGridLineDic[lineUiObject.StageName2] then
                    self.NodeNameToGridLineDic[lineUiObject.StageName2] = {}
                end
                self.NodeNameToGridLineDic[lineUiObject.StageName2][lineUiObject.StageName1] = lineUiObject
                index = index + 1
            end
            --关卡节点
            index = 1
            while true do
                local name = string.format("%d_%d", groupIndex, index)
                local stagePos = panelStage.transform:FindTransform(name)
                if not stagePos then
                    break
                end
                self.StagePosDic[name] = stagePos
                index = index + 1
            end
            --地图背景
            if lineBg then
                local bgObject = lineBg and XUiGridMapBg.New(lineBg, self)
                table.insert(self.GridMapBgList, bgObject)
            end
        else
            stageGroup.gameObject:SetActiveEx(false)
        end
    end
end
--初始化关卡
function XUiPanelStage:StageInit()
    --预制体列表
    local perfabList = {}
    for key, path in pairs(NodeType2StagePerfabPath) do
        perfabList[key] = self.Obj:GetPrefab(path)
    end

    ---@type XUiGridStage[]
    self.GridStageDic = {} --关卡StageGrid字典 Key关卡名(例 3-1)
    self.NodeId2GridStageDic = {} --关卡StageGrid字典 Key关卡NodeId(int)
    self.AllNodeDic = {} --节点Entity字典 Key关卡名(例 3-1)
    --关卡ID跟路线节点的字典 Key关卡名 Value XUiGridLine[]
    self.NodeIdToGridLineDic = {}
    for _, node in pairs(self.AllNodesList or {}) do
        local nodeType = node:GetNodeType()
        if perfabList[nodeType] then
            local obj = CS.UnityEngine.Object.Instantiate(perfabList[nodeType], self.StagePosDic[node:GetStageIndexName()])
            local GridScript = NodeType2StageGrid[nodeType]
            local grid = (GridScript and GridScript.New(obj, self)) or XUiGridStage.New(obj, self)
            self.GridStageDic[node:GetStageIndexName()] = grid
            self.NodeId2GridStageDic[node:GetId()] = grid
            self.AllNodeDic[node:GetStageIndexName()] = node
        end
    end
end
--初始化精英怪
function XUiPanelStage:MonsterInit()
    --怪物Grid字典 Alive正在运行的 Dead类似内存池？
    self.GridMonsterDic = {}
    self.GridMonsterDic["Alive"] = {}
    self.GridMonsterDic["Dead"] = {}
end
--设置按钮响应
function XUiPanelStage:SetButtonCallBack()

end
--endregion
--跟随XUiGuildWarStageMain的OnStart
function XUiPanelStage:OnStart()

end
--跟随XUiGuildWarStageMain的OnEnable
function XUiPanelStage:OnEnable()
    self:AddEventListener()
    self:ShowAction(true)
    self:StartActionCheck()
    self:StartDefendLeftTimeTimer()
end
--跟随XUiGuildWarStageMain的OnDisable
function XUiPanelStage:OnDisable()
    self:RemoveEventListener()
    self:StopActionPlay()
    self:StopActionCheck()
    self:StopDefendLeftTimeTimer()
end
--添加监听
function XUiPanelStage:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_CLOSE_MOVIEMODE, self.CloseMovieMode, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_STAGEDETAIL_CHANGE, self.SelectGridNode, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_TIME_REFRESH, self.UpdatePanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_NODEDATA_CHANGE, self.UpdatePanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_MONSTER_CHANGE, self.UpdateAllMonster, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_PLAYER_MOVE, self.UpdateStage, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_LOOKAT_ME, self.LookAtMySelfNode, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTIONLIST_OVER, self.DoActionOver, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_SECRETNODE_CAMERA, self.DoCameraMoveToSecretNode, self)
    --region 行为动画监听
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_OPEN_MOVIEMODE, self.OpenMovieMode, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_ROUND_START, self.ShowRoundStart, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_BORN, self.ShowMonsterBorn, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_MOVE, self.ShowMonsterMove, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_DEAD, self.ShowMonsterDead, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_BASEHIT, self.ShowBaseHit, self)
    --XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_BASE_BE_HIT_BY_BOSS, self.BaseBeHitByBoss, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_MONSTER_BORN_TIME_CHANGE, self.ShowMonsterBornTimeChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_BOSS_MERGE, self.ShowBossMerge, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_BOSS_TREAT_MONSTER, self.ShowBossTreatMonster, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_NODEDESTROY, self.ShowNodeDestroyed, self)
    self._FocusBase = function()
        self:FocusOnBase()
    end
    CS.XGameEventManager.Instance:RegisterEvent(XEventId.EVENT_GUIDE_START, self._FocusBase)
    --endregion
    
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_DEFEND_UPDATE,self.RefreshResourcesNode,self)
    --XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ATTACKINFO_UPDATE,self.RefreshResourcesNodeState,self)
end
--移除监听
function XUiPanelStage:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_OPEN_MOVIEMODE, self.OpenMovieMode, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_CLOSE_MOVIEMODE, self.CloseMovieMode, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_STAGEDETAIL_CHANGE, self.SelectGridNode, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_TIME_REFRESH, self.UpdatePanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_NODEDATA_CHANGE, self.UpdatePanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_MONSTER_CHANGE, self.UpdateAllMonster, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_PLAYER_MOVE, self.UpdateStage, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_LOOKAT_ME, self.LookAtMySelfNode, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTIONLIST_OVER, self.DoActionOver, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_SECRETNODE_CAMERA, self.DoCameraMoveToSecretNode, self)

    --region 行为动画监听
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_OPEN_MOVIEMODE, self.OpenMovieMode, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_ROUND_START, self.ShowRoundStart, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_BORN, self.ShowMonsterBorn, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_MOVE, self.ShowMonsterMove, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_DEAD, self.ShowMonsterDead, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_BASEHIT, self.ShowBaseHit, self)
    --XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_BASE_BE_HIT_BY_BOSS, self.BaseBeHitByBoss, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_MONSTER_BORN_TIME_CHANGE, self.ShowMonsterBornTimeChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_BOSS_MERGE, self.ShowBossMerge, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_BOSS_TREAT_MONSTER, self.ShowBossTreatMonster, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_NODEDESTROY, self.ShowNodeDestroyed, self)
    CS.XGameEventManager.Instance:RemoveEvent(XEventId.EVENT_GUIDE_START, self._FocusBase)

    --endregion
    self:StopTimerBaseBeHit()

    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_DEFEND_UPDATE,self.RefreshResourcesNode,self)
    --XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ATTACKINFO_UPDATE,self.RefreshResourcesNodeState,self)

end

--更新MonsterGrid的数据 并获取对应Grid的引用
function XUiPanelStage:UpdateGridMonster(monsterData, IsActionPlaying)
    local gridMonster
    --如果还活着 直接提取
    for _, grid in pairs(self.GridMonsterDic["Alive"] or {}) do
        if grid:GetMonsterUID() == monsterData:GetUID() then
            gridMonster = grid
            break
        end
    end
    --如果没活 从死区获取
    if not gridMonster then
        gridMonster = self.GridMonsterDic["Dead"][1]
        if gridMonster then
            table.remove(self.GridMonsterDic["Dead"], 1)
        else
            --如果死区为空 创建
            local obj = CS.UnityEngine.Object.Instantiate(self.Obj:GetPrefab("GuildWarStageMonster"), self.Transform)
            gridMonster = XUiGridMonster.New(obj, self, self.BattleManager)
        end
        table.insert(self.GridMonsterDic["Alive"], gridMonster)
    end
    gridMonster:ShowGrid(true)
    gridMonster:UpdateGrid(monsterData, self.IsPathEdit, IsActionPlaying)
    return gridMonster
end

--杀死MonsterGrid (回去内存池？)
function XUiPanelStage:KillGridMonster(gridMonster)
    local removeIndex = -1
    for index, grid in pairs(self.GridMonsterDic["Alive"] or {}) do
        if grid == gridMonster then
            removeIndex = index
            break
        end
    end
    if removeIndex > 0 then
        table.remove(self.GridMonsterDic["Alive"], removeIndex)
    end

    gridMonster:ShowGrid(false)
    table.insert(self.GridMonsterDic["Dead"], gridMonster)
end

--获取关卡节点的位置 indexName 关卡名(例 3-1)
function XUiPanelStage:GetNodePos(indexName)
    local pos = self.StagePosDic[indexName]
    return pos and pos.transform.position
end

--参数IsRetrograde为是否逆行
function XUiPanelStage:GetRootPosList(fromIndexName, toIndexName, IsRetrograde)
    local fromPos = self.StagePosDic[fromIndexName]
    local toPos = self.StagePosDic[toIndexName]
    local spotPosList = {}
    local index = 1

    while true do
        local spot
        if IsRetrograde then
            spot = fromPos.transform:FindTransform(string.format("Spot%d", index))
        else
            spot = toPos.transform:FindTransform(string.format("Spot%d", index))
        end

        if not spot then
            break
        end

        if IsRetrograde then
            table.insert(spotPosList, 1, spot.transform.position)
        else
            table.insert(spotPosList, spot.transform.position)
        end

        index = index + 1
    end

    table.insert(spotPosList, toPos.transform.position)

    return spotPosList
end

--刷新界面显示
function XUiPanelStage:UpdatePanel(isPathEditOver)
    self:UpdateAllMonster()
    self:UpdateStage(false, isPathEditOver)
    self:UpdateLine()
    self:UpdateLineBg()
end

--刷新关卡显示
function XUiPanelStage:UpdateStage(IsActionPlaying, isPathEditOver)
    --控制隐藏关区域显隐
    --local roundEntity = XDataCenter.GuildWarManager.GetCurrentRound()
    --local isFinish = roundEntity:GetBossIsDead()
    self.StageGroupConceal.gameObject:SetActiveEx(false)

    for key, node in pairs(self.AllNodeDic or {}) do
        local grid = self.GridStageDic[key]
        grid:UpdateGrid(node, self.IsPathEdit, IsActionPlaying, isPathEditOver, self)
    end
end

--刷新路线显示
function XUiPanelStage:UpdateLine()
    for _, lineUi in pairs(self.GridLineList or {}) do
        local node1 = self.AllNodeDic[lineUi.StageName1]
        local node2 = self.AllNodeDic[lineUi.StageName2]
        lineUi:UpdateViewByStageNode(node1, node2)
        lineUi:SetLineInPlan(false)
    end
    local pathList = self.BattleManager:GetNodePlanPathList()
    --因为路线不包含基地节点，所以要先画出基地节点到第一个路线点的路线显示。
    if #pathList > 0 then
        local nodeIndexName1 = BASENODE_INDEX
        local nodeIndexName2 = self.NodeId2GridStageDic[pathList[1]]:GetStageIndexName()
        local gridLine = self.NodeNameToGridLineDic[nodeIndexName1] and self.NodeNameToGridLineDic[nodeIndexName1][nodeIndexName2] or nil
        if gridLine then
            gridLine:SetLineInPlan(true)
        end
    end
    for i = 1, #pathList - 1, 1 do
        local nodeIndexName1 = self.NodeId2GridStageDic[pathList[i]]:GetStageIndexName()
        local nodeIndexName2 = self.NodeId2GridStageDic[pathList[i + 1]]:GetStageIndexName()
        local gridLine = self.NodeNameToGridLineDic[nodeIndexName1] and self.NodeNameToGridLineDic[nodeIndexName1][nodeIndexName2] or nil
        if gridLine then
            gridLine:SetLineInPlan(true)
        end
    end
end

--刷新地图背景显示
function XUiPanelStage:UpdateLineBg()
    local roundEntity = XDataCenter.GuildWarManager.GetCurrentRound()
    local isFinish = roundEntity:GetBossIsDead()
    for i, lineBg in ipairs(self.GridMapBgList) do
        lineBg:SetRoundFinish(isFinish)
    end
end


--刷新精英怪显示
function XUiPanelStage:UpdateAllMonster()
    local monsterEntityDic = self.BattleManager:GetMonsterDic()
    for _, monsterEntity in pairs(monsterEntityDic or {}) do
        if not monsterEntity:GetIsDead() then
            self:UpdateGridMonster(monsterEntity, false)
        end
    end
end

--刚进入界面时预先刷新地图上的精英怪显示
function XUiPanelStage:UpdatePreMonster()
    local preMonsterDataList = self.BattleManager:GetPreMonsterDataDic()

    for _, monsterData in pairs(preMonsterDataList or {}) do
        local monsterEntity = self.BattleManager:GetMonsterById(monsterData.UID)
        monsterEntity:UpdateCurrentRouteIndex(monsterData.NodeIndex)

        self:UpdateGridMonster(monsterEntity, true)
    end
end

--选择关卡节点Grid
function XUiPanelStage:SelectGridNode(stageIndexName, IsSelectMonster)
    local indexName = stageIndexName or ""

    for key, stageGrid in pairs(self.GridStageDic or {}) do
        stageGrid:DoSelect(key == indexName, not IsSelectMonster)
    end

    for _, monsterGrid in pairs(self.GridMonsterDic["Alive"] or {}) do
        local IsSelect = monsterGrid:GetMonsterCurrentNodeIndexName() == indexName and IsSelectMonster
        monsterGrid:DoSelect(IsSelect)
    end

    local gridNode = indexName and self.GridStageDic[indexName]
    self:PanelDragFocusTarget(gridNode)
end



---------------------------------------------------Action播放相关------------------------------------------------------------------
--region 行为动画播放

--开启新动作动画检测计时器
function XUiPanelStage:StartActionCheck()
    self.ActionShowTimer = XScheduleManager.ScheduleForever(function()
        if XLuaUiManager.GetTopUiName() == "UiGuildWarStageMain" and not self:CheckIsPathEdit() then
            self:ShowAction(false)
        end
    end, XScheduleManager.SECOND, 0)
end

--关闭新动作动画检测计时器
function XUiPanelStage:StopActionCheck()
    if self.ActionShowTimer then
        XScheduleManager.UnSchedule(self.ActionShowTimer)
        self.ActionShowTimer = nil
    end
end

-- 停止动作播放
function XUiPanelStage:StopActionPlay()
    if XLuaUiManager.IsMaskShow(XGuildWarConfig.MASK_KEY) then
        XLuaUiManager.SetMask(false, XGuildWarConfig.MASK_KEY)
    end

    for _, gridMonsterGroup in pairs(self.GridMonsterDic or {}) do
        for _, gridMonster in pairs(gridMonsterGroup or {}) do
            gridMonster:StopTween()
        end
    end

    for _, gridStage in pairs(self.GridStageDic or {}) do
        gridStage:StopTween()
    end
end

--开始播放行动动画
function XUiPanelStage:ShowAction(IsInit)
    local IsHasCanPlayAction = self.BattleManager:GetIsHasCanPlayAction(PlayTypeList)
    if not IsHasCanPlayAction and not IsInit then
        return
    end
    --正在播放 return
    if self.BattleManager:CheckActionPlaying() then
        return
    end
    if not XLuaUiManager.IsMaskShow(XGuildWarConfig.MASK_KEY) then
        XLuaUiManager.SetMask(true, XGuildWarConfig.MASK_KEY)
    end

    --初始化
    if IsInit then
        self:UpdatePreMonster() --预先初始化应该在地图上的怪物节点
        self:UpdateStage(true) --更新关卡节点数据
    end
    --检查有没有可以播放的行为动画 并播放
    self.BattleManager:CheckActionList(PlayTypeList)
end

--一个行动动画播放完毕时调用 
function XUiPanelStage:DoActionOver()
    if XLuaUiManager.IsMaskShow(XGuildWarConfig.MASK_KEY) then
        XLuaUiManager.SetMask(false, XGuildWarConfig.MASK_KEY)
    end
    self:UpdatePanel()
    self:JumpToJustPassedNode()
end

--开启电影模式(其实就是播放动画时 出现上下黑边 表现得像看电影一样)
function XUiPanelStage:OpenMovieMode(cb, actionGroup)
    --2期轮次开启时播放的据点交换动画(莫名其妙 3期已弃用)
    --local action = actionGroup[1]
    --if action and action.ActionType == XGuildWarConfig.GWActionType.RoundStart then
    --    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_EXCHANGE_NODE, action)
    --end

    local IsHistory = self.BattleManager:CheckIsHistoryAction()
    self:LookAllMap(true, cb)
    self.Base.ReviewPanel:ShowPanel(IsHistory and
            XGuildWarConfig.ActionShowType.History or
            XGuildWarConfig.ActionShowType.Now)
end

--关闭电影模式
function XUiPanelStage:CloseMovieMode()
    self:LookAllMap(false)
    self.Base.ReviewPanel:HidePanel()
    XDataCenter.GuideManager.CheckGuideOpen()
end

function XUiPanelStage:CheckFinishCount(maxCount, actType, cb)
    self.FinishCountDic[actType] = self.FinishCountDic[actType] + 1
    if self.FinishCountDic[actType] >= maxCount then
        if cb then
            cb()
        end
    end
end

--播放关卡Grid节点动画接口
function XUiPanelStage:PlayGridAction(actType, gridList, cb)
    self.FinishCountDic[actType] = 0
    if gridList and next(gridList) then
        for _, grid in pairs(gridList) do
            grid:ShowAction(actType, function()
                self:CheckFinishCount(#gridList, actType, cb)
            end)
        end
    else
        self:CheckFinishCount(0, actType, cb)
    end
end
--region 动画事件
--回合开始
function XUiPanelStage:ShowRoundStart(actionGroup)
    self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.RoundStart, PlayTypeList)
end
--怪物死亡
function XUiPanelStage:ShowMonsterDead(actionGroup)
    local gridShowMonsterList = {}
    for _, action in pairs(actionGroup or {}) do
        local monsterEntity = self.BattleManager:GetMonsterById(action.MonsterUid)
        monsterEntity:UpdateCurrentRouteIndex(action.CurNodeIdx)

        local gridMonster = self:UpdateGridMonster(monsterEntity, true)
        table.insert(gridShowMonsterList, gridMonster)
    end

    self:PlayGridAction(XGuildWarConfig.GWActionType.MonsterDead, gridShowMonsterList, function()
        self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.MonsterDead, PlayTypeList)
    end)
end
--怪物诞生
function XUiPanelStage:ShowMonsterBorn(actionGroup)
    local gridShowMonsterList = {}
    for _, action in pairs(actionGroup or {}) do
        local monsterEntity = self.BattleManager:GetMonsterById(action.MonsterUid)
        monsterEntity:UpdateWithServerData(action.MonsterData)

        local gridMonster = self:UpdateGridMonster(monsterEntity, true)
        gridMonster:ShowGrid(false)
        table.insert(gridShowMonsterList, gridMonster)
    end

    self:PlayGridAction(XGuildWarConfig.GWActionType.MonsterBorn, gridShowMonsterList, function()
        self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.MonsterBorn, PlayTypeList)
    end)
end
--怪物移动
function XUiPanelStage:ShowMonsterMove(actionGroup)
    local gridShowMonsterList = {}
    for _, action in pairs(actionGroup or {}) do
        local monsterEntity = self.BattleManager:GetMonsterById(action.MonsterUid)
        monsterEntity:UpdateCurrentRouteIndex(action.PreNodeIdx)
        monsterEntity:UpdateNextRouteIndex(action.NextNodeIdx)

        local gridMonster = self:UpdateGridMonster(monsterEntity, true)
        table.insert(gridShowMonsterList, gridMonster)
    end

    self:PlayGridAction(XGuildWarConfig.GWActionType.MonsterMove, gridShowMonsterList, function()
        self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.MonsterMove, PlayTypeList)
    end)
end
--基地受伤
function XUiPanelStage:ShowBaseHit(actionGroup)
    local damageDic = {}
    local gridNodeList = {}
    local addDic = {}
    for _, action in pairs(actionGroup or {}) do
        for _, node in pairs(self.AllNodesList or {}) do
            if node:GetUID() == action.NodeUid then
                local indexName = node:GetStageIndexName()
                local grid = self.GridStageDic[indexName]
                node:UpdateWithServerData(action.NodeData)
                grid:UpdateGrid(node, false, true)

                damageDic[indexName] = damageDic[indexName] or 0
                damageDic[indexName] = damageDic[indexName] + action.Damage
                grid:SetDamage(damageDic[indexName])
                if not addDic[indexName] then
                    table.insert(gridNodeList, grid)
                    addDic[indexName] = true
                end
                break
            end
        end
    end

    self:PlayGridAction(XGuildWarConfig.GWActionType.BaseBeHit, gridNodeList, function()
        self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.BaseBeHit, PlayTypeList)
    end)
end
--基地被boss攻击
function XUiPanelStage:BaseBeHitByBoss(actionGroup)
    if self.TimerBaseBeHitByBoss1 or self.TimerBaseBeHitByBoss2 then
        return
    end
    self.TimerBaseBeHitByBoss1 = XScheduleManager.ScheduleOnce(function()
        self.TimerBaseBeHitByBoss1 = false

        XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.GuildWar_FireToBase, XSoundManager.SoundType.Sound)
        self:SetActiveStageEffectObj(self.StageGroupBoss, "ImgEffectFashe", true)
        self:SetActiveStageEffectObj(self.StageGroupBoss, "ImgEffectDandao", true)
        self.TimerBaseBeHitByBoss1 = XScheduleManager.ScheduleOnce(function()
            self.TimerBaseBeHitByBoss1 = false
            self:HideBeHitEffect()
            XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.GuildWar_BaseBeHit, XSoundManager.SoundType.Sound)
            self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.BaseBeHitByBoss, PlayTypeList)
        end, 1.5 * XScheduleManager.SECOND)

        self.TimerBaseBeHitByBoss2 = XScheduleManager.ScheduleOnce(function()
            self:SetActiveStageEffectObj(self.StageGroupBase, "ImgEffectShouji", true)
            self.TimerBaseBeHitByBoss2 = false
        end, 1 * XScheduleManager.SECOND)
    end, BornWaitTime)
end
--小前哨被击破
function XUiPanelStage:ShowMonsterBornTimeChange(actionGroup)
    self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.MonsterBornTimeChange, PlayTypeList)
end
--Boss合体
function XUiPanelStage:ShowBossMerge(actionGroup)
    self.GridStageDic[BOSSNODE_INDEX]:UpdateBoss(false, false, true)
    self:PanelDragFocusTarget(self.GridStageDic[BOSSNODE_INDEX])
    if not self.BossMergeTimer then
        self.BossMergeTimer = XScheduleManager.ScheduleOnce(function()
            self.BossMergeTimer = nil
            self:PlayGridAction(XGuildWarConfig.GWActionType.BossMerge, { self.GridStageDic[BOSSNODE_INDEX] }, function()
                self:UpdatePanel()
                self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.BossMerge, PlayTypeList)
            end)
        end, XScheduleManager.SECOND)
    end
end
--BOSS治疗怪物
function XUiPanelStage:ShowBossTreatMonster(actionGroup)
    self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.BossTreatMonster, PlayTypeList)
end
--节点攻破
function XUiPanelStage:ShowNodeDestroyed(actionGroup)
    self:UpdatePanel()
    XDataCenter.GuildWarManager.ShowNodeDestroyed(actionGroup, function()
        self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.NodeDestroyed, PlayTypeList)
    end)
end
--endregion

--endregion
---------------------------------------界面聚焦相关-------------------------------------------------
--region 界面聚焦
function XUiPanelStage:LookAtMySelfNode()
    for key, node in pairs(self.AllNodeDic or {}) do
        if node:GetIsPlayerNode() then
            local grid = self.GridStageDic[key]
            self:PanelDragFocusTarget(grid)
            return
        end
    end
    --不在任何节点上时(没参加活动资格) 定位到基地
    local grid = self.GridStageDic[BASENODE_INDEX]
    self:PanelDragFocusTarget(grid)
end

function XUiPanelStage:GetMySelfNode()
    for key, node in pairs(self.AllNodeDic or {}) do
        if node:GetIsPlayerNode() then
            return self.GridStageDic[key]
        end
    end
    return
end

function XUiPanelStage:PanelDragFocusTarget(gridNode)
    local tagPos = gridNode and Vector3(gridNode.Transform.position.x + 2, gridNode.Transform.position.y, self.PanelDrag.transform.position.z) or self.PanelDrag.transform.position----TODO工具需要修改
    local scale = gridNode and self.PanelDrag.MaxScale or 1
    self.PanelDrag:FocusPos(tagPos, scale, PanelDragFocusTime, CS.UnityEngine.Vector3.zero)
end

function XUiPanelStage:LookAllMap(IsLook, cb)
    local firstGrid = {}
    local lastGrid = {}
    local tagTra = self:GetMySelfNode() or self.GridStageDic[BASENODE_INDEX]

    for key, node in pairs(self.AllNodeDic or {}) do
        if node:GetNodeType() == XGuildWarConfig.NodeType.Home or node:GetNodeType() == XGuildWarConfig.NodeType.Resource then
            firstGrid = self.GridStageDic[node:GetStageIndexName()]
        elseif node:GetIsLastNode() then
            lastGrid = self.GridStageDic[node:GetStageIndexName()]
        end
    end

    local tagPos
    if IsLook then
        tagPos = (firstGrid.Transform.position + lastGrid.Transform.position) / 2
    else
        tagPos = tagTra and tagTra.Transform.position or self.PanelDrag.transform.position
    end

    tagPos.z = self.PanelDrag.transform.position.z
    local scale = IsLook and self.PanelDrag.MinScale or 1
    self.PanelDrag:FocusPos(tagPos, scale, PanelDragFocusTime, CS.UnityEngine.Vector3.zero, cb)
end
--endregion
-------------------------------------------路径编辑相关-------------------------------------------------
--region 路径编辑
--进入编辑模式
function XUiPanelStage:PathEdit()
    self:RemoveEventListener()
    self.IsPathEdit = true
    self:UpdatePanel()
    self.PathList = {}
    self.OldPathList = self.BattleManager:GetNodePlanPathList()
    for _, nodeId in ipairs(self.OldPathList) do
        table.insert(self.PathList, nodeId)
    end
end

--检查节点是否在路线中 返回节点位置
function XUiPanelStage:CheckNodeInPlanPath(targetNodeId)
    for index, nodeId in ipairs(self.PathList) do
        if nodeId == targetNodeId then
            return index
        end
    end
    return -1
end

--点击据点进行 增加 删除 路线操作
function XUiPanelStage:AddPath(nodeId, grid)
    local maxCount = XDataCenter.GuildWarManager.GetPathMarkMaxCount()
    local nodeIndex = self:CheckNodeInPlanPath(nodeId)
    --卸载节点操作
    if nodeIndex > -1 then
        for i = #self.PathList, nodeIndex, -1 do
            local lastNodeId = self.PathList[i]
            table.remove(self.PathList)
            local grid = self.NodeId2GridStageDic[lastNodeId]
            grid:DoPathMark(false)
            local lastStageGrid = self.PathList[i - 1] and self.NodeId2GridStageDic[self.PathList[i - 1]] or self.GridStageDic[BASENODE_INDEX] --默认第一个节点是基地
            local gridLine = self.NodeNameToGridLineDic[lastStageGrid:GetStageIndexName()] and self.NodeNameToGridLineDic[lastStageGrid:GetStageIndexName()][grid:GetStageIndexName()] or nil
            if gridLine then
                gridLine:SetLineInPlan(false)
            end
        end
    else
        --增加节点操作
        local lastStageGrid --路线最后的节点
        if #self.PathList == 0 then
            lastStageGrid = self.GridStageDic[BASENODE_INDEX] --默认第一个节点是基地
        else
            lastStageGrid = self.NodeId2GridStageDic[self.PathList[#self.PathList]] --路线最后节点
        end
        local lastNode = lastStageGrid.StageNode
        local lastChildNodes = lastNode:GetNextNodes()
        local operationSuccess = false
        for _, childNode in ipairs(lastChildNodes) do
            if nodeId == childNode:GetId() then
                --如果新节点可以构成连线
                table.insert(self.PathList, nodeId)
                grid:DoPathMark(true)
                local gridLine = self.NodeNameToGridLineDic[lastStageGrid:GetStageIndexName()] and self.NodeNameToGridLineDic[lastStageGrid:GetStageIndexName()][grid:GetStageIndexName()] or nil
                if gridLine then
                    gridLine:SetLineInPlan(true)
                    operationSuccess = true
                end
            end
        end
        if not operationSuccess then
            XUiManager.TipMsg(CS.XTextManager.GetText("GuildWarEditPathCantLink"))
        end
    end
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_PATHEDIT_PATHCHANGE, self:CheckPathChange(self.PathList))
end

--检查路线是否变更
function XUiPanelStage:CheckPathChange(newPathList)
    if not (#newPathList == #self.OldPathList) then
        return true
    end
    for i = 1, #newPathList do
        if not (newPathList[i] == self.OldPathList[i]) then
            return true
        end
    end
    return false
end

--检查UI是否在编辑路线中
function XUiPanelStage:CheckIsPathEdit()
    return self.IsPathEdit
end

--编辑完毕 保存编辑结果
function XUiPanelStage:PathEditOver(IsSave, cb)
    local callBack = function()
        if cb then
            cb()
        end
        self:AddEventListener()
        self.IsPathEdit = false
        self:UpdatePanel(true)
    end

    if IsSave then
        XDataCenter.GuildWarManager.EditPlan(self.PathList, function()
            XUiManager.TipText("GuildWarPathEditOverHint")
            callBack()
        end)
    else
        callBack()
    end
end
--endregion

function XUiPanelStage:DoCameraMoveToSecretNode()
    local gridNode = indexName and self.GridStageDic[SECRETNODE_INDEX]
    self:PanelDragFocusTarget(gridNode)
    if not self.CameraMoveTimer then
        self.CameraMoveTimer = XScheduleManager.ScheduleOnce(function()
            self.CameraMoveTimer = nil
            XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_SECRETNODE_CAMERA_DONE)
        end, XScheduleManager.SECOND)
    end
end

function XUiPanelStage:SetActiveStageEffectObj(ui, effectObjName, isActive)
    local groupUiObject = ui.transform:GetComponent("UiObject")
    local effectObj = groupUiObject:GetObject(effectObjName)
    if effectObj then
        effectObj.gameObject:SetActiveEx(isActive)
    end
end

function XUiPanelStage:HideBeHitEffect()
    self:SetActiveStageEffectObj(self.StageGroupBase, "ImgEffectShouji", false)
    self:SetActiveStageEffectObj(self.StageGroupBoss, "ImgEffectFashe", false)
    self:SetActiveStageEffectObj(self.StageGroupBoss, "ImgEffectDandao", false)
end

function XUiPanelStage:JumpToJustPassedNode()
    ---@type XGWNode
    local node = XDataCenter.GuildWarManager.GetJustPassedNode()
    if node then
        if node:GetIsTerm4Boss() then
            return
        end
        local uiGridStage = self:GetMySelfNode()
        if uiGridStage then
            uiGridStage:OnBtnStageClick(node:GetId(), true)
        end
    end
end

function XUiPanelStage:StopTimerBaseBeHit()
    if self.TimerBaseBeHitByBoss2 then
        XScheduleManager.UnSchedule(self.TimerBaseBeHitByBoss2)
        self.TimerBaseBeHitByBoss2 = false
    end
    if self.TimerBaseBeHitByBoss1 then
        XScheduleManager.UnSchedule(self.TimerBaseBeHitByBoss1)
        self.TimerBaseBeHitByBoss1 = false
    end
end

function XUiPanelStage:FocusOnBase()
    if XDataCenter.GuideManager.CheckIsGuide(61332) then
        local grid = self.GridStageDic[BASENODE_INDEX]
        self:PanelDragFocusTarget(grid)
    end
end

function XUiPanelStage:RefreshResourcesNode()
    for i, v in pairs(self.AllNodeDic) do
        if v:GetNodeType() == XGuildWarConfig.NodeType.Resource then
            self.GridStageDic[i]:RefreshGarrison()
            self.GridStageDic[i]:RefreshNormalIcon()
        end
    end
end

function XUiPanelStage:RefreshResourcesNodeState()
    for i, v in pairs(self.AllNodeDic) do
        if v:GetNodeType() == XGuildWarConfig.NodeType.Resource then
            self.GridStageDic[i]:UpdateNodeData()
            self.GridStageDic[i]:RefreshGarrison()
            self.GridStageDic[i]:RefreshRebuildState()
            self.GridStageDic[i]:RefreshNormalIcon()
        end
    end
end 

function XUiPanelStage:SetResourcesDisplayWithAttackAnimation(isAnimation)
    for i, v in pairs(self.AllNodeDic) do
        if v:GetNodeType() == XGuildWarConfig.NodeType.Resource then
            self.GridStageDic[i]:SetDisplayWithAttackAnimation(isAnimation)
        end
    end
end

function XUiPanelStage:StartDefendLeftTimeTimer()
    if XDataCenter.GuildWarManager.CheckRoundIsInTime() then
        self.TextDefendTime.transform.parent.gameObject:SetActiveEx(true)
        self:StopDefendLeftTimeTimer()
        self:UpdateDefendLeftTime()
        self.DefendLeftTimeTimerId = XScheduleManager.ScheduleForever(handler(self,self.UpdateDefendLeftTime),XScheduleManager.SECOND,0)
    else
        self.TextDefendTime.transform.parent.gameObject:SetActiveEx(false)
    end
end

function XUiPanelStage:StopDefendLeftTimeTimer()
    if self.DefendLeftTimeTimerId then
        XScheduleManager.UnSchedule(self.DefendLeftTimeTimerId)
    end
end

function XUiPanelStage:UpdateDefendLeftTime()
    if not XDataCenter.GuildWarManager.CheckRoundIsInTime() then
        self.TextDefendTime.transform.parent.gameObject:SetActiveEx(false)
        self:StopDefendLeftTimeTimer()
        return
    end
    local nextTime = XDataCenter.GuildWarManager.GetNextAttackedTime()
    local leftTime = nextTime - XTime.GetServerNowTimestamp()

    self.TextDefendTime.transform.parent.gameObject:SetActiveEx(leftTime >= 0)
    
    self.TextDefendTime.text = XUiHelper.FormatText(XGuildWarConfig.GetClientConfigValues('DefendTime')[1],XUiHelper.GetTime(leftTime,XUiHelper.TimeFormatType.DAY_HOUR_SIMPLY))
end

return XUiPanelStage