local XUiGridRpgMakerGameMapNode = require("XUi/XUiRpgMakerGame/Hint/XUiGridRpgMakerGameMapNode")
local XUiGridRpgMakerGameRecord = require("XUi/XUiRpgMakerGame/Hint/XUiGridRpgMakerGameRecord")

local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local Vector3 = CS.UnityEngine.Vector3

--关卡谜底界面
local XUiRpgMakerGameMapTip = XLuaUiManager.Register(XLuaUi, "UiRpgMakerGameMapTip")

function XUiRpgMakerGameMapTip:OnAwake()
    self:InitMap()
    self:AutoAddListener()
    self.GridNode.gameObject:SetActiveEx(false)
    self.EffectLine.gameObject:SetActiveEx(false)
end

function XUiRpgMakerGameMapTip:OnStart(mapId, isNotShowLine)
    self.MapId = mapId
    self.IsNotShowLine = isNotShowLine    --是否不显示通关路线和播放移动动画
    self.RecordGrids = {}
    if not isNotShowLine then
        self.HintLineMap, self.HintLineTotalCount = XRpgMakerGameConfigs.GetHintLineMap(mapId)
    end

    self.TxtTips.text = isNotShowLine and "" or XRpgMakerGameConfigs.GetHintLineHintTitle(mapId)
    self.TextTitle.text = isNotShowLine and XUiHelper.GetText("RpgMakerGameMapTitle") or XUiHelper.GetText("RpgMakerGameClearHintTitle")
end

function XUiRpgMakerGameMapTip:OnEnable()
    self:UpdateMap()
    self:UpdateRecords()
end

function XUiRpgMakerGameMapTip:OnDisable()
    self:StopEffectLineMoveAnima()
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
        grid:Refresh(blockId, self.MapId, self.IsNotShowLine)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if not self.IsNotShowLine then
            self:StartEffectLineMoveAnima()
        end
    end
end

function XUiRpgMakerGameMapTip:StartEffectLineMoveAnima()
    self:StopEffectLineMoveAnima()

    local totalCount = self.HintLineTotalCount
    local curLineId = 0
    local isOnceMoveEnd = true   --是否在当前格子的线段中移动到了终点
    local grids = self.DynamicTable:GetGrids()
    local imageLine              --移动特效所在的线
    local imageLineWidth         --线的宽度
    local onceMoveDistance = CS.XGame.ClientConfig:GetInt("RpgMakerGameMapTipMoveSpeed")  --每次移动特效的距离
    local localPosX

    self.EffectLineMoveTimer = XScheduleManager.ScheduleForever(function() 
        if isOnceMoveEnd then
            curLineId = curLineId + 1 > totalCount and 1 or curLineId + 1
            for _, grid in pairs(grids) do
                imageLine = grid:GetImageLine(curLineId)
                if imageLine then
                    imageLineWidth = imageLine.transform.rect.width
                    self.EffectLine.transform:SetParent(imageLine.transform)
                    if curLineId == 1 or self.EffectLine.localPosition.x < 0 or self.EffectLine.localPosition.x > imageLineWidth then
                        self.EffectLine.localPosition = Vector3(0, 0, 0)
                    end
                    self.EffectLine.gameObject:SetActiveEx(true)
                    break
                end
            end
        end

        if not imageLine then
            return
        end

        localPosX = self.EffectLine.localPosition.x + onceMoveDistance
        localPosX = math.min(localPosX, imageLineWidth)
        self.EffectLine.localPosition = Vector3(localPosX, 0, 0)

        isOnceMoveEnd = localPosX == imageLineWidth
    end, 1)
end

function XUiRpgMakerGameMapTip:StopEffectLineMoveAnima()
    if self.EffectLineMoveTimer then
        XScheduleManager.UnSchedule(self.EffectLineMoveTimer)
        self.EffectLineMoveTimer = nil
    end
end

function XUiRpgMakerGameMapTip:UpdateRecords()
    local mapId = self:GetMapId()
    local hintIconKeyList = XRpgMakerGameConfigs.GetRpgMakerGameHintIconKeyListByMapId(mapId, self.IsNotShowLine)
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

function XUiRpgMakerGameMapTip:GetHintLineMapParams(row, col)
    return self.HintLineMap and self.HintLineMap[row] and self.HintLineMap[row][col]
end