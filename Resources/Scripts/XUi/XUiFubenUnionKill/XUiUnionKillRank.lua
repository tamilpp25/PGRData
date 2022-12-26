local XUiUnionKillRank = XLuaUiManager.Register(XLuaUi, "UiUnionKillRank")
local XUiPanelUnionKillMainRank = require("XUi/XUiFubenUnionKill/XUiPanelUnionKillMainRank")
local XUiPanelUnionKillRankReward = require("XUi/XUiFubenUnionKill/XUiPanelUnionKillRankReward")

function XUiUnionKillRank:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset,
    XDataCenter.ItemManager.ItemId.FreeGem,
    XDataCenter.ItemManager.ItemId.ActionPoint,
    XDataCenter.ItemManager.ItemId.Coin)
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.BtnHelp.CallBack = function()
        self:OnBtnHelpClick()
    end
    self:BindHelpBtnOnly(self.BtnHelp)

    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")

    self.MainRankInfo = XUiPanelUnionKillMainRank.New(self.PanelBossRankInfo, self)
    self.RankReward = XUiPanelUnionKillRankReward.New(self.PanelRankReward, self)
end

function XUiUnionKillRank:OnDestroy()
    self.MainRankInfo:EndSectionCounter()
end

function XUiUnionKillRank:OnStart(rankType)
    self.RankType = rankType

    self.MainRankInfo:Refresh(rankType)
end

function XUiUnionKillRank:OpenRankReward(rankSelectLevel)
    if self.RankType == XFubenUnionKillConfigs.UnionRankType.KillNumber then
        self:PlayAnimation("RankRewardEnable", function()
            XLuaUiManager.SetMask(false)
        end, function()
            XLuaUiManager.SetMask(true)
        end)
        self.RankReward:Refresh(rankSelectLevel)
    end
end

function XUiUnionKillRank:OnBtnHelpClick()
    if self.RankType == XFubenUnionKillConfigs.UnionRankType.KillNumber then
        XUiManager.ShowHelpTip("UnionKillRankHelp")
    else
        XUiManager.ShowHelpTip("UnionPraiseRankHelp")
    end
end

function XUiUnionKillRank:OnBtnBackClick()
    self:Close()
end

function XUiUnionKillRank:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end