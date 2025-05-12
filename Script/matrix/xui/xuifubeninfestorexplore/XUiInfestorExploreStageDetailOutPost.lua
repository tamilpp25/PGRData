local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local stringGsub = string.gsub

local EVENT_NAME_STR = CS.XTextManager.GetText("InfestorExploreOutPostNodeName")

local XUiInfestorExploreStageDetailOutPost = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreStageDetailOutPost")

function XUiInfestorExploreStageDetailOutPost:OnAwake()
    self.GridItem.gameObject:SetActiveEx(false)
    self:AutoAddListener()
end

function XUiInfestorExploreStageDetailOutPost:OnStart(closeCb)
    self.CloseCb = closeCb
    self.GridList = {}
end

function XUiInfestorExploreStageDetailOutPost:Refresh(chapterId, nodeId)
    self.ChapterId = chapterId
    self.NodeId = nodeId

    self.TxtName.text = EVENT_NAME_STR
    local des = XDataCenter.FubenInfestorExploreManager.GetOutPostNodeStartDes(chapterId, nodeId)
    self.TxtDes.text = stringGsub(des, "\\n", "\n")

    local bg = XDataCenter.FubenInfestorExploreManager.GetNodeStageBg(chapterId, nodeId)
    self.RImgIcon:SetRawImage(bg)

    local isUnReach = XDataCenter.FubenInfestorExploreManager.IsNodeUnReach(chapterId, nodeId)
    local isPassed = XDataCenter.FubenInfestorExploreManager.IsNodePassed(chapterId, nodeId)
    self.BtnFight.gameObject:SetActiveEx(not isUnReach and not isPassed)

    local rewardId = XDataCenter.FubenInfestorExploreManager.GetNodeShowRewardId(chapterId, nodeId)
    if not rewardId or rewardId == 0 then
        self.PanelReward.gameObject:SetActiveEx(false)
    else
        local rewards = XRewardManager.GetRewardListNotCount(rewardId)
        if rewards then
            for i, item in ipairs(rewards) do
                local grid
                if self.GridList[i] then
                    grid = self.GridList[i]
                else
                    local ui = CS.UnityEngine.Object.Instantiate(self.GridItem, self.PanelReward)
                    grid = XUiGridCommon.New(self, ui)
                    self.GridList[i] = grid
                end
                grid:Refresh(item)
                grid.GameObject:SetActive(true)
            end
        end

        local rewardsCount = 0
        if rewards then
            rewardsCount = #rewards
        end

        for j = 1, #self.GridList do
            if j > rewardsCount then
                self.GridList[j].GameObject:SetActive(false)
            end
        end

        self.PanelReward.gameObject:SetActiveEx(true)
    end
end

function XUiInfestorExploreStageDetailOutPost:OnDisable()
    self.CloseCb()
end

function XUiInfestorExploreStageDetailOutPost:AutoAddListener()
    self.BtnCloseMask.CallBack = function() self:Close() end
    self.BtnGuestbook.CallBack = function() self:OnClickBtnGuestbook() end
    self.BtnFight.CallBack = function() self:OnClickBtnFight() end
end

function XUiInfestorExploreStageDetailOutPost:OnClickBtnFight()
    local chapterId = self.ChapterId
    local nodeId = self.NodeId

    if XDataCenter.FubenInfestorExploreManager.IsNodePassed(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreOutPostNodePassed")
        return
    end

    if XDataCenter.FubenInfestorExploreManager.IsNodeUnReach(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreOutPostNodeNotReach")
        return
    end

    if XDataCenter.FubenInfestorExploreManager.IsNodeCurrentFinished(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreOutPostNodeCurrent")
        return
    end

    if not XDataCenter.FubenInfestorExploreManager.CheckActionPoint(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreActionPointNotEnough")
        return
    end

    self:Close()
    XLuaUiManager.Open("UiInfestorExploreOutpost", chapterId, nodeId)
end

function XUiInfestorExploreStageDetailOutPost:OnClickBtnGuestbook()
    XDataCenter.FubenInfestorExploreManager.OpenGuestBook(self.ChapterId)
end