local XUiGridFubenInfestorExploreMember = require("XUi/XUiFubenInfestorExplore/XUiGridFubenInfestorExploreMember")
local XUiGridInfestorExploreOutPostStory = require("XUi/XUiFubenInfestorExplore/XUiGridInfestorExploreOutPostStory")

local stringGsub = string.gsub
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local CSXTextManagerGetText = CS.XTextManager.GetText
local CSXScheduleManagerScheduleForever = XScheduleManager.ScheduleForever
local CSXScheduleManagerUnSchedule = XScheduleManager.UnSchedule

local MAX_OPTION_NUM = 2
local MAX_MEMBER_NUM = 3
local STORY_CD = 1
local EVENT_NAME_STR = CS.XTextManager.GetText("InfestorExploreOutPostNodeName")

local XUiInfestorExploreOutpost = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreOutpost")

function XUiInfestorExploreOutpost:OnAwake()
    self.GridMember.gameObject:SetActiveEx(false)
    self.GridDescribe.gameObject:SetActiveEx(false)
    self:AutoAddListener()
end

function XUiInfestorExploreOutpost:OnStart(chapterId, nodeId)
    self.ChapterId = chapterId
    self.NodeId = nodeId
    self.CharacterIds = XDataCenter.FubenInfestorExploreManager.GetChapterTeamCharacterIds(chapterId)
    self.MemberGrids = {}
    self.StoryGrids = {}

    self:InitView()
end

function XUiInfestorExploreOutpost:OnDestroy()
    self:ClearTimer()

    if XDataCenter.FubenInfestorExploreManager.IsFightRewadsExist() then
        XLuaUiManager.Open("UiInfestorExploreChoose")
    end
end

function XUiInfestorExploreOutpost:OnGetEvents()
    return { XEventId.EVENT_INFESTOREXPLORE_CHARACTER_HP_CHANGE
    , XEventId.EVENT_INFESTOREXPLORE_RESET
    }
end

function XUiInfestorExploreOutpost:OnNotify(evt, ...)
    if evt == XEventId.EVENT_INFESTOREXPLORE_CHARACTER_HP_CHANGE then
        self.DelayChangeHp = true
    elseif evt == XEventId.EVENT_INFESTOREXPLORE_RESET then
        XDataCenter.FubenInfestorExploreManager.Reset()
    end
end

function XUiInfestorExploreOutpost:InitView()
    local defaultSelectPos
    local characterIds = self.CharacterIds
    for pos = 1, MAX_MEMBER_NUM do
        local characterId = characterIds[pos]
        local grid = self.MemberGrids[pos]
        if characterId > 0 then
            if not grid then
                local go = CSUnityEngineObjectInstantiate(self.GridMember, self.PanelRole)
                local clickCb = function()
                    self:OnSelectMember(pos)
                end
                grid = XUiGridFubenInfestorExploreMember.New(go, clickCb)
                self.MemberGrids[pos] = grid
            end
            grid:Refresh(characterId)
            grid.GameObject:SetActiveEx(true)

            defaultSelectPos = defaultSelectPos or pos
        else
            if grid then
                grid.GameObject:SetActiveEx(false)
            end
        end
    end

    self.TxtTile.text = EVENT_NAME_STR
    self.Panel01.gameObject:SetActiveEx(true)
    self.Panel02.gameObject:SetActiveEx(false)
    self.Panel03.gameObject:SetActiveEx(false)

    self:OnSelectMember(defaultSelectPos)
end

function XUiInfestorExploreOutpost:OnSelectMember(pos)
    local grid = self.MemberGrids[pos]
    if self.LastSelectMemberGrid then
        self.LastSelectMemberGrid:SetSelect(false)
    end
    self.LastSelectMemberGrid = grid
    grid:SetSelect(true)

    local characterId = self.CharacterIds[pos]
    self.SelectCharacterId = characterId

    local icon = XDataCenter.CharacterManager.GetCharHalfBodyBigImage(characterId)
    self.RImgRole:SetRawImage(icon)

    local fullName = XMVCA.XCharacter:GetCharacterFullNameStr(characterId)
    self.TxtName.text = fullName

    self:UpdateCharacterHp()
end

function XUiInfestorExploreOutpost:UpdateCharacterHp()
    local characterId = self.SelectCharacterId
    if not characterId then return end
    local hpPercent = XDataCenter.FubenInfestorExploreManager.GetCharacterHpPrecent(characterId)
    self.TxtBlood.text = CSXTextManagerGetText("InfestorExploreCharacterHpPercent", hpPercent)
end

function XUiInfestorExploreOutpost:OnSelectHowToFight(rewardMoney, subHpList)
    self.RewardMoney = rewardMoney
    self.SubHpList = subHpList

    self.Panel01.gameObject:SetActiveEx(false)
    self.Panel02.gameObject:SetActiveEx(true)
    self.Panel03.gameObject:SetActiveEx(false)

    --写换名字逻辑 --now
    local chapterId = self.ChapterId
    local nodeId = self.NodeId
    self.BtnOption1:SetName(XDataCenter.FubenInfestorExploreManager.GetOutPostOption1Txt(chapterId, nodeId))
    self.BtnOption2:SetName(XDataCenter.FubenInfestorExploreManager.GetOutPostOption2Txt(chapterId, nodeId))

    self:PlayAnimationWithMask("Panel02Enable")
end

function XUiInfestorExploreOutpost:OnFightStory()
    local chapterId = self.ChapterId
    local nodeId = self.NodeId

    local characterId = self.SelectCharacterId
    local characterName = XMVCA.XCharacter:GetCharacterFullNameStr(characterId)

    local gridIndex = 1
    local option = self.SelectOption
    local subHpList = self.SubHpList
    local totalSubHp = 0
    local timeStamp = XTime.GetServerNowTimestamp()
    for _, subHp in ipairs(subHpList) do
        local myTurnDes = XDataCenter.FubenInfestorExploreManager.GetOutPostNodeMyTurnDes(chapterId, nodeId, option, characterName)
        local grid = self.StoryGrids[gridIndex]
        if not grid then
            local go = CSUnityEngineObjectInstantiate(self.GridDescribe, self.PanelFightContent)
            grid = XUiGridInfestorExploreOutPostStory.New(go)
            self.StoryGrids[gridIndex] = grid
        end
        timeStamp = timeStamp + STORY_CD
        grid:Refresh(myTurnDes, timeStamp)
        grid.GameObject:SetActiveEx(false)
        gridIndex = gridIndex + 1

        local isHurt = subHp > 0
        local hisTurnDes = XDataCenter.FubenInfestorExploreManager.GetOutPostNodeHisTurnDes(chapterId, nodeId, option, isHurt, characterName, subHp)
        local grid = self.StoryGrids[gridIndex]
        if not grid then
            local go = CSUnityEngineObjectInstantiate(self.GridDescribe, self.PanelFightContent)
            grid = XUiGridInfestorExploreOutPostStory.New(go)
            self.StoryGrids[gridIndex] = grid
        end
        timeStamp = timeStamp + STORY_CD
        grid:Refresh(hisTurnDes, timeStamp)
        grid.GameObject:SetActiveEx(false)
        gridIndex = gridIndex + 1

        totalSubHp = totalSubHp + subHp
    end

    local endDes = XDataCenter.FubenInfestorExploreManager.GetOutPostNodeEndDes(chapterId, nodeId, characterName, totalSubHp)
    local grid = self.StoryGrids[gridIndex]
    if not grid then
        local go = CSUnityEngineObjectInstantiate(self.GridDescribe, self.PanelFightContent)
        grid = XUiGridInfestorExploreOutPostStory.New(go)
        self.StoryGrids[gridIndex] = grid
    end
    timeStamp = timeStamp + STORY_CD
    grid:Refresh(endDes, timeStamp)
    grid.GameObject:SetActiveEx(false)

    self.Panel01.gameObject:SetActiveEx(false)
    self.Panel02.gameObject:SetActiveEx(false)
    self.Panel03.gameObject:SetActiveEx(true)
    self.BtnSkip.gameObject:SetActiveEx(true)

    self:PlayAnimationWithMask("Panel03Enable")
    self:BeginStoryAnim()
end

function XUiInfestorExploreOutpost:BeginStoryAnim()
    self.StageOngoing.gameObject:SetActiveEx(true)
    self.StageCease.gameObject:SetActiveEx(false)
    self.BtnBack.gameObject:SetActiveEx(false)

    local gridIndex = 1
    self:ClearTimer()
    self.TimerId = CSXScheduleManagerScheduleForever(function()
        if XTool.UObjIsNil(self.GameObject) then self:ClearTimer() return end
        local grid = self.StoryGrids[gridIndex]
        if not grid then
            self:OnStoryEnd()
            return
        end
        grid.GameObject:SetActiveEx(true)
        gridIndex = gridIndex + 1
    end, STORY_CD * XScheduleManager.SECOND)
end

function XUiInfestorExploreOutpost:ClearTimer()
    if self.TimerId then
        CSXScheduleManagerUnSchedule(self.TimerId)
        self.TimerId = nil
    end
end

function XUiInfestorExploreOutpost:OnStoryEnd()
    self:ClearTimer()
    self.StageOngoing.gameObject:SetActiveEx(false)
    self.StageCease.gameObject:SetActiveEx(true)
    self.BtnSkip.gameObject:SetActiveEx(false)
    self.BtnBack.gameObject:SetActiveEx(true)

    if XDataCenter.FubenInfestorExploreManager.IsFightRewadsExist() then
        XLuaUiManager.Open("UiInfestorExploreChoose")
    end

    if self.RewardMoney then
        XDataCenter.FubenInfestorExploreManager.OnGetMoneyTip(self.RewardMoney)
        self.RewardMoney = nil
    end

    if self.DelayChangeHp then
        self.DelayChangeHp = nil
        self:UpdateCharacterHp()
    end
end

function XUiInfestorExploreOutpost:AutoAddListener()
    self.BtnBack.CallBack = function() self:OnClickBack() end
    self.BtnSkip.CallBack = function() self:OnClickBtnSkip() end
    self.BtnSend.CallBack = function() self:OnClickBtnSend() end
    for index = 1, MAX_OPTION_NUM do
        self["BtnOption" .. index].CallBack = function() self:OnClickBtnOption(index) end
    end
end

function XUiInfestorExploreOutpost:OnClickBack()
    XDataCenter.FubenInfestorExploreManager.RequestFinishAction()
    self:Close()
end

function XUiInfestorExploreOutpost:OnClickBtnSkip()
    self:OnStoryEnd()
    for _, grid in pairs(self.StoryGrids) do
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiInfestorExploreOutpost:OnClickBtnSend()
    local nodeId = self.NodeId
    local characterId = self.SelectCharacterId
    local function callBack(rewardMoney, subHpList)
        self:OnSelectHowToFight(rewardMoney, subHpList)
    end
    XDataCenter.FubenInfestorExploreManager.RequestOutPostSend(nodeId, characterId, callBack)
end

function XUiInfestorExploreOutpost:OnClickBtnOption(index)
    self.SelectOption = index
    self:OnFightStory()
end