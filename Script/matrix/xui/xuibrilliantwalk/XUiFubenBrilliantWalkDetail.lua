local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---光辉同行关卡详细信息界面
local XUiFubenBrilliantWalkDetail = XLuaUiManager.Register(XLuaUi, "UiFubenBrilliantWalkDetail")
local XUIBrilliantWalkStageDetailPluginGrid = require("XUi/XUiBrilliantWalk/XUIGrid/XUIBrilliantWalkStageDetailPluginGrid")
--local XUIBrilliantWalkStageDetailUnlockGrid = require("XUi/XUiBrilliantWalk/XUIGrid/XUIBrilliantWalkStageDetailUnlockGrid")
local BrilliantWalkEnergyItem = CS.XGame.ClientConfig:GetInt("BrilliantWalkEnergyItem")

function XUiFubenBrilliantWalkDetail:OnAwake()
    self.PanelBossDetail.gameObject:SetActiveEx(false)
    self.PanelDetail.gameObject:SetActiveEx(true)
    self.PanelStoryDetail.gameObject:SetActiveEx(false)
    XTool.InitUiObjectByUi(self,self.PanelDetail)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint)
    --推荐插件配置
    self.PluginGridPool = XStack.New() --插件UI内存池
    self.PluginGridList = XStack.New() --正在使用的插件UI
    self.GridRecommendPlugin.gameObject:SetActiveEx(false) --插件UI template
    self.GridRecommendNone.gameObject:SetActiveEx(false)
    --解锁插件
    self.UnlockGridPool = XStack.New() --插件解锁预览 UI内存池
    self.UnlockGridList = XStack.New() --正在使用的插件解锁预览UI
    self.GridCommon.gameObject:SetActiveEx(false) --插件解锁预览UI template
    --解锁能量Grid
    self.EnergyGrid = XUiGridCommon.New(self, self.GridCommon2)
    self.EnergyGrid:Refresh({
        TemplateId = BrilliantWalkEnergyItem,
        TipNotShowCount = true,
    })
    self.EnergyGrid:SetUiActive(self.EnergyGrid.ImgQuality, false)
    
    self.BtnEnter.CallBack = function()
        self:OnBtnEnterClick()
    end
    self.Close.CallBack = function()
        self:OnBtnCloseClick()
    end
end
function XUiFubenBrilliantWalkDetail:OnEnable(openUIData)
    self.StageId = openUIData.StageId
    self.EnterCallback = openUIData.StageEnterCallback
    self.PluginSkipCallback = openUIData.PluginSkipCallback
    self.CloseCallback = openUIData.CloseCallback
    self:UpdateView()
end
function XUiFubenBrilliantWalkDetail:OnDisable()
    self:PluginGridReturnPool()
    self:UnlockGridReturnPool()
end
--获取插件item
function XUiFubenBrilliantWalkDetail:GetPluginGrid()
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
function XUiFubenBrilliantWalkDetail:GetUnlockGrid()
    local item
    if self.UnlockGridPool:IsEmpty() then
        local object = CS.UnityEngine.Object.Instantiate(self.GridCommon)
        object.transform:SetParent(self.PanelDropContent, false)
        item = XUiGridCommon.New(self, object)
        item.TagGet = item.Transform:FindTransform("TagGet")
        --item = XUIBrilliantWalkStageDetailUnlockGrid.New(object,item)
    else
        item = self.UnlockGridPool:Pop()
    end
    item.GameObject:SetActiveEx(true)
    self.UnlockGridList:Push(item)
    return item
end
--所有使用中插件Item回归内存池
function XUiFubenBrilliantWalkDetail:PluginGridReturnPool()
    while (not self.PluginGridList:IsEmpty()) do
        local object = self.PluginGridList:Pop()
        object.GameObject:SetActiveEx(false)
        self.PluginGridPool:Push(object)
    end
end
function XUiFubenBrilliantWalkDetail:UnlockGridReturnPool()
    while (not self.UnlockGridList:IsEmpty()) do
        local object = self.UnlockGridList:Pop()
        object.GameObject:SetActiveEx(false)
        self.UnlockGridPool:Push(object)
    end
end
--刷新界面
function XUiFubenBrilliantWalkDetail:UpdateView()
    local UiData = XDataCenter.BrilliantWalkManager.GetUiDataStageDetail(self.StageId)
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


    self:UnlockGridReturnPool()
    self.DrolListNone.gameObject:SetActiveEx(false)
    --解锁能量
    if UiData.UnlockEnergy > 0 then
        self.EnergyGrid.GameObject:SetActiveEx(true)
        self.EnergyGrid.TxtCount.text = tostring(UiData.UnlockEnergy)
        self.EnergyGrid.TagGet.gameObject:SetActiveEx(UiData.IsClear)
    else
        self.EnergyGrid.GameObject:SetActiveEx(false)
    end
    --解锁组件
    if #UiData.UnlockPlugin > 0 then
        for index,plugInId in pairs(UiData.UnlockPlugin) do
            local item = self:GetUnlockGrid()
            local itemId = XBrilliantWalkConfigs.GetBuildPluginItemId(plugInId)
            item:Refresh({
                TemplateId = itemId,
                TipNotShowCount = true,
                TipShowBlackBg = true,
            })
            item.TagGet.gameObject:SetActiveEx(UiData.IsClear)
            item:SetUiActive(item.ImgQuality, false)
        end
    end
    if UiData.UnlockEnergy == 0 and #UiData.UnlockPlugin == 0 then
        self.DrolListNone.gameObject:SetActiveEx(true)
    end
end
--点击战斗准备按钮
function XUiFubenBrilliantWalkDetail:OnBtnEnterClick()
    if self.EnterCallback then self.EnterCallback(self.StageId) end
end
--点击空白区域关闭按钮
function XUiFubenBrilliantWalkDetail:OnBtnCloseClick()
    if self.CloseCallback then self.CloseCallback() end
end
--点击插件跳转按钮
function XUiFubenBrilliantWalkDetail:OnPluginSkipClick(pluginId)
    if self.PluginSkipCallback then self.PluginSkipCallback(pluginId) end
end