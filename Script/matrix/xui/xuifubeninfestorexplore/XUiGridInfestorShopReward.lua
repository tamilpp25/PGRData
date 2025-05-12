local XUiGridInfestorExploreCore = require("XUi/XUiFubenInfestorExplore/XUiGridInfestorExploreCore")

local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiGridInfestorShopReward = XClass(nil, "XUiGridInfestorShopReward")

function XUiGridInfestorShopReward:Ctor(ui, rootUi, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:InitRootUi(rootUi)
    self:SetSelect(false)
end

function XUiGridInfestorShopReward:InitRootUi(rootUi)
    self.RootUi = rootUi
end

function XUiGridInfestorShopReward:Refresh(rewardId, chapterId, nodeId)
    self.GridCore = self.GridCore or XUiGridInfestorExploreCore.New(self.GridInfestorExploreCore, self.RootUi)
    local coreId = XFubenInfestorExploreConfigs.GetRewardCoreId(rewardId)
    local coreLevel = XFubenInfestorExploreConfigs.GetRewardCoreLevel(rewardId)
    self.GridCore:Refresh(coreId, coreLevel)

    if XDataCenter.FubenInfestorExploreManager.IsLastPlayerSelectReward(chapterId, nodeId, rewardId) then
        
        local headPortraitId = XDataCenter.FubenInfestorExploreManager.GetSelectRewardPlayerHeadId(chapterId, nodeId)
        local headFrameId = XDataCenter.FubenInfestorExploreManager.GetSelectRewardPlayerHeadFrameId(chapterId, nodeId)
        XUiPlayerHead.InitPortrait(headPortraitId, headFrameId, self.Head)
        
        local playerName = XDataCenter.FubenInfestorExploreManager.GetSelectRewardPlayerName(chapterId, nodeId)
        self.TxtLastPlayer.text = CSXTextManagerGetText("InfestorExploreRewardNodeLastPlayerSelect", playerName)

        self.PanelPlayer.gameObject:SetActiveEx(true)
    else
        self.PanelPlayer.gameObject:SetActiveEx(false)
    end
end

function XUiGridInfestorShopReward:SetSelect(value)
    self.ImgSelect.gameObject:SetActiveEx(value)
end

return XUiGridInfestorShopReward