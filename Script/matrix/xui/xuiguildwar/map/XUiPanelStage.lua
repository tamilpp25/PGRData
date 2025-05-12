---@class XUiGuildWarPanelStage: XUiNode
---@field _Control XGuildWarControl
---@field Parent XLuaUi
local XUiPanelStage = XClass(XUiNode, "XUiPanelStage")

local XUiGridStage = require("XUi/XUiGuildWar/Map/XUiGridStage/XUiGridStage")
local XUiGridMonster = require("XUi/XUiGuildWar/Map/XUiGridMonster")
local XUiGridReinforcements = require('XUi/XUiGuildWar/Map/XUiGridReinforcements')
local XUiGridLine = require("XUi/XUiGuildWar/Map/XUiGridLine")
local XUiGridMapBg = require("XUi/XUiGuildWar/Map/XUiGridMapBg")
local XUiGridStageContainer = require('XUi/XUiGuildWar/Map/XUiGridStage/XUiGridStageContainer')
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
    [XGuildWarConfig.NodeType.Resource] = require("XUi/XUiGuildWar/Map/XUiGridStage/XUiGridStageResource"),
    [XGuildWarConfig.NodeType.NodeBoss7] = require("XUi/XUiGuildWar/Map/XUiGridStage/XUiGridStageBoss7"),
}
--类型节点对应的预制体路径
local NodeType2StagePerfabPath = {
    [XGuildWarConfig.NodeType.Resource] = "GuildWarStageType1", -- 之前实装驻守点的时候UI预制是直接在基地上改的。因此共用。后面如需再开最好单独一个预制
    [XGuildWarConfig.NodeType.Home] = "GuildWarStageType1",
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
    [XGuildWarConfig.NodeType.NodeBoss7] = "GuildWarStageType10",
    [XGuildWarConfig.NodeType.NodeRelic] = "GuildWarStageType2",
}

--region 初始化
function XUiPanelStage:OnStart(base, battleManager)
    self.Base = base

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
    self:ReinforcementsInit()
    self:HideBeHitEffect()

    self.TimerBaseBeHitByBoss1 = false
    self.TimerBaseBeHitByBoss2 = false

    self.TimerMap = {}
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
    self.AllNodesList = self._Control:GetMainMapNodes()
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

    if self.GridStageDic == nil then
        ---@type XUiGridStageContainer[]
        self.GridStageDic = {} --关卡StageGrid字典 Key关卡名(例 3-1)
    end

    if self.NodeId2GridStageDic == nil then
        self.NodeId2GridStageDic = {} --关卡StageGrid字典 Key关卡NodeId(int)
    end
    
    self.AllNodeDic = {} --节点Entity字典 Key关卡名(例 3-1)
    
    for _, node in pairs(self.AllNodesList or {}) do
        local nodeType = node:GetNodeType()
        if perfabList[nodeType] then
            -- 节点隶属的容器的key
            local containerKey = node:GetStageIndexName()
            local nodeId = node:GetId()
            
            if not self.GridStageDic[containerKey] then
                self.GridStageDic[containerKey] = XUiGridStageContainer.New(self.StagePosDic[containerKey], self)
                self.GridStageDic[containerKey]:Open()
            end

            if not self.GridStageDic[containerKey]:CheckContainsNodeId(nodeId) then
                -- 实例化节点UI
                local obj = CS.UnityEngine.Object.Instantiate(perfabList[nodeType], self.StagePosDic[node:GetStageIndexName()])
                local GridScript = NodeType2StageGrid[nodeType]
                local grid = (GridScript and GridScript.New(obj, self)) or XUiGridStage.New(obj, self)

                -- 将节点传给对应容器
                self.GridStageDic[containerKey]:AddUiGridNode(nodeId, grid)

                self.NodeId2GridStageDic[node:GetId()] = grid
                grid:SetNodeEntityOnly(node)
            end

            self.GridStageDic[containerKey]:SetShowOnly(node:GetId())
            self.AllNodeDic[containerKey] = node
        end
    end
    
    self:RefreshSpecialStage()
end

function XUiPanelStage:RefreshSpecialStage()
    -- 特殊刷新显示
    local dragonRageNodes = self._Control.DragonRageControl:GetMainMapNodesWithDragonRage()

    if not XTool.IsTableEmpty(dragonRageNodes) then
        local isDragonRageOpen = self._Control.DragonRageControl:GetIsOpenDragonRage()
        for i, v in pairs(dragonRageNodes) do
            local containerKey = v:GetStageIndexName()
            self.GridStageDic[containerKey]:SetShowOnly(v:GetId())
            self.AllNodeDic[containerKey] = v

            ---@type XUiGridStage
            local grid = self.GridStageDic[containerKey]:GetCurShowGrid()
            if grid then
                grid.ComDragonRage:PlayDragonRageStateShow(isDragonRageOpen)
            end
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

--跟随XUiGuildWarStageMain的OnEnable
function XUiPanelStage:OnEnable()
    self:AddEventListener()
    self:ShowAction(true)
    self:StartActionCheck()
    self:StartDefendLeftTimeTimer()
    XMVCA.XGuildWar.DragonRageCom:SetIsNewGameThroughActionWaitToPlay(nil)
end
--跟随XUiGuildWarStageMain的OnDisable
function XUiPanelStage:OnDisable()
    self:RemoveEventListener()
    self:StopActionPlay()
    self:StopActionCheck()
    self:StopDefendLeftTimeTimer()
    self:ClearAllTimer()
    XMVCA.XGuildWar.DragonRageCom:SetIsNewGameThroughActionWaitToPlay(nil)
end
--添加监听
function XUiPanelStage:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_CLOSE_MOVIEMODE, self.CloseMovieMode, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_STAGEDETAIL_CHANGE, self.SelectGridNode, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_TIME_REFRESH, self.UpdatePanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_NODEDATA_CHANGE, self.UpdatePanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_MONSTER_CHANGE, self.UpdateAllMonster, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_PLAYER_MOVE, self.UpdateAfterPlayerMove, self)
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

    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_REINFORCEMENTS_BORN, self.ShowReinforcementsBorn, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_REINFORCEMENTS_MOVE, self.ShowReinforcementsMove, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_REINFORCEMENTS_ATTACK, self.ShowReinforcementsAttack, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_REINFORCEMENTS_DEAD, self.ShowReinforcementsDead, self)
    --XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_BASE_BE_HIT_BY_BOSS, self.BaseBeHitByBoss, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_MONSTER_BORN_TIME_CHANGE, self.ShowMonsterBornTimeChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_BOSS_MERGE, self.ShowBossMerge, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_BOSS_TREAT_MONSTER, self.ShowBossTreatMonster, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_NODEDESTROY, self.ShowNodeDestroyed, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_DRAGON_RAGE_EMPTY, self.ShowDragonRageEmpty, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_DRAGON_RAGE_FULL, self.ShowDragonRageFull, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_DRAGON_RAGE_CHANGE_RELIC, self.ShowNodeToRelic, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_DRAGON_RAGE_NEW_GAMETHROUH, self.ShowNewGameThough, self)
    
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
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_PLAYER_MOVE, self.UpdateAfterPlayerMove, self)
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

    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_REINFORCEMENTS_BORN, self.ShowReinforcementsBorn, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_REINFORCEMENTS_MOVE, self.ShowReinforcementsMove, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_REINFORCEMENTS_ATTACK, self.ShowReinforcementsAttack, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_REINFORCEMENTS_DEAD, self.ShowReinforcementsDead, self)
    --XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_BASE_BE_HIT_BY_BOSS, self.BaseBeHitByBoss, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_MONSTER_BORN_TIME_CHANGE, self.ShowMonsterBornTimeChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_BOSS_MERGE, self.ShowBossMerge, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_BOSS_TREAT_MONSTER, self.ShowBossTreatMonster, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_NODEDESTROY, self.ShowNodeDestroyed, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_DRAGON_RAGE_EMPTY, self.ShowDragonRageEmpty, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_DRAGON_RAGE_FULL, self.ShowDragonRageFull, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_DRAGON_RAGE_CHANGE_RELIC, self.ShowNodeToRelic, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_DRAGON_RAGE_NEW_GAMETHROUH, self.ShowNewGameThough, self)

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
    self:UpdateAllReinforcements()
    self:UpdateStage(false, isPathEditOver)
    self:UpdateLine()
    self:UpdateLineBg()
    self:UpdateDragonRageShow()
end

function XUiPanelStage:UpdateAfterPlayerMove()
    self:UpdateStage()
    self:UpdateLine()
    self:UpdateLineBg()
end

--刷新关卡显示
function XUiPanelStage:UpdateStage(IsActionPlaying, isPathEditOver)
    self.StageGroupConceal.gameObject:SetActiveEx(false)

    for key, node in pairs(self.AllNodeDic or {}) do
        ---@type XUiGridStageContainer
        local container = self.GridStageDic[key]
        container:UpdateUiGridByNodeData(node, self.IsPathEdit, IsActionPlaying, isPathEditOver, self)
    end
end

--刷新路线显示
function XUiPanelStage:UpdateLine()
    local moveDistanceMap = self._Control:GetMoveDistanceMap()
    local preNodes = self._Control:GetMovePreNodes(moveDistanceMap)
    
    for _, lineUi in pairs(self.GridLineList or {}) do
        local node1 = self.AllNodeDic[lineUi.StageName1]
        local node2 = self.AllNodeDic[lineUi.StageName2]

        if XTool.IsNumberValid(node1:GetRootId()) then
            node1 = XDataCenter.GuildWarManager.GetNode(node1:GetRootId())
        end

        if XTool.IsNumberValid(node2:GetRootId()) then
            node2 = XDataCenter.GuildWarManager.GetNode(node2:GetRootId())
        end
        
        lineUi:UpdateViewByStageNode(node1, node2, preNodes)
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
function XUiPanelStage:SelectGridNode(stageIndexName, IsSelectMonster, IsSelectReinforcements)
    local indexName = stageIndexName or ""

    if not XTool.IsTableEmpty(self.GridStageDic) then
        for key, container in pairs(self.GridStageDic) do
            local stageGrid = container:GetCurShowGrid()

            if stageGrid then
                stageGrid:DoSelect(key == indexName, not IsSelectMonster and not IsSelectReinforcements)
            end
        end
    end

    if not XTool.IsTableEmpty(self.GridMonsterDic) then
        for _, monsterGrid in pairs(self.GridMonsterDic["Alive"]) do
            local IsSelect = monsterGrid:GetMonsterCurrentNodeIndexName() == indexName and IsSelectMonster
            monsterGrid:DoSelect(IsSelect)
        end
    end

    if not XTool.IsTableEmpty(self.GridReinforcementsDic) then
        for _, reinforcementGrid in pairs(self.GridReinforcementsDic["Alive"] ) do
            local IsSelect = reinforcementGrid:GetReinforcementCurrentNodeIndexName() == indexName and IsSelectReinforcements
            reinforcementGrid:DoSelect(IsSelect)
        end
    end

    local gridNode = not string.IsNilOrEmpty(indexName) and self.GridStageDic[indexName]:GetCurShowGrid()
    self:PanelDragFocusTarget(gridNode)
end

--region -------------- 援军相关 ----------------------->>>
--初始化精英怪
function XUiPanelStage:ReinforcementsInit()
    --怪物Grid字典 Alive正在运行的 Dead类似内存池？
    self.GridReinforcementsDic = {}
    self.GridReinforcementsDic["Alive"] = {}
    self.GridReinforcementsDic["Dead"] = {}
end

--刚进入界面时预先刷新地图上的援军显示
function XUiPanelStage:UpdatePreReinforcements()
    local preReinforcementDataList = self.BattleManager:GetPreReinforcementDataDic()

    if not XTool.IsTableEmpty(preReinforcementDataList) then
        for _, reinforcementData in pairs(preReinforcementDataList) do
            local reinforcementEntity = self.BattleManager:GetReinforcementById(reinforcementData.UID)
            reinforcementEntity:UpdateCurrentNodeId(reinforcementData.NodeId)

            self:UpdateGridReinforcement(reinforcementEntity, false)
        end
    end
end

--刷新援军显示
function XUiPanelStage:UpdateAllReinforcements()
    local reinforcementsDict = self.BattleManager:GetReinforcementsDic()

    if not XTool.IsTableEmpty(reinforcementsDict) then
        for _, entity in pairs(reinforcementsDict) do
            if not entity:GetIsDead() then
                self:UpdateGridReinforcement(entity, false)
            end
        end
    end
end

--更新ReinforceGrid的数据 并获取对应Grid的引用
function XUiPanelStage:UpdateGridReinforcement(reinforcementData, IsActionPlaying)
    local gridReinforcements = nil
    --如果还活着 直接提取
    if not XTool.IsTableEmpty(self.GridReinforcementsDic) then
        for _, grid in pairs(self.GridReinforcementsDic["Alive"]) do
            if grid:GetReinforcementUID() == reinforcementData:GetUID() then
                gridReinforcements = grid
                break
            end
        end
    end
    --如果没活 从死区获取
    if not gridReinforcements then
        gridReinforcements = self.GridReinforcementsDic["Dead"][1]
        if gridReinforcements then
            table.remove(self.GridReinforcementsDic["Dead"], 1)
        else
            --如果死区为空 创建
            local obj = CS.UnityEngine.Object.Instantiate(self.Obj:GetPrefab("GuildWarStageReinforce"), self.Transform)
            gridReinforcements = XUiGridReinforcements.New(obj, self, self.BattleManager)
        end
        table.insert(self.GridReinforcementsDic["Alive"], gridReinforcements)
    end
    gridReinforcements:UpdateGrid(reinforcementData, self.IsPathEdit, IsActionPlaying)
    gridReinforcements:ShowGrid(true)
    return gridReinforcements
end

--杀死ReinforceGrid (回去内存池？)
function XUiPanelStage:KillGridReinforcement(gridReinforce)
    local removeIndex = -1
    if not XTool.IsTableEmpty(self.GridReinforcementsDic["Alive"]) then
        for index, grid in pairs(self.GridReinforcementsDic["Alive"]) do
            if grid == gridReinforce then
                removeIndex = index
                break
            end
        end
        if removeIndex > 0 then
            table.remove(self.GridReinforcementsDic["Alive"], removeIndex)
        end
    end

    gridReinforce:ShowGrid(false)
    table.insert(self.GridReinforcementsDic["Dead"], gridReinforce)
end
--endregion <<<------------------------------------------

--region ---------- 龙怒系统相关 ---------->>>
function XUiPanelStage:UpdateDragonRageShow()
    if self.EffectFull and XMVCA.XGuildWar.DragonRageCom:IsOpenDragonRageSystem() then
        self.EffectFull.gameObject:SetActiveEx(self._Control.DragonRageControl:GetIsDragonRageValueDown())
    end
end

--endregion <<<----------------------------

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

    for _, container in pairs(self.GridStageDic or {}) do
        local gridStage = container:GetCurShowGrid()
        if gridStage then
            gridStage:StopTween()
        end
    end

    if not XTool.IsTableEmpty(self.GridReinforcementsDic) then
        for _, gridReinforcementsGroup in pairs(self.GridReinforcementsDic) do
            for _, gridReinforcements in pairs(gridReinforcementsGroup) do
                gridReinforcements:StopTween()
            end
        end
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
        self:UpdatePreReinforcements() -- 初始化援军节点
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
                local grid = self.GridStageDic[indexName]:GetCurShowGrid()
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

        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.GuildWar_FireToBase)
        self:SetActiveStageEffectObj(self.StageGroupBoss, "ImgEffectFashe", true)
        self:SetActiveStageEffectObj(self.StageGroupBoss, "ImgEffectDandao", true)
        self.TimerBaseBeHitByBoss1 = XScheduleManager.ScheduleOnce(function()
            self.TimerBaseBeHitByBoss1 = false
            self:HideBeHitEffect()
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.GuildWar_BaseBeHit)
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
    local grid = self.GridStageDic[BOSSNODE_INDEX]:GetCurShowGrid()
    grid:UpdateBoss(false, false, true)
    self:PanelDragFocusTarget(grid)
    if not self.BossMergeTimer then
        self.BossMergeTimer = XScheduleManager.ScheduleOnce(function()
            self.BossMergeTimer = nil
            self:PlayGridAction(XGuildWarConfig.GWActionType.BossMerge, { grid }, function()
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
    self:StageInit()
    self:UpdatePanel()
    XDataCenter.GuildWarManager.ShowNodeDestroyed(actionGroup, function()
        self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.NodeDestroyed, PlayTypeList)
    end)
end

-- 援军生成
function XUiPanelStage:ShowReinforcementsBorn(actionGroup)
    local gridShowReinforcementsList = {}
    local isFirstBorn = false
    
    -- 只取最后一次批量下发的action
    if not XTool.IsTableEmpty(actionGroup) then
        -- 生成需要判断初生，得整个表都遍历
        for _, action in pairs(actionGroup) do
            if action.FirstBorn then
                isFirstBorn = true
            end

            local reinforcementsEntity = self.BattleManager:GetReinforcementById(action.ReinforcementUid)

            if reinforcementsEntity then
                reinforcementsEntity:UpdateWithServerData(action.ReinforcementData)

                local gridReinforcement = self:UpdateGridReinforcement(reinforcementsEntity, true)
                gridReinforcement:ShowGrid(false)
                table.insert(gridShowReinforcementsList, gridReinforcement)
            end
        end
    end

    self:PlayGridAction(XGuildWarConfig.GWActionType.ReinforcementBorn, gridShowReinforcementsList, function()
        if not isFirstBorn or XDataCenter.GuildWarManager.CheckIsSkipCurrentRound() then
            self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.ReinforcementBorn, PlayTypeList)
        else
            if XLuaUiManager.IsMaskShow(XGuildWarConfig.MASK_KEY) then
                XLuaUiManager.SetMask(false, XGuildWarConfig.MASK_KEY)
            end
            XLuaUiManager.OpenWithCloseCallback('UiGuildWarBossReaultsAttack',function()
                self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.ReinforcementBorn, PlayTypeList)
            end)
        end
    end)
end

-- 援军移动
function XUiPanelStage:ShowReinforcementsMove(actionGroup)
    local gridShowReinforcementsList = {}
    
    -- 只播放最后一个回合的内容
    if not XTool.IsTableEmpty(actionGroup) then
        local hasMoveMark = {}
        for i=#actionGroup, 1, -1 do
            local action = actionGroup[i]
            -- 因为援军移动行为不跟随nextturn，同一个援军在一个回合内可能会移动多次，需要保证同一个援军只播放这回合最新的一次移动
            if not hasMoveMark[action.ReinforcementUid] then
                hasMoveMark[action.ReinforcementUid] = true
                local reinforcementsEntity = self.BattleManager:GetReinforcementById(action.ReinforcementUid)
                reinforcementsEntity:UpdateCurrentNodeId(action.PreNodeId)
                reinforcementsEntity:UpdateNextNodeId(action.NextNodeId)

                local gridReinforcement = self:UpdateGridReinforcement(reinforcementsEntity, true)
                table.insert(gridShowReinforcementsList, gridReinforcement)
            end
        end
    end

    self:PlayGridAction(XGuildWarConfig.GWActionType.ReinforcementMove, gridShowReinforcementsList, function()
        self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.ReinforcementMove, PlayTypeList)
    end)
end

-- 援军攻击
function XUiPanelStage:ShowReinforcementsAttack(actionGroup)
    local gridShowReinforcementsList = {}

    -- 只播放最后一个回合的内容
    if not XTool.IsTableEmpty(actionGroup) then
        for i, action in pairs(actionGroup) do
            
            local reinforcementsEntity = self.BattleManager:GetReinforcementById(action.ReinforcementUid)

            local gridReinforcement = self:UpdateGridReinforcement(reinforcementsEntity, true)
            gridReinforcement:SetInjuryShow(action.Damage)
            table.insert(gridShowReinforcementsList, gridReinforcement)
        end
    end
    

    self:PlayGridAction(XGuildWarConfig.GWActionType.ReinforcementAttack, gridShowReinforcementsList, function()
        self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.ReinforcementAttack, PlayTypeList)
    end)
end

-- 援军死亡
function XUiPanelStage:ShowReinforcementsDead(actionGroup)
    local gridShowReinforcementsList = {}
    
    -- 只播放最后一个回合的内容
    if not XTool.IsTableEmpty(actionGroup) then
        for i, action in pairs(actionGroup) do
            local reinforcementsEntity = self.BattleManager:GetReinforcementById(action.ReinforcementUid)

            local gridReinforcement = self:UpdateGridReinforcement(reinforcementsEntity, true)
            table.insert(gridShowReinforcementsList, gridReinforcement)
        end
    end

    self:PlayGridAction(XGuildWarConfig.GWActionType.ReinforcementDead, gridShowReinforcementsList, function()
        self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.ReinforcementDead, PlayTypeList)
    end)
end

--- 龙怒系统结束
function XUiPanelStage:ShowDragonRageFull(actionGroup)
    -- 如果播放动画的时候龙怒不是下降阶段，就不播具体的动画
    if not self._Control.DragonRageControl:GetIsDragonRageValueDown() then
        self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.DragonRageFull, PlayTypeList)
        return
    end
    
    -- 找到转换前的节点
    local oldGridStages = {}
    local changeNodeIds = self._Control.DragonRageControl:GetChangeToRelicNodeIdsByGameThroughId()
    
    if not XTool.IsTableEmpty(self.AllNodeDic) and not XTool.IsTableEmpty(changeNodeIds) then
        ---@param v XGWNode
        for i, v in pairs(self.AllNodeDic) do
            local nodeId = v:GetId()

            if v:GetNodeType() ~= XGuildWarConfig.NodeType.NodeRelic and table.contains(changeNodeIds, nodeId) then
                local grid = self.NodeId2GridStageDic[nodeId]

                if grid then
                    table.insert(oldGridStages, grid)
                end
            end
        end
    end
    
    -- 封装节点切换动画逻辑
    local nodeChangedFunc = function()
        -- 播放原节点隐藏动画
        self:PlayGridAction(XGuildWarConfig.GWActionType.DragonRageFull, oldGridStages, function()
            self:StageInit()
            self:UpdatePanel()
            XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_DRAGONRAGE_CHANGE)

            -- 找到当前所有显示的龙怒节点
            local gridStages = {}
            if not XTool.IsTableEmpty(self.AllNodeDic) then
                ---@param v XGWNode
                for i, v in pairs(self.AllNodeDic) do
                    if v:GetNodeType() ~= XGuildWarConfig.NodeType.NodeRelic and XTool.IsNumberValid(v:GetRootId()) then
                        local nodeId = v:GetId()
                        local grid = self.NodeId2GridStageDic[nodeId]

                        if grid then
                            table.insert(gridStages, grid)
                        end
                    end
                end
            end

            -- 播放龙怒节点显示动画
            self:PlayGridAction(XGuildWarConfig.GWActionType.DragonRageFull, gridStages, function()
                self._Control.DragonRageControl:ShowDragonRageFull(actionGroup, function()
                    self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.DragonRageFull, PlayTypeList)
                end)
            end)
        end)
    end
    
    
    -- 先播放炮击，再播放节点切换
    local isBegin = false
    
    self.Parent:PlayAnimation('YuanziTuxiEnable', nodeChangedFunc, function()
        isBegin = true
    end)

    if not isBegin then
        nodeChangedFunc()
    end
end

--- 龙怒系统开始
function XUiPanelStage:ShowDragonRageEmpty(actionGroup)
    -- 如果播放动画的时候龙怒不是积累阶段，就不播具体的动画
    if self._Control.DragonRageControl:GetIsDragonRageValueDown() then
        self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.DragonRageEmpty, PlayTypeList)
        return
    end

    -- 找到当前所有显示的龙怒节点
    local gridStages = {}
    if not XTool.IsTableEmpty(self.AllNodeDic) then
        ---@param v XGWNode
        for i, v in pairs(self.AllNodeDic) do
            if v:GetNodeType() ~= XGuildWarConfig.NodeType.NodeRelic and XTool.IsNumberValid(v:GetRootId()) then
                local nodeId = v:GetId()
                local grid = self.NodeId2GridStageDic[nodeId]

                if grid then
                    table.insert(gridStages, grid)
                end
            end
        end
    end
    
    -- 播放龙怒隐藏动画
    self:PlayGridAction(XGuildWarConfig.GWActionType.DragonRageFull, gridStages, function()
        self:StageInit()
        self:UpdatePanel()
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_DRAGONRAGE_CHANGE)

        -- 找到原节点
        local oldGridStages = {}
        local changeNodeIds = self._Control.DragonRageControl:GetChangeToRelicNodeIdsByGameThroughId()

        if not XTool.IsTableEmpty(self.AllNodeDic) and not XTool.IsTableEmpty(changeNodeIds) then
            ---@param v XGWNode
            for i, v in pairs(self.AllNodeDic) do
                local nodeId = v:GetId()

                if v:GetNodeType() ~= XGuildWarConfig.NodeType.NodeRelic and table.contains(changeNodeIds, nodeId) then
                    local grid = self.NodeId2GridStageDic[nodeId]

                    if grid then
                        table.insert(oldGridStages, grid)
                    end
                end
            end
        end
        
        -- 播放原节点显示动画
        self:PlayGridAction(XGuildWarConfig.GWActionType.DragonRageFull, oldGridStages, function()
            self._Control.DragonRageControl:ShowDragonRageEmpty(actionGroup, function()
                self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.DragonRageEmpty, PlayTypeList)
            end)
        end)
    end)
end

--- 节点切换为废墟节点
function XUiPanelStage:ShowNodeToRelic(actionGroup)
    self:StageInit()
    self:UpdatePanel()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_DRAGONRAGE_CHANGE)

    local gridStages = {}
    local originNodeIds = {}
    
    if not XTool.IsTableEmpty(actionGroup) then
        local latestNode = nil
        -- 只取最新的切换动画
        for i=#actionGroup, 1, -1 do
            local action = actionGroup[i]

            if latestNode == nil then
                latestNode = action
            elseif action.ActionId > latestNode.ActionId then
                latestNode = action
            end
        end

        local changedNodeIds = self._Control.DragonRageControl:GetChangeToRelicNodeIdsByGameThroughId(latestNode.GameThroughId)

        if not XTool.IsTableEmpty(changedNodeIds) then
            for i, nodeId in pairs(changedNodeIds) do
                table.insert(originNodeIds, nodeId)
            end
        end
    end
    
    -- 找到当前所有显示的废墟节点
    if not XTool.IsTableEmpty(self.AllNodeDic) then
        ---@param v XGWNode
        for i, v in pairs(self.AllNodeDic) do
            if v:GetNodeType() == XGuildWarConfig.NodeType.NodeRelic then
                local nodeId = v:GetId()
                local grid = self.NodeId2GridStageDic[nodeId]

                if grid then
                    table.insert(gridStages, grid)
                end
            end
        end
    end

    self:PlayGridAction(XGuildWarConfig.GWActionType.NodeChangeToRelic, gridStages, function()
        self._Control.DragonRageControl:ShowNodeToRelic(originNodeIds, function()
            self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.NodeChangeToRelic, PlayTypeList)
        end)
    end)
    
    
end

--- 新周目
function XUiPanelStage:ShowNewGameThough(actionGroup)
    self:StageInit()
    self:UpdatePanel()
    
    if XLuaUiManager.IsMaskShow(XGuildWarConfig.MASK_KEY) then
        XLuaUiManager.SetMask(false, XGuildWarConfig.MASK_KEY)
    end

    local callBackFinish = function()
        XLuaUiManager.SetMask(true, XGuildWarConfig.MASK_KEY)
        self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.NewGameThrough, PlayTypeList)
    end

    XLuaUiManager.Open("UiGuildWarBossReaultsNewThrough", callBackFinish)
end
--endregion

--endregion
---------------------------------------界面聚焦相关-------------------------------------------------
--region 界面聚焦
function XUiPanelStage:LookAtMySelfNode()
    for key, node in pairs(self.AllNodeDic or {}) do
        if node:GetIsPlayerNode() then
            local grid = self.GridStageDic[key]:GetCurShowGrid()
            self:PanelDragFocusTarget(grid)
            return
        end
    end
    --不在任何节点上时(没参加活动资格) 定位到基地
    local grid = self.GridStageDic[BASENODE_INDEX]:GetCurShowGrid()
    self:PanelDragFocusTarget(grid)
end

function XUiPanelStage:GetMySelfNode()
    for key, node in pairs(self.AllNodeDic or {}) do
        if node:GetIsPlayerNode() then
            return self.GridStageDic[key]:GetCurShowGrid()
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
    local tagTra = self:GetMySelfNode() or self.GridStageDic[BASENODE_INDEX]:GetCurShowGrid()

    for key, node in pairs(self.AllNodeDic or {}) do
        if node:GetNodeType() == XGuildWarConfig.NodeType.Home or node:GetNodeType() == XGuildWarConfig.NodeType.Resource then
            firstGrid = self.GridStageDic[node:GetStageIndexName()]:GetCurShowGrid()
        elseif node:GetIsLastNode() then
            lastGrid = self.GridStageDic[node:GetStageIndexName()]:GetCurShowGrid()
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
    -- 龙怒，废墟需要找父节点
    local nodeData = self.BattleManager:GetNode(nodeId)
    local nodeType = nodeData:GetNodeType()
    if nodeType == XGuildWarConfig.NodeType.NodeRelic or (self._Control.DragonRageControl:GetIsOpenDragonRage() and XTool.IsNumberValid(nodeData:GetRootId())) then
        nodeId = nodeData:GetRootId()
    end
    
    local maxCount = XDataCenter.GuildWarManager.GetPathMarkMaxCount()
    local nodeIndex = self:CheckNodeInPlanPath(nodeId)
    --卸载节点操作
    if nodeIndex > -1 then
        for i = #self.PathList, nodeIndex, -1 do
            local lastNodeId = self.PathList[i]
            table.remove(self.PathList)
            local grid = self.NodeId2GridStageDic[lastNodeId]
            grid:DoPathMark(false)
            local lastStageGrid = self.PathList[i - 1] and self.NodeId2GridStageDic[self.PathList[i - 1]] or self.GridStageDic[BASENODE_INDEX]:GetCurShowGrid() --默认第一个节点是基地
            local gridLine = self.NodeNameToGridLineDic[lastStageGrid:GetStageIndexName()] and self.NodeNameToGridLineDic[lastStageGrid:GetStageIndexName()][grid:GetStageIndexName()] or nil
            if gridLine then
                gridLine:SetLineInPlan(false)
            end
        end
    else
        --增加节点操作
        local lastStageGrid --路线最后的节点
        if #self.PathList == 0 then
            lastStageGrid = self.GridStageDic[BASENODE_INDEX]:GetCurShowGrid() --默认第一个节点是基地
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
    local gridNode = indexName and self.GridStageDic[SECRETNODE_INDEX]:GetCurShowGrid()
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
        if node:GetIsTerm4Boss() or node:GetIsBaseNode() or node:GetNodeType() == XGuildWarConfig.NodeType.NodeBoss7 then
            return
        end
        local uiGridStage = self:GetMySelfNode()
        if uiGridStage and uiGridStage.StageNode and uiGridStage.StageNode:GetId() == node:GetId() then
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
        local grid = self.GridStageDic[BASENODE_INDEX]:GetCurShowGrid()
        self:PanelDragFocusTarget(grid)
    end
end

function XUiPanelStage:RefreshResourcesNode()
    for i, v in pairs(self.AllNodeDic) do
        if v:GetNodeType() == XGuildWarConfig.NodeType.Resource then
            local grid = self.GridStageDic[i]:GetCurShowGrid()
            grid:RefreshGarrison()
            grid:RefreshNormalIcon()
        end
    end
end

function XUiPanelStage:RefreshResourcesNodeState()
    for i, v in pairs(self.AllNodeDic) do
        if v:GetNodeType() == XGuildWarConfig.NodeType.Resource then
            local grid = self.GridStageDic[i]:GetCurShowGrid()
            grid:UpdateNodeData()
            grid:RefreshGarrison()
            grid:RefreshRebuildState()
            grid:RefreshNormalIcon()
        end
    end
end 

function XUiPanelStage:SetResourcesDisplayWithAttackAnimation(isAnimation)
    for i, v in pairs(self.AllNodeDic) do
        if v:GetNodeType() == XGuildWarConfig.NodeType.Resource then
            local grid = self.GridStageDic[i]:GetCurShowGrid()
            grid:SetDisplayWithAttackAnimation(isAnimation)
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

function XUiPanelStage:AddTimerId(timeId)
    self.TimerMap[timeId] = true
end

function XUiPanelStage:RemoveTimerId(timeId)
    self.TimerMap[timeId] = nil
end

function XUiPanelStage:ClearAllTimer()
    if not XTool.IsTableEmpty(self.TimerMap) then
        for timeId, v in pairs(self.TimerMap) do
            XScheduleManager.UnSchedule(timeId)
        end
    end

    self.TimerMap = {}
end

return XUiPanelStage