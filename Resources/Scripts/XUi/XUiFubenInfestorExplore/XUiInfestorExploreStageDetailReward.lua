local CSXTextManagerGetText = CS.XTextManager.GetText
local EVENT_NAME_STR = CSXTextManagerGetText("InfestorExploreRewardNodeName")
local EVENT_DES_STR = CSXTextManagerGetText("InfestorExploreRewardNodeDes")

local XUiInfestorExploreStageDetailReward = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreStageDetailReward")

function XUiInfestorExploreStageDetailReward:OnAwake()
    self:AutoAddListener()
end

function XUiInfestorExploreStageDetailReward:OnStart(closeCb)
    self.CloseCb = closeCb
end

function XUiInfestorExploreStageDetailReward:Refresh(chapterId, nodeId)
    self.ChapterId = chapterId
    self.NodeId = nodeId

    self.TxtName.text = EVENT_NAME_STR
    self.TxtDes.text = EVENT_DES_STR

    local bg = XDataCenter.FubenInfestorExploreManager.GetNodeStageBg(chapterId, nodeId)
    self.RImgIcon:SetRawImage(bg)

    local playerHeadIcon = XDataCenter.FubenInfestorExploreManager.GetSelectRewardPlayerHeadIcon(chapterId, nodeId)-----zhangshuang
    if playerHeadIcon then
        self.RImgHead:SetRawImage(playerHeadIcon)
    end

    local effctPath = XDataCenter.FubenInfestorExploreManager.GetSelectRewardPlayerHeadEffectPath(chapterId, nodeId)
    if effctPath then
        self.EffectHead:LoadUiEffect(effctPath)
    end

    self.TxtRoleName.text = XDataCenter.FubenInfestorExploreManager.GetSelectRewardPlayerName(chapterId, nodeId)
    self.TxtWord.text = XDataCenter.FubenInfestorExploreManager.GetSelectRewardMessage(chapterId, nodeId)
end

function XUiInfestorExploreStageDetailReward:OnDisable()
    self.CloseCb()
end

function XUiInfestorExploreStageDetailReward:AutoAddListener()
    self.BtnCloseMask.CallBack = function() self:Close() end
    self.BtnGuestbook.CallBack = function() self:OnClickBtnGuestbook() end
    self.BtnReward.CallBack = function() self:OnClickBtnReward() end
end

function XUiInfestorExploreStageDetailReward:OnClickBtnReward()
    local chapterId = self.ChapterId
    local nodeId = self.NodeId

    if XDataCenter.FubenInfestorExploreManager.IsNodePassed(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreRewardNodePassed")
        return
    end

    if XDataCenter.FubenInfestorExploreManager.IsNodeCurrentFinished(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreRewardNodePassed")
        return
    end

    if XDataCenter.FubenInfestorExploreManager.IsNodeUnReach(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreRewardNodeNotReach")
        return
    end

    if not XDataCenter.FubenInfestorExploreManager.CheckActionPoint(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreActionPointNotEnough")
        return
    end

    local rewardCallBack = function(selectRewardIdList)
        self:Close()
        XLuaUiManager.Open("UiInfestorExploreStageDetailRewardGive", selectRewardIdList, chapterId, nodeId)
    end
    XDataCenter.FubenInfestorExploreManager.RequestGetSelectReward(nodeId, rewardCallBack)
end

function XUiInfestorExploreStageDetailReward:OnClickBtnGuestbook()
    XDataCenter.FubenInfestorExploreManager.OpenGuestBook(self.ChapterId)
end