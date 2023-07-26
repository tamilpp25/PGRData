---光辉同行关卡详细信息界面
local XUiFubenBrilliantWalkBossDetail = XLuaUiManager.Register(XLuaUi, "UiFubenBrilliantWalkBossDetail")
local XUIBrilliantWalkStageDetailPluginGrid = require("XUi/XUiBrilliantWalk/XUIGrid/XUIBrilliantWalkStageDetailPluginGrid")

function XUiFubenBrilliantWalkBossDetail:OnAwake()
    self.PanelDetail.gameObject:SetActiveEx(false)
    self.PanelBossDetail.gameObject:SetActiveEx(true)
    self.PanelStoryDetail.gameObject:SetActiveEx(false)
    XTool.InitUiObjectByUi(self,self.PanelBossDetail)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint)
    --推荐插件配置
    self.PluginGridPool = XStack.New() --插件UI内存池
    self.PluginGridList = XStack.New() --正在使用的插件UI
    self.GridRecommendPlugin.gameObject:SetActiveEx(false) --插件UI template
    self.GridRecommendNone.gameObject:SetActiveEx(false)

    self.BtnEnter.CallBack = function()
        self:OnBtnEnterClick()
    end
    self.BtnBecaful.CallBack = function()
        self:OnBtnBecarefulClick()
    end
    self.Close.CallBack = function()
        self:OnBtnCloseClick()
    end
end
function XUiFubenBrilliantWalkBossDetail:OnEnable(openUIData)
    self.StageId = openUIData.StageId
    self.EnterCallback = openUIData.StageEnterCallback
    self.PluginSkipCallback = openUIData.PluginSkipCallback
    self.AttentionCallback = openUIData.AttentionCallback
    self.CloseCallback = openUIData.CloseCallback
    self:UpdateView()
end
function XUiFubenBrilliantWalkBossDetail:OnDisable()
    self:PluginGridReturnPool()
end
--获取插件item
function XUiFubenBrilliantWalkBossDetail:GetPluginGrid()
    local item
    if self.PluginGridPool:IsEmpty() then
        local object = CS.UnityEngine.Object.Instantiate(self.GridRecommendPlugin)
        object.transform:SetParent(self.PanelRecommend, false)
        item = XUIBrilliantWalkStageDetailPluginGrid.New(object,self)
    else
        item = self.PluginGridPool:Pop()
    end
    item.GameObject:SetActiveEx(true)
    self.PluginGridList:Push(item)
    return item
end
--所有使用中插件Item回归内存池
function XUiFubenBrilliantWalkBossDetail:PluginGridReturnPool()
    while (not self.PluginGridList:IsEmpty()) do
        local object = self.PluginGridList:Pop()
        object.GameObject:SetActiveEx(false)
        self.PluginGridPool:Push(object)
    end
end
--刷新界面
function XUiFubenBrilliantWalkBossDetail:UpdateView()
    local UiData = XDataCenter.BrilliantWalkManager.GetUiDataBossStageInfo(self.StageId)
    --关卡名
    self.TxtTitle.text = UiData.StageName
    --消耗血清
    self.TxtATNums.text = UiData.ActionPoint
    --推荐配置
    self:PluginGridReturnPool()
    if #UiData.RecommendBuild > 0 then
        self.GridRecommendNone.gameObject:SetActiveEx(false)
        for index,plugInId in pairs(UiData.RecommendBuild) do
            local item = self:GetPluginGrid()
            item:Refresh(plugInId)
            item:SetEquiped(UiData.RecommendBuildEquipState[index])
        end
    else
        self.GridRecommendNone.gameObject:SetActiveEx(true)
    end
    --最高得分
    if UiData.MaxScore > 0 then
        self.PanelScoreInfo.gameObject:SetActiveEx(true)
        self.ScoreNone.gameObject:SetActiveEx(false)
        local rank = XDataCenter.BrilliantWalkManager.GetStageScoreRank(self.StageId,UiData.MaxScore)
        self.ImgScore:SetRawImage(CS.XGame.ClientConfig:GetString("BrilliantWalkStageDetailRankRImg" .. rank))
        self.TextScore.text = UiData.MaxScore
    else
        self.PanelScoreInfo.gameObject:SetActiveEx(false)
        self.ScoreNone.gameObject:SetActiveEx(true)
    end
    --关卡提示按钮
    self.BtnBecaful.gameObject:SetActiveEx(true)
end
--点击战斗准备按钮
function XUiFubenBrilliantWalkBossDetail:OnBtnEnterClick()
    if self.EnterCallback then self.EnterCallback(self.StageId) end
end
--点击注意事项按钮
function XUiFubenBrilliantWalkBossDetail:OnBtnBecarefulClick()
    if self.AttentionCallback then self.AttentionCallback() end
end
--点击空白区域关闭按钮
function XUiFubenBrilliantWalkBossDetail:OnBtnCloseClick()
    if self.CloseCallback then self.CloseCallback() end
end
--点击插件跳转按钮
function XUiFubenBrilliantWalkBossDetail:OnPluginSkipClick(pluginId)
    if self.PluginSkipCallback then self.PluginSkipCallback(pluginId) end
end