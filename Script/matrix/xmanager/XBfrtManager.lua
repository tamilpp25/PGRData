---@class XBfrtData
---@field BfrtGroupRecords XBfrtGroupRecord[]
---@field BfrtTeamInfos XBfrtTeamInfo[]
---@field BfrtProgressInfo XBfrtProgressInfo
---@field CourseRewardStar number

---@class XBfrtGroupRecord
---@field Id number
---@field Count number
---@field IsRecvReward boolean

---@class XBfrtTeamInfo
---@field Id number
---@field FightTeamList number[][]
---@field LogisticsTeamList number[][]
---@field CaptainPosList number[]
---@field FirstFightPosList number[]

---@class XBfrtProgressInfo
---@field GroupId number
---@field StageIds number[]

---@class XBfrtTaskData
---@field Id number taskId/rewardId
---@field Schedule table<number, table>
---@field State number XTaskManager.TaskState
---@field IsReward boolean
---@field Title string
---@field Desc string
---@field ChapterId number
---@field GroupId number

---@class XBfrtChapterInfo
---@field Unlock boolean
---@field Passed boolean
---@field ChapterId number

---@class XBfrtGroupInfo
---@field Unlock boolean
---@field Passed boolean
---@field ChapterId number
---@field OrderId number
---@field IsRecvReward boolean

---@class XBfrtStageInfo
---@field GroupId number
---@field IsLastStage boolean

---@class XBfrtCourseRewardChapter
---@field ChapterId number
---@field RewardId boolean

local XExFubenSimulationChallengeManager = require("XEntity/XFuben/XExFubenSimulationChallengeManager")
XBfrtManagerCreator = function()
    local pairs = pairs
    local ipairs = ipairs
    local string = string
    local table = table
    local tableInsert = table.insert
    local tableRemove = table.remove
    local tableSort = table.sort
    local ParseToTimestamp = XTime.ParseToTimestamp
    local FightCb
    local CloseLoadingCb

    -- 据点战管理器
    ---@class XBfrtManager:XExFubenSimulationChallengeManager
    local XBfrtManager = XExFubenSimulationChallengeManager.New(XFubenConfigs.ChapterType.Bfrt)

    --据点战梯队类型
    XBfrtManager.EchelonType = {
        Fight = 0, --作战梯队
        Logistics = 1, --后勤梯队
    }

    local METHOD_NAME = {
        GetBfrtDataRequest = "GetBfrtDataRequest",  -- 无用？by ljb
        BfrtTeamSetRequest = "BfrtTeamSetRequest",  -- 据点队伍设置
        BfrtOneKeyPassGroupRequest = "BfrtOneKeyPassGroupRequest",  -- 据点一键通关组
        BfrtResetGroupStageRequest = "BfrtResetGroupStageRequest",  -- 据点重置组关卡
        BfrtReceiveCourseRewardRequest = "BfrtReceiveCourseRewardRequest",  -- 据点领取历程奖励
        BfrtReceiveChapterGroupRewardRequest = "BfrtReceiveChapterGroupRewardRequest",  -- 据点领取通关奖励
    }

    ---@type XTableBfrtChapter[]
    local BfrtChapterTemplates = {}
    ---@type XTableBfrtGroup[]
    local BfrtGroupTemplates = {}
    ---@type XTableEchelonInfo[]
    local EchelonInfoTemplates = {}

    local BfrtFollowGroupDic = {}
    ---@type XBfrtChapterInfo[]
    local ChapterInfos = {}
    ---@type XBfrtGroupInfo[]
    local GroupInfos = {}
    ---@type table<number, number> key = orderId, value = ChapterId
    local ChapterDic = {}
    ---@type table<number, number> key = groupId, value = orderId
    local GroupIdToOrderIdDic = {}
    ---@type table<number, XBfrtStageInfo> key = baseStageId
    local StageDic = {}
    ---@type table<number, number> key = groupId, value = ChapterId
    local GroupIdToChapterIdDic = {}
    local TaskIdToOrderIdDic = {}
    ---@type XBfrtCourseRewardChapter[]
    local _CourseImpRewardChapterList = {}
    
    local EchlonTeamPosDic = {} --缓存本地修改的队长位
    local EchlonServerTeamPosDic = {}   --缓存服务端下发的队长位
    local EchlonFirstFightDic = {}  --缓存本地修改的首发位
    local EchlonServerFirstFightDic = {}    --缓存服务端下发的首发位
    -- 由于fubenManager不再使用InitStageInfo因此手动处理 by ljb - v2.9
    local _IsInitStageInfo = false

    --面板上显示的位置 = 队伍中实际中的位置
    local TEAM_POS_DIC = {
        [1] = 2,
        [2] = 1,
        [3] = 3,
    }

    ---@type XBfrtData
    local BfrtData = {}
    local FightTeams = {}
    local LogisticsTeams = {}

    local function IsGroupPassed(groupId)
        local records = BfrtData.BfrtGroupRecords
        if not records then
            return false
        end

        for _, record in pairs(records) do
            if record.Id == groupId then
                return true
            end
        end

        return false
    end

    function XBfrtManager.GetChapterInfo(chapterId)
        return ChapterInfos[chapterId]
    end

    local function GetGroupInfo(groupId)
        return GroupInfos[groupId]
    end

    local function GetGroupCfg(groupId)
        local groupCfg = BfrtGroupTemplates[groupId]
        if not groupCfg then
            XLog.ErrorTableDataNotFound("GetGroupCfg", "groupCfg", "Share/Fuben/Bfrt/BfrtGroup.tab", "groupId", tostring(groupId))
            return
        end
        return groupCfg
    end

    local function GetEchelonInfo(echelonId)
        local echelon = EchelonInfoTemplates[echelonId]
        if not echelon then
            XLog.ErrorTableDataNotFound("GetEchelonInfo", "echelon", "Share/Fuben/Bfrt/EchelonInfo.tab", "echelonId", tostring(echelonId))
            return
        end

        return echelon
    end

    local function CheckTeamLimit(echelonId, team)
        local needNum = XBfrtManager.GetEchelonNeedCharacterNum(echelonId)
        for i = 1, needNum do
            local characterId = team[i]
            if not characterId or characterId == 0 then
                return false
            end
        end

        return true
    end

    local function InitGroupInfo()
        GroupInfos = {}
        for groupId, groupCfg in pairs(BfrtGroupTemplates) do
            local info = {}
            GroupInfos[groupId] = info
            GroupIdToOrderIdDic[groupId] = groupCfg.GroupOrderId

            info.Unlock = true
            local preGroupId = groupCfg.PreGroupId
            if preGroupId and preGroupId > 0 then
                info.Unlock = false
                for _, record in pairs(BfrtData.BfrtGroupRecords) do
                    if record.Id == preGroupId then
                        info.Unlock = true
                        break
                    end
                end
            end

            StageDic[groupCfg.BaseStage] = {
                GroupId = groupId,
                IsLastStage = false,
            }

            local count = #groupCfg.StageId
            for k, v in pairs(groupCfg.StageId) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(v)
                if stageInfo then
                    stageInfo.Unlock = info.Unlock

                    StageDic[v] = {
                        GroupId = groupId,
                        IsLastStage = (k == count)
                    }
                else
                    local tmpStr = "XBfrtManager.InitGroupInfo错误, 无法根据 Share/Fuben/Bfrt/BfrtGroup.tab 表里面的stageId"
                    XLog.Error(tmpStr .. v .. " 找到Share/Fuben/Stage.tab 表中的表项")
                end
            end
            info.Passed = IsGroupPassed(groupId)
        end
        for _, record in ipairs(BfrtData.BfrtGroupRecords) do
            GroupInfos[record.Id].IsRecvReward = record.IsRecvReward
        end
    end

    local function InitChapterInfo()
        ChapterInfos = {}
        for chapterId, chapterCfg in pairs(BfrtChapterTemplates) do
            ChapterDic[chapterCfg.OrderId] = chapterId
            local info = {}
            ChapterInfos[chapterId] = info
            info.ChapterId = chapterId
            if #chapterCfg.GroupId > 0 then
                local groupId = chapterCfg.GroupId[1]
                local groupInfo = GroupInfos[groupId]
                if groupInfo then
                    info.Unlock = groupInfo.Unlock
                end
            end

            local allPassed = true
            for k, v in pairs(chapterCfg.GroupId) do
                GroupIdToChapterIdDic[v] = chapterId

                local groupInfo = GroupInfos[v]
                groupInfo.OrderId = k
                groupInfo.ChapterId = chapterId

                local groupCfg = BfrtGroupTemplates[v]
                for _, v2 in pairs(groupCfg.StageId) do
                    local stageInfo = XDataCenter.FubenManager.GetStageInfo(v2)
                    stageInfo.ChapterId = chapterId
                end

                if not groupInfo.Passed then
                    allPassed = false
                end
            end
            info.Passed = allPassed

            for orderId, taskId in ipairs(chapterCfg.TaskId) do
                TaskIdToOrderIdDic[taskId] = orderId
            end
            
            if XTool.IsNumberValid(chapterCfg.BfrtRewardId) then
                local courseRewardCfg = XBfrtManager.GetBfrtReward(chapterCfg.BfrtRewardId)
                local isHaveInfo = false
                for i, rewardInfo in ipairs(_CourseImpRewardChapterList) do
                    if rewardInfo.ChapterId == chapterId then
                        isHaveInfo = true
                    end
                end
                if XTool.IsNumberValid(courseRewardCfg.IsImportantItem) and not isHaveInfo then
                    ---@type XBfrtCourseRewardChapter
                    local courseChapterInfo = {}
                    courseChapterInfo.ChapterId = chapterId
                    courseChapterInfo.RewardId = chapterCfg.BfrtRewardId
                    tableInsert(_CourseImpRewardChapterList, courseChapterInfo)
                end
            end
        end
    end

    local function RefreshChapterPassed()
        for chapterId, chapterCfg in pairs(BfrtChapterTemplates) do
            local info = ChapterInfos[chapterId]
            if info then
                local allPassed = true
                for k, v in pairs(chapterCfg.GroupId) do
                    local groupInfo = GroupInfos[v]
                    if not groupInfo.Passed then
                        allPassed = false
                    end
                end
                info.Passed = allPassed
            end
        end
    end

    local function InitFollowGroup()
        for k, v in pairs(BfrtGroupTemplates) do
            if v.PreGroupId > 0 then
                local list = BfrtFollowGroupDic[v.PreGroupId]
                if not list then
                    list = {}
                end

                tableInsert(list, k)
                BfrtFollowGroupDic[v.PreGroupId] = list
            end
        end
    end

    local function InitTeamRecords()
        ---@type XBfrtTeamInfo
        local teamInfos = BfrtData.BfrtTeamInfos
        if not teamInfos then return end

        for _, teamInfo in pairs(teamInfos) do
            if teamInfo then
                local groupId = teamInfo.Id
                FightTeams[groupId] = teamInfo.FightTeamList
                LogisticsTeams[groupId] = teamInfo.LogisticsTeamList

                local captainList = teamInfo.CaptainPosList
                local firstFightList = teamInfo.FirstFightPosList

                if captainList then
                    local fightInfoIdList = XBfrtManager.GetFightInfoIdList(groupId)
                    for index, echelonId in ipairs(fightInfoIdList) do
                        XBfrtManager.SetTeamCaptainPos(echelonId, captainList[index])
                        XBfrtManager.SetServerTeamCaptainPos(echelonId, captainList[index])
                    end
                end

                if firstFightList then
                    local fightInfoIdList = XBfrtManager.GetFightInfoIdList(groupId)
                    for index, echelonId in ipairs(fightInfoIdList) do
                        XBfrtManager.SetTeamFirstFightPos(echelonId, firstFightList[index])
                        XBfrtManager.SetServerTeamFirstFightPos(echelonId, firstFightList[index])
                    end
                end
            end
        end
    end

    local function UnlockFollowGroup(groupId)
        local list = BfrtFollowGroupDic[groupId]
        if not list then
            return
        end

        for _, id in pairs(list) do
            GroupInfos[id].Unlock = true

            local groupCfg = BfrtGroupTemplates[id]
            for _, v in pairs(groupCfg.StageId) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(v)
                stageInfo.Unlock = true
            end

            local baseStageInfo = XDataCenter.FubenManager.GetStageInfo(groupCfg.BaseStage)
            baseStageInfo.Unlock = true

            local chapterId = XBfrtManager.GetChapterIdByGroupId(id)
            local chapterInfo = XBfrtManager.GetChapterInfo(chapterId)
            chapterInfo.Unlock = true
        end
    end

    function XBfrtManager.Init()
        _IsInitStageInfo = false
        BfrtChapterTemplates = XBfrtConfigs.GetBfrtChapterTemplates()
        BfrtGroupTemplates = XBfrtConfigs.GetBfrtGroupTemplates()
        EchelonInfoTemplates = XBfrtConfigs.GetEchelonInfoTemplates()
    end

    function XBfrtManager.CheckStageTypeIsBfrt(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if stageInfo and stageInfo.Type == XDataCenter.FubenManager.StageType.Bfrt then
            return true
        end
        return false
    end

    function XBfrtManager.CheckActivityCondition(chapterId)
        local chapterCfg = XBfrtManager.GetChapterCfg(chapterId)
        local conditionId = chapterCfg.ActivityCondition
        if conditionId ~= 0 and not XConditionManager.CheckCondition(conditionId) then
            return false
        end
        return true
    end

    --获取当前最新解锁的Chapter
    function XBfrtManager.GetActiveChapterId()
        local activeChapterId

        local chapterIdList = XBfrtManager.GetChapterList()
        for _, chapterId in ipairs(chapterIdList) do
            local chapterInfo = XBfrtManager.GetChapterInfo(chapterId)
            if chapterInfo.Unlock then
                activeChapterId = chapterId
            end
        end

        return activeChapterId
    end

    function XBfrtManager.IsChapterInTime(chapterId)
        local chapterCfg = XBfrtManager.GetChapterCfg(chapterId)
        local startTime = ParseToTimestamp(chapterCfg.OpenTimeStr)
        if not startTime or startTime <= 0 then
            return true
        end

        local nowTime = XTime.GetServerNowTimestamp()
        return startTime <= nowTime
    end

    function XBfrtManager.IsGroupPassedByStageId(stageId)
        local groupId = XDataCenter.BfrtManager.GetGroupIdByStageId(stageId)
        local groupInfo = GetGroupInfo(groupId)
        return groupInfo.Passed
    end
    
    --region Chapter
    function XBfrtManager.GetChapterList()
        local list = {}

        for _, chapterId in pairs(ChapterDic) do
            if XBfrtManager.IsChapterInTime(chapterId) then
                tableInsert(list, chapterId)
            end
        end

        return list
    end

    function XBfrtManager.GetChapterInfoForOrder(orderId)
        local chapterId = ChapterDic[orderId]
        return ChapterInfos[chapterId]
    end

    --获取Chapter中所有Group用于展示的BaseStage的List
    function XBfrtManager.GetBaseStageList(chapterId)
        local baseStageList = {}

        local groupList = XBfrtManager.GetChapterGroupList(chapterId)
        for _, groupId in ipairs(groupList) do
            local groupCfg = GetGroupCfg(groupId)
            table.insert(baseStageList, groupCfg.BaseStage)
        end

        return baseStageList
    end
    
    ---@return XTableBfrtChapter
    function XBfrtManager.GetChapterCfg(chapterId)
        local chapterCfg = BfrtChapterTemplates[chapterId]
        if not chapterCfg then
            XLog.ErrorTableDataNotFound("XBfrtManager.GetChapterCfg", "chapterCfg",
                    "Share/Fuben/Bfrt/BfrtChapter.tab", "chapterId", tostring(chapterId))
            return
        end
        return chapterCfg
    end
    
    function XBfrtManager.GetChapterOrderId(chapterId)
        local chapterCfg = XBfrtManager.GetChapterCfg(chapterId)
        return chapterCfg.OrderId
    end

    function XBfrtManager.GetChapterGroupList(chapterId)
        local chapter = BfrtChapterTemplates[chapterId]
        if not chapter then
            XLog.ErrorTableDataNotFound("XBfrtManager.GetGroupList", "chapter", "Share/Fuben/Bfrt/BfrtChapter.tab", "chapterId", tostring(chapterId))
            return
        end

        return chapter.GroupId
    end

    function XBfrtManager.GetChapterName(chapterId)
        local chapter = XBfrtManager.GetChapterCfg(chapterId)
        return chapter and chapter.ChapterName
    end

    function XBfrtManager.GetChapterEn(chapterId)
        local chapter = XBfrtManager.GetChapterCfg(chapterId)
        return chapter and chapter.ChapterEn
    end
    
    function XBfrtManager.GetChapterPassCount(chapterId)
        local passCount = 0

        local groupList = XBfrtManager.GetChapterGroupList(chapterId)
        for _, groupId in ipairs(groupList) do
            if GroupInfos[groupId].Passed then
                passCount = passCount + 1
            end
        end

        return passCount
    end

    function XBfrtManager.GetChapterGroupCount(chapterId)
        local groupList = XBfrtManager.GetChapterGroupList(chapterId)
        return #groupList
    end

    function XBfrtManager.GetChapterCourseRewardId(chapterId)
        local chapterCfg = XBfrtManager.GetChapterCfg(chapterId)
        return chapterCfg and chapterCfg.BfrtRewardId
    end
    
    function XBfrtManager.GetChapterIdByGroupId(groupId)
        return GroupIdToChapterIdDic[groupId]
    end

    function XBfrtManager.GetNextChapterIdById(targetChapterId)
        local isFind = false

        local chapterIdList = XBfrtManager.GetChapterList()
        for _, chapterId in ipairs(chapterIdList) do
            if isFind then
                return chapterId
            end
            -- 到targetChapterId为止一共有多少个group
            if targetChapterId == chapterId then
                isFind = true
            end
        end
        return targetChapterId
    end
    
    function XBfrtManager.GetAllChapterPassCount()
        local result = 0

        local chapterIdList = XBfrtManager.GetChapterList()
        for _, chapterId in ipairs(chapterIdList) do
            result = result + XBfrtManager.GetChapterPassCount(chapterId)
        end
        return result
    end

    function XBfrtManager.GetAllChapterGroupCount(targetChapterId)
        local result = 0

        local chapterIdList = XBfrtManager.GetChapterList()
        for _, chapterId in ipairs(chapterIdList) do
            result = result + XBfrtManager.GetChapterGroupCount(chapterId)
            -- 到targetChapterId为止一共有多少个group
            if targetChapterId == chapterId then
                return result
            end
        end
        return result
    end

    function XBfrtManager.CheckChapterNew(chapterId)
        local chapterInfo = XBfrtManager.GetChapterInfo(chapterId)
        return chapterInfo.Unlock and not chapterInfo.Passed
    end
    --endregion
    
    --region Group
    ---@param data XBfrtGroupRecord
    function XBfrtManager._UpdateGroupInfo(data)
        local groupId = data.Id
        GroupInfos[groupId].Passed = true
        GroupInfos[groupId].IsRecvReward = data.IsRecvReward

        local findRecord = false
        for _, record in pairs(BfrtData.BfrtGroupRecords) do
            if record.Id == groupId then
                record.Count = data.Count
                findRecord = true
                break
            end
        end

        if not findRecord then
            tableInsert(BfrtData.BfrtGroupRecords, data)
        end
        UnlockFollowGroup(groupId)
    end

    function XBfrtManager.GetLogisticsInfoIdList(groupId)
        local groupCfg = GetGroupCfg(groupId)
        return groupCfg.LogisticsInfoId
    end

    function XBfrtManager.GetBaseStage(groupId)
        local groupCfg = GetGroupCfg(groupId)
        return groupCfg.BaseStage
    end

    function XBfrtManager.GetGroupNeedAbility(groupId)
        local groupCfg = GetGroupCfg(groupId)
        return groupCfg.NeedPoint or 0
    end

    function XBfrtManager.GetGroupClearOpen(groupId)
        local groupCfg = GetGroupCfg(groupId)
        return XTool.IsNumberValid(groupCfg.ClearOpen)
    end

    function XBfrtManager.GetGroupIdByStageId(stageId)
        if not StageDic[stageId] then
            XLog.Error("XBfrtManager GetGroupIdByStageId 无法从StageDic中找到groupId，检查 Share/Fuben/Bfrt/BfrtGroup.tab 表, stageId 是" .. stageId)
            return
        end
        return StageDic[stageId].GroupId
    end

    function XBfrtManager.GetGroupIdByBaseStage(baseStage)
        return XBfrtManager.GetGroupIdByStageId(baseStage)
    end

    function XBfrtManager.GetGroupOrderIdByStageId(stageId)
        local groupId = XBfrtManager.GetGroupIdByStageId(stageId)
        return GroupIdToOrderIdDic[groupId]
    end
    
    function XBfrtManager.GetStageIdList(groupId)
        local stageIdList = {}

        local groupCfg = GetGroupCfg(groupId)
        local seqList = string.ToIntArray(groupCfg.TeamFightSeq, '|')
        local originList = groupCfg.StageId
        for index, seq in ipairs(seqList) do
            stageIdList[index] = originList[seq]
        end

        return stageIdList
    end

    function XBfrtManager.GetFightTeamList(groupId)
        local team = FightTeams[groupId]
        if not team then
            local preGroupId = XBfrtConfigs.GetBfrtPreGroupId(groupId)
            team = FightTeams[preGroupId] or {}
        end

        return XTool.Clone(team)
    end

    function XBfrtManager.GetLogisticsTeamList(groupId)
        local team = LogisticsTeams[groupId] or {}
        return XTool.Clone(team)
    end

    function XBfrtManager.GetFightInfoIdList(groupId)
        local fightInfoIdList = {}

        local groupCfg = GetGroupCfg(groupId)
        local seqList = string.ToIntArray(groupCfg.TeamFightSeq, '|')
        local originList = groupCfg.FightInfoId
        for index, seq in ipairs(seqList) do
            fightInfoIdList[index] = originList[seq]
        end

        return fightInfoIdList
    end

    function XBfrtManager.GetGroupFinishCount(baseStage)
        local records = BfrtData.BfrtGroupRecords
        if not records then
            return 0
        end

        local groupId = XBfrtManager.GetGroupIdByBaseStage(baseStage)
        for _, record in pairs(records) do
            if record.Id == groupId then
                return record.Count
            end
        end

        return 0
    end

    function XBfrtManager.GetGroupMaxChallengeNum(baseStage)
        local groupId = XBfrtManager.GetGroupIdByBaseStage(baseStage)
        local groupCfg = GetGroupCfg(groupId)
        return groupCfg.ChallengeNum
    end

    function XBfrtManager.GetGroupRequireCharacterNum(groupId)
        local groupRequireCharacterNum = 0

        local fightInfoList = XBfrtManager.GetFightInfoIdList(groupId)
        for _, echelonId in pairs(fightInfoList) do
            groupRequireCharacterNum = groupRequireCharacterNum + XBfrtManager.GetEchelonNeedCharacterNum(echelonId)
        end

        local logisticsInfoList = XBfrtManager.GetLogisticsInfoIdList(groupId)
        for _, echelonId in pairs(logisticsInfoList) do
            groupRequireCharacterNum = groupRequireCharacterNum + XBfrtManager.GetEchelonNeedCharacterNum(echelonId)
        end

        return groupRequireCharacterNum
    end

    function XBfrtManager.GetGroupOrderId(groupId)
        local groupInfo = GetGroupInfo(groupId)
        return groupInfo.OrderId
    end
    
    function XBfrtManager.GetGroupChapterId(groupId)
        local groupInfo = GroupInfos[groupId]
        return groupInfo and groupInfo.ChapterId
    end

    function XBfrtManager.CheckIsGroupLastStage(stageId)
        local groupId = XBfrtManager.GetGroupIdByStageId(stageId)
        local stageIdList = XBfrtManager.GetStageIdList(groupId)
        return stageIdList[#stageIdList] == stageId
    end

    function XBfrtManager.CheckPreGroupUnlock(groupId)
        local groupInfo = GetGroupInfo(groupId)
        local groupCfg = GetGroupCfg(groupId)
        return groupInfo.Unlock, groupCfg.PreGroupId
    end

    function XBfrtManager.CheckBaseStageUnlock(baseStage)
        local groupId = XBfrtManager.GetGroupIdByBaseStage(baseStage)
        local groupInfo = GetGroupInfo(groupId)
        return groupInfo.Unlock
    end

    function XBfrtManager.CheckGroupRewardRecv(groupId)
        if XTool.IsTableEmpty(GroupInfos) then
            return false
        end
        if not GroupInfos[groupId] then
            return false
        end
        return GroupInfos[groupId].IsRecvReward
    end

    function XBfrtManager.CheckGroupIsPass(groupId)
        if XTool.IsTableEmpty(GroupInfos) then
            return false
        end
        if not GroupInfos[groupId] then
            return false
        end
        return GroupInfos[groupId].Passed
    end
    
    function XBfrtManager._SetGroupRewardRecv(groupId)
        if not GroupInfos[groupId] then
            GroupInfos[groupId] = {}
        end
        GroupInfos[groupId].IsRecvReward = true
    end
    --endregion

    --region Echelon
    --获取各梯队需求人数
    function XBfrtManager.GetEchelonNeedCharacterNum(echelonId)
        local echelon = GetEchelonInfo(echelonId)
        return echelon and echelon.NeedCharacter
    end

    function XBfrtManager.GetLogisticSkillDes(echelonId)
        local echelon = GetEchelonInfo(echelonId)
        if not echelon.BuffId or echelon.BuffId == 0 then
            XLog.ErrorTableDataNotFound("XBfrtManager.GetLogisticSkillDes", "BuffId",
                    "Share/Fuben/Bfrt/EchelonInfo.tab", "echelonId", tostring(echelonId))
            return
        end

        local fightEventCfg = CS.XNpcManager.GetFightEventTemplate(echelon.BuffId)
        return fightEventCfg and fightEventCfg.Description
    end

    function XBfrtManager.GetEchelonRequireAbility(echelonId)
        local echelon = GetEchelonInfo(echelonId)
        return echelon.RequireAbility
    end

    function XBfrtManager.GetEchelonConditionId(echelonId)
        local echelon = GetEchelonInfo(echelonId)
        return echelon.Condition
    end

    function XBfrtManager.GetEchelonNameTxt(echelonType, echelonIndex)
        local echelonNameTxt
        if echelonType == XBfrtManager.EchelonType.Fight then
            echelonNameTxt = CS.XTextManager.GetText("BfrtFightEchelonTitle", echelonIndex)
        elseif echelonType == XBfrtManager.EchelonType.Logistics then
            echelonNameTxt = CS.XTextManager.GetText("BfrtLogisticEchelonTitle", echelonIndex)
        end

        return echelonNameTxt
    end

    function XBfrtManager.GetEchelonInfoShowFightEventIds(echelonId)
        local config = GetEchelonInfo(echelonId)
        return config and config.ShowFightEventIds or {}
    end
    --endregion
    
    --region TaskData
    local function GetChapterTaskIdList(chapterId)
        local chapterCfg = XBfrtManager.GetChapterCfg(chapterId)
        local taskIdList = chapterCfg.TaskId
        if not taskIdList then
            XLog.ErrorTableDataNotFound("XBfrtManager.GetChapterTaskIdList",
                    "TaskId", "Share/Fuben/Bfrt/BfrtChapter.tab", "chapterId", tostring(chapterId))
        end
        return taskIdList
    end

    function XBfrtManager.GetTaskOrderId(taskId)
        return TaskIdToOrderIdDic[taskId]
    end

    function XBfrtManager.GetBfrtTaskId(chapterId)
        local taskIdList = GetChapterTaskIdList(chapterId)
        return taskIdList[1]
    end

    function XBfrtManager.GetChapterTaskDataList(chapterId, isSort)
        if isSort == nil then
            isSort = true
        end
        ---@type XBfrtTaskData[]
        local result = {}
        local cfg = XBfrtManager.GetChapterCfg(chapterId)
        -- 因为新迭代的奖励需要老玩家也兼容，所以不是使用taskId实现
        -- 于是新增Ui数据结构以处理

        -- 奖励
        local rewardList = cfg.RewardIds
        for i, rewardId in ipairs(rewardList) do
            ---@type XBfrtTaskData
            local data = {}
            data.Id = rewardId
            data.State = XBfrtManager._GetRewardTaskDataState(chapterId, i)
            data.IsReward = true
            data.Title = cfg.RewardTitleList[i]
            data.Desc = cfg.RewardDescList[i]
            data.ChapterId = chapterId
            data.GroupId = cfg.GroupId[i]
            data.Schedule = {}
            table.insert(data.Schedule, {
                Id = rewardId,
                Value = data.State ~= XDataCenter.TaskManager.TaskState.Active and 1 or 0
            })
            table.insert(result, data)
        end
        -- 任务
        ---@type XTaskData[]
        local taskDataList = {}
        local taskIdList = cfg.TaskId
        if not XTool.IsTableEmpty(taskIdList) then
            taskDataList = XDataCenter.TaskManager.GetTaskIdListData(taskIdList, true)
        end
        for _, taskData in ipairs(taskDataList) do
            ---@type XBfrtTaskData
            local data = {}
            data.Id = taskData.Id
            data.Schedule = taskData.Schedule
            data.State = taskData.State
            data.IsReward = false
            data.GroupId = 0
            table.insert(result, data)
        end
        if isSort then
            table.sort(result, XBfrtManager._CompareTaskData)
        end
        return result
    end

    function XBfrtManager.GetChapterTaskRewardList(chapterId)
        local result = {}
        local resultDir = {}
        local cfg = XBfrtManager.GetChapterCfg(chapterId)
        -- reward
        local rewardList = cfg.RewardIds
        for _, rewardId in ipairs(rewardList) do
            local rewardDataList = XRewardManager.GetRewardList(rewardId)
            for _, rewardData in ipairs(rewardDataList) do
                if resultDir[rewardData.TemplateId] then
                    result[resultDir[rewardData.TemplateId]].Count = result[resultDir[rewardData.TemplateId]].Count + rewardData.Count
                else
                    table.insert(result, rewardData)
                    resultDir[rewardData.TemplateId] = #result
                end
            end
        end
        -- task
        local taskId = XDataCenter.BfrtManager.GetBfrtTaskId(chapterId)
        local taskConfig = XDataCenter.TaskManager.GetTaskTemplate(taskId)
        local rewardId = taskConfig.RewardId
        local rewards = XRewardManager.GetRewardList(rewardId)
        for _, rewardData in ipairs(rewards) do
            if resultDir[rewardData.TemplateId] then
                result[resultDir[rewardData.TemplateId]].Count = result[resultDir[rewardData.TemplateId]].Count + rewardData.Count
            else
                table.insert(result, rewardData)
                resultDir[rewardData.TemplateId] = #result
            end
        end
        XRewardManager.SortRewardGoodsList(result)
        return result
    end

    ---@param dataA XBfrtTaskData
    ---@param dataB XBfrtTaskData
    function XBfrtManager._CompareTaskData(dataA, dataB)
        if dataA.State ~= dataB.State then
            return XBfrtManager._State2Num(dataA.State) > XBfrtManager._State2Num(dataB.State)
        end
        if dataA.IsReward ~= dataB.IsReward then
            return dataA.IsReward
        end
        if dataA.GroupId ~= dataB.GroupId then
            return dataA.GroupId < dataB.GroupId
        end
        return dataA.Id < dataB.Id
    end

    function XBfrtManager._State2Num(state)
        if state == XDataCenter.TaskManager.TaskState.Achieved then
            return 1
        end
        if state == XDataCenter.TaskManager.TaskState.Finish then
            return -1
        end
        return 0
    end

    ---@return number XTaskManager.TaskState
    function XBfrtManager._GetRewardTaskDataState(chapterId, index)
        local cfg = XBfrtManager.GetChapterCfg(chapterId)
        local groupId = cfg.GroupId[index]
        if XBfrtManager._CheckChapterGroupPass(chapterId, index) then
            if XBfrtManager.CheckGroupRewardRecv(groupId) then
                return XDataCenter.TaskManager.TaskState.Finish
            else
                return XDataCenter.TaskManager.TaskState.Achieved
            end
        end
        return XDataCenter.TaskManager.TaskState.Active
    end

    function XBfrtManager.CheckAnyTaskRewardCanGet(chapterId)
        if not chapterId then
            return false
        end
        local taskDataList = XBfrtManager.GetChapterTaskDataList(chapterId, false)
        for _, taskData in ipairs(taskDataList) do
            if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
                return true
            end
        end
        return false
    end

    function XBfrtManager.CheckAllTaskRewardHasGot(chapterId)
        if not chapterId then
            return false
        end
        local taskDataList = XBfrtManager.GetChapterTaskDataList(chapterId, false)
        for _, taskData in ipairs(taskDataList) do
            if taskData.State ~= XDataCenter.TaskManager.TaskState.Finish then
                return false
            end
        end
        return true
    end

    function XBfrtManager.CheckAllChapterReward()
        if not ChapterDic then return false end
        for _, chapterId in pairs(ChapterDic) do
            if XBfrtManager.CheckAnyTaskRewardCanGet(chapterId) then
                return true
            end
        end
        return false
    end

    function XBfrtManager._CheckChapterGroupPass(chapterId, index)
        local groupIdList = XBfrtManager.GetChapterGroupList(chapterId)
        local groupId = groupIdList[index]
        if not XTool.IsNumberValid(groupId) then
            return false
        end
        return XBfrtManager.CheckGroupIsPass(groupId)
    end
    --endregion
    
    --region CourseReward 历程奖励
    function XBfrtManager.GetCourseRewardStarCount()
        return BfrtData.CourseRewardStar or 0
    end

    function XBfrtManager._SetCourseRewardStarCount(value)
        BfrtData.CourseRewardStar = value
    end

    function XBfrtManager.GetBfrtImportantRewardId(chapterId)
        local result = false
        for _, info in ipairs(_CourseImpRewardChapterList) do
            if info.ChapterId == chapterId then
                return info.RewardId
            end
            -- 返回下一个标记
            if info.ChapterId > chapterId then
                return info.RewardId
            end
        end
        return result
    end
    
    function XBfrtManager.GetBfrtRewardList()
        return XBfrtConfigs.GetBfrtRewardTemplates()
    end

    function XBfrtManager.GetBfrtReward(bfrtRewardId)
        return XBfrtConfigs.GetBfrtRewardTemplateById(bfrtRewardId)
    end

    function XBfrtManager.GetBfrtRewardShowItemList(bfrtRewardId, index)
        local cfg = XBfrtConfigs.GetBfrtRewardTemplateById(bfrtRewardId)
        local result = {}
        if cfg.ShowItems and cfg.ShowItems[index] then
            return XBfrtManager.GetBfrtRewardShowItemListByStr(cfg.ShowItems[index])
        end
        return result
    end

    function XBfrtManager.GetBfrtRewardShowItemListByStr(showItemStr)
        local result = {}
        --切割字符串
        local idStrs = string.Split(showItemStr,'|')
        for _, id in ipairs(idStrs) do
            table.insert(result, tonumber(id))
        end
        return result
    end
    
    function XBfrtManager.CheckCourseRewardIsRecv(bfrtRewardId, index)
        local bfrtRewardCfg = XBfrtManager.GetBfrtReward(bfrtRewardId)
        if not bfrtRewardCfg then
            return false
        end
        local recvRewardStar = XBfrtManager.GetCourseRewardStarCount()
        if index then
            if XTool.IsNumberValid(bfrtRewardCfg.CourseStars[index]) then
                return recvRewardStar >= bfrtRewardCfg.CourseStars[index]
            end
            return false 
        end
        for _, startCount in pairs(bfrtRewardCfg.CourseStars) do
            if recvRewardStar < startCount then
                return false
            end
        end
        return true
    end
    
    function XBfrtManager.CheckCanRecvCourseReward(chapterId)
        local bfrtRewardId = XBfrtManager.GetChapterCourseRewardId(chapterId)
        local bfrtRewardCfg = XBfrtManager.GetBfrtReward(bfrtRewardId)
        if not bfrtRewardCfg then
            return false
        end
        local recvRewardStar = XBfrtManager.GetCourseRewardStarCount()
        local allPassCount = XBfrtManager.GetAllChapterPassCount()
        for _, startCount in ipairs(bfrtRewardCfg.CourseStars) do
            if recvRewardStar < startCount and allPassCount >= startCount then
                return true
            end
        end
        return false
    end
    
    function XBfrtManager.CheckAnyCourseRewardRecv()
        local recvRewardStar = XBfrtManager.GetCourseRewardStarCount()
        local allPassCount = XBfrtManager.GetAllChapterPassCount()
        for _, cfg in ipairs(XBfrtManager.GetBfrtRewardList()) do
            local recvStarCountList = cfg.CourseStars
            for _, count in ipairs(recvStarCountList) do
                if recvRewardStar < count and allPassCount >= count then
                    return true
                end
            end
        end
        return false
    end
    
    function XBfrtManager.CheckCourseRewardCanRecv(rewardId, index)
        local allPassCount = XBfrtManager.GetAllChapterPassCount()
        local cfg = XBfrtManager.GetBfrtReward(rewardId)
        return allPassCount >= cfg.CourseStars[index]
    end
    --endregion
    
    --region StageRecord
    function XBfrtManager.UpdateStageInfo(isIgnoreInit)
        if _IsInitStageInfo and not isIgnoreInit then
            return
        end
        for groupId, groupCfg in pairs(BfrtGroupTemplates) do
            local groupInfo = GroupInfos[groupId]
            for _, v in pairs(groupCfg.StageId) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(v)
                if not stageInfo then
                    local tmpStr = "XBfrtManager InitStageInfo错误, 无法根据 Share/Fuben/Bfrt/BfrtGroup.tab 表里面的stageId"
                    XLog.Error(tmpStr .. v .. " 找到Share/Fuben/Stage.tab 表中的表项")
                    break
                end

                stageInfo.IsOpen = true
                stageInfo.Unlock = groupInfo and groupInfo.Unlock or false
                stageInfo.ChapterId = groupInfo and groupInfo.ChapterId

            end

            local baseStageInfo = XDataCenter.FubenManager.GetStageInfo(groupCfg.BaseStage)
            baseStageInfo.IsOpen = true
            baseStageInfo.Unlock = groupInfo and groupInfo.Unlock or false
            baseStageInfo.ChapterId = groupInfo and groupInfo.ChapterId
        end
        if not isIgnoreInit then
            _IsInitStageInfo = true
        end
    end
    
    function XBfrtManager.TipStageIsPass()
        XUiManager.TipErrorWithKey("BfrtBanChangeTeam")
    end
    
    function XBfrtManager.GetGroupStageRecordIndex(groupId)
        local stageIdList = XBfrtManager._GetGroupRecordStageList(groupId)
        if XTool.IsTableEmpty(stageIdList) then
            return false
        end
        local passStageIdListDir = {}
        for _, stageId in ipairs(stageIdList) do
            passStageIdListDir[stageId] = true
        end
        for i, stageId in ipairs(XBfrtManager.GetStageIdList(groupId)) do
            if not passStageIdListDir[stageId] then
                return i
            end
        end
        return false
    end
    
    function XBfrtManager.CheckAndDialogGroupStageRecord(groupId, cb)
        local processData = BfrtData.BfrtProgressInfo
        if XTool.IsTableEmpty(processData) or not XTool.IsNumberValid(processData.GroupId) or processData.GroupId == groupId then
            return false
        end
        local chapterId = XBfrtManager.GetGroupChapterId(processData.GroupId)
        local groupCfg = BfrtGroupTemplates[processData.GroupId]
        local text = XUiHelper.GetText("BfrtHaveStageRecord", XBfrtManager.GetChapterEn(chapterId), groupCfg.GroupName)
        XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), text, XUiManager.DialogType.Normal, nil, function()
            XBfrtManager.RequestResetGroupStage(nil, true, cb)
        end)
        return true
    end
    
    function XBfrtManager.CheckIsGroupStageRecordStage(groupId, stageId)
        local stageIdList = XBfrtManager._GetGroupRecordStageList(groupId)
        if XTool.IsTableEmpty(stageIdList) then
            return
        end
        for _, passStageId in pairs(stageIdList) do
            if passStageId == stageId then
                return true
            end
        end
        return false
    end
    
    function XBfrtManager.CheckIsGroupStagePassRecord(groupId)
        local processData = BfrtData.BfrtProgressInfo
        if XTool.IsTableEmpty(processData) or not XTool.IsNumberValid(processData.GroupId)  then
            return false
        end
        return processData.GroupId == groupId
    end
    
    function XBfrtManager._GetGroupRecordStageList(groupId)
        local processData = BfrtData.BfrtProgressInfo
        if not XTool.IsNumberValid(groupId)
                or XTool.IsTableEmpty(processData)
                or processData.GroupId ~= groupId
        then
            return false
        end
        return processData.StageIds
    end

    function XBfrtManager._SetGroupStageRecord(data)
        BfrtData.BfrtProgressInfo = data
    end

    function XBfrtManager._ResetGroupRecordStage(stageId)
        if XTool.IsTableEmpty(BfrtData.BfrtProgressInfo) then
            return
        end
        local stageIdList = {}
        for _, id in ipairs(BfrtData.BfrtProgressInfo.StageIds) do
            if id ~= stageId then
                table.insert(stageIdList, id)
            end
        end
        if XTool.IsTableEmpty(stageIdList) then
            BfrtData.BfrtProgressInfo = nil -- 无则为空
        else
            BfrtData.BfrtProgressInfo.StageIds = stageIdList
        end
    end
    --endregion
    
    --region Fuben
    function XBfrtManager.OpenFightLoading()
        return
    end

    function XBfrtManager.CloseFightLoading(stage)
        if CloseLoadingCb then
            CloseLoadingCb()
        end

        local groupId = XBfrtManager.GetGroupIdByStageId(stage)
        local logisticsInfoIdList = XBfrtManager.GetLogisticsInfoIdList(groupId)
        local totalShowTimes = #logisticsInfoIdList
        if totalShowTimes > 0 then
            XLuaUiManager.Open("UiTipBfrtLogisticSkill", groupId)
        end
    end

    function XBfrtManager.SetCloseLoadingCb(cb)
        CloseLoadingCb = cb
    end

    function XBfrtManager.SetFightCb(cb)
        FightCb = cb
    end
    
    function XBfrtManager.FinishStage(stageId)
        local stage = StageDic[stageId]
        if not stage or not stage.IsLastStage then
            return
        end

        local groupId = stage.GroupId
        GroupInfos[groupId].Passed = true

        local findRecord = false
        for _, record in pairs(BfrtData.BfrtGroupRecords) do
            if record.Id == groupId then
                record.Count = record.Count + 1
                findRecord = true
                break
            end
        end

        if not findRecord then
            local record = {
                Id = groupId,
                Count = 1,
            }
            tableInsert(BfrtData.BfrtGroupRecords, record)
        end

        UnlockFollowGroup(groupId)
    end
    
    function XBfrtManager.FinishFight(settle)
        XDataCenter.FubenManager.FinishFight(settle)
        if FightCb then
            FightCb(settle.IsWin)
        end
    end

    function XBfrtManager.ShowReward(winData)
        if XBfrtManager.CheckIsGroupLastStage(winData.StageId) then
            XLuaUiManager.Open("UiBfrtPostWarCount", winData)
        end
    end
    --endregion

    --region FubenEx
    -- 获取进度提示
    function XBfrtManager:ExGetProgressTip()
        RefreshChapterPassed()

        local strProgress = ""
        if not self:ExGetIsLocked() then
            -- 进度
            local passCount = 0
            local allCount = 0
            for k, info in pairs(ChapterInfos) do
                if info.Passed then
                    passCount = passCount + 1
                end
                allCount = allCount + 1
            end
            strProgress = CS.XTextManager.GetText("BfrtAllChapterProgress", passCount, allCount)
        end

        return strProgress
    end

    function XBfrtManager:ExOpenMainUi()
        if not XFunctionManager.DetectionFunction(self:ExGetFunctionNameType()) then
            return
        end

        --分包资源检测
        if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.FuBen.ChapterType.Bfrt) then
            return
        end

        XLuaUiManager.Open("UiNewFubenChapterBfrt")
    end
    --endregion
    
    --region Team
    local function CheckFightTeamCondition(groupId, teamList)
        local infoList = XBfrtManager.GetFightInfoIdList(groupId)

        for k, echelonId in pairs(infoList) do
            local team = teamList[k]
            if not team then
                return false
            end

            if not CheckTeamLimit(echelonId, team) then
                return false
            end
        end

        return true
    end

    local function CheckLogisticsTeamCondition(groupId, teamList)
        local infoList = XBfrtManager.GetLogisticsInfoIdList(groupId)

        if not infoList or not next(infoList) then
            return true
        end

        for k, echelonId in pairs(infoList) do
            local team = teamList[k]
            if not team or not CheckTeamLimit(echelonId, team) then
                return false
            end
        end

        return true
    end
    
    function XBfrtManager.TeamPosConvert(index)
        return TEAM_POS_DIC[index]
    end

    function XBfrtManager.MemberIndexConvert(pos)
        for index, dicPos in pairs(TEAM_POS_DIC) do
            if pos == dicPos then
                return index
            end
        end
    end

    function XBfrtManager.AutoTeam(groupId)
        local anyMemberInTeam = false
        local fightTeamList = {}
        local logisticsTeamList = {}
        local sortTeamInfoList = {}
        local fightInfoIdList = XBfrtManager.GetFightInfoIdList(groupId)
        local stageIds = XBfrtManager.GetStageIdList(groupId)
        
        local curFightTeamList = XBfrtManager.GetFightTeamList(groupId)
        local curLogisticsTeamList = XBfrtManager.GetLogisticsTeamList(groupId)
        local curRecordCharacterDir = {}
        
        for i, echelonId in ipairs(fightInfoIdList) do
            if XBfrtManager.CheckIsGroupStageRecordStage(groupId, stageIds[i]) then
                for _, id in ipairs(curFightTeamList[i]) do
                    curRecordCharacterDir[id] = true
                end
                tableInsert(fightTeamList, curFightTeamList[i])
            else
                local fightTeam = { 0, 0, 0 }
                tableInsert(fightTeamList, fightTeam)

                local echelonCfg = GetEchelonInfo(echelonId)
                local teamInfo = {
                    Index = i,
                    RequireAbility = echelonCfg.RequireAbility,
                    NeedCharacter = echelonCfg.NeedCharacter,
                    Team = fightTeam,
                    StageId = stageIds[i],
                }
                tableInsert(sortTeamInfoList, teamInfo)
            end
        end

        local logisticsInfoIdList = XBfrtManager.GetLogisticsInfoIdList(groupId)
        for i, echelonId in ipairs(logisticsInfoIdList) do
            if XBfrtManager.CheckIsGroupStageRecordStage(groupId, stageIds[i]) then
                for _, id in ipairs(curLogisticsTeamList[i]) do
                    curRecordCharacterDir[id] = true
                end
                tableInsert(fightTeamList, curLogisticsTeamList[i])
            else
                local logisticsTeam = { 0, 0, 0 }
                tableInsert(logisticsTeamList, logisticsTeam)

                local echelonCfg = GetEchelonInfo(echelonId)
                local teamInfo = {
                    Index = i,
                    RequireAbility = echelonCfg.RequireAbility,
                    NeedCharacter = echelonCfg.NeedCharacter,
                    Team = logisticsTeam,
                    StageId = stageIds[i],
                }
                tableInsert(sortTeamInfoList, teamInfo)
            end
        end

        tableSort(sortTeamInfoList, function(a, b)
            if a.RequireAbility ~= b.RequireAbility then
                return a.RequireAbility > b.RequireAbility
            end
            return a.Index < b.Index
        end)

        local ownCharacters = XDataCenter.CharacterManager.GetOwnCharacterList()
        tableSort(ownCharacters, function(a, b)
            return a.Ability > b.Ability
        end)

        for _, teamInfo in pairs(sortTeamInfoList) do
            if not next(ownCharacters) then break end

            local characterLimitType = XFubenConfigs.GetStageCharacterLimitType(teamInfo.StageId)
            local defaultCharacterType = XDataCenter.FubenManager.GetDefaultCharacterTypeByCharacterLimitType(characterLimitType)
            for memberIndex = 1, teamInfo.NeedCharacter do
                for index, character in ipairs(ownCharacters) do
                    if not curRecordCharacterDir[character.Id] then
                        -- if character.Ability >= teamInfo.RequireAbility then
                        local charType = XMVCA.XCharacter:GetCharacterType(character.Id)
                        if defaultCharacterType ~= XFubenConfigs.CharacterLimitType.All and defaultCharacterType ~= charType then
                            goto SELECT_CONTINUE
                        end
                        teamInfo.Team[memberIndex] = character.Id
                        tableRemove(ownCharacters, index)
                        anyMemberInTeam = true
                        break
                        -- end
                        :: SELECT_CONTINUE ::
                    end
                end
            end
        end


        return fightTeamList, logisticsTeamList, anyMemberInTeam
    end

    function XBfrtManager.GetTeamCaptainPos(echelonId, groupId, stageIndex)
        local captainPos = EchlonTeamPosDic[echelonId]
        local preGroupId = XBfrtConfigs.GetBfrtPreGroupId(groupId)
        if not captainPos and XTool.IsNumberValid(preGroupId) then
            local stageIdList = XBfrtManager.GetStageIdList(preGroupId)
            echelonId = stageIdList and stageIdList[stageIndex]
            captainPos = echelonId and EchlonTeamPosDic[echelonId]
        end
        return captainPos or XEnumConst.BFRT.CAPTIAN_MEMBER_INDEX
    end

    function XBfrtManager.SetTeamCaptainPos(echelonId, captainPos)
        EchlonTeamPosDic[echelonId] = captainPos
    end

    function XBfrtManager.SetServerTeamCaptainPos(echelonId, captainPos)
        EchlonServerTeamPosDic[echelonId] = captainPos
    end

    function XBfrtManager.InitTeamCaptainPos(isClientToServerData)
        if isClientToServerData then
            for echelonId, captainPos in pairs(EchlonTeamPosDic) do
                XBfrtManager.SetServerTeamCaptainPos(echelonId, captainPos)
            end
            return
        end
        for echelonId, captainPos in pairs(EchlonServerTeamPosDic) do
            XBfrtManager.SetTeamCaptainPos(echelonId, captainPos)
        end
    end

    ---==========================================
    --- 得到队伍首发位
    --- 当首发位不为空时，直接返回首发位，否则返回默认首发位
    ---（因为服务器在之前只有队长位，后面区分了队长位与首发位，存在有队长位数据，没有首发位数据的情况）
    ---@return number
    ---==========================================
    function XBfrtManager.GetTeamFirstFightPos(echelonId, groupId, stageIndex)
        local firstFightPos = EchlonFirstFightDic[echelonId]
        local preGroupId = XBfrtConfigs.GetBfrtPreGroupId(groupId)
        if not firstFightPos and XTool.IsNumberValid(preGroupId) then
            local stageIdList = XBfrtManager.GetStageIdList(preGroupId)
            echelonId = stageIdList and stageIdList[stageIndex]
            firstFightPos = echelonId and EchlonFirstFightDic[echelonId]
        end
        return firstFightPos or XEnumConst.BFRT.FIRST_FIGHT_MEMBER_INDEX
    end

    function XBfrtManager.SetTeamFirstFightPos(echelonId, firstFightPos)
        EchlonFirstFightDic[echelonId] = firstFightPos
    end

    function XBfrtManager.SetServerTeamFirstFightPos(echelonId, firstFightPos)
        EchlonServerFirstFightDic[echelonId] = firstFightPos
    end

    function XBfrtManager.InitTeamFirstFightPos(isClientToServerData)
        if isClientToServerData then
            for echelonId, firstFightPos in pairs(EchlonFirstFightDic) do
                XBfrtManager.SetServerTeamFirstFightPos(echelonId, firstFightPos)
            end
            return
        end
        for echelonId, firstFightPos in pairs(EchlonServerFirstFightDic) do
            XBfrtManager.SetTeamFirstFightPos(echelonId, firstFightPos)
        end
    end
    --endregion

    --region Rpc
    function XBfrtManager.RequestSetTeam(groupId, fightTeamList, logisticsTeamList, cb)
        if not CheckFightTeamCondition(groupId, fightTeamList) then
            XUiManager.TipText("FightTeamConditionLimit")
            return
        end

        if not CheckLogisticsTeamCondition(groupId, logisticsTeamList) then
            XUiManager.TipText("LogisticsTeamConditionLimit")
            return
        end

        local captainList = {}
        local firstFightPosList = {}
        local fightInfoIdList = XBfrtManager.GetFightInfoIdList(groupId)
        for i, echelonId in ipairs(fightInfoIdList) do
            local captainPos = XBfrtManager.GetTeamCaptainPos(echelonId, groupId, i)
            if not XTool.IsNumberValid(fightTeamList[i] and fightTeamList[i][captainPos]) then
                XUiManager.TipMsg(XUiHelper.GetText("BfrtNotCaptain", i))
                return
            end
            tableInsert(captainList, captainPos)

            local firstFightPos = XBfrtManager.GetTeamFirstFightPos(echelonId, groupId, i)
            if not XTool.IsNumberValid(fightTeamList[i] and fightTeamList[i][firstFightPos]) then
                XUiManager.TipMsg(XUiHelper.GetText("BfrtNotFirstFight", i))
                return
            end
            tableInsert(firstFightPosList, firstFightPos)
        end

        XNetwork.Call(METHOD_NAME.BfrtTeamSetRequest, {
            BfrtGroupId = groupId,
            FightTeam = fightTeamList, --List<List<int /*characterId*/> /*characterId list*/>
            LogisticsTeam = logisticsTeamList, --List<List<int /*characterId*/> /*characterId list*/>
            CaptainPosList = captainList,
            FirstFightPosList = firstFightPosList,
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            FightTeams[groupId] = fightTeamList
            LogisticsTeams[groupId] = logisticsTeamList
            XBfrtManager.InitTeamCaptainPos(true)
            XBfrtManager.InitTeamFirstFightPos(true)

            if cb then
                cb()
            end
        end)
    end

    --- 快速通关
    function XBfrtManager.RequestFastPassGroup(chapterId, groupId, cb)
        local req = {
            BfrtChapterId = chapterId,
            BfrtGroupId = groupId
        }
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.BfrtOneKeyPassGroupRequest, req, function(res)
            if not XTool.IsTableEmpty(res.RewardGoodsList) then
                XUiManager.OpenUiObtain(res.RewardGoodsList)
            end
            if res.BfrtGroupRecord then
                XBfrtManager._UpdateGroupInfo(res.BfrtGroupRecord)
                XDataCenter.BfrtManager.UpdateStageInfo(true)
            end
            XEventManager.DispatchEvent(XEventId.EVENT_BFRT_FAST_PASS)
            if cb then
                cb()
            end
        end)
    end

    --- 重置关卡
    function XBfrtManager.RequestResetGroupStage(bfrtStageId, isClear, cb)
        local req = {
            BfrtStageId = bfrtStageId or 0,
            IsClear = isClear
        }
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.BfrtResetGroupStageRequest, req, function(res)
            if isClear then
                XBfrtManager._SetGroupStageRecord(nil)
            else
                XBfrtManager._ResetGroupRecordStage(bfrtStageId)
                XEventManager.DispatchEvent(XEventId.EVENT_BFRT_RESET_STAGE_RECORD, bfrtStageId)
            end
            if cb then
                cb()
            end
        end)
    end

    --- 领取历程奖励
    function XBfrtManager.RequestReceiveCourseReward(cb)
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.BfrtReceiveCourseRewardRequest, {}, function(res)
            XBfrtManager._SetCourseRewardStarCount(res.CourseRewardStar)
            XUiManager.OpenUiObtain(res.RewardGoodsList)
            XEventManager.DispatchEvent(XEventId.EVENT_BFRT_COURSE_REWARD_RECV)
            if cb then
                cb()
            end
        end)
    end

    --- 领取章节关卡奖励
    function XBfrtManager.RequestReceiveChapterGroupReward(chapterId, groupId)
        local req = {
            BfrtChapterId = chapterId,
            BfrtGroupId = groupId
        }
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.BfrtReceiveChapterGroupRewardRequest, req, function(res)
            XBfrtManager._SetGroupRewardRecv(groupId)
            XUiManager.OpenUiObtain(res.RewardGoodsList)
            XEventManager.DispatchEvent(XEventId.EVENT_BFRT_CHAPTER_REWARD_RECV)
        end)
    end

    function XBfrtManager.NotifyBfrtData(data)
        BfrtData = data.BfrtData
        InitGroupInfo()
        InitChapterInfo()
        InitFollowGroup()
        InitTeamRecords()
    end

    function XBfrtManager.NotifyBfrtProgressInfo(data)
        XBfrtManager._SetGroupStageRecord(data.BfrtProgressInfo)
    end
    --endregion

    XBfrtManager.Init()
    return XBfrtManager
end

XRpc.NotifyBfrtData = function(data)
    XDataCenter.BfrtManager.NotifyBfrtData(data)
end

XRpc.NotifyBfrtProgressInfo = function(data)
    XDataCenter.BfrtManager.NotifyBfrtProgressInfo(data)
end