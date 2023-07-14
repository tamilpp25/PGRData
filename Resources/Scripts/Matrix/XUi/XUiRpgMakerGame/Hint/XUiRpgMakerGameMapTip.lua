local XUiGridRpgMakerGameMapNode = require("XUi/XUiRpgMakerGame/Hint/XUiGridRpgMakerGameMapNode")
local XUiGridRpgMakerGameRecord = require("XUi/XUiRpgMakerGame/Hint/XUiGridRpgMakerGameRecord")

local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

--关卡谜底界面
local XUiRpgMakerGameMapTip = XLuaUiManager.Register(XLuaUi, "UiRpgMakerGameMapTip")

function XUiRpgMakerGameMapTip:OnAwake()
    self:InitMap()
    self:AutoAddListener()
    self.GridNode.gameObject:SetActiveEx(false)
end

function XUiRpgMakerGameMapTip:OnStart(mapId)
    self.MapId = mapId
    self.RecordGrids = {}
end

function XUiRpgMakerGameMapTip:OnEnable()
    self:UpdateMap()
    self:UpdateRecords()
end

function XUiRpgMakerGameMapTip:InitMap()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewStage)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridRpgMakerGameMapNode)
end

function XUiRpgMakerGameMapTip:UpdateMap()
    local mapId = self:GetMapId()
    local blockIdListTemp = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToBlockIdList(mapId)
    blockIdListTemp = XTool.Clone(blockIdListTemp)
    self.BlockIdList = XTool.ReverseList(blockIdListTemp)
    self.DynamicTable:SetDataSource(self.BlockIdList)
    self.DynamicTable:ReloadDataSync()
end

function XUiRpgMakerGameMapTip:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local blockId = self.BlockIdList[index]
        grid:Refresh(blockId, self.MapId)
    end
end

function XUiRpgMakerGameMapTip:UpdateRecords()
    local mapId = self:GetMapId()
    local hintIconKeyList = XRpgMakerGameConfigs.GetRpgMakerGameHintIconKeyListByMapId(mapId)
    local grids = self.RecordGrids

    for i, hintIconKey in ipairs(hintIconKeyList) do
        local grid = grids[i]
        if not grid then
            local ui = i == 1 and self.GridReward or CSUnityEngineObjectInstantiate(self.GridReward, self.PanelContent)
            grid = XUiGridRpgMakerGameRecord.New(ui, self)
            grids[i] = grid
        end
        grid:Refresh(hintIconKey)
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiRpgMakerGameMapTip:AutoAddListener()
    self.BtnTanchuangCloseBig.CallBack = handler(self, self.Close)
end

function XUiRpgMakerGameMapTip:GetMapId()
    return self.MapId
end