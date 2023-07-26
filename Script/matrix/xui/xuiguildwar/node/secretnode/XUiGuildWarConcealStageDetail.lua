local XUiGuildWarConcealSituationGrid = require("XUi/XUiGuildWar/Node/SecretNode/XUiGuildWarConcealSituationGrid")
--######################## XUiGuildWarConcealStageDetail ########################
local XUiGuildWarConcealStageDetail = XLuaUiManager.Register(XLuaUi, "UiGuildWarConcealStageDetail")

--难度对应的隐藏节点排行ID
local RoundIdToRankId = {
    [1] = 9,
    [2] = 10,
    [3] = 11,
}

function XUiGuildWarConcealStageDetail:OnAwake()
    self:Init()
    ---@type XTerm3SecretRootGWNode
    self.Node = nil
    self.GridBossRank.gameObject:SetActiveEx(false)
    return
end

function XUiGuildWarConcealStageDetail:Init()
    self.GuildWarManager = XDataCenter.GuildWarManager
    self.BattleManager = self.GuildWarManager.GetBattleManager()
    --资源面板
    XUiHelper.NewPanelActivityAsset({ XGuildWarConfig.ActivityPointItemId }
    , self.PanelSpecialTool, { self.GuildWarManager.GetMaxActionPoint() })
    --当前进度列表
    self.DynamicTableSituation = XDynamicTableNormal.New(self.ListSituation.gameObject)
    self.DynamicTableSituation:SetProxy(XUiGuildWarConcealSituationGrid)
    self.DynamicTableSituation:SetDelegate(self)
    --设置富文本
    self.TxtAreaDetails.supportRichText = true
    --关闭按钮
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClicked)
    --进入关卡按钮
    XUiHelper.RegisterClickEvent(self, self.BtnGo, self.OnBtnGoClicked)
    --提示按钮
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, self.OnBtnHelpClicked)
    --排行榜按钮
    XUiHelper.RegisterClickEvent(self, self.BtnPlayer, self.OnBtnPlayerClicked)
    
end

-- node : XTerm3SecretRootGWNode
function XUiGuildWarConcealStageDetail:OnStart(node, isMonsterStatus)
    self:RefreshNode(node)
end

function XUiGuildWarConcealStageDetail:OnEnable()
    XUiGuildWarConcealStageDetail.Super.OnEnable(self)
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_STAGEDETAIL_CHANGE, self.Node:GetStageIndexName(), false)
end

function XUiGuildWarConcealStageDetail:OnDisable()
    XUiGuildWarConcealStageDetail.Super.OnDisable(self)
end

function XUiGuildWarConcealStageDetail:OnDestroy()
    XUiGuildWarConcealStageDetail.Super.OnDestroy(self)
end

function XUiGuildWarConcealStageDetail:RefreshNode(node)
    if node == nil then node = self.Node end
    self.Node = node
    local nodeId = self.Node:GetId()
    --BOSS信息
    self.RImgMonsterIcon:SetRawImage(XGuildWarConfig.GetNodeShowMonsterIcon(nodeId))
    self.TxtMonsterName.text = XGuildWarConfig.GetNodeShowMonsterName(nodeId)
    local score = self.Node:GetAreaScore()
    if score <= 0 then score = "-" end
    self.TxtMyScore.text = score
    --区域名
    self.TxtNodeName.text = XGuildWarConfig.GetNodeName(nodeId)
    --区域详情
    self.TxtAreaDetails.text = XGuildWarConfig.GetNodeDesc(nodeId)
    --作战记录展示情况
    local allAreaNum = #self.Node:GetChildrenNodes()
    self.DataRecord = self.Node:GetAreaSituation()
    self.TextSituation.text = "("..#self.DataRecord.."/"..allAreaNum..")"
    if next(self.DataRecord) then
        self.ImgNoSituation.gameObject:SetActiveEx(false)
    else
        self.ImgNoSituation.gameObject:SetActiveEx(true)
    end
    self.DynamicTableSituation:SetDataSource(self.DataRecord)
    self.DynamicTableSituation:ReloadDataASync(1)
    --区域排行榜人数
    self.BtnPlayer:SetNameByGroup(0,0)
    self.BtnPlayer:SetNameByGroup(0,self.Node.FightCount)
    --进入按钮(休战期隐藏)
    self.BtnGo.gameObject:SetActiveEx(XDataCenter.GuildWarManager.CheckRoundIsInTime())
end

function XUiGuildWarConcealStageDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.DataRecord and self.DataRecord[index] then
            --grid.GameObject:SetActiveEx(true)
            grid:RefreshData(self.DataRecord[index])
        end
    end
end

function XUiGuildWarConcealStageDetail:OnBtnGoClicked()
    self:Close()
    XLuaUiManager.Open("UiGuildWarDeploy", self.Node)
end
function XUiGuildWarConcealStageDetail:OnBtnHelpClicked()
    XLuaUiManager.Open("UiGuildWarStageTips", self.Node)
end
function XUiGuildWarConcealStageDetail:OnBtnPlayerClicked()
    local rankId = RoundIdToRankId[XDataCenter.GuildWarManager.GetCurrentRoundId()]
    XLuaUiManager.Open("UiGuildWarRank", rankId)
end
function XUiGuildWarConcealStageDetail:OnBtnCloseClicked()
    self:Close()
end

function XUiGuildWarConcealStageDetail:RefreshButtonStatus()
    -- 无法参与此轮
    if XDataCenter.GuildWarManager.CheckIsPlayerSkipRound() then
        self.BtnGo.gameObject:SetActiveEx(false)
        return
    end
end

return XUiGuildWarConcealStageDetail