---光辉同行关卡详细信息界面
local XUiFubenBrilliantWalkStoryDetail = XLuaUiManager.Register(XLuaUi, "UiFubenBrilliantWalkStoryDetail")
local XUIBrilliantWalkStageDetailPluginGrid = require("XUi/XUiBrilliantWalk/XUIGrid/XUIBrilliantWalkStageDetailPluginGrid")

function XUiFubenBrilliantWalkStoryDetail:OnAwake()
    self.PanelDetail.gameObject:SetActiveEx(false)
    self.PanelBossDetail.gameObject:SetActiveEx(false)
    self.PanelStoryDetail.gameObject:SetActiveEx(true)
    XTool.InitUiObjectByUi(self,self.PanelStoryDetail)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint)
    self.BtnEnter.CallBack = function()
        self:OnBtnEnterClick()
    end
    self.Close.CallBack = function()
        self:OnBtnCloseClick()
    end
end
function XUiFubenBrilliantWalkStoryDetail:OnEnable(openUIData)
    self.StageId = openUIData.StageId
    self.EnterCallback = openUIData.StageEnterCallback
    self.CloseCallback = openUIData.CloseCallback
    self:UpdateView()
end
function XUiFubenBrilliantWalkStoryDetail:OnDisable()
end
--刷新界面
function XUiFubenBrilliantWalkStoryDetail:UpdateView()
    local UiData = XDataCenter.BrilliantWalkManager.GetUiDataBossStageInfo(self.StageId)
    --关卡名
    self.TxtTitle.text = UiData.StageName
    --关卡详情
    self.TxtStoryDes.text = UiData.Description
    --消耗血清
    self.TxtATNums.text = UiData.ActionPoint
end
--点击战斗准备按钮
function XUiFubenBrilliantWalkStoryDetail:OnBtnEnterClick()
    if self.EnterCallback then self.EnterCallback(self.StageId) end
end
--点击空白区域关闭按钮
function XUiFubenBrilliantWalkStoryDetail:OnBtnCloseClick()
    if self.CloseCallback then self.CloseCallback() end
end