local XUiGridFubenInfestorExploreStage = require("XUi/XUiFubenInfestorExplore/XUiGridFubenInfestorExploreStage")
local XUiGridFubenInfestorExploreOccupiedPlayer = require("XUi/XUiFubenInfestorExplore/XUiGridFubenInfestorExploreOccupiedPlayer")
local OccupiedPlayerPreafabPath = CS.XGame.ClientConfig:GetString("GridFubenInfestorExploreOccupiedPlayerPreafab")

local ipairs = ipairs
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local TWEE_DURATION = 0.2

local XUiPanelFubenInfestorExploreStages = XClass(nil, "XUiPanelFubenInfestorExploreStages")

function XUiPanelFubenInfestorExploreStages:Ctor(ui, rootUi, chapterId, clickStageCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ChapterId = chapterId
    self.ClickStageCb = clickStageCb
    self.RootUi = rootUi

    XTool.InitUiObject(self)
    self.ScrollRect = self.Transform:Find("PaneStageList"):GetComponent("ScrollRect")
    self.MarkX = self.Transform:Find("PaneStageList/ViewPort"):GetComponent("RectTransform").rect.width * 0.3
    self.InitPosX = self.PanelStageContent.localPosition.x

    self:InitStagesMap()
end

function XUiPanelFubenInfestorExploreStages:InitStagesMap()
    local chapterId = self.ChapterId

    local bg = XFubenInfestorExploreConfigs.GetChapterBg(chapterId)
    self.RImgChapterBg:SetRawImage(bg)

    self.LastSelectGrid = nil
    local clickCb = function(grid, paramNodeId)
        if self.LastSelectGrid then
            self.LastSelectGrid:SetSelect(false)
        end
        grid:SetSelect(true)
        self.LastSelectGrid = grid

        --当打开了详情界面时才进行滑动定位
        if not XDataCenter.FubenInfestorExploreManager.IsNodeStart(chapterId, paramNodeId)
        and not XDataCenter.FubenInfestorExploreManager.IsNodeCurrentShop(chapterId, paramNodeId) then
            self:PlayScrollViewMove(grid)
        end

        self.ClickStageCb(chapterId, paramNodeId, grid)
    end
    self.GridStages = {}
    local mapNodeIds = XDataCenter.FubenInfestorExploreManager.GetMapNodeIds(chapterId)
    for nodeId in ipairs(mapNodeIds) do
        self.GridStages[nodeId] = XUiGridFubenInfestorExploreStage.New(self.RootUi, chapterId, nodeId, clickCb)
    end

    self.GridPlayers = {}
end

function XUiPanelFubenInfestorExploreStages:UpdateStagesMap()
    for _, grid in pairs(self.GridPlayers) do
        grid.GameObject:SetActiveEx(false)
    end

    local chapterId = self.ChapterId
    for nodeId, grid in pairs(self.GridStages) do
        local stageParent = self["Stage" .. nodeId]
        if XTool.UObjIsNil(stageParent) then
            local mapId = XFubenInfestorExploreConfigs.GetMapId(chapterId)
            local parentPrefabPath = XFubenInfestorExploreConfigs.GetChapterPrefabPath(chapterId)
            XLog.Error("XUiPanelFubenInfestorExploreStages:InitStagesMap Error:感染体玩法地图配置节点数量与UI不一致, 地图Id: " .. mapId .. ", UI路径: " .. parentPrefabPath)
            return
        end

        local prefabPath = XDataCenter.FubenInfestorExploreManager.GetNodePrefabPath(chapterId, nodeId)
        local go = stageParent:LoadPrefab(prefabPath)
        grid:Refresh(go)

        --刷新小队成员所在位置
        local playerId = XDataCenter.FubenInfestorExploreManager.GetNodeShowOccupiedPlayerId(chapterId, nodeId)
        if playerId > 0 then
            --在起点或终点的非自己小队成员头像不显示
            -- if not (playerId ~= XPlayer.Id and (XDataCenter.FubenInfestorExploreManager.IsNodeStart(chapterId, nodeId)
            -- or XDataCenter.FubenInfestorExploreManager.IsNodeEnd(chapterId, nodeId))
            -- ) then
                local palyerGrid = self.GridPlayers[playerId]
                if not palyerGrid then
                    local go = self:CreatePlayerGo()
                    palyerGrid = XUiGridFubenInfestorExploreOccupiedPlayer.New(go, playerId)
                    self.GridPlayers[playerId] = palyerGrid
                end

                palyerGrid.Transform:SetParent(stageParent, false)
                palyerGrid.GameObject:SetActiveEx(true)
            --end
        end

        if playerId == XPlayer.Id then
            self:PlayScrollViewMove(grid, true)
        end
    end
end

function XUiPanelFubenInfestorExploreStages:CreatePlayerGo(parent)
    local go = self.PlayerGo
    if not go then
        go = self.PanelStageContent:LoadPrefab(OccupiedPlayerPreafabPath)
        self.PlayerGo = go
    else
        go = CSUnityEngineObjectInstantiate(self.PlayerGo)
    end
    return go
end

function XUiPanelFubenInfestorExploreStages:PlayScrollViewMove(grid, ignoreAnim)
    local gridX = grid.Transform.parent:GetComponent("RectTransform").localPosition.x
    local contentPos = self.PanelStageContent.localPosition
    local markX = self.MarkX
    local diffX = gridX - markX
    if diffX ~= 0 then
        local targetPosX = self.InitPosX - diffX
        local tarPos = contentPos
        tarPos.x = targetPosX

        if not ignoreAnim then
            XLuaUiManager.SetMask(true)
            self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
            XUiHelper.DoMove(self.PanelStageContent, tarPos, TWEE_DURATION, XUiHelper.EaseType.Sin, function()
                XLuaUiManager.SetMask(false)
            end)
        else
            self.PanelStageContent.localPosition = tarPos
        end
    end
end

return XUiPanelFubenInfestorExploreStages