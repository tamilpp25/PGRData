--===========================
--超级爬塔多波关卡详情
--===========================
local XUiSuperTowerMultiStageDetail = XLuaUiManager.Register(XLuaUi, "UiSuperTowerMultiStageDetail")
local CSTextManagerGetText = CS.XTextManager.GetText
local XUiGridStageReward = require("XUi/XUiSuperTower/Map/XUiGridStageReward")
local XUiSuperTowerBattleRoleRoom = require("XUi/XUiSuperTower/Room/XUiSuperTowerBattleRoleRoom")
function XUiSuperTowerMultiStageDetail:OnStart(stageData, themeIndex, callBack)
    self.STStage = stageData
    self.ThemeIndex = themeIndex
    self.CallBack = callBack
    self:SetButtonCallBack()
    self:InitPanelReward()
end

function XUiSuperTowerMultiStageDetail:OnDestroy()

end

function XUiSuperTowerMultiStageDetail:OnEnable()
    self:UpdatePanel()
end

function XUiSuperTowerMultiStageDetail:OnDisable()
    
end

function XUiSuperTowerMultiStageDetail:SetButtonCallBack()
   self.BtnFight.CallBack = function()
       self:OnBtnFightClick()
   end
    self.BtnCloseMask.CallBack = function()
        self:OnBtnCloseMaskClick()
    end
end

function XUiSuperTowerMultiStageDetail:OnBtnFightClick()
    self:OnBtnCloseMaskClick()
    if self.STStage:CheckIsMultiTeamMultiWave() then
        XLuaUiManager.Open("UiSuperTowerDeploy", self.STStage)
    elseif self.STStage:CheckIsSingleTeamMultiWave() then
        XLuaUiManager.Open("UiBattleRoleRoom",
            self.STStage:GetFirstStageId(),
            XDataCenter.SuperTowerManager.GetTeamByStageId(self.STStage:GetFirstStageId()),
            require("XUi/XUiSuperTower/Room/XUiSuperTowerBattleRoleRoom"))
    end
    
end

function XUiSuperTowerMultiStageDetail:OnBtnCloseMaskClick()
    self:Close()
    if self.CallBack then self.CallBack() end
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_ST_MAP_THEME_SELECT, self.ThemeIndex)
end

function XUiSuperTowerMultiStageDetail:InitPanelReward()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelReward)
    self.DynamicTable:SetProxy(XUiGridStageReward)
    self.DynamicTable:SetDelegate(self)
    self.GridReward.gameObject:SetActiveEx(false)
end

function XUiSuperTowerMultiStageDetail:UpdatePanel()
    self:UpdatePanelSingleTeam()
    self:UpdatePanelMultiTeam()
    self:UpdatePanelInfo()
    self:UpdatePanelReward()
    self:UpdateAssetsPanel()
end

function XUiSuperTowerMultiStageDetail:UpdatePanelMultiTeam()
    local IsMultiTeam = self.STStage:CheckIsMultiTeamMultiWave()
    if IsMultiTeam then
        self.PanelMultiTeam:GetObject("TxtProgress").text = self.STStage:GetProgressStr()
        self.PanelMultiTeam:GetObject("TxtTeamCount").text = #self.STStage:GetStageId()
    end
    self.PanelMultiTeam.gameObject:SetActiveEx(IsMultiTeam)
end

function XUiSuperTowerMultiStageDetail:UpdatePanelSingleTeam()
    local IsSingleTeam = self.STStage:CheckIsSingleTeamMultiWave()
    if IsSingleTeam then
        self.PanelSingleTeam:GetObject("TxtProgress").text = self.STStage:GetProgressStr()
    end
    self.PanelSingleTeam.gameObject:SetActiveEx(IsSingleTeam)
end

function XUiSuperTowerMultiStageDetail:UpdatePanelInfo()
    self.PanelInfo:GetObject("TxtName").text = self.STStage:GetStageName()
    self.PanelInfo:GetObject("TxtNumber").text = self.STStage:GetSimpleName()
    self.PanelInfo:GetObject("RImgIcon"):SetRawImage(self.STStage:GetStageBg())
end

function XUiSuperTowerMultiStageDetail:UpdatePanelReward()
    self.PageDatas = self.STStage:GetRewardId()
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiSuperTowerMultiStageDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self, self.PageDatas[index], index, self.STStage)
    end
end

function XUiSuperTowerMultiStageDetail:UpdateAssetsPanel()
    if not self.PanelSpecialTool then return end
    local itemIds = XSuperTowerConfigs.GetMainAssetsPanelItemIds()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener(itemIds, function()
            self.AssetActivityPanel:Refresh(itemIds)
        end, self.AssetActivityPanel)
    self.AssetActivityPanel:Refresh(itemIds)
end