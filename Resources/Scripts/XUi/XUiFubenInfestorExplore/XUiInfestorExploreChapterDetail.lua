local XUiGridFubenInfestorExploreMember = require("XUi/XUiFubenInfestorExplore/XUiGridFubenInfestorExploreMember")

local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local CSXTextManagerGetText = CS.XTextManager.GetText
local TipTitle = CSXTextManagerGetText("InfestorExploreTeamChangeConfirmTitle")
local TipContent = CSXTextManagerGetText("InfestorExploreTeamChangeConfirmContent")
local MAX_MEMBER_NUM = 3

local XUiInfestorExploreChapterDetail = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreChapterDetail")

function XUiInfestorExploreChapterDetail:OnAwake()
    self:AutoAddListener()
    self.GridMember.gameObject:SetActiveEx(false)
end

function XUiInfestorExploreChapterDetail:OnStart()
    self.MemberGrids = {}
end

function XUiInfestorExploreChapterDetail:RefreshView(chapterId)
    self.ChapterId = chapterId

    self.TxtChapter.text = XFubenInfestorExploreConfigs.GetChapterName(chapterId)
    self.TxtActionPoint.text = XDataCenter.FubenInfestorExploreManager.GetActionPoint()

    local chapterId = self.ChapterId
    self.TxtDes.text = XFubenInfestorExploreConfigs.GetChapterDescription(chapterId)

    local characterLimitType = XFubenInfestorExploreConfigs.GetChapterCharacterLimitType(chapterId)
    local limitBuffId = XFubenInfestorExploreConfigs.GetChapterLimitBuffId(chapterId)
    if not XFubenConfigs.IsStageCharacterLimitConfigExist(characterLimitType) then
        self.TxtConditions.gameObject:SetActiveEx(false)
    else
        self.TxtConditions.text = XFubenConfigs.GetChapterCharacterLimitText(characterLimitType, limitBuffId)
        self.TxtConditions.gameObject:SetActiveEx(true)
    end

    self.TxtEffectPosion.text = XDataCenter.FubenInfestorExploreManager.GetBuffDes()

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
                local go = CSUnityEngineObjectInstantiate(self.GridMember, self["PanelGrid" .. pos])
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

function XUiInfestorExploreChapterDetail:AutoAddListener()
    self.BtnBg.CallBack = function() self:Close() end
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.BtnEnter.CallBack = function() self:OnClickBtnEnter() end
    for index = 1, MAX_MEMBER_NUM do
        self["BtnJoin" .. index].CallBack = function() self:OnClickBtnJoin() end
    end
end

function XUiInfestorExploreChapterDetail:OnClickBtnEnter()
    local chapterId = self.ChapterId
    if XDataCenter.FubenInfestorExploreManager.IsChapterTeamEmpty(chapterId) then
        XUiManager.TipText("InfestorExploreTeamEmptyTip")
        return
    end

    if XDataCenter.FubenInfestorExploreManager.IsChapterTeamNoCaptain(chapterId) then
        XUiManager.TipText("TeamManagerCheckCaptainNil")
        return
    end

    local sureCallback = function()
        local callBack = function()
            self:Close()
            XUiManager.TipText("InfestorExploreTeamSaveSuc")
            XLuaUiManager.Open("UiInfestorExploreStage", chapterId)
        end
        XDataCenter.FubenInfestorExploreManager.RequestUpdateTeam(chapterId, callBack)
    end
    XUiManager.DialogTip(TipTitle, TipContent, XUiManager.DialogType.Normal, nil, sureCallback)
end

function XUiInfestorExploreChapterDetail:OnClickBtnJoin()
    local chapterId = self.ChapterId
    local characterIds = XDataCenter.FubenInfestorExploreManager.GetChapterTeamCharacterIds(chapterId)
    local captainPos = XDataCenter.FubenInfestorExploreManager.GetChapterTeamCaptainPos(chapterId)
    local firstFightPos = XDataCenter.FubenInfestorExploreManager.GetChapterTeamFirstFightPos(chapterId)
    local saveCallBack = function(cacheCharacterIds, cacheCaptainPos, cacheFirstFightPos)
        XDataCenter.FubenInfestorExploreManager.SaveChapterTeam(chapterId, cacheCharacterIds, cacheCaptainPos, cacheFirstFightPos)
        self:RefreshView(self.ChapterId)
    end
    local characterLimitType = XFubenInfestorExploreConfigs.GetChapterCharacterLimitType(chapterId)
    local limitBuffId = XFubenInfestorExploreConfigs.GetChapterLimitBuffId(chapterId)
    XLuaUiManager.Open("UiInfestorExploreTeamEdit", characterLimitType, limitBuffId, characterIds, captainPos, saveCallBack, nil, nil, firstFightPos)
end