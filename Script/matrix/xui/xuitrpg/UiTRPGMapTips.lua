local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridTRPGMapNode = require("XUi/XUiTRPG/XUiGridTRPGMapNode")
local XUiGridTRPGCardRecord = require("XUi/XUiTRPG/XUiGridTRPGCardRecord")

local CSXTextManagerGetText = CS.XTextManager.GetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local mathFloor = math.floor

local XUiTRPGMapTips = XLuaUiManager.Register(XLuaUi, "UiTRPGMapTips")

function XUiTRPGMapTips:OnAwake()
    self:AutoAddListener()
    self.GridNode.gameObject:SetActiveEx(false)
end

function XUiTRPGMapTips:OnStart(mazeId)
    self.MazeId = mazeId
    self.LayerIds = XTRPGConfigs.GetMazeLayerIds(mazeId)
    self.LayerId = XDataCenter.TRPGManager.GetMazeCurrentLayerId(mazeId)
    self.RecordGrids = {}
    self.LayerBtns = {}

    self:InitMaze()
end

function XUiTRPGMapTips:OnEnable()

    self.PanelLayer:SelectIndex(self:GetLayerIndex(self.LayerId))
    self:UpdateCardRecords()
end

function XUiTRPGMapTips:OnDisable()

end

function XUiTRPGMapTips:OnGetEvents()
    return { XEventId.EVENT_TRPG_MAZE_RECORD_CARD }
end

function XUiTRPGMapTips:OnNotify(evt, ...)
    if evt == XEventId.EVENT_TRPG_MAZE_RECORD_CARD then
        self:UpdateProgress()
        self:UpdateCardRecords()
    end
end

function XUiTRPGMapTips:InitMaze()
    local mazeId = self.MazeId
    self.TxtMazeName.text = XTRPGConfigs.GetMazeName(mazeId)

    local btns = {}
    for index in pairs(self.LayerIds) do
        local btn = index == 1 and self.BtnTabLayer or CSUnityEngineObjectInstantiate(self.BtnTabLayer, self.PanelLayer.transform)
        btns[index] = btn
        btn:SetName(CSXTextManagerGetText("TRPGMazeMapBtnName", index))
    end
    self.PanelLayer:Init(btns, function(index) self:OnSelectLayer(index) end)
    self.LayerBtns = btns

    self.DynamicTable = XDynamicTableNormal.New(self.SViewStage)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridTRPGMapNode)
end

function XUiTRPGMapTips:OnSelectLayer(index)
    self:PlayAnimation("QieHuan")

    local layerId = self.LayerIds[index]
    self.LayerId = layerId

    self:UpdateMap()
    self:UpdateProgress()
end

function XUiTRPGMapTips:UpdateProgress()
    local mazeId = self.MazeId
    local layerId = self.LayerId

    local mazeProgress = XDataCenter.TRPGManager.GetMazeProgress(mazeId, layerId)
    self.TxtProgress.text = mathFloor(mazeProgress * 100) .. "%"
end

function XUiTRPGMapTips:UpdateMap()
    local mazeId = self.MazeId
    local layerId = self.LayerId

    self.TxtMazeName.text = XTRPGConfigs.GetMazeLayerName(layerId)

    local isCurrentLayer = XDataCenter.TRPGManager.IsCurrentLayer(mazeId, layerId)


    local curStandNodeIndex = isCurrentLayer and XDataCenter.TRPGManager.GetMazeCurrentStandNodeIndex(mazeId, layerId) or 1
    local nodeIdList = XDataCenter.TRPGManager.GetMazeNodeIdList(mazeId, layerId, true)
    self.NodeIdList = nodeIdList
    self.DynamicTable:SetDataSource(nodeIdList)
    self.DynamicTable:ReloadDataSync(curStandNodeIndex)

    for index, layerId in pairs(self.LayerIds) do
        local isCurrentLayer = XDataCenter.TRPGManager.IsCurrentLayer(mazeId, layerId)
        local btn = self.LayerBtns[index]
        btn:ShowTag(isCurrentLayer)
    end
end

function XUiTRPGMapTips:OnDynamicTableEvent(event, index, grid)
    local mazeId = self.MazeId
    local layerId = self.LayerId
    local nodeIdList = self.NodeIdList

    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local nodeId = nodeIdList[index]
        grid:Refresh(mazeId, layerId, nodeId)
    end
end

function XUiTRPGMapTips:UpdateCardRecords()
    local mazeId = self.MazeId
    local grids = self.RecordGrids

    local cardRecordGroupIds = XTRPGConfigs.GetMazeCardRecordGroupIdList()
    for i, groupId in ipairs(cardRecordGroupIds) do
        local grid = grids[i]
        if not grid then
            local ui = i == 1 and self.GridReward or CSUnityEngineObjectInstantiate(self.GridReward, self.PanelContent)
            grid = XUiGridTRPGCardRecord.New(ui, self)
            grids[i] = grid
        end
        grid:Refresh(mazeId, groupId)
        grid.GameObject:SetActiveEx(true)
    end

    for i = #cardRecordGroupIds + 1, #grids do
        if grids[i] then
            grids[i].GameObject:SetActiveEx(false)
        end
    end
end

function XUiTRPGMapTips:AutoAddListener()
    self.BtnTanchuangCloseBig.CallBack = function() self:OnBtnBackClick() end
end

function XUiTRPGMapTips:OnBtnBackClick()
    self:Close()
end

function XUiTRPGMapTips:GetLayerIndex(targetLayerId)
    for index, layerId in pairs(self.LayerIds or {}) do
        if layerId == targetLayerId then
            return index
        end
    end
    return 1
end