--######################## XUiGridStage ########################
local XUiGridNode = XClass(nil, "XUiGridNode")

function XUiGridNode:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
end

function XUiGridNode:SetData(node, count)
    self.ImgIcon:SetSprite(node:GetIcon())
    if node:GetIsInfectNode() then
        self.TxtNodeName.text = node:GetName(false)
    else
        self.TxtNodeName.text = node:GetName()
    end
    self.TxtNodeCount.text = string.format( "X%s", count)
end

--######################## XUiGuildWarStageResults ########################
-- 轮次结算界面
local XUiGuildWarStageResults = XLuaUiManager.Register(XLuaUi, "UiGuildWarStageResults")

function XUiGuildWarStageResults:OnAwake()
    self.BattleManager = XDataCenter.GuildWarManager.GetBattleManager()
    -- 奖励列表
    self.DynamicTable = XDynamicTableNormal.New(self.RewardList)
    self.DynamicTable:SetProxy(XUiGridCommon)
    self.DynamicTable:SetDelegate(self)
    self.GridReward.gameObject:SetActiveEx(false)
    self.RewardDatas = nil
    self:RegisterUiEvents()
end

function XUiGuildWarStageResults:OnStart(nodeIds, callBack)
    self.CallBack = callBack
    -- 节点刷新
    local nodeId2Count = {}
    for _, nodeId in ipairs(nodeIds) do
        nodeId2Count[nodeId] = nodeId2Count[nodeId] or 0
        nodeId2Count[nodeId] = nodeId2Count[nodeId] + 1
    end
    local nodes = {}
    for nodeId, _ in pairs(nodeId2Count) do
        table.insert(nodes, self.BattleManager:GetNode(nodeId))
    end
    table.sort(nodes, function(nodeA, nodeB)
        return nodeA:GetNodeType() > nodeB:GetNodeType()
    end)
    XUiHelper.RefreshCustomizedList(self.PanelStage, self.GridStage, #nodes
    , function(index, child)
        local grid = XUiGridNode.New(child)
        local node = nodes[index]
        grid:SetData(node, nodeId2Count[node:GetId()])
    end)
    -- 节点奖励结算
    local rewardDatas = {}
    local rewardData = nil
    local tempDataDic = {}
    for _, node in ipairs(nodes) do
        rewardData = XRewardManager.GetRewardList(node:GetRewardId())
        if rewardData then
            for _, data in pairs(rewardData) do  
                tempDataDic[data.TemplateId] = tempDataDic[data.TemplateId] or {}
                tempDataDic[data.TemplateId].Count = tempDataDic[data.TemplateId].Count or 0
                tempDataDic[data.TemplateId].Count = tempDataDic[data.TemplateId].Count + data.Count * nodeId2Count[node:GetId()]
                tempDataDic[data.TemplateId].Data = tempDataDic[data.TemplateId].Data or data

            end
        end
    end
    for _, data in pairs(tempDataDic) do
        data.Data.Count = data.Count
        table.insert(rewardDatas, data.Data)    
    end
    self.RewardDatas = rewardDatas
    self.DynamicTable:SetDataSource(rewardDatas)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiGuildWarStageResults:OnDestroy()
    
end

--######################## 私有方法 ########################

function XUiGuildWarStageResults:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnCloseClisk)
end

function XUiGuildWarStageResults:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.RewardDatas[index])
    end
end

function XUiGuildWarStageResults:OnCloseClisk()
    if self.CallBack then self.CallBack() end
    self:Close()
end

return XUiGuildWarStageResults