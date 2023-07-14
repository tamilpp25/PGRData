--     -------------------(引用外部模块)begin---------------------
local XInfestorExploreMapNode = require("XEntity/XInfestorExplore/XInfestorExploreMapNode")
local XInfestorExplorePlayer = require("XEntity/XInfestorExplore/XInfestorExplorePlayer")
local XInfestorExploreCharacter = require("XEntity/XInfestorExplore/XInfestorExploreCharacter")
local XInfestorExploreCore = require("XEntity/XInfestorExplore/XInfestorExploreCore")
local XInfestorExploreTeam = require("XEntity/XInfestorExplore/XInfestorExploreTeam")
--     -------------------(引用外部模块)end---------------------
--     -------------------(lua api c#函数 api)begin------------------
local pairs = pairs
local tableInsert = table.insert
local tableRemove = table.remove
local tableSort = table.sort
local CSXTextManagerGetText = CS.XTextManager.GetText
--     -------------------(lua api c#函数 api)end------------------
local REQUEST_SYNC_INFO_CD = CS.XGame.Config:GetInt("InfestorSyncPlayerInfoInterval")
local REQUEST_LEAVE_CHAPTER_MSG_CD = CS.XGame.Config:GetInt("InfestorChapterLeaveMsgInterval")
local REQUEST_GET_LEAVE_CHAPTER_MSG_CD = CS.XGame.Config:GetInt("InfestorChapterLeaveMsgInterval")
local MAX_CHAPTER_MESSAGE_COUNT = CS.XGame.Config:GetInt("InfestorChapterLeaveMsgMaxCount")
local SectionType = {
    Init = 0, --初始化
    RESET = 1, --结算期
    StageExplore = 2, --关卡探索
    BossFight = 3, --boss战
}



--     -------------------(数据)begin------------------
XFubenInfestorExploreManagerCreator = function()
    local SectionStatus = SectionType.Init --当前处于的阶段
    local CurChapterId = 0 --当前的章节
    local CurNodeId = 0 --当前的节点
    local DelayMoveNodeId
    local LastFinishNodeId = 0
    local CurGroupId = 0
    local CurDiff = 0
    local LastSyncInfoTime = 0
    local LastLeaveChapterMsgTime = 0
    local LastGetLeaveChapterMsgTime = 0
    local Maps = {} --存储五个地图的配置
    local PlayerDataDic = {}
    local PlayerRankDataList = {}
    local CharacterDataDic = {}
    local BuffIds = {}
    local CoreDic = {}
    local CoreIdList = {}
    local CoreUseIdDic = {}
    local ChapterIdToShopDic = {}
    local SelectRewardInfoDic = {}
    local ContractEventIdDic = {}
    local FightRewardBuyDic = {}
    local ChapterMsgDic = {}
    local FightEventId = 0
    local ActivityId = 0
    local Chapter2ScoreDic = {}
    local ActivityNo = 0
    local OldActivityNo = 0
    local LastDiff = 0
    local AfterFightNeedShowReward
    local NewChapterNeedShowAnim
    local Team = {
        [XFubenConfigs.CharacterLimitType.All] = XInfestorExploreTeam.New(XFubenConfigs.CharacterLimitType.All),
        [XFubenConfigs.CharacterLimitType.Normal] = XInfestorExploreTeam.New(XFubenConfigs.CharacterLimitType.Normal),
        [XFubenConfigs.CharacterLimitType.Isomer] = XInfestorExploreTeam.New(XFubenConfigs.CharacterLimitType.Isomer),
        [XFubenConfigs.CharacterLimitType.IsomerDebuff] = XInfestorExploreTeam.New(XFubenConfigs.CharacterLimitType.IsomerDebuff),
        [XFubenConfigs.CharacterLimitType.NormalDebuff] = XInfestorExploreTeam.New(XFubenConfigs.CharacterLimitType.NormalDebuff),
    }
    local TeamChanged = nil

    local OldMoneyCount = 0
    local NewMoneyCount = 0

    local OpenInfestorExploreCoreDelay = 0
    local OpenInfestorExploreCoreScheduleId = nil
    local OpenInfestorExploreCoreCbTemp = nil
    --     -------------------(数据)end------------------
    --     -------------------(本地接口)begin------------------
    local function GetCookieKey()
        return XPlayer.Id .. "NEW_DIFF"
    end

    local function GetMap(chapterId)
        local map = Maps[chapterId]
        if not map then
            XLog.Error("XFubenInfestorExploreManager GetMap Error: 获取地图失败，章节不存在地图配置，chapterId: " .. chapterId)
            return
        end
        return map
    end

    local function GetStageNode(chapterId, nodeId)
        local map = GetMap(chapterId)
        local stageNode = map and map[nodeId]
        if not stageNode then
            XLog.Error("XFubenInfestorExploreManager GetStageNode Error: 获取地图节点失败，章节不存在地图配置，chapterId: " .. chapterId .. ", nodeId: " .. nodeId .. ", map: ", map)
            return
        end
        return stageNode
    end

    local function GetNodeOutPostStory(chapterId, nodeId)
        local node = GetStageNode(chapterId, nodeId)
        return node:GetOutPostStory()
    end

    local function GetCharacterData(characterId)
        local characterData = CharacterDataDic[characterId]
        if not characterData then
            characterData = XInfestorExploreCharacter.New()
            CharacterDataDic[characterId] = characterData
        end
        return characterData
    end

    local function GetTeam(teamType)
        return Team[teamType]
    end

    local function GetChapterTeam(chapterId)
        local teamType = XFubenInfestorExploreConfigs.GetChapterCharacterLimitType(chapterId)
        return GetTeam(teamType)
    end

    local function GetCore(coreId)
        return CoreDic[coreId]
    end

    local function AddCore(coreData)
        local core = XInfestorExploreCore.New()
        core:UpdateData(coreData)

        local coreId = core:GetId()
        CoreDic[coreId] = core
        tableInsert(CoreIdList, coreId)
    end

    local function DeleteCore(coreId)
        CoreDic[coreId] = nil

        for index, paramCoreId in pairs(CoreIdList) do
            if coreId == paramCoreId then
                tableRemove(CoreIdList, index)
                break
            end
        end

        for pos, paramCoreId in pairs(CoreUseIdDic) do
            if coreId == paramCoreId then
                CoreUseIdDic[pos] = 0
                break
            end
        end
    end

    local function IsHaveCore(coreId)
        if not coreId then return false end
        local core = GetCore(coreId)
        return core and true or false
    end

    local function TakeOffCore(pos)
        local coreId = CoreUseIdDic[pos]
        if coreId and coreId > 0 then
            local core = GetCore(coreId)
            if core then
                core:TakeOff()
            end
            CoreUseIdDic[pos] = 0
        end
    end

    local function PutOnCore(coreId, pos)
        --在装备一个Buff之前先把对应位置上的buff TakeOff
        TakeOffCore(pos)

        local core = GetCore(coreId)
        core:PutOn(pos)
        CoreUseIdDic[pos] = coreId
    end

    local function AddBuff(buffId)
        for _, existBuffId in pairs(BuffIds) do
            if existBuffId == buffId then
                return
            end
        end
        tableInsert(BuffIds, buffId)
    end

    local function RemoveBuff(buffId)
        if not buffId or buffId == 0 then return end
        for index, existBuffId in pairs(BuffIds) do
            if existBuffId == buffId then
                tableRemove(BuffIds, index)
                return
            end
        end
    end

    local function CheckBuffExsit(buffId)
        if not buffId or buffId == 0 then return false end
        for index, existBuffId in pairs(BuffIds) do
            if existBuffId == buffId then
                return true
            end
        end
        return false
    end

    local function GetShop()
        return ChapterIdToShopDic[CurChapterId]
    end

    local function GetSelectRewardInfo(chapterId, nodeId)
        return SelectRewardInfoDic[chapterId] and SelectRewardInfoDic[chapterId][nodeId]
    end

    local function GetPlayerData(playerId)
        return PlayerDataDic[playerId]
    end

    local function GetSelectRewardPlayerData(chapterId, nodeId)
        local selectRewardInfo = GetSelectRewardInfo(chapterId, nodeId)
        if not selectRewardInfo then
            return
        end

        local playerId = selectRewardInfo.PlayerId
        if not playerId then
            return
        end

        return GetPlayerData(playerId)
    end

    local function OnGetMapStartNodeId(chapterId)
        local map = GetMap(chapterId)
        for _, node in pairs(map) do
            if node:IsStart() then
                return node:GetNodeId()
            end
        end
    end

    local function InitMaps()
        local chapterConfigs = XFubenInfestorExploreConfigs.GetChapterConfigs()
        for chapterId in pairs(chapterConfigs) do
            local tree = {}

            local mapConfig = XFubenInfestorExploreConfigs.GetMapConfig(chapterId)
            for nodeId, nodeConfig in pairs(mapConfig) do
                local node = tree[nodeId]
                if not node then
                    node = XInfestorExploreMapNode.New(nodeId)
                    tree[nodeId] = node
                end

                local parentIds = nodeConfig.FrontId
                for _, parentId in pairs(parentIds) do
                    if parentId ~= 0 then
                        node:SetParentId(parentId)

                        local parentNode = tree[parentId]
                        if not parentNode then
                            parentNode = XInfestorExploreMapNode.New(parentId)
                            tree[parentId] = parentNode
                        end

                        parentNode:SetChildId(nodeId)
                    end
                end
            end

            Maps[chapterId] = tree

        end
    end

    local function UpdateFinishedNodesStatus(finishedGridDic)
        if finishedGridDic then
            for chapterId, finishedNodeIds in pairs(finishedGridDic) do
                if next(finishedNodeIds) then
                    for _, nodeId in pairs(finishedNodeIds) do
                        local node = GetStageNode(chapterId, nodeId)
                        node:SetStatusPassed()

                        --已走过的路径驱散子节点迷雾
                        local childIds = node:GetChildIds()
                        for childId in pairs(childIds) do
                            local childNode = GetStageNode(chapterId, childId)
                            childNode:SetStatusUnReach()
                        end
                    end
                end
            end
        end

        local chapterId = CurChapterId
        local currentNode = GetStageNode(chapterId, CurNodeId)
        currentNode:SetStatusCurrent()

        --最后一章判最后一关通关
        local nextChapterId = XFubenInfestorExploreConfigs.GetNextChapterId(chapterId)
        if nextChapterId == 0 then
            if currentNode:IsEnd() then
                currentNode:SetStatusPassed()
            end
        end

        local childIds = currentNode:GetChildIds()
        for childId in pairs(childIds) do
            local childNode = GetStageNode(chapterId, childId)
            childNode:SetStatusReach()
        end
    end

    local function OnGetMoneyTip(moneyCount, closeCallback)
        if not moneyCount or moneyCount <= 0 then return end
        local rewardGoodsList = {}
        tableInsert(rewardGoodsList, XRewardManager.CreateRewardGoods(XDataCenter.ItemManager.ItemId.InfestorMoney, moneyCount))
        XUiManager.OpenUiObtain(rewardGoodsList, nil, closeCallback)
    end

    local function OnGetNewCore(coreId, coreLevel, finishCb)
        local core = GetCore(coreId)
        local finishCbTemp = finishCb
        if not core then
            local coreData = { Id = coreId, Level = coreLevel }
            AddCore(coreData)
            XDataCenter.FubenInfestorExploreManager.OpenGetNewCoreUi(function()
                XLuaUiManager.Open("UiInfestorExploreCoreObtain", coreId, coreLevel, finishCbTemp)
            end)
        else
            if core:IsMaxLevel() then
                local title = CSXTextManagerGetText("InfestorExploreCoreAutoDecomposeTitle")
                local coreName = core:GetName()
                local decomposeMoney = XFubenInfestorExploreConfigs.GetCoreDecomposeMoney(coreId, coreLevel)
                local content = CSXTextManagerGetText("InfestorExploreCoreAutoDecomposeContent", coreName, decomposeMoney)
                local sureCallBack = function()
                    OnGetMoneyTip(decomposeMoney, finishCbTemp)
                end
                local closeCallback = sureCallBack
                XDataCenter.FubenInfestorExploreManager.OpenGetNewCoreUi(function()
                    XUiManager.DialogTip(title, content, XUiManager.DialogType.OnlySure, closeCallback, sureCallBack)
                end)
            else
                local oldLevel = core:GetLevel()
                local maxLevel = core:GetMaxLevel()
                local newLevel = coreLevel + oldLevel
                local coreIdTemp = coreId
                newLevel = newLevel > maxLevel and maxLevel or newLevel
                core:SetLevel(newLevel)
                XDataCenter.FubenInfestorExploreManager.OpenGetNewCoreUi(function()
                    XLuaUiManager.Open("UiInfestorExploreCoreLevelUp", coreIdTemp, oldLevel, newLevel, finishCbTemp)
                end)
            end
        end
        XDataCenter.FubenInfestorExploreManager.AutoWearingOnceCore(coreId)
    end

    local function OnNewEventTips(eventType, eventArgs)
        if eventType == XFubenInfestorExploreConfigs.EventType.AddCore then
            if not eventArgs then return end
            local coreId = eventArgs[1]
            local coreLevel = eventArgs[2]
            OnGetNewCore(coreId, coreLevel)
        else
            if eventType == XFubenInfestorExploreConfigs.EventType.AddBuff then
                if not eventArgs then return end
                local buffId = eventArgs[1]
                AddBuff(buffId)
            elseif eventType == XFubenInfestorExploreConfigs.EventType.RemoveBuff then
                local buffIds = eventArgs
                if buffIds then
                    for _, buffId in pairs(buffIds) do
                        RemoveBuff(buffId)
                    end
                end
            elseif eventType == XFubenInfestorExploreConfigs.EventType.LostCore then
                local coreId = eventArgs and eventArgs[1]
                if IsHaveCore(coreId) then
                    DeleteCore(coreId)
                end
            elseif eventType == XFubenInfestorExploreConfigs.EventType.LevelUpCore then
                local coreId = eventArgs and eventArgs[1]
                local core = GetCore(coreId)
                if core then
                    OnGetNewCore(coreId, 1)
                end
            end
        end
    end

    local function GetEventTipsContent(eventType, eventArgs)
        return XFubenInfestorExploreConfigs.GetEventTypeTipContent(eventType, eventArgs)
    end

    local function OnNotAddCoreEventTips(content)
        if content and "" ~= content then
            local title = CSXTextManagerGetText("InfestorExploreEventTypeTipTitle")
            XUiManager.DialogTip(title, content, XUiManager.DialogType.OnlySure)
        end
    end

    local function MoveToNextChapter()
        local curNode = GetStageNode(CurChapterId, CurNodeId)
        if not curNode:IsEnd() then return end
        curNode:SetStatusPassed()

        local nextChapterId = XFubenInfestorExploreConfigs.GetNextChapterId(CurChapterId)
        if nextChapterId > 0 then
            CurChapterId = nextChapterId
            CurNodeId = OnGetMapStartNodeId(CurChapterId)
        end

        UpdateFinishedNodesStatus()

        NewChapterNeedShowAnim = true

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_INFESTOREXPLORE_CHAPTER_FINISH)
    end

    local function MoveToNextNode(oldNodeId, newNodeId)
        local chapterId = CurChapterId
        local playerId = XPlayer.Id

        local oldNode = GetStageNode(chapterId, CurNodeId)
        oldNode:SetStatusPassed()
        oldNode:ClearOccupiedPlayerId(playerId)

        local childIds = oldNode:GetChildIds()
        for childId in pairs(childIds) do
            local childNode = GetStageNode(chapterId, childId)
            childNode:SetStatusUnReach()
        end

        local newNode = GetStageNode(chapterId, newNodeId)
        newNode:SetStatusCurrent()
        newNode:SetOccupiedPlayerId(playerId)

        local childIds = newNode:GetChildIds()
        for childId in pairs(childIds) do
            local childNode = GetStageNode(chapterId, childId)
            childNode:SetStatusReach()
        end

        CurNodeId = newNodeId

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_INFESTOREXPLORE_MOVE_TO_NEXT_NODE)

        MoveToNextChapter()
    end

    local function SetLastFinishNodeId(nodeId)
        if not nodeId then return end
        LastFinishNodeId = nodeId
    end

    local function InsertChapterMessage(chapterId, playerMsgInfo)
        local msgs = ChapterMsgDic[chapterId] or {}
        ChapterMsgDic[chapterId] = msgs


        local playerId = playerMsgInfo.Id
        local player = GetPlayerData(playerId)
        if not player then
            player = XInfestorExplorePlayer.New()
            PlayerDataDic[playerId] = player
        end
        player:UpdateData(playerMsgInfo)

        tableInsert(msgs, 1, playerMsgInfo)

        local msgNum = #msgs
        if msgNum > MAX_CHAPTER_MESSAGE_COUNT then
            tableRemove(msgs, msgNum)
        end
    end
    --     -------------------(本地接口)end------------------
    --     -------------------(对外开放接口)begin------------------
    local XFubenInfestorExploreManager = {}

    function XFubenInfestorExploreManager.GetCurSectionName()
        return XFubenInfestorExploreConfigs.GetSectionName(SectionStatus)
    end

    function XFubenInfestorExploreManager.Reset()
        XLuaUiManager.RunMain()
        XUiManager.TipText("InfestorExploreReset")
    end

    function XFubenInfestorExploreManager.IsOpen()
        return SectionStatus ~= SectionType.Init
    end

    function XFubenInfestorExploreManager.IsInSectionOne()
        return SectionStatus == SectionType.StageExplore
    end

    function XFubenInfestorExploreManager.IsInSectionTwo()
        return SectionStatus == SectionType.BossFight
    end

    function XFubenInfestorExploreManager.IsInSectionEnd()
        return SectionStatus == SectionType.RESET
    end

    function XFubenInfestorExploreManager.GetCurDiff()
        return CurDiff
    end

    function XFubenInfestorExploreManager.CheckNewDiff()

        if OldActivityNo and OldActivityNo == ActivityNo then
            return
        end

        --每期段位弹出一次并记录Cookie
        XLuaUiManager.Open("UiInfestorExploreActivityResult", LastDiff, CurDiff)
        OldActivityNo = ActivityNo
        XSaveTool.SaveData(GetCookieKey(), ActivityNo)
    end

    function XFubenInfestorExploreManager.GetDiffIcon(diff)
        diff = diff or CurDiff
        return XFubenInfestorExploreConfigs.GetDiffIcon(CurGroupId, diff)
    end

    function XFubenInfestorExploreManager.GetDiffName(diff)
        diff = diff or CurDiff
        return XFubenInfestorExploreConfigs.GetDiffName(CurGroupId, diff)
    end

    function XFubenInfestorExploreManager.GetDiffUpNum()
        return XFubenInfestorExploreConfigs.GetDiffUpNum(CurGroupId, CurDiff)
    end

    function XFubenInfestorExploreManager.GetDiffKeepNum()
        return XFubenInfestorExploreConfigs.GetDiffKeepNum(CurGroupId, CurDiff)
    end

    function XFubenInfestorExploreManager.GetDiffDownNum()
        return XFubenInfestorExploreConfigs.GetDiffDownNum(CurGroupId, CurDiff)
    end

    function XFubenInfestorExploreManager.GetDiffShowScoreGap()
        return XFubenInfestorExploreConfigs.GetDiffShowScoreGap(CurGroupId, CurDiff)
    end

    function XFubenInfestorExploreManager.GetDiffShowScoreLimit()
        return XFubenInfestorExploreConfigs.GetDiffShowScoreLimit(CurGroupId, CurDiff)
    end

    function XFubenInfestorExploreManager.IsChapterPassed(chapterId)
        local nextChapterId = XFubenInfestorExploreConfigs.GetNextChapterId(chapterId)
        if nextChapterId == 0 then
            --最后一章判最后一关通关
            local nodeId = CurNodeId
            return XFubenInfestorExploreManager.IsNodeEnd(chapterId, nodeId) and XFubenInfestorExploreManager.IsNodePassed(chapterId, nodeId)
        end
        return CurChapterId > chapterId
    end

    function XFubenInfestorExploreManager.IsChapterUnlock(chapterId)
        local preChapterId = XFubenInfestorExploreConfigs.GetPreChapterId(chapterId)
        return not preChapterId or preChapterId == 0 or XFubenInfestorExploreManager.IsChapterPassed(preChapterId)
    end

    function XFubenInfestorExploreManager.IsChapterRequireIsomer(chapterId)
        local characterLimitType = XFubenInfestorExploreConfigs.GetChapterCharacterLimitType(chapterId)
        local characterType = XDataCenter.FubenManager.GetDefaultCharacterTypeByCharacterLimitType(characterLimitType)
        return characterType == XCharacterConfigs.CharacterType.Isomer
    end

    function XFubenInfestorExploreManager.GetBuffDes()
        local buffId
        if XFubenInfestorExploreManager.IsInSectionOne() then
            buffId = XFubenInfestorExploreConfigs.GetBuffId(FightEventId)
        elseif XFubenInfestorExploreManager.IsInSectionTwo() then
            buffId = XFubenInfestorExploreConfigs.GetBuffIdTwo(FightEventId)
        end
        local fightEventCfg = buffId and buffId ~= 0 and CS.XNpcManager.GetFightEventTemplate(buffId)
        return fightEventCfg and fightEventCfg.Description or ""
    end

    function XFubenInfestorExploreManager.GetActionPoint()
        local itemId = XDataCenter.ItemManager.ItemId.InfestorActionPoint
        return XDataCenter.ItemManager.GetCount(itemId)
    end

    function XFubenInfestorExploreManager.CheckActionPointEnough(count)
        local haveCount = XFubenInfestorExploreManager.GetActionPoint()
        return haveCount >= count
    end

    function XFubenInfestorExploreManager.IsActionPointEmpty()
        local haveCount = XFubenInfestorExploreManager.GetActionPoint()
        return haveCount <= 0
    end

    function XFubenInfestorExploreManager.GetCurGroupLevelBorder()
        return XFubenInfestorExploreConfigs.GetGroupLevelBorder(CurGroupId)
    end

    function XFubenInfestorExploreManager.GetCurGroupDiffConfigs()
        return XFubenInfestorExploreConfigs.GetGroupDiffConfigs(CurGroupId)
    end

    function XFubenInfestorExploreManager.GetCurGroupRankRegionDescText(diff, region)
        return XFubenInfestorExploreConfigs.GetRankRegionDescText(CurGroupId, diff, region)
    end

    function XFubenInfestorExploreManager.GetCurGroupRankRegionRewardList(diff, region)
        diff = diff or CurDiff
        local mailId = XFubenInfestorExploreConfigs.GetRankRegionMailId(CurGroupId, diff, region)
        if not mailId or mailId == 0 then
            return {}
        end
        return XDataCenter.MailManager.GetRewardList(mailId)
    end

    function XFubenInfestorExploreManager.GetPlayerRankIndexList() --返回序号
        local indexList = {}
        for index in pairs(PlayerRankDataList) do
            indexList[index] = index
        end
        return indexList
    end

    function XFubenInfestorExploreManager.GetPlayerRankData(rankIndex) --通过上面返回的序号，拿到对应的来拿取数据
        return PlayerRankDataList[rankIndex]
    end

    function XFubenInfestorExploreManager.GetRankPlayerId(rankIndex)
        local rankPlayerData = XFubenInfestorExploreManager.GetPlayerRankData(rankIndex)
        return rankPlayerData and rankPlayerData:GetPlayerId()
    end

    function XFubenInfestorExploreManager.IsChapterTeamEmpty(chapterId)
        local team = GetChapterTeam(chapterId)
        return team:IsEmpty()
    end

    function XFubenInfestorExploreManager.IsChapterTeamNoCaptain(chapterId)
        local team = GetChapterTeam(chapterId)
        return not team:IsCaptainExist()
    end

    function XFubenInfestorExploreManager.IsChapterTeamExist(chapterId)
        -- local team = GetChapterTeam(chapterId)
        -- return not team:IsEmpty() and team:IsSyned()
        -- 起点类型任意编队
        return not XFubenInfestorExploreManager.IsNodeStart(chapterId, CurNodeId)
    end

    function XFubenInfestorExploreManager.GetChapterTeamCharacterIds(chapterId)
        local team = GetChapterTeam(chapterId)
        return team:GetCharacterIds()
    end

    function XFubenInfestorExploreManager.GetChapterTeamCaptainPos(chapterId)
        local team = GetChapterTeam(chapterId)
        return team:GetCaptainPos()
    end

    function XFubenInfestorExploreManager.GetChapterTeamFirstFightPos(chapterId)
        local team = GetChapterTeam(chapterId)
        return team:GetFirstFightPos()
    end

    function XFubenInfestorExploreManager.SaveChapterTeam(chapterId, characterIds, captainPos, firstFightPos)
        local team = GetChapterTeam(chapterId)

        local oldCharacterIds = team:GetCharacterIds()
        for _, characterId in pairs(oldCharacterIds) do
            if characterId > 0 then
                local characterData = GetCharacterData(characterId)
                characterData:ClearTeamInfo()
            end
        end

        team:SetCharacterIds(characterIds)
        team:SetCaptainPos(captainPos)
        team:SetFirstFightPos(firstFightPos)

        local newCharacterIds = team:GetCharacterIds()
        for teamPos, characterId in pairs(newCharacterIds) do
            if characterId > 0 then
                local characterData = GetCharacterData(characterId)
                local isCaptain = captainPos == teamPos
                local firstFight = firstFightPos == teamPos
                characterData:SetTeamInfo(teamPos, isCaptain, firstFight)
            end
        end
    end

    function XFubenInfestorExploreManager:SetTeamChangedFlag()
        TeamChanged = true
    end

    function XFubenInfestorExploreManager:IsTeamChanged()
        return TeamChanged
    end

    function XFubenInfestorExploreManager:ClearTeamChangedFlag()
        TeamChanged = nil
    end

    function XFubenInfestorExploreManager.GetCharacterHpPrecent(characterId)
        local characterData = GetCharacterData(characterId)
        return characterData:GetHpPercent()
    end

    function XFubenInfestorExploreManager.RefreshCacheMoneyCount(newMoneyCount, oldMoneyCount)
        OldMoneyCount = oldMoneyCount or NewMoneyCount
        NewMoneyCount = newMoneyCount
    end

    function XFubenInfestorExploreManager.GetOldMoneyCount()
        return OldMoneyCount
    end

    function XFubenInfestorExploreManager.GetMoneyIcon()
        return XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.InfestorMoney)
    end

    function XFubenInfestorExploreManager.GetMoneyCount()
        return XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.InfestorMoney)
    end

    function XFubenInfestorExploreManager.GetMoneyName()
        return XDataCenter.ItemManager.GetItemName(XDataCenter.ItemManager.ItemId.InfestorMoney)
    end

    function XFubenInfestorExploreManager.CheckMoneyEnough(count)
        local haveCount = XFubenInfestorExploreManager.GetMoneyCount()
        return haveCount >= count
    end

    function XFubenInfestorExploreManager.IsMoneyEmpty()
        local haveCount = XFubenInfestorExploreManager.GetMoneyCount()
        return haveCount <= 0
    end

    function XFubenInfestorExploreManager.GetMapNodeIds(chapterId)
        return GetMap(chapterId)
    end

    function XFubenInfestorExploreManager.GetNodePrefabPath(chapterId, nodeId)
        local node = GetStageNode(chapterId, nodeId)
        return node:GetPrefabPath()
    end

    function XFubenInfestorExploreManager.GetNodeStageBg(chapterId, nodeId)
        local node = GetStageNode(chapterId, nodeId)
        return node:GetStageBg()
    end

    function XFubenInfestorExploreManager.GetNodeTypeIcon(chapterId, nodeId)
        local node = GetStageNode(chapterId, nodeId)
        return node:GetTypeIcon()
    end

    function XFubenInfestorExploreManager.GetNodeTypeDetailUiName(chapterId, nodeId)
        local node = GetStageNode(chapterId, nodeId)
        return node:GetNodeTypeUiName()
    end

    function XFubenInfestorExploreManager.GetNodeEventPoolId(chapterId, nodeId)
        local node = GetStageNode(chapterId, nodeId)
        return node:GetEventPoolId()
    end

    function XFubenInfestorExploreManager.GetNodeFightStageId(chapterId, nodeId)
        local node = GetStageNode(chapterId, nodeId)
        return node:GetFightStageId()
    end

    function XFubenInfestorExploreManager.GetNodeShowRewardId(chapterId, nodeId)
        local node = GetStageNode(chapterId, nodeId)
        return node:GetShowRewardId()
    end

    function XFubenInfestorExploreManager.GetSupplyNodeDesList(chapterId, nodeId)
        local node = GetStageNode(chapterId, nodeId)
        return node:GetSupplyDesList()
    end

    function XFubenInfestorExploreManager.IsNodeCurrentShop(chapterId, nodeId)
        local node = GetStageNode(chapterId, nodeId)
        return node:IsShop() and node:IsCurrent()
    end

    function XFubenInfestorExploreManager.IsNodeSelectEvent(chapterId, nodeId)
        local node = GetStageNode(chapterId, nodeId)
        return node:IsSelectEvent()
    end

    function XFubenInfestorExploreManager.IsNodeAutoEvent(chapterId, nodeId)
        local node = GetStageNode(chapterId, nodeId)
        return node:IsAutoEvent()
    end

    function XFubenInfestorExploreManager.IsNodeCurrent(chapterId, nodeId)
        local node = GetStageNode(chapterId, nodeId)
        return node:IsCurrent()
    end

    function XFubenInfestorExploreManager.IsNodeFinished(nodeId)
        return LastFinishNodeId == nodeId
    end

    function XFubenInfestorExploreManager.IsNodeCurrentFinished(chapterId, nodeId)
        return XFubenInfestorExploreManager.IsNodeCurrent(chapterId, nodeId) and XFubenInfestorExploreManager.IsNodeFinished(nodeId)
    end

    function XFubenInfestorExploreManager.IsNodeReach(chapterId, nodeId)
        local node = GetStageNode(chapterId, nodeId)
        return node:IsReach()
    end

    function XFubenInfestorExploreManager.IsNodeUnReach(chapterId, nodeId)
        local node = GetStageNode(chapterId, nodeId)
        return node:IsUnReach()
    end

    function XFubenInfestorExploreManager.IsNodePassed(chapterId, nodeId)
        local node = GetStageNode(chapterId, nodeId)
        return node:IsPassed()
    end

    function XFubenInfestorExploreManager.IsNodeFog(chapterId, nodeId)
        local node = GetStageNode(chapterId, nodeId)
        return node:IsFog()
    end

    function XFubenInfestorExploreManager.IsNodeCurrent(chapterId, nodeId)
        local node = GetStageNode(chapterId, nodeId)
        return node:IsCurrent()
    end

    function XFubenInfestorExploreManager.IsNodeStart(chapterId, nodeId)
        local node = GetStageNode(chapterId, nodeId)
        return node:IsStart()
    end

    function XFubenInfestorExploreManager.IsNodeEnd(chapterId, nodeId)
        local node = GetStageNode(chapterId, nodeId)
        return node:IsEnd()
    end

    --如果同一个节点有多个玩家，只显示一个（优先显示自己）
    function XFubenInfestorExploreManager.GetNodeShowOccupiedPlayerId(chapterId, nodeId)
        local showPlayerId = 0

        local node = GetStageNode(chapterId, nodeId)
        local playerIds = node:GetOccupiedPlayerIds()
        for _, playerId in pairs(playerIds) do
            showPlayerId = playerId
            if playerId == XPlayer.Id then
                break
            end
        end

        return showPlayerId
    end

    function XFubenInfestorExploreManager.CheckActionPoint(chapterId, nodeId)
        local node = GetStageNode(chapterId, nodeId)
        local useActionPoint = node:GetUseActionPoint()
        return XFubenInfestorExploreManager.CheckActionPointEnough(useActionPoint)
    end

    function XFubenInfestorExploreManager.GetBuffIds()
        return BuffIds
    end

    local Default_Core_Sort = function(aId, bId)
        local aQuality = XFubenInfestorExploreConfigs.GetCoreQuality(aId)
        local bQuality = XFubenInfestorExploreConfigs.GetCoreQuality(bId)
        if aQuality ~= bQuality then
            return aQuality > bQuality
        end

        local aLevel = XFubenInfestorExploreManager.GetCoreLevel(aId)
        local bLevel = XFubenInfestorExploreManager.GetCoreLevel(bId)
        if aLevel ~= bLevel then
            return aLevel > bLevel
        end
    end

    function XFubenInfestorExploreManager.GetCoreIds()
        local coreIds = {}

        for _, coreId in pairs(CoreIdList) do
            if not XFubenInfestorExploreManager.IsCoreWearing(coreId) then
                tableInsert(coreIds, coreId)
            end
        end
        tableSort(coreIds, Default_Core_Sort)

        return coreIds
    end

    function XFubenInfestorExploreManager.IsHaveOnceCore()
        return next(CoreIdList) and true or false
    end

    function XFubenInfestorExploreManager.GetWearingCoreIdDic()
        return XTool.Clone(CoreUseIdDic)
    end

    function XFubenInfestorExploreManager.GetWearingCoreId(pos)
        return CoreUseIdDic[pos] or 0
    end

    function XFubenInfestorExploreManager.GetOnceNotWearingPos()
        for pos = 1, XFubenInfestorExploreConfigs.MaxWearingCoreNum do
            if XFubenInfestorExploreManager.GetWearingCoreId(pos) == 0 then
                return pos
            end
        end
        return 0
    end

    function XFubenInfestorExploreManager.AutoWearingOnceCore(coreId)
        if XFubenInfestorExploreManager.IsCoreWearing(coreId) then return end

        local pos = XFubenInfestorExploreManager.GetOnceNotWearingPos()
        if pos > 0 then
            XDataCenter.FubenInfestorExploreManager.RequestInfestorExplorePutOnCore(coreId, pos)
        end
    end

    function XFubenInfestorExploreManager.IsCoreWearing(coreId)
        local core = GetCore(coreId)
        return core:IsWearing()
    end

    function XFubenInfestorExploreManager.GetCoreLevel(coreId)
        local core = GetCore(coreId)
        return core:GetLevel()
    end

    function XFubenInfestorExploreManager.GetCoreDecomposeMoney(coreIds)
        local totalMoney = 0

        for _, coreId in pairs(coreIds) do
            local core = GetCore(coreId)
            totalMoney = totalMoney + core:GetDecomposeMoney()
        end

        return totalMoney
    end

    function XFubenInfestorExploreManager.GetRandomSupplyRewardDesList(num)
        local desList = {}

        num = num or 0
        local retNum = 0
        local retCheckDic = {}
        local totalDesNum = XFubenInfestorExploreConfigs.GetSupplyRewardDesTotalNum()
        math.randomseed(os.time())

        while true do
            if retNum >= num then
                break
            end

            local ret = math.random(totalDesNum)
            if not retCheckDic[ret] then
                retCheckDic[ret] = ret
                retNum = retNum + 1
                tableInsert(desList, XFubenInfestorExploreConfigs.GetSupplyRewardDes(ret))
            end
        end

        return desList
    end

    function XFubenInfestorExploreManager.GetOutPostNodeStartDes(chapterId, nodeId)
        local outPostStory = GetNodeOutPostStory(chapterId, nodeId)
        return outPostStory:GetStartDes()
    end

    function XFubenInfestorExploreManager.GetOutPostOption1Txt(chapterId, nodeId)
        local outPostStory = GetNodeOutPostStory(chapterId, nodeId)
        return outPostStory:GetOption1Txt()
    end

    function XFubenInfestorExploreManager.GetOutPostOption2Txt(chapterId, nodeId)
        local outPostStory = GetNodeOutPostStory(chapterId, nodeId)
        return outPostStory:GetOption2Txt()
    end

    function XFubenInfestorExploreManager.GetOutPostNodeMyTurnDes(chapterId, nodeId, option, characterName)
        local outPostStory = GetNodeOutPostStory(chapterId, nodeId)
        return outPostStory:GetMyTurnDes(option, characterName)
    end

    function XFubenInfestorExploreManager.GetOutPostNodeHisTurnDes(chapterId, nodeId, option, isHurt, characterName, hp)
        local outPostStory = GetNodeOutPostStory(chapterId, nodeId)
        return outPostStory:GetHisTurnDes(option, isHurt, characterName, hp)
    end

    function XFubenInfestorExploreManager.GetOutPostNodeEndDes(chapterId, nodeId, characterName, hp)
        local outPostStory = GetNodeOutPostStory(chapterId, nodeId)
        return outPostStory:GetEndDes(characterName, hp)
    end

    function XFubenInfestorExploreManager.CheckShopExist()
        -- local shop = GetShop()
        -- return shop and next(shop) and true or false
        return false
    end

    function XFubenInfestorExploreManager.CheckNewChapterNeedShowAnim()
        return NewChapterNeedShowAnim
    end

    function XFubenInfestorExploreManager.ClearNewChapterNeedShowAnim()
        NewChapterNeedShowAnim = nil
    end

    function XFubenInfestorExploreManager.GetGoodsIds()
        local goodsIds = {}
        local goodsRecordDic = GetShop().GoodsRecordDic
        for goodsId in pairs(goodsRecordDic) do
            tableInsert(goodsIds, goodsId)
        end
        return goodsIds
    end

    function XFubenInfestorExploreManager.GetShopRefreshCost()
        local shopId = GetShop().ShopId
        return XFubenInfestorExploreConfigs.GetShopRefreshCost(shopId)
    end

    function XFubenInfestorExploreManager.IsGoodsSellOut(goodsId)
        local limitCount = XFubenInfestorExploreConfigs.GetGoodsLimitCount(goodsId)


        if limitCount == 0 then
            return false
        end

        local goodsRecordDic = GetShop().GoodsRecordDic
        local buyCount = goodsRecordDic[goodsId]
        return buyCount and buyCount >= limitCount
    end

    local DEFAULT_PLAYER_NAME = CSXTextManagerGetText("InfestorExploreRewardNodeDefaultPlayerName")
    function XFubenInfestorExploreManager.GetSelectRewardPlayerName(chapterId, nodeId)
        local player = GetSelectRewardPlayerData(chapterId, nodeId)
        if not player then
            return DEFAULT_PLAYER_NAME
        end
        return player:GetName()
    end

    local DEFAULT_MESSAGE = CSXTextManagerGetText("InfestorExploreRewardNodeDefaultMessage")
    function XFubenInfestorExploreManager.GetSelectRewardMessage(chapterId, nodeId)
        local selectRewardInfo = GetSelectRewardInfo(chapterId, nodeId)
        if not selectRewardInfo then
            return DEFAULT_MESSAGE
        end

        local player = GetSelectRewardPlayerData(chapterId, nodeId)
        local msg = selectRewardInfo.Message
        if string.IsNilOrEmpty(msg) then
            return player:GetSign()
        end

        return msg
    end

    function XFubenInfestorExploreManager.GetSelectRewardPlayerHeadId(chapterId, nodeId)
        local player = GetSelectRewardPlayerData(chapterId, nodeId)
        if not player then
            return
        end
        return player:GetHeadPortraitId()
    end

    function XFubenInfestorExploreManager.GetSelectRewardPlayerHeadFrameId(chapterId, nodeId)
        local player = GetSelectRewardPlayerData(chapterId, nodeId)
        if not player then
            return
        end
        return player:GetHeadFrameId()
    end

    function XFubenInfestorExploreManager.GetSelectRewardPlayerHeadIcon(chapterId, nodeId)
        local player = GetSelectRewardPlayerData(chapterId, nodeId)
        if not player then
            return
        end
        return player:GetHeadIcon()
    end

    function XFubenInfestorExploreManager.GetSelectRewardPlayerHeadEffectPath(chapterId, nodeId)
        local player = GetSelectRewardPlayerData(chapterId, nodeId)
        if not player then
            return
        end
        return player:GetHeadEffectPath()
    end

    function XFubenInfestorExploreManager.GetSelectRewardPlayerHeadFrame(chapterId, nodeId)
        local player = GetSelectRewardPlayerData(chapterId, nodeId)
        if not player then
            return
        end
        return player:GetHeadFrame()
    end

    function XFubenInfestorExploreManager.GetSelectRewardPlayerHeadFrameEffectPath(chapterId, nodeId)
        local player = GetSelectRewardPlayerData(chapterId, nodeId)
        if not player then
            return
        end
        return player:GetHeadFrameEffectPath()
    end

    function XFubenInfestorExploreManager.IsLastPlayerSelectReward(chapterId, nodeId, rewardId)
        local selectRewardInfo = GetSelectRewardInfo(chapterId, nodeId)
        if not selectRewardInfo then
            return false
        end
        return selectRewardInfo.RewardId == rewardId
    end

    function XFubenInfestorExploreManager.GetShopEventIds()
        local shopEventIds = {}

        for eventId in pairs(ContractEventIdDic) do
            tableInsert(shopEventIds, eventId)
        end

        return shopEventIds
    end

    function XFubenInfestorExploreManager.IsShopEventSellOut()
        for _, value in pairs(ContractEventIdDic) do
            if value == true then
                return true
            end
        end
        return false
    end

    function XFubenInfestorExploreManager.ClearFightRewards()
        FightRewardBuyDic = {}
        AfterFightNeedShowReward = nil

        --最后一关BOSS打完之后未翻牌，重登翻牌之后需要手动检查是否通关章节
        MoveToNextChapter()
    end

    function XFubenInfestorExploreManager.IsFightRewadsExist()

        return next(FightRewardBuyDic) and true or false
    end

    function XFubenInfestorExploreManager.GetFightRewardIds()
        local rewardIds = {}
        for rewardId, isBuy in pairs(FightRewardBuyDic) do
            tableInsert(rewardIds, rewardId)
        end
        return rewardIds
    end

    function XFubenInfestorExploreManager.IsFightRewadBuy(rewardId)
        return FightRewardBuyDic[rewardId]
    end

    function XFubenInfestorExploreManager.GetFightRewadBuyTimes()
        local times = 0
        for rewardId, isBuy in pairs(FightRewardBuyDic) do
            if isBuy then
                times = times + 1
            end
        end
        return times
    end

    function XFubenInfestorExploreManager.GetAllChapterMsgs(chapterId)
        return ChapterMsgDic[chapterId] or {}
    end

    function XFubenInfestorExploreManager.GetChapterPlayerMsg(chapterId, msgId)
        local msgs = ChapterMsgDic[chapterId]
        return msgs and msgs[msgId] or ""
    end

    function XFubenInfestorExploreManager.GetPlayerScore(playerId)
        local player = GetPlayerData(playerId)
        if not player then
            return 0
        end
        return player:GetScore()
    end

    function XFubenInfestorExploreManager.GetPlayerHeadIcon(playerId)
        local player = GetPlayerData(playerId)
        if not player then
            return
        end
        return player:GetHeadIcon()
    end

    function XFubenInfestorExploreManager.GetPlayerHeadEffectPath(playerId)
        local player = GetPlayerData(playerId)
        if not player then
            return
        end
        return player:GetHeadEffectPath()
    end

    function XFubenInfestorExploreManager.GetPlayerHeadFrame(playerId)
        local player = GetPlayerData(playerId)
        if not player then
            return
        end
        return player:GetHeadFrame()
    end

    function XFubenInfestorExploreManager.GetPlayerHeadFrameEffectPath(playerId)
        local player = GetPlayerData(playerId)
        if not player then
            return
        end
        return player:GetHeadFrameEffectPath()
    end

    function XFubenInfestorExploreManager.GetPlayerName(playerId)
        local player = GetPlayerData(playerId)
        if not player then
            return
        end
        return player:GetName()
    end

    function XFubenInfestorExploreManager.GetPlayerLevel(playerId)
        local player = GetPlayerData(playerId)
        if not player then
            return
        end
        return player:GetLevel()
    end

    function XFubenInfestorExploreManager.GetPlayerDiffName(playerId)
        local player = GetPlayerData(playerId)
        if not player then
            return
        end
        return player:GetDiffName()
    end

    function XFubenInfestorExploreManager.GetPlayerDiffIcon(playerId)
        local player = GetPlayerData(playerId)
        if not player then
            return
        end
        return player:GetDiffIcon()
    end

    function XFubenInfestorExploreManager.GetPlayerHeadId(playerId)
        local player = GetPlayerData(playerId)
        if not player then
            return
        end
        return player:GetHeadPortraitId()
    end

    function XFubenInfestorExploreManager.GetPlayerHeadFrameId(playerId)
        local player = GetPlayerData(playerId)
        if not player then
            return
        end
        return player:GetHeadFrameId()
    end

    function XFubenInfestorExploreManager.GetChapter2StageScore(stageId)
        return Chapter2ScoreDic[stageId] or 0
    end

    function XFubenInfestorExploreManager.GetChapter2TotalScore()
        local totalScore = 0
        if Chapter2ScoreDic then
            for _, score in pairs(Chapter2ScoreDic) do
                totalScore = totalScore + score
            end
        end
        return totalScore
    end

    function XFubenInfestorExploreManager.GetChapter2StageIds()
        return XFubenInfestorExploreConfigs.GetChapter2StageIds(ActivityId)
    end

    function XFubenInfestorExploreManager.SetOpenInfestorExploreCoreDelay(openInfestorExploreCoreDelay)
        OpenInfestorExploreCoreDelay = openInfestorExploreCoreDelay
    end

    function XFubenInfestorExploreManager.GetOpenInfestorExploreCoreDelay()
        return OpenInfestorExploreCoreDelay
    end

    function XFubenInfestorExploreManager.OpenGetNewCoreUi(cb)
        if not cb and not OpenInfestorExploreCoreCbTemp then return end

        if OpenInfestorExploreCoreScheduleId then
            XScheduleManager.UnSchedule(OpenInfestorExploreCoreScheduleId)
        end

        if cb then
            OpenInfestorExploreCoreCbTemp = cb
        end
        local openInfestorExploreCoreCb = cb or OpenInfestorExploreCoreCbTemp
        local scheduleCallback = function()
            openInfestorExploreCoreCb()
            XDataCenter.FubenInfestorExploreManager.SetOpenInfestorExploreCoreDelay(0)
            OpenInfestorExploreCoreCbTemp = nil
            OpenInfestorExploreCoreScheduleId = nil
        end
        local delayTime = XDataCenter.FubenInfestorExploreManager.GetOpenInfestorExploreCoreDelay()
        OpenInfestorExploreCoreScheduleId = XScheduleManager.ScheduleOnce(scheduleCallback, delayTime)
    end


    local function UpdateSectionData(status, nextResetTime) --更新现在出于什么时间段，更新这个时间段的的剩余时间
        SectionStatus = status
        local leftTime = nextResetTime - XTime.GetServerNowTimestamp()

        XCountDown.CreateTimer(XCountDown.GTimerName.FubenInfestorExplore, leftTime)
    end

    local function CreateCenterFog(chapterId, centerNodeId, fogDepth)
        local centerNode = GetStageNode(chapterId, centerNodeId)
        centerNode:SetStatusFog()

        if fogDepth == 0 then
            return
        end

        fogDepth = fogDepth - 1

        local childIds = centerNode:GetChildIds()
        for childId in pairs(childIds) do
            CreateCenterFog(chapterId, childId, fogDepth)
        end

        local parentIds = centerNode:GetParentIds()
        for parentId in pairs(parentIds) do
            CreateCenterFog(chapterId, parentId, fogDepth)
        end
    end

    local FogCenterNodeIds = {}
    local function UpdateStagesInfo(mapList)
        if not mapList then return end

        InitMaps()

        for _, map in pairs(mapList) do
            local chapterId = map.ChapterId
            local stageDataList = map.GridList
            for _, stageData in pairs(stageDataList) do
                local nodeId = stageData.Id
                local node = GetStageNode(chapterId, nodeId)
                if not node then
                    local mapId = XFubenInfestorExploreConfigs.GetMapId(chapterId)
                    XLog.Error("XFubenInfestorExploreManager UpdateStagesInfo error:关卡地图中不存在节点,  chapterId: " .. chapterId .. ", nodeId: " .. nodeId .. ", mapId: " .. mapId)
                end

                local stageId = stageData.NodeId
                node:SetStageId(stageId)
            end

            --必须等待所有节点更新完毕后再生成迷雾
            for _, stageData in pairs(stageDataList) do
                local nodeId = stageData.Id
                local stageId = stageData.NodeId
                local nodeResType = XFubenInfestorExploreConfigs.GetNodeResType(stageId)
                local fogDepth = XFubenInfestorExploreConfigs.GetFogDepth(nodeResType)

                if fogDepth ~= 0 then
                    CreateCenterFog(chapterId, nodeId, fogDepth)
                    tableInsert(FogCenterNodeIds, nodeId)
                end
            end

            --迷雾全部生成完毕后还原各中心点初始状态
            for _, centerNodeId in pairs(FogCenterNodeIds) do
                local centerNode = GetStageNode(chapterId, centerNodeId)
                centerNode:SetStatusUnReach()
            end
            FogCenterNodeIds = {}
        end
    end

    local function ResetData()
        FightRewardBuyDic = {}
        CharacterDataDic = {}
        LastSyncInfoTime = 0
        LastLeaveChapterMsgTime = 0
        LastGetLeaveChapterMsgTime = 0
        ChapterMsgDic = {}

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_INFESTOREXPLORE_RESET)
    end

    local function UpdateChapterData(data)
        CurChapterId = data.CurrentChapterId
        CurNodeId = data.CurrentGridId
        CurGroupId = data.GroupId
        FightEventId = data.FightEventId
        ActivityId = data.ActivityId
    end

    local function UpdateDiff(data)
        CurDiff = data.Diff
        LastDiff = data.LastDiff
        ActivityNo = data.ActivityNo
        OldActivityNo = XSaveTool.GetData(GetCookieKey())
    end

    local function UpdateChapter2Data(bossFightScoreInfoList)
        if not bossFightScoreInfoList then return end
        Chapter2ScoreDic = {}

        for _, info in pairs(bossFightScoreInfoList) do
            local stageId = info.StageId
            local score = info.Score
            Chapter2ScoreDic[stageId] = score
        end
    end

    local function UpdateBuffData(buffList)
        BuffIds = buffList
    end

    local function UpdateCharacterData(characterInfoList)
        if not characterInfoList then return end

        for _, info in pairs(characterInfoList) do
            local characterId = info.CharacterId
            local characterData = GetCharacterData(characterId)
            characterData:UpdateData(info)
            CharacterDataDic[characterId] = characterData
        end

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_INFESTOREXPLORE_CHARACTER_HP_CHANGE)
    end

    local function UpdateCoreData(coreInfo)
        if not coreInfo then return end

        CoreDic = {}
        CoreIdList = {}
        CoreUseIdDic = {}
        local coreDataList = coreInfo.CoreList
        for _, coreData in pairs(coreDataList) do
            AddCore(coreData)
        end

        local useDic = coreInfo.UseList
        for pos = 1, XFubenInfestorExploreConfigs.MaxWearingCoreNum do
            local coreId = useDic[pos]
            if coreId and coreId > 0 then
                local core = GetCore(coreId)
                if not core then
                    XLog.Error("XFubenInfestorExploreManager UpdateCoreData Error:穿戴中的核心未拥有, coreId: " .. coreId)
                else
                    PutOnCore(coreId, pos)
                end
            else
                TakeOffCore(pos)
            end
        end
    end

    local function UpdateShopData(shopData)
        if not shopData then return end

        local shop = {}
        shop.ShopId = shopData.Id

        local goodsRecordDic = {}
        local shopInfoList = shopData.GoodsList
        for _, shopInfo in pairs(shopInfoList) do
            local id = shopInfo.Id
            local buyCount = shopInfo.BuyCount
            goodsRecordDic[id] = buyCount
        end
        shop.GoodsRecordDic = goodsRecordDic

        ChapterIdToShopDic[CurChapterId] = shop
    end

    local function UpdateTeamData(teamType, teamdata)
        if not teamdata then return end

        local captainPos = 1
        local firstFightPos

        local characterIds = { 0, 0, 0 }
        for _, characterId in pairs(teamdata) do
            local characterData = GetCharacterData(characterId)
            local teamPos = characterData:GetTeamPos()
            characterIds[teamPos] = characterId
            if characterData:IsMeCaptain() then
                captainPos = teamPos
            end
            if characterData:IsMeFirstFight() then
                firstFightPos = teamPos
            end
        end

        -- 服务器没有首发位数据就和队长位一致
        if firstFightPos == nil then
            firstFightPos = captainPos
        end

        local team = GetTeam(teamType)
        team:SetCaptainPos(captainPos)
        team:SetFirstFightPos(firstFightPos)
        team:SetCharacterIds(characterIds)
        if not team:IsEmpty() then
            team:Syn()
        end
    end

    local function UpdateTeamInfoList(teamInfoList)
        if not teamInfoList then return end

        for _, teamInfo in pairs(teamInfoList) do
            local teamType = teamInfo.CharacterLimitType
            local teamData = teamInfo.CharacterList
            UpdateTeamData(teamType, teamData)
        end
    end

    local PLAYER_RANK_SORT = function(aPlayer, bPlayer)
        local aScore = aPlayer:GetScore()
        local bScore = bPlayer:GetScore()
        if aScore ~= bScore then
            return aScore > bScore
        end

        local aChapterId = aPlayer:GetChapterId()
        local bChapterId = bPlayer:GetChapterId()
        if aChapterId ~= bChapterId then
            return aChapterId > bChapterId
        end

        local aGridId = aPlayer:GetGridId()
        local bGridId = bPlayer:GetGridId()
        if aGridId ~= bGridId then
            return aGridId > bGridId
        end
    end

    local function UpdatePlayerRank(infestorPlayerList)
        PlayerRankDataList = {}

        for index, playerData in pairs(infestorPlayerList) do
            local playerId = playerData.Id

            local player = GetPlayerData(playerId)
            if player then
                --清除小队成员之前所在的格子位置
                local chapterId = player:GetChapterId()
                local nodeId = player:GetGridId()
                if chapterId > 0 and nodeId > 0 then
                    local node = GetStageNode(chapterId, nodeId)
                    node:ClearOccupiedPlayerId(playerId)
                end
            else
                player = XInfestorExplorePlayer.New()
            end

            player:UpdateData(playerData)
            PlayerDataDic[playerId] = player
            PlayerRankDataList[index] = player

            --记录小队成员所在的格子位置
            local chapterId = player:GetChapterId()
            local nodeId = player:GetGridId()
            if chapterId > 0 and nodeId > 0 then
                local node = GetStageNode(chapterId, nodeId)
                node:SetOccupiedPlayerId(playerId)
            end
        end
        tableSort(PlayerRankDataList, PLAYER_RANK_SORT)

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_INFESTOREXPLORE_REFRESH_PALYER_RANK)
    end

    local function UpdateSelectRewardInfoList(selectRewardInfoList)
        if not selectRewardInfoList then return end

        SelectRewardInfoDic = {}
        for _, rewardInfo in pairs(selectRewardInfoList) do
            local chapterId = rewardInfo.ChapterId
            local chapterDic = SelectRewardInfoDic[chapterId] or {}
            SelectRewardInfoDic[chapterId] = chapterDic

            local nodeId = rewardInfo.GridId
            local nodeDic = chapterDic[nodeId] or {}
            chapterDic[nodeId] = nodeDic

            nodeDic.RewardId = rewardInfo.RewardId
            nodeDic.PlayerId = rewardInfo.PlayerId
            nodeDic.Message = rewardInfo.Msg
        end
    end

    local function UpdateContractInfo(contractInfo, nextResetTime)
        if not contractInfo then return end
        ContractEventIdDic = {}

        local goodsIdList = contractInfo.GoodsIdList
        if goodsIdList then
            for _, eventId in pairs(goodsIdList) do
                ContractEventIdDic[eventId] = false
            end
        end

        local buyGoodsId = contractInfo.BuyGoodsId
        if buyGoodsId and buyGoodsId > 0 then
            if ContractEventIdDic[buyGoodsId] == false then
                ContractEventIdDic[buyGoodsId] = true
            end
        end

        nextResetTime = nextResetTime or XTime.GetSeverNextRefreshTime()
        local nowTime = XTime.GetServerNowTimestamp()
        local leftTime = nextResetTime - nowTime


        XCountDown.CreateTimer(XCountDown.GTimerName.FubenInfestorExploreDaily, leftTime)

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_INFESTOREXPLORE_CONTRACT_DAILY_RESET)
    end

    local function UpdateFightRewards(fightRewardInfoList)
        if not fightRewardInfoList then return end
        FightRewardBuyDic = {}

        for _, fightRewardInfo in pairs(fightRewardInfoList) do
            local rewardId = fightRewardInfo.RewardId
            local isBuy = fightRewardInfo.IsBuy
            FightRewardBuyDic[rewardId] = isBuy
        end
    end

    local function UpdateChapterLeaveMsg(chapterId, msgList)
        if not chapterId or not msgList then return end
        ChapterMsgDic[chapterId] = {}

        for _, playerMsgInfo in pairs(msgList) do
            InsertChapterMessage(chapterId, playerMsgInfo)
        end
    end

    function XFubenInfestorExploreManager.OpenEntranceUi(openCb)
        local now = XTime.GetServerNowTimestamp()
        if LastSyncInfoTime + REQUEST_SYNC_INFO_CD >= now then
            openCb()
        else
            XDataCenter.FubenInfestorExploreManager.RequestInfo(function()
                openCb()
            end)
        end
    end

    function XFubenInfestorExploreManager.RequestInfo(callBack)
        local now = XTime.GetServerNowTimestamp()
        if LastSyncInfoTime + REQUEST_SYNC_INFO_CD >= now then
            return
        end
        LastSyncInfoTime = now

        XNetwork.Call("InfestorExploreGetInfoRequest", nil, function(res)

            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local data = res.InfestorInfo
            UpdateCharacterData(data.CharacterList)
            UpdateTeamInfoList(data.TeamInfoList)
            UpdateChapterData(data)
            UpdateDiff(data)
            UpdateChapter2Data(data.BossFightScoreInfoList)
            UpdateFinishedNodesStatus(data.FinishGridDict)
            UpdateBuffData(data.BuffList)
            UpdateCoreData(data.CoreInfo)
            UpdatePlayerRank(data.InfestorPlayerList)
            UpdateSelectRewardInfoList(data.SelectRewardInfoList)
            UpdateContractInfo(data.EventShopInfo)
            SetLastFinishNodeId(data.LastFinishGridId)

            if callBack then callBack() end
        end)
    end

    function XFubenInfestorExploreManager.RequestShopInfo(nodeId, callBack)
        if XFubenInfestorExploreManager.CheckShopExist() then
            return
        end

        local req = { GridId = nodeId }
        XNetwork.Call("InfestorExploreGetShopRequest", req, function(res)

            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local shop = res.Shop
            UpdateShopData(shop)

            MoveToNextNode(CurNodeId, nodeId)

            if callBack then callBack() end
        end)
    end

    function XFubenInfestorExploreManager.RequestBuyGoods(goodsId, callBack)
        local req = { GoodsId = goodsId }
        XNetwork.Call("InfestorExploreBuyGoodsRequest", req, function(res)

            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local coreData = res.Core
            if coreData and coreData.Id then
                OnGetNewCore(coreData.Id, coreData.Level)
            end

            local goodsRecordDic = GetShop().GoodsRecordDic
            local buyCount = goodsRecordDic[goodsId]
            goodsRecordDic[goodsId] = buyCount + 1

            if callBack then callBack() end
        end)
    end

    function XFubenInfestorExploreManager.RequestRefreshShop(callBack)
        XNetwork.Call("InfestorExploreRefreshShopRequest", nil, function(res)

            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local shop = res.Shop
            UpdateShopData(shop)

            if callBack then callBack() end
        end)
    end

    function XFubenInfestorExploreManager.RequestGetSelectReward(nodeId, rewardCallBack)
        local req = { GridId = nodeId }
        XNetwork.Call("InfestorExploreGetSelectRewardRequest", req, function(res)

            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local selectRewardFunc = function()
                local selectRewardIdList = res.SelectRewardIdList
                if selectRewardIdList and next(selectRewardIdList) then
                    rewardCallBack(selectRewardIdList)
                end
            end

            local rewardCore = res.RewardCore
            if rewardCore and rewardCore.Id then
                OnGetNewCore(rewardCore.Id, rewardCore.Level, selectRewardFunc)
            else
                selectRewardFunc()
            end

            MoveToNextNode(CurNodeId, nodeId)
        end)
    end

    function XFubenInfestorExploreManager.RequestSetSelectReward(rewardId, msg, callBack)
        local req = { RewardId = rewardId, Msg = msg }
        XNetwork.Call("InfestorExploreSetSelectRewardRequest", req, function(res)

            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            SetLastFinishNodeId(CurNodeId)

            if callBack then callBack() end
        end)
    end

    function XFubenInfestorExploreManager.RequestSupply(chapterId, nodeId, callBack)
        local req = { ChapterId = chapterId, GridId = nodeId }

        XNetwork.Call("InfestorExploreSupplyRequest", req, function(res)

            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local coreList = res.CoreRewardList
            local index = 1
            local finishCb
            finishCb = function()
                index = index + 1
                local nextCoreData = coreList[index]
                if not nextCoreData then return end
                OnGetNewCore(nextCoreData.CoreId, nextCoreData.CoreLevel, finishCb)
            end
            local coreData = coreList[index]
            OnGetNewCore(coreData.CoreId, coreData.CoreLevel, finishCb)

            MoveToNextNode(CurNodeId, nodeId)
            SetLastFinishNodeId(CurNodeId)

            if callBack then callBack() end
        end)
    end

    function XFubenInfestorExploreManager.RequestUpdateTeam(chapterId, callBack)
        local req = {}
        local team = GetChapterTeam(chapterId)
        req.Team = team:GetCharacterIds()
        req.CaptainPos = team:GetCaptainPos()
        req.FirstFightPos = team:GetFirstFightPos()

        XNetwork.Call("InfestorExploreUpdateTeamRequest", req, function(res)

            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            team:Syn()

            if callBack then callBack() end
        end)
    end

    function XFubenInfestorExploreManager.RequestRest(chapterId, nodeId, callBack)
        local req = {}
        req.ChapterId = chapterId
        req.GridId = nodeId
        local team = GetChapterTeam(chapterId)
        req.Team = team:GetCharacterIds()
        req.CaptainPos = team:GetCaptainPos()
        req.FirstFightPos = team:GetFirstFightPos()

        XNetwork.Call("InfestorExploreRestRequest", req, function(res)

            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            MoveToNextNode(CurNodeId, nodeId)
            SetLastFinishNodeId(CurNodeId)

            if callBack then callBack() end
        end)
    end

    function XFubenInfestorExploreManager.RequestBuyEventGoods(goodsId, callBack)
        local req = { GoodsId = goodsId }
        XNetwork.Call("InfestorBuyEventGoodsRequest", req, function(res)

            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local eventType = res.EventType
            local eventArgs = res.EventArgs
            if eventType ~= XFubenInfestorExploreConfigs.EventType.AddCore then
                local content = GetEventTipsContent(eventType, eventArgs)
                OnNotAddCoreEventTips(content)
            end
            OnNewEventTips(eventType, eventArgs)

            ContractEventIdDic[goodsId] = true

            if callBack then callBack() end
        end)
    end

    function XFubenInfestorExploreManager.RequestInfestorExploreBuyFightReward(rewardId, callBack)
        local req = { RewardId = rewardId }
        XNetwork.Call("InfestorExploreBuyFlopRewardRequest", req, function(res)

            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            FightRewardBuyDic[rewardId] = true

            local coreId = XFubenInfestorExploreConfigs.GetRewardCoreId(rewardId)
            local coreLevel = XFubenInfestorExploreConfigs.GetRewardCoreLevel(rewardId)
            OnGetNewCore(coreId, coreLevel)

            if callBack then callBack() end
        end)
    end

    function XFubenInfestorExploreManager.RequestFinishAction(callBack)
        XNetwork.Call("InfestorExploreFinishActionRequest", nil, function(res)

            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            SetLastFinishNodeId(CurNodeId)

            if callBack then callBack() end
        end)
    end

    function XFubenInfestorExploreManager.RequestInfestorExplorePutOnCore(coreId, pos, callBack)
        local req = { CoreId = coreId, Index = pos }

        XNetwork.Call("InfestorExploreUseCoreRequest", req, function(res)

            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            PutOnCore(coreId, pos)

            CsXGameEventManager.Instance:Notify(XEventId.EVENT_INFESTOREXPLORE_CORE_PUTON, pos)

            if callBack then callBack() end
        end)
    end

    function XFubenInfestorExploreManager.RequestInfestorExploreTakeOffCore(pos, callBack)
        local req = { Index = pos }

        XNetwork.Call("InfestorExploreTakeOffCoreRequest", req, function(res)

            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            TakeOffCore(pos)

            CsXGameEventManager.Instance:Notify(XEventId.EVENT_INFESTOREXPLORE_CORE_TAKEOFF)

            if callBack then callBack() end
        end)
    end

    function XFubenInfestorExploreManager.RequestInfestorExploreDecomposeCore(coreIds, callBack)
        local req = { CoreList = coreIds }

        XNetwork.Call("InfestorExploreDecomposeCoreRequest", req, function(res)

            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local moneyCount = XFubenInfestorExploreManager.GetCoreDecomposeMoney(coreIds)
            OnGetMoneyTip(moneyCount)

            for _, coreId in pairs(coreIds) do
                DeleteCore(coreId)
            end

            CsXGameEventManager.Instance:Notify(XEventId.EVENT_INFESTOREXPLORE_CORE_DECOMPOESE)

            if callBack then callBack() end
        end)
    end

    function XFubenInfestorExploreManager.RequestInfestorExploreSelectEvent(nodeId, eventIds, callBack)
        local req = { GridId = nodeId, EventIdList = eventIds }


        XNetwork.Call("InfestorExploreSelectEventRequest", req, function(res)

            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local eventResultList = res.EventResultList
            local tipsContent = ""
            for _, eventResult in pairs(eventResultList) do
                local eventType = eventResult.EventType
                local eventArgs = eventResult.Args
                if eventType ~= XFubenInfestorExploreConfigs.EventType.AddCore then
                    local content = GetEventTipsContent(eventType, eventArgs)
                    tipsContent = tipsContent .. content .. "\n"
                end
                OnNewEventTips(eventType, eventArgs)
            end
            OnNotAddCoreEventTips(tipsContent)

            MoveToNextNode(CurNodeId, nodeId)
            SetLastFinishNodeId(CurNodeId)

            if callBack then callBack() end
        end)
    end

    function XFubenInfestorExploreManager.RequestInfestorExploreAutoEvent(nodeId, callBack)
        local req = { GridId = nodeId }

        XNetwork.Call("InfestorExploreAutoEventRequest", req, function(res)

            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local eventResult = res.EventResult
            local eventType = eventResult.EventType
            local eventArgs = eventResult.Args
            if eventType ~= XFubenInfestorExploreConfigs.EventType.AddCore then
                local content = GetEventTipsContent(eventType, eventArgs)
                OnNotAddCoreEventTips(content)
            end
            OnNewEventTips(eventType, eventArgs)

            MoveToNextNode(CurNodeId, nodeId)
            SetLastFinishNodeId(CurNodeId)

            if callBack then callBack() end
        end)
    end

    function XFubenInfestorExploreManager.OpenGuestBook(chapterId)
        local now = XTime.GetServerNowTimestamp()
        if LastGetLeaveChapterMsgTime + REQUEST_GET_LEAVE_CHAPTER_MSG_CD >= now then
            XLuaUiManager.Open("UiInfestorExploreGuestbook", chapterId)
            return
        end

        local callBack = function()
            XLuaUiManager.Open("UiInfestorExploreGuestbook", chapterId)
        end
        XFubenInfestorExploreManager.RequestGetChapterLeaveMsg(chapterId, callBack)
    end

    function XFubenInfestorExploreManager.RequestGetChapterLeaveMsg(chapterId, callBack)
        local now = XTime.GetServerNowTimestamp()
        if LastGetLeaveChapterMsgTime + REQUEST_GET_LEAVE_CHAPTER_MSG_CD >= now then
            return
        end
        LastGetLeaveChapterMsgTime = now

        local req = { ChapterId = chapterId }
        XNetwork.Call("InfestorGetChapterLeaveMsgRequest", req, function(res)

            local msgList = res.MsgList
            if msgList then
                UpdateChapterLeaveMsg(chapterId, msgList)
            end

            if callBack then callBack() end
        end)
    end

    function XFubenInfestorExploreManager.RequestChapterLeaveMsg(chapterId, msg, callBack)
        local now = XTime.GetServerNowTimestamp()
        if LastLeaveChapterMsgTime + REQUEST_LEAVE_CHAPTER_MSG_CD >= now then
            local tip = CSXTextManagerGetText("InfestorExploreRequestChapterLeaveMsgInCD", REQUEST_LEAVE_CHAPTER_MSG_CD)
            XUiManager.TipMsg(tip)
            return
        end

        local req = { ChapterId = chapterId, Msg = msg }
        XNetwork.Call("InfestorChapterLeaveMsgRequest", req, function(res)

            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            LastLeaveChapterMsgTime = now

            local playerMsgInfo = {
                Msg = msg,
                Id = XPlayer.Id,
                GroupId = CurGroupId,
                Diff = CurDiff,
            }
            InsertChapterMessage(chapterId, playerMsgInfo)

            if callBack then callBack() end
        end)
    end

    function XFubenInfestorExploreManager.RequestOutPostSend(nodeId, characterId, callBack)
        local req = { GridId = nodeId, CharacterId = characterId }
        XNetwork.Call("InfestorExploreBfrtRequest", req, function(res)

            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            MoveToNextNode(CurNodeId, nodeId)

            local rewardMoney = res.RewardMoney
            local subHpList = res.SubHpList

            if callBack then callBack(rewardMoney, subHpList) end
        end)
    end

    function XFubenInfestorExploreManager.RequestEnterFight(chapterId, nodeId)
        local stageId = XFubenInfestorExploreManager.GetNodeFightStageId(chapterId, nodeId)
        local team = XFubenInfestorExploreManager.GetChapterTeamCharacterIds(chapterId)
        local captainPos = XDataCenter.FubenInfestorExploreManager.GetChapterTeamCaptainPos(chapterId)
        local firstFightPos = XDataCenter.FubenInfestorExploreManager.GetChapterTeamFirstFightPos(chapterId)
        XDataCenter.FubenManager.EnterInfestorExploreFight(stageId, team, captainPos, nodeId, firstFightPos)

        DelayMoveNodeId = nodeId
    end


    function XFubenInfestorExploreManager.NotifyInfestorStatus(data)

        if data.IsReset then
            ResetData()
        end
        UpdateSectionData(data.Status, data.NextResetTime)
        UpdateStagesInfo(data.MapList)
    end

    function XFubenInfestorExploreManager.NotifyInfestorDailyReset(data)

        UpdateContractInfo(data.EventShopInfo, data.NextResetTime)
    end

    function XFubenInfestorExploreManager.NotifyInfestorCharacterList(data)

        UpdateCharacterData(data.CharacterList)
    end

    function XFubenInfestorExploreManager.NotifyFlopRewardInfoList(data)

        UpdateFightRewards(data.FlopRewardInfoList)

        if AfterFightNeedShowReward then
            AfterFightNeedShowReward = nil
            if XFubenInfestorExploreManager.IsFightRewadsExist() then
                XLuaUiManager.Open("UiInfestorExploreChoose")
            end
        end
    end

    function XFubenInfestorExploreManager.NotifyInfestorPlayerInfoList(data)

        local infestorPlayerList = data.PlayerInfoList
        if not infestorPlayerList then return end
        UpdatePlayerRank(infestorPlayerList)
    end

    --FubenManager相关
    function XFubenInfestorExploreManager.InitStageInfo()
        local configs = XFubenInfestorExploreConfigs.GetStageConfigs()
        for _, config in pairs(configs) do
            local stageId = config.FightStageId
            if stageId > 0 then
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                if stageInfo then
                    stageInfo.Type = XDataCenter.FubenManager.StageType.InfestorExplore
                end
            end
        end

        local activityConfigs = XFubenInfestorExploreConfigs.GetActivityConfigs()
        for _, config in pairs(activityConfigs) do
            for _, stageId in pairs(config.BossStageId) do
                if stageId > 0 then
                    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                    if stageInfo then
                        stageInfo.Type = XDataCenter.FubenManager.StageType.InfestorExplore
                    end
                end
            end
        end
    end

    --战斗结算翻牌走副本之外独立协议通知
    function XFubenInfestorExploreManager.FinishFight(settle)

        local infestorBossFightResult = settle.InfestorBossFightResult
        if infestorBossFightResult and next(infestorBossFightResult) then
            local stageId = settle.StageId

            local newScore = infestorBossFightResult.TotalScore
            local oldScore = XFubenInfestorExploreManager.GetChapter2StageScore(stageId)
            local isNewScore = newScore > oldScore
            if isNewScore then
                Chapter2ScoreDic[stageId] = newScore
            end

            local totalScore = XFubenInfestorExploreManager.GetChapter2TotalScore()
            local player = GetPlayerData(XPlayer.Id)
            player:SetScore(totalScore)

            XLuaUiManager.Open("UiInfestorExploreFightResult", stageId, infestorBossFightResult, isNewScore)
        else
            XDataCenter.FubenManager.FinishFight(settle)
            if settle.IsWin then
                if DelayMoveNodeId then
                    MoveToNextNode(CurNodeId, DelayMoveNodeId)
                    DelayMoveNodeId = nil
                end

                AfterFightNeedShowReward = true
            end
        end
    end

    XFubenInfestorExploreManager.OnGetMoneyTip = OnGetMoneyTip
    XFubenInfestorExploreManager.IsHaveCore = IsHaveCore
    XFubenInfestorExploreManager.CheckBuffExsit = CheckBuffExsit
    return XFubenInfestorExploreManager
    --     -------------------(对外开放接口)end------------------
end

--     -------------------(服务器推送)begin------------------
XRpc.NotifyInfestorStatus = function(data)
    XDataCenter.FubenInfestorExploreManager.NotifyInfestorStatus(data)
end

XRpc.NotifyInfestorDailyReset = function(data)
    XDataCenter.FubenInfestorExploreManager.NotifyInfestorDailyReset(data)
end

XRpc.NotifyInfestorCharacterList = function(data)
    XDataCenter.FubenInfestorExploreManager.NotifyInfestorCharacterList(data)
end

XRpc.NotifyFlopRewardInfoList = function(data)
    XDataCenter.FubenInfestorExploreManager.NotifyFlopRewardInfoList(data)
end

XRpc.NotifyInfestorPlayerInfoList = function(data)
    XDataCenter.FubenInfestorExploreManager.NotifyInfestorPlayerInfoList(data)
end
--     -------------------(服务器推送)end------------------