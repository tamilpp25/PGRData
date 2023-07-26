--===========================
--超级爬塔 爬塔进入关卡准备 页面
--===========================
local XUiSTTierPrepare = XLuaUiManager.Register(XLuaUi, "UiSuperTowerStageDetail04")
local SHOW_TYPE = { --显示类型
        Start = 1, --开始爬塔
        Continue = 2 --继续爬塔
    }
--子面板序号
local CHILD_PANEL_INDEX = {
    Enhance = 1, --爬塔增益面板
    Plugins = 2, --插件掉落面板
    Progress = 3, --进度面板
    Score = 4, --荣誉分数面板
    Team = 5, --队伍面板
}
--子面板脚本地址
local CHILD_PANEL_SCRIPT_PATH = "XUi/XUiSuperTower/Stages/Tier/XUiStTp"

function XUiSTTierPrepare:OnAwake()
    XTool.InitUiObject(self)
end

function XUiSTTierPrepare:InitChildPanelControl()
    local script = require("XUi/XUiSuperTower/Common/XUiSTMainPage")
    self.ChildPanelControl = script.New(self)
end

function XUiSTTierPrepare:InitBtns()
    self.BtnFight.CallBack = function() self:OnBtnFightClick() end
    self.BtnDrop.CallBack = function() self:OnBtnDropClick() end
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self:BindHelpBtn(self.BtnHelp, "SuperTowerTierHelp")
end

function XUiSTTierPrepare:OnStart(theme)
    self.Theme = theme
    self:InitChildPanelControl()
    self:InitPanelAssets()
    self.ChildPanelControl:RegisterChildPanels(CHILD_PANEL_INDEX, CHILD_PANEL_SCRIPT_PATH)
    self:InitBtns()
    self:SetActivityTimeLimit()
end

function XUiSTTierPrepare:OnEnable()
    XUiSTTierPrepare.Super.OnEnable(self)
    self.ShowType = self.Theme:CheckTierIsPlaying() and SHOW_TYPE.Continue or SHOW_TYPE.Start
    self:ShowPanel()
end

function XUiSTTierPrepare:InitPanelAssets()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    local itemIds = XSuperTowerConfigs.GetMainAssetsPanelItemIds()
    XDataCenter.ItemManager.AddCountUpdateListener(itemIds, function()
            self.AssetActivityPanel:Refresh(itemIds)
        end, self.AssetActivityPanel)
    self.AssetActivityPanel:Refresh(itemIds)
end

function XUiSTTierPrepare:ShowPanel()
    self:SetIconAlphaByShowType()
    self:SetBtnsByType()
    self:ShowChildPanelsByType()
end

function XUiSTTierPrepare:SetIconAlphaByShowType()
    self.RImgIcon.gameObject:SetActiveEx(self:GetIsStart())
    if self.ImgThemeIndex then self.ImgThemeIndex:SetSprite(XUiHelper.GetClientConfig("SuperTowerThemeIndexLogo" .. self.Theme:GetIndex(), XUiHelper.ClientConfigType.String)) end
end

function XUiSTTierPrepare:SetBtnsByType()
    self.BtnFight:SetName(self:GetIsStart() and CS.XTextManager.GetText("STStartTier") or CS.XTextManager.GetText("STContinueTier"))
    self.BtnDrop.gameObject:SetActiveEx(not self:GetIsStart())
end

function XUiSTTierPrepare:ShowChildPanelsByType()
    local showIndex = {
        [CHILD_PANEL_INDEX.Enhance] = true, --爬塔增益面板
        [CHILD_PANEL_INDEX.Plugins] = true, --插件掉落面板
        [CHILD_PANEL_INDEX.Progress] = true, --进度面板
        [CHILD_PANEL_INDEX.Score] = true, --荣誉分数面板
        [CHILD_PANEL_INDEX.Team] = not self:GetIsStart(), --队伍面板
        }
    self.ChildPanelControl:ShowChildPanel(showIndex)
end

function XUiSTTierPrepare:OnBtnBackClick()
    self:Close()
end

function XUiSTTierPrepare:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiSTTierPrepare:GetIsStart()
    return self.ShowType == SHOW_TYPE.Start
end

function XUiSTTierPrepare:OnBtnFightClick()
    local isStart = self:GetIsStart()
    if isStart then
        XLuaUiManager.Open("UiBattleRoleRoom"
            , self.Theme:GetCurrentTierStageId()
            , XDataCenter.SuperTowerManager.GetTeamByStageType(XDataCenter.SuperTowerManager.StageType.LllimitedTower)
            , require("XUi/XUiSuperTower/Room/XUiSuperTowerBattleRoleRoom"))
    else
        local stageConfig = XDataCenter.FubenManager.GetStageCfg(self.Theme:GetCurrentTierStageId())
        local isAssist = false
        local challengeCount = 1
        XDataCenter.FubenManager.EnterFight(stageConfig, nil, isAssist, challengeCount)
    end
end

function XUiSTTierPrepare:OnBtnDropClick()
    XLuaUiManager.Open("UiSuperTowerFubenCloseTip", self.Theme)
end

function XUiSTTierPrepare:SetActivityTimeLimit()
    -- 自动关闭
    local endTime = XDataCenter.SuperTowerManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
            if isClose then
                XDataCenter.SuperTowerManager.HandleActivityEndTime()
            end
        end)
end