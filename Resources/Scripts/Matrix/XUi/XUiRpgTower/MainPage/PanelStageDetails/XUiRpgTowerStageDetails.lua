--兵法蓝图主界面：关卡详细面板
local XUiRpgTowerStageDetails = XClass(nil, "XUiRpgTowerStageDetails")
local XUiRpgTowerStageBuffPanel = require("XUi/XUiRpgTower/MainPage/PanelStageDetails/XUiRpgTowerStageBuffPanel")
local XUiRpgTowerStageRewardsPanel = require("XUi/XUiRpgTower/MainPage/PanelStageDetails/XUiRpgTowerStageRewardsPanel")
function XUiRpgTowerStageDetails:Ctor(ui, rootUi)
    XTool.InitUiObjectByUi(self, ui)
    self.RootUi = rootUi
    self.RewardsPanel = XUiRpgTowerStageRewardsPanel.New(self.PanelReward, self.RootUi)
    self.BuffPanel = XUiRpgTowerStageBuffPanel.New(self.PanelBuff, self.RootUi)
    self.BtnEnter.CallBack = function() self:OnClickBtnEnter() end
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, function() self:HidePanel() end)
end
--================
--刷新关卡数据
--================
function XUiRpgTowerStageDetails:RefreshStage(rStage)
    self.TxtTitle.text = rStage:GetStageName()
    self.TxtBuff.text = rStage:GetStageBuffDesc()
    local tipsText = CS.XTextManager.GetText("RpgTowerStageDetialRecommendLevelTips", rStage:GetRecommendLevel())
    if XDataCenter.RpgTowerManager.GetCurrentLevel() < (self.RootUi.RStage:GetRecommendLevel() or 0) then
        self.TxtTips.text = CS.XTextManager.GetText("CommonRedText", tipsText)
    else
        self.TxtTips.text = tipsText
    end
    self.RewardsPanel:RefreshRewards(rStage)
    self.BuffPanel:RefreshBuff(rStage)

end
--================
--进入关卡按钮
--================
function XUiRpgTowerStageDetails:OnClickBtnEnter()
    local stageCfg = self.RootUi.RStage:GetStageCfg()
    if XDataCenter.RpgTowerManager.GetCurrentLevel() < (self.RootUi.RStage:GetRecommendLevel() or 0) then
        local tipTitle = CS.XTextManager.GetText("RpgTowerTeamLevelNotEnoughTitle")
        local tipContent = CS.XTextManager.GetText("RpgTowerTeamLevelNotEnoughContent")
        CsXUiManager.Instance:Open("UiDialog", tipTitle, tipContent, XUiManager.DialogType.Normal, nil, function()
                    if not XDataCenter.FubenManager.CheckPreFight(stageCfg) then
                        return
                    end
                    self:HidePanel()
                    XLuaUiManager.Open("UiNewRoomSingle", self.RootUi.RStage:GetStageId())
                end)
    else
        if not XDataCenter.FubenManager.CheckPreFight(stageCfg) then
            return
        end
        self:HidePanel()
        XLuaUiManager.Open("UiNewRoomSingle", self.RootUi.RStage:GetStageId())
    end
end
--================
--隐藏面板
--================
function XUiRpgTowerStageDetails:HidePanel()
    self.GameObject:SetActiveEx(false)
end
--================
--打开面板
--================
function XUiRpgTowerStageDetails:ShowPanel()
    self.RootUi:PlayAnimation("PanelPopupEnable")
    self.GameObject:SetActiveEx(true)
end

return XUiRpgTowerStageDetails