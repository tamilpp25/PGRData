local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
--===========================
--超级爬塔单波关卡详情
--===========================
local XUiSuperTowerSingleStageDetail = XLuaUiManager.Register(XLuaUi, "UiSuperTowerSingleStageDetail")
local CSTextManagerGetText = CS.XTextManager.GetText
local CSObjectInstantiate = CS.UnityEngine.Object.Instantiate
local DefaultIndex = 1
function XUiSuperTowerSingleStageDetail:OnStart(stStage, themeIndex, callBack)
    self.STStage = stStage
    self.ThemeIndex = themeIndex
    self.CallBack = callBack
    self:SetButtonCallBack()
    self.PanelReward:GetObject("Grid128").gameObject:SetActiveEx(false)
    self.GridRewardList = {}
end

function XUiSuperTowerSingleStageDetail:OnDestroy()

end

function XUiSuperTowerSingleStageDetail:OnEnable()
    self:UpdatePanel()
end

function XUiSuperTowerSingleStageDetail:OnDisable()
    
end

function XUiSuperTowerSingleStageDetail:SetButtonCallBack()
    self.BtnFight.CallBack = function()
        self:OnBtnFightClick()
    end
    self.BtnCloseMask.CallBack = function()
        self:OnBtnCloseMaskClick()
    end
end

function XUiSuperTowerSingleStageDetail:OnBtnFightClick()
    local team = XDataCenter.SuperTowerManager.GetTeamByStageId(self.STStage:GetFirstStageId())
    local extraData = team:GetExtraData()
    extraData:SetStageId(self.STStage:GetFirstStageId())
    self:OnBtnCloseMaskClick()
    XLuaUiManager.Open("UiBattleRoleRoom",
        self.STStage:GetFirstStageId(),
        XDataCenter.SuperTowerManager.GetTeamByStageId(self.STStage:GetFirstStageId()),
        require("XUi/XUiSuperTower/Room/XUiSuperTowerBattleRoleRoom"))
end

function XUiSuperTowerSingleStageDetail:OnBtnCloseMaskClick()
    self:Close()
    if self.CallBack then self.CallBack() end
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_ST_MAP_THEME_SELECT, self.ThemeIndex)
end

function XUiSuperTowerSingleStageDetail:UpdatePanel()
    self:UpdatePanelReward()
    self:UpdatePanelInfo()
    self:UpdateAssetsPanel()
end

function XUiSuperTowerSingleStageDetail:UpdatePanelReward()
    local rewardIds = self.STStage:GetRewardId()
    local rewards = XRewardManager.GetRewardList(rewardIds[DefaultIndex])--单波只存在一个奖励ID
    if rewards then
        for i, item in pairs(rewards) do
            local grid = self.GridRewardList[i]
            if not grid then
                local ui = CSObjectInstantiate(self.PanelReward:GetObject("Grid128"),self.PanelReward:GetObject("RewardParent"))
                grid = XUiGridCommon.New(self, ui)
                self.GridRewardList[i] = grid
            end
            grid:Refresh(item)
            grid.GameObject:SetActiveEx(true)
        end

        for i = #rewards + 1, #self.GridRewardList do
            self.GridRewardList[i].GameObject:SetActiveEx(false)
        end
    end
    
    self.PanelReward:GetObject("PanelClear").gameObject:SetActiveEx(self.STStage:CheckIsClear())
end

function XUiSuperTowerSingleStageDetail:UpdatePanelInfo()
    local description = self.STStage:GetStageDescription() or ""
    description = string.gsub(description, "\\n", "\n")
    self.PanelInfo:GetObject("TxtStageInfo").text = description
    self.PanelInfo:GetObject("TxtName").text = self.STStage:GetStageName()
    self.PanelInfo:GetObject("TxtNumber").text = self.STStage:GetSimpleName()
    self.PanelInfo:GetObject("RImgIcon"):SetRawImage(self.STStage:GetStageBg())
end

function XUiSuperTowerSingleStageDetail:UpdateAssetsPanel()
    if not self.PanelSpecialTool then return end
    local itemIds = XSuperTowerConfigs.GetMainAssetsPanelItemIds()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener(itemIds, function()
            self.AssetActivityPanel:Refresh(itemIds)
        end, self.AssetActivityPanel)
    self.AssetActivityPanel:Refresh(itemIds)
end