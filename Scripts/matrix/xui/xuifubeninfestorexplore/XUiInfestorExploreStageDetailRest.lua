local XUiGridFubenInfestorExploreMember = require("XUi/XUiFubenInfestorExplore/XUiGridFubenInfestorExploreMember")

local CSXTextManagerGetText = CS.XTextManager.GetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local TipTitle = CSXTextManagerGetText("InfestorExploreRestNodeSucTitle")
local TipContent = CSXTextManagerGetText("InfestorExploreRestNodeSucContent")
local EVENT_NAME_STR = CS.XTextManager.GetText("InfestorExploreRestNodeName")
local EVENT_DES_STR = CS.XTextManager.GetText("InfestorExploreRestNodeDes")
local MAX_MEMBER_NUM = 3

local XUiInfestorExploreStageDetailRest = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreStageDetailRest")

function XUiInfestorExploreStageDetailRest:OnAwake()
    self.GridHead.gameObject:SetActiveEx(false)
    self:AutoAddListener()
end

function XUiInfestorExploreStageDetailRest:OnStart(closeCb)
    self.CloseCb = closeCb
    self.MemberGrids = {}
end

function XUiInfestorExploreStageDetailRest:Refresh(chapterId, nodeId)
    self.ChapterId = chapterId
    self.NodeId = nodeId

    self.TxtName.text = EVENT_NAME_STR
    self.TxtDes.text = EVENT_DES_STR

    local bg = XDataCenter.FubenInfestorExploreManager.GetNodeStageBg(chapterId, nodeId)
    self.RImgIcon:SetRawImage(bg)

    local isUnReach = XDataCenter.FubenInfestorExploreManager.IsNodeUnReach(chapterId, nodeId)
    local isPassed = XDataCenter.FubenInfestorExploreManager.IsNodePassed(chapterId, nodeId)
    local isShowBtn = not isUnReach and not isPassed
    self.BtnConfirm.gameObject:SetActiveEx(isShowBtn)

    self:UpdateView()
end

function XUiInfestorExploreStageDetailRest:OnDisable()
    self.CloseCb()
end

function XUiInfestorExploreStageDetailRest:UpdateView()
    local chapterId = self.ChapterId
    local nodeId = self.NodeId

    local characterIds = XDataCenter.FubenInfestorExploreManager.GetChapterTeamCharacterIds(chapterId)
    local captainPos = XDataCenter.FubenInfestorExploreManager.GetChapterTeamCaptainPos(chapterId)
    local firstFightPos = XDataCenter.FubenInfestorExploreManager.GetChapterTeamFirstFightPos(chapterId)
    for pos = 1, MAX_MEMBER_NUM do
        local characterId = characterIds[pos]
        local isCaptain = pos == captainPos
        local isFirstFight = pos == firstFightPos
        local grid = self.MemberGrids[pos]
        if characterId > 0 then
            if not grid then
                local go = CSUnityEngineObjectInstantiate(self.GridHead, self.PanelThemeHead)
                grid = XUiGridFubenInfestorExploreMember.New(go)
                self.MemberGrids[pos] = grid
            end
            grid:Refresh(characterId, isCaptain, isFirstFight)
            grid.GameObject:SetActiveEx(true)
        else
            if grid then
                grid.GameObject:SetActiveEx(false)
            end
        end
    end
end

function XUiInfestorExploreStageDetailRest:AutoAddListener()
    self.BtnCloseMask.CallBack = function() self:OnClickBtnClose() end
    self.BtnGuestbook.CallBack = function() self:OnClickBtnGuestbook() end
    self.BtnConfirm.CallBack = function() self:OnClickBtnConfirm() end
    self.BtnChange.CallBack = function() self:OnClickBtnChange() end
end

function XUiInfestorExploreStageDetailRest:OnClickBtnClose()
    local chapterId = self.ChapterId
    local nodeId = self.NodeId

    if not XDataCenter.FubenInfestorExploreManager.IsNodeReach(chapterId, nodeId)
    or not XDataCenter.FubenInfestorExploreManager.IsTeamChanged()
    then
        self:Close()
    else
        self:OnClickBtnConfirm()
    end
end

function XUiInfestorExploreStageDetailRest:OnClickBtnConfirm()
    local chapterId = self.ChapterId
    local nodeId = self.NodeId

    if XDataCenter.FubenInfestorExploreManager.IsNodePassed(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreRestNodePassed")
        return
    end

    if XDataCenter.FubenInfestorExploreManager.IsNodeUnReach(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreRestNodeNotReach")
        return
    end

    if XDataCenter.FubenInfestorExploreManager.IsNodeCurrentFinished(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreRestNodeCurrent")
        return
    end

    if not XDataCenter.FubenInfestorExploreManager.CheckActionPoint(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreActionPointNotEnough")
        return
    end

    local callBack = function()
        XDataCenter.FubenInfestorExploreManager.ClearTeamChangedFlag()
        XUiManager.DialogTip(TipTitle, TipContent, XUiManager.DialogType.Normal)
        self:Close()
    end
    XDataCenter.FubenInfestorExploreManager.RequestRest(chapterId, nodeId, callBack)
end

function XUiInfestorExploreStageDetailRest:OnClickBtnChange()
    local chapterId = self.ChapterId
    local nodeId = self.NodeId

    if XDataCenter.FubenInfestorExploreManager.IsNodeCurrentFinished(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreRestNodeCurrent")
        return
    end

    local isUnReach = XDataCenter.FubenInfestorExploreManager.IsNodeUnReach(chapterId, nodeId)
    local isPassed = XDataCenter.FubenInfestorExploreManager.IsNodePassed(chapterId, nodeId)
    local isShowBtn = not isUnReach and not isPassed
    if not isShowBtn then
        XUiManager.TipText("InfestorExploreRestNodeNotReach")
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
        XDataCenter.FubenInfestorExploreManager.SetTeamChangedFlag()
        self:UpdateView()
    end
    local characterLimitType = XFubenInfestorExploreConfigs.GetChapterCharacterLimitType(chapterId)
    local limitBuffId = XFubenInfestorExploreConfigs.GetChapterLimitBuffId(chapterId)
    XLuaUiManager.Open("UiInfestorExploreTeamEdit", characterLimitType, limitBuffId, characterIds, captainPos, saveCallBack, nil, nil, firstFightPos)
end

function XUiInfestorExploreStageDetailRest:OnClickBtnGuestbook()
    XDataCenter.FubenInfestorExploreManager.OpenGuestBook(self.ChapterId)
end