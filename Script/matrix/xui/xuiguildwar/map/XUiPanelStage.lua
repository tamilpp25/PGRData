local XUiPanelStage = XClass(nil, "XUiPanelStage")
local XUiGridStage = require("XUi/XUiGuildWar/Map/XUiGridStage")
local XUiGridMonster = require("XUi/XUiGuildWar/Map/XUiGridMonster")
local CSTextManagerGetText = CS.XTextManager.GetText
local PanelDragFocusTime = 1.5
local Vector3 = CS.UnityEngine.Vector3
function XUiPanelStage:Ctor(ui, base, battleManager)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.BattleManager = battleManager
    self.IsSetMask = false
    self.IsPathEdit = false
    self.FinishCountDic = {}
    self.PathDic = {}
    self.OldPathDic = {}
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self:GroupInit()
    self:StageInit()
    self:MonsterInit()
end

function XUiPanelStage:GroupInit()
    self.StageGroupObjList = {
        self.StageGroupBase,
        self.StageGroupBoss,
        self.StageGroupLine1,
        self.StageGroupLine2,
        self.StageGroupLine3,
    }

    self.LineUiObjectList = {}
    self.StagePosDic = {}

    local UsedStageGroupDic = {}
    self.AllNodesList = self.BattleManager:GetNodes()
    for _,node in pairs(self.AllNodesList or {}) do
        UsedStageGroupDic[node:GetGroupIndex()] = true
    end

    for groupIndex,stageGroup in pairs(self.StageGroupObjList) do

        if UsedStageGroupDic[groupIndex] then
            local groupUiObject = stageGroup.transform:GetComponent("UiObject")
            local panelLine = groupUiObject:GetObject("PanelLine")
            local panelStage = groupUiObject:GetObject("PanelStage")
            stageGroup.gameObject:SetActiveEx(true)

            local index = 1
            while true do
                local line = panelLine.transform:FindTransform(string.format("Line%d", index))
                local lineUiObject = line and line.transform:GetComponent("UiObject")
                if not lineUiObject then
                    break
                end
                table.insert(self.LineUiObjectList, lineUiObject)
                index = index + 1
            end

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
        else
            stageGroup.gameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelStage:StageInit()
    self.GridStageObjList = {
        self.Obj:GetPrefab("GuildWarStageType1"),
        self.Obj:GetPrefab("GuildWarStageType2"),
        self.Obj:GetPrefab("GuildWarStageType3"),
        self.Obj:GetPrefab("GuildWarStageType4"),
        self.Obj:GetPrefab("GuildWarStageType5"),
        self.Obj:GetPrefab("GuildWarStageType6"),
    }

    self.GridStageDic = {}
    self.AllNodeDic = {}
    for _,node in pairs(self.AllNodesList or {}) do
        local obj = CS.UnityEngine.Object.Instantiate(self.GridStageObjList[node:GetNodeType()], self.StagePosDic[node:GetStageIndexName()])
        self.GridStageDic[node:GetStageIndexName()] = XUiGridStage.New(obj, self)
        self.AllNodeDic[node:GetStageIndexName()] = node
    end
end

function XUiPanelStage:MonsterInit()
    self.GridMonsterDic = {}
    self.GridMonsterDic["Alive"] = {}
    self.GridMonsterDic["Dead"] = {}
end

function XUiPanelStage:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_OPEN_MOVIEMODE, self.OpenMovieMode, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_CLOSE_MOVIEMODE, self.CloseMovieMode, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_STAGEDETAIL_CHANGE, self.SelectGridNode, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_TIME_REFRESH, self.UpdatePanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_NODEDATA_CHANGE, self.UpdatePanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_MONSTER_CHANGE, self.UpdateAllMonster, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_PLAYER_MOVE, self.UpdateStage, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_LOOKAT_ME, self.LookAtMySelfNode, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTIONLIST_OVER, self.DoActionOver, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_DEAD, self.ShowMonsterDead, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_BORN, self.ShowMonsterBorn, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_MOVE, self.ShowMonsterMove, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_BASEHIT, self.ShowBaseHit, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_NODEDESTROY, self.ShowNodeDestroyed, self)
end

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
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_DEAD, self.ShowMonsterDead, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_BORN, self.ShowMonsterBorn, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_MOVE, self.ShowMonsterMove, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_BASEHIT, self.ShowBaseHit, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_NODEDESTROY, self.ShowNodeDestroyed, self)
end

function XUiPanelStage:SetButtonCallBack()

end

function XUiPanelStage:UpdateGridMonster(monsterData, IsActionPlaying)
    local gridMonster
    for _,grid in pairs(self.GridMonsterDic["Alive"] or {}) do
        if grid:GetMonsterUID() == monsterData:GetUID() then
            gridMonster = grid
            break
        end
    end

    if not gridMonster then
        gridMonster = self.GridMonsterDic["Dead"][1]
        if gridMonster then
            table.remove(self.GridMonsterDic["Dead"], 1)
        else
            local obj = CS.UnityEngine.Object.Instantiate(self.Obj:GetPrefab("GuildWarStageMonster"), self.Transform)
            gridMonster = XUiGridMonster.New(obj, self, self.BattleManager)
        end
        table.insert(self.GridMonsterDic["Alive"], gridMonster)
    end
    gridMonster:ShowGrid(true)
    gridMonster:UpdateGrid(monsterData, self.IsPathEdit, IsActionPlaying)
    return gridMonster
end

function XUiPanelStage:KillGridMonster(gridMonster)
    local removeIndex = -1
    for index,grid in pairs(self.GridMonsterDic["Alive"] or {}) do
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

function XUiPanelStage:StopActionPlay()
    if self.IsSetMask then
        self.IsSetMask = false
        XLuaUiManager.SetMask(false)
    end

    for _,gridMonsterGroup in pairs(self.GridMonsterDic or {}) do
        for _,gridMonster in pairs(gridMonsterGroup or {}) do
            gridMonster:StopTween()
        end
    end

    for _,gridStage in pairs(self.GridStageDic or {}) do
        gridStage:StopTween()
    end
end

function XUiPanelStage:ShowAction(IsInit)
    local IsHasCanPlayAction = self.BattleManager:GetIsHasCanPlayAction()
    if not IsHasCanPlayAction and not IsInit then
        return
    end

    if self.BattleManager:CheckActionPlaying() then
        return
    end

    if not self.IsSetMask then
        XLuaUiManager.SetMask(true)
        self.IsSetMask = true
    end
    
    if IsInit then
        self:UpdatePreMonster()
        self:UpdateStage(true)
    end
    
    self.BattleManager:CheckActionList()
end

function XUiPanelStage:DoActionOver()
    if self.IsSetMask then
        self.IsSetMask = false
        XLuaUiManager.SetMask(false)
    end
    self:UpdatePanel()
end

function XUiPanelStage:OpenMovieMode(cb)
    local IsHistory = self.BattleManager:CheckIsHistoryAction()
    self:LookAllMap(true, cb)
    self.Base.ReviewPanel:ShowPanel(IsHistory and
        XGuildWarConfig.ActionShowType.History or
        XGuildWarConfig.ActionShowType.Now)
end

function XUiPanelStage:CloseMovieMode()
    self:LookAllMap(false)
    self.Base.ReviewPanel:HidePanel()
end

function XUiPanelStage:UpdatePanel()
    self:UpdateAllMonster()
    self:UpdateStage(false)
    self:UpdateLine()
end

function XUiPanelStage:UpdateStage(IsActionPlaying)
    for key,node in pairs(self.AllNodeDic or {}) do
        local grid = self.GridStageDic[key]
        grid:UpdateGrid(node, self.IsPathEdit, IsActionPlaying)
    end
end

function XUiPanelStage:UpdateLine()
    for _,lineUi in pairs(self.LineUiObjectList or {}) do
        local node1 = self.AllNodeDic[lineUi:GetObject("Stage1").transform.name]
        local node2 = self.AllNodeDic[lineUi:GetObject("Stage2").transform.name]

        if node1 and node2 then
            local IsOnLink = (node1:GetIsDead() or node1:GetIsBaseNode()) or (node2:GetIsDead() or node2:GetIsBaseNode())
            lineUi:GetObject("Normal").gameObject:SetActiveEx(not IsOnLink)
            lineUi:GetObject("Press").gameObject:SetActiveEx(IsOnLink)
            lineUi.gameObject:SetActiveEx(true)
        else
            lineUi.gameObject:SetActiveEx(false)
        end

    end
end

function XUiPanelStage:UpdateAllMonster()
    local monsterEntityDic = self.BattleManager:GetMonsterDic()
    for _,monsterEntity in pairs(monsterEntityDic or {}) do
        if not monsterEntity:GetIsDead() then
            self:UpdateGridMonster(monsterEntity, false)
        end
    end
end

function XUiPanelStage:UpdatePreMonster()
    local preMonsterDataList = self.BattleManager:GetPreMonsterDataDic()

    for _,monsterData in pairs(preMonsterDataList or {}) do
        local monsterEntity = self.BattleManager:GetMonsterById(monsterData.UID)
        monsterEntity:UpdateCurrentRouteIndex(monsterData.NodeIndex)

        self:UpdateGridMonster(monsterEntity, true)
    end
end
---------------------------------------------------Action播放相关------------------------------------------------------------------
function XUiPanelStage:ShowMonsterDead(actionGroup)
    local gridShowMonsterList = {}
    for _,action in pairs(actionGroup or {}) do
        local monsterEntity = self.BattleManager:GetMonsterById(action.MonsterUid)
        monsterEntity:UpdateCurrentRouteIndex(action.CurNodeIdx)

        local gridMonster = self:UpdateGridMonster(monsterEntity, true)
        table.insert(gridShowMonsterList, gridMonster)
    end

    self:PlayAction(XGuildWarConfig.MosterActType.Dead, gridShowMonsterList, function ()
            self.BattleManager:DoActionFinish(XGuildWarConfig.MosterActType.Dead)
        end)
end

function XUiPanelStage:ShowMonsterBorn(actionGroup)
    local gridShowMonsterList = {}
    for _,action in pairs(actionGroup or {}) do
        local monsterEntity = self.BattleManager:GetMonsterById(action.MonsterUid)
        monsterEntity:UpdateWithServerData(action.MonsterData)

        local gridMonster = self:UpdateGridMonster(monsterEntity, true)
        gridMonster:ShowGrid(false)
        table.insert(gridShowMonsterList, gridMonster)
    end

    self:PlayAction(XGuildWarConfig.MosterActType.Born, gridShowMonsterList, function ()
            self.BattleManager:DoActionFinish(XGuildWarConfig.MosterActType.Born)
        end)
end

function XUiPanelStage:ShowMonsterMove(actionGroup)
    local gridShowMonsterList = {}
    for _,action in pairs(actionGroup or {}) do
        local monsterEntity = self.BattleManager:GetMonsterById(action.MonsterUid)
        monsterEntity:UpdateCurrentRouteIndex(action.PreNodeIdx)
        monsterEntity:UpdateNextRouteIndex(action.NextNodeIdx)

        local gridMonster = self:UpdateGridMonster(monsterEntity, true)
        table.insert(gridShowMonsterList, gridMonster)
    end

    self:PlayAction(XGuildWarConfig.MosterActType.Move, gridShowMonsterList, function ()
            self.BattleManager:DoActionFinish(XGuildWarConfig.MosterActType.Move)
        end)
end

function XUiPanelStage:ShowBaseHit(actionGroup)
    local damageDic = {}
    local gridNodeList = {}
    local addDic = {}
    for _,action in pairs(actionGroup or {}) do
        for _,node in pairs(self.AllNodesList or {}) do
            if node:GetUID() == action.NodeUid then
                local indexName = node:GetStageIndexName()
                local grid = self.GridStageDic[indexName]
                node:UpdateWithServerData(action.NodeData)
                grid:UpdateGrid(node, false, true)

                damageDic[indexName] = damageDic[indexName] or 0
                damageDic[indexName] = damageDic[indexName] + action.Damage
                grid:SetDamage(damageDic[indexName])
                if not addDic[indexName] then
                    table.insert(gridNodeList,grid)
                    addDic[indexName] = true
                end
                break
            end
        end
    end

    self:PlayAction(XGuildWarConfig.MosterActType.BaseHit, gridNodeList, function ()
            self.BattleManager:DoActionFinish(XGuildWarConfig.MosterActType.BaseHit)
        end)
end

function XUiPanelStage:ShowNodeDestroyed(actionGroup)
    local nodeIdList = {}
    for _,action in pairs(actionGroup or {}) do
        table.insert(nodeIdList, action.NodeId)
    end
    if self.IsSetMask then
        self.IsSetMask = false
        XLuaUiManager.SetMask(false)
    end
    
    local callBackFinish = function()
        self.IsSetMask = true
        XLuaUiManager.SetMask(true)
        self.BattleManager:DoActionFinish(XGuildWarConfig.MosterActType.NodeDestroyed)
    end

    local callBackCheck = function()
        local IsKillBoss = false
        
        for _,nodeId in pairs(nodeIdList or {}) do
            local node = self.BattleManager:GetNode(nodeId)
            if node:GetIsInfectNode() then
                IsKillBoss = true
                break
            end
        end
        
        if IsKillBoss then
            XScheduleManager.ScheduleOnce(function ()
                    XLuaUiManager.Open("UiGuildWarBossReaults", callBackFinish)
                end, 1)
        else
            callBackFinish()
        end
    end

    XLuaUiManager.Open("UiGuildWarStageResults", nodeIdList, callBackCheck)
end

function XUiPanelStage:PlayAction(actType, gridList, cb)
    self.FinishCountDic[actType] = 0
    if gridList and next(gridList) then
        for _,grid in pairs(gridList) do
            grid:ShowAction(actType, function ()
                    self:CheckFinishCount(#gridList, actType, cb)
                end)
        end
    else
        self:CheckFinishCount(0, actType, cb)
    end
end

function XUiPanelStage:CheckFinishCount(maxCount, actType, cb)
    self.FinishCountDic[actType] = self.FinishCountDic[actType] + 1
    if self.FinishCountDic[actType] >= maxCount then
        if cb then cb() end
    end
end

function XUiPanelStage:SelectGridNode(stageIndexName, IsSelectMonster)
    local indexName = stageIndexName or ""

    for key,stageGrid in pairs(self.GridStageDic or {}) do
        stageGrid:DoSelect(key == indexName, not IsSelectMonster)
    end

    for _,monsterGrid in pairs(self.GridMonsterDic["Alive"] or {}) do
        local IsSelect = monsterGrid:GetMonsterCurrentNodeIndexName() == indexName and IsSelectMonster
        monsterGrid:DoSelect(IsSelect)
    end

    local gridNode = indexName and self.GridStageDic[indexName]
    self:PanelDragFocusTarget(gridNode)
end
---------------------------------------界面聚焦相关-------------------------------------------------
function XUiPanelStage:LookAtMySelfNode()
    for key,node in pairs(self.AllNodeDic or {}) do
        if node:GetIsPlayerNode() then
            local grid = self.GridStageDic[key]
            self:PanelDragFocusTarget(grid)
            return
        end
    end
end

function XUiPanelStage:GetMySelfNode()
    for key,node in pairs(self.AllNodeDic or {}) do
        if node:GetIsPlayerNode() then
            return self.GridStageDic[key]
        end
    end
    return
end

function XUiPanelStage:PanelDragFocusTarget(gridNode)
    local tagPos = gridNode and Vector3(gridNode.Transform.position.x + 2,gridNode.Transform.position.y,self.PanelDrag.transform.position.z) or self.PanelDrag.transform.position----TODO工具需要修改
    local scale = gridNode and self.PanelDrag.MaxScale or 1
    self.PanelDrag:FocusPos(tagPos, scale, PanelDragFocusTime, CS.UnityEngine.Vector3.zero)
end

function XUiPanelStage:LookAllMap(IsLook, cb)
    local firstGrid = {}
    local lastGrid = {}
    local tagTra = self:GetMySelfNode()

    for key,node in pairs(self.AllNodeDic or {}) do
        if node:GetNodeType() == XGuildWarConfig.NodeType.Home then
            firstGrid = self.GridStageDic[node:GetStageIndexName()]
        elseif node:GetNodeType() == XGuildWarConfig.NodeType.Infect then
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
-------------------------------------------路径编辑相关-------------------------------------------------
function XUiPanelStage:PathEdit()
    self:RemoveEventListener()
    self.IsPathEdit = true
    self:UpdatePanel()

    self.PathDic = {}
    self.OldPathDic = {}
    for _,node in pairs(self.AllNodesList or {}) do
        if node:GetIsTargetNode() then
            self.PathDic[node:GetId()] = node:GetId()
            self.OldPathDic[node:GetId()] = true
        end
    end
end

function XUiPanelStage:PathEditOver(IsSave, cb)
    local nodeIdList = {}
    for _,nodeId in pairs(self.PathDic or {}) do
        table.insert(nodeIdList,nodeId)
    end

    local callBack = function()
        if cb then cb() end
        self:AddEventListener()
        self.IsPathEdit = false
        self:UpdatePanel()
    end

    if IsSave then
        XDataCenter.GuildWarManager.EditPlan(nodeIdList, function ()
                XUiManager.TipText("GuildWarPathEditOverHint")
                callBack()
            end)
    else
        callBack()
    end
end

function XUiPanelStage:AddPath(nodeId, grid)
    local maxCount = XDataCenter.GuildWarManager.GetPathMarkMaxCount()
    if self.PathDic[nodeId] then
        self.PathDic[nodeId] = nil
        grid:DoPathMark(false)
    else
        if self:CheckPathCount() then
            self.PathDic[nodeId] = nodeId
            grid:DoPathMark(true)
        end
    end

    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_PATHEDIT_PATHCHANGE, self:CheckPathChange(self.PathDic))
end

function XUiPanelStage:CheckPathCount()
    local maxCount = XDataCenter.GuildWarManager.GetPathMarkMaxCount()
    local count = 0
    for _,_ in pairs(self.PathDic or {}) do
        count = count + 1
    end
    if count >= maxCount then
        XUiManager.TipText("GuildWarPathMaxHint")
        return false
    else
        return true
    end
end

function XUiPanelStage:CheckPathChange(newPathDic)
    if newPathDic and self.OldPathDic then
        for key,_ in pairs(newPathDic) do
            if not self.OldPathDic[key] then
                return true
            end
        end
        for key,_ in pairs(self.OldPathDic) do
            if not newPathDic[key] then
                return true
            end
        end
    end
    return false
end

function XUiPanelStage:CheckIsPathEdit()
    return self.IsPathEdit
end

return XUiPanelStage