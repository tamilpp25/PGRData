local stringGsub = string.gsub

local XUiInfestorExploreStageDetailFight = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreStageDetailFight")

function XUiInfestorExploreStageDetailFight:OnAwake()
    self.GridItem.gameObject:SetActiveEx(false)
    self:AutoAddListener()
end

function XUiInfestorExploreStageDetailFight:OnStart(closeCb)
    self.CloseCb = closeCb
    self.GridList = {}
end

function XUiInfestorExploreStageDetailFight:OnDisable()
    self.CloseCb()
end

function XUiInfestorExploreStageDetailFight:Refresh(chapterId, nodeId)
    self.ChapterId = chapterId
    self.NodeId = nodeId

    local fightStageId = XDataCenter.FubenInfestorExploreManager.GetNodeFightStageId(chapterId, nodeId)

    self.TxtName.text = XDataCenter.FubenManager.GetStageName(fightStageId)
    local des = XDataCenter.FubenManager.GetStageDes(fightStageId)
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

function XUiInfestorExploreStageDetailFight:AutoAddListener()
    self.BtnCloseMask.CallBack = function() self:Close() end
    self.BtnGuestbook.CallBack = function() self:OnClickBtnGuestbook() end
    self.BtnFight.CallBack = function() self:OnClickBtnFight() end
end

function XUiInfestorExploreStageDetailFight:OnClickBtnFight()
    local chapterId = self.ChapterId
    local nodeId = self.NodeId

    if XDataCenter.FubenInfestorExploreManager.IsNodePassed(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreFightNodePassed")
        return
    end

    if XDataCenter.FubenInfestorExploreManager.IsNodeUnReach(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreFightNodeNotReach")
        return
    end

    if XDataCenter.FubenInfestorExploreManager.IsNodeCurrentFinished(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreFightNodeCurrent")
        return
    end

    if not XDataCenter.FubenInfestorExploreManager.CheckActionPoint(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreActionPointNotEnough")
        return
    end

    local characterIds = XDataCenter.FubenInfestorExploreManager.GetChapterTeamCharacterIds(chapterId)
    local captainPos = XDataCenter.FubenInfestorExploreManager.GetChapterTeamCaptainPos(chapterId)
    local firstFightPos = XDataCenter.FubenInfestorExploreManager.GetChapterTeamFirstFightPos(chapterId)
    local saveCallBack = function(cacheCharacterIds, cacheCaptainPos, cacheFirstFightPos)
        XDataCenter.FubenInfestorExploreManager.SaveChapterTeam(chapterId, cacheCharacterIds, cacheCaptainPos, cacheFirstFightPos)
    end
    local enterCallBack = function()
        XDataCenter.FubenInfestorExploreManager.RequestEnterFight(chapterId, nodeId)
        self:Close()
    end
    local forbitReplaceCharacter = true
    local characterLimitType = XFubenInfestorExploreConfigs.GetChapterCharacterLimitType(chapterId)
    local limitBuffId = XFubenInfestorExploreConfigs.GetChapterLimitBuffId(chapterId)
    XLuaUiManager.Open("UiInfestorExploreTeamEdit", characterLimitType, limitBuffId, characterIds, captainPos, saveCallBack, enterCallBack, forbitReplaceCharacter, firstFightPos)
end

function XUiInfestorExploreStageDetailFight:OnClickBtnGuestbook()
    XDataCenter.FubenInfestorExploreManager.OpenGuestBook(self.ChapterId)
end