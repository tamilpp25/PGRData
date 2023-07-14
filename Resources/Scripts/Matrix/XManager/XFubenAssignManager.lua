--- 占领副本管理器
XFubenAssignManagerCreator = function()
    local XFubenAssignManager = {}

    -- 协议
    local METHOD_NAME = {
        AssignGetDataRequest = "AssignGetDataRequest",
        AssignSetTeamRequest = "AssignSetTeamRequest",
        AssignSetCharacterRequest = "AssignSetCharacterRequest",
        AssignGetRewardRequest = "AssignGetRewardRequest",
    }

    -- 常量
    XFubenAssignManager.MaxSelectConditionNum = 4
    XFubenAssignManager.SelectConditionColor = {[true] = CS.UnityEngine.Color.black, [false] = CS.UnityEngine.Color.gray }
    XFubenAssignManager.MemberColor = {
        "FF1111FF", -- red
        "4F99FFFF", -- blue
        "F9CB35FF", -- yellow
    }
    XFubenAssignManager.FomationAnimFinishDelay = 400 -- 特效显示时间
    XFubenAssignManager.FormationState = { Effect = 1, Reset = 2 }
    local CHARACTERTYPE_ALL = 0
    local SKILLTYPE_BITS = 1000
    local KeyAccountEnterAssign = "Assign"

    -- ui操作所缓存的数据
    XFubenAssignManager.SelectChapterId = nil
    XFubenAssignManager.SelectGroupId = nil
    XFubenAssignManager.SelectCharacterId = nil
    XFubenAssignManager.OccupyFirstSelectTeamId = nil
    XFubenAssignManager.OccupyFirstSelectOrder = nil
    XFubenAssignManager.OccupySecondSelectTeamId = nil
    XFubenAssignManager.OccupySecondSelectOrder = nil

    XFubenAssignManager.CAPTIAN_MEMBER_INDEX = 1 -- 队长位置
    XFubenAssignManager.FIRSTFIGHT_MEMBER_INDEX = 1 -- 首发位置
    local MEMBER_MAX_COUNT = 3 -- 队伍最大成员数

    local ChapterIdList = nil
    local ChapterDataDict = nil -- 章节
    local GroupDataDict = nil -- 关卡组
    local TeamDataDict = nil -- 队伍

    ------ 战斗接口用的数据
    local FinishFightCb = nil
    local CloseLoadingCb = nil
    -- local MEMBER_INDEX_BY_ORDER = {[1] = 2, [2] = 1, [3] = 3} -- 面板上显示的位置(order) = 队伍中实际中的位置(index)
    local MEMBER_ORDER_BY_INDEX = {[1] = 2, [2] = 1, [3] = 3 } -- 队伍中实际中的位置(index) = 面板上显示的位置(order)
    local GroupIdByStageId = nil -- {[stageId] = groupId, ...}
    local FollowGroupDict = nil -- {[前置组id] = {后置组id, ...}, ...}


    function XFubenAssignManager.Init()
    end

    function XFubenAssignManager.ClearData()
        XFubenAssignManager.SelectChapterId = nil
        XFubenAssignManager.SelectGroupId = nil
        XFubenAssignManager.SelectCharacterId = nil
        XFubenAssignManager.OccupyFirstSelectTeamId = nil
        XFubenAssignManager.OccupyFirstSelectOrder = nil
        XFubenAssignManager.OccupySecondSelectTeamId = nil
        XFubenAssignManager.OccupySecondSelectOrder = nil

        ChapterIdList = nil
        ChapterDataDict = nil -- 章节
        GroupDataDict = nil -- 关卡组
        TeamDataDict = nil -- 队伍
        FollowGroupDict = nil
    end

    ----------- 章节数据 begin-----------
    local ChapterData = XClass(nil, "ChapterData")
    function ChapterData:Ctor(id)
        self.Id = id
        self.CharacterId = nil -- 驻守角色
        self.Rewarded = false -- 已领奖
        self.IsPassByServer = nil -- 服务器已通关标记
    end
    function ChapterData:GetCfg()
        return XFubenAssignConfigs.GetChapterTemplateById(self.Id)
    end
    function ChapterData:GetId() return self.Id end
    function ChapterData:GetName() return self:GetCfg().ChapterName end
    function ChapterData:GetDesc() return self:GetCfg().ChapterEn end
    function ChapterData:GetOrderId() return self:GetCfg().OrderId end
    function ChapterData:GetIcon() return self:GetCfg().Cover end
    function ChapterData:GetSkillPlusId() return self:GetCfg().SkillPlusId end
    function ChapterData:GetAssignCondition() return self:GetCfg().AssignCondition end
    function ChapterData:GetSelectCharCondition() return self:GetCfg().SelectCharCondition end
    function ChapterData:GetRewardId() return self:GetCfg().RewardId end
    function ChapterData:GetGroupId() return self:GetCfg().GroupId end

    -- 获得所有加成效果的key
    function ChapterData:GetBuffKeys()
        if not self.BuffKeys then
            self.BuffKeys = {}
            local buffConfigId = self:GetSkillPlusId()
            if buffConfigId and buffConfigId ~= 0 then
                local plusConfig = XCharacterConfigs.GetSkillTypePlusTemplate(buffConfigId)
                if plusConfig then
                    local key

                    local isAllMember = (#plusConfig.CharacterType == #XCharacterConfigs.GetAllCharacterCareerIds())
                    if isAllMember then
                        local characterType = CHARACTERTYPE_ALL
                        for _, skillType in ipairs(plusConfig.SkillType) do
                            key = characterType * SKILLTYPE_BITS + skillType
                            table.insert(self.BuffKeys, key)
                        end
                    else
                        for _, characterType in ipairs(plusConfig.CharacterType) do
                            for _, skillType in ipairs(plusConfig.SkillType) do
                                key = characterType * SKILLTYPE_BITS + skillType
                                table.insert(self.BuffKeys, key)
                            end
                        end
                    end
                end
            end
            self.BuffKeys = XFubenAssignManager.SortKeys(self.BuffKeys)
        end
        return self.BuffKeys
    end

    function ChapterData:GetBuffDescList()
        return XFubenAssignManager.GetBuffDescListByKeys(self:GetBuffKeys())
    end

    function ChapterData:IsCharConditionMatch(characterId)
        local isMatch = true
        local conditions = self:GetSelectCharCondition()
        for _, conditionId in ipairs(conditions) do
            if not (XConditionManager.CheckCondition(conditionId, characterId)) then
                isMatch = false
                break
            end
        end
        return isMatch
    end

    function ChapterData:GetProgressStr()
        local groupNum = #self:GetGroupId()
        return math.floor((self:GetPassNum() / groupNum) * 100) .. "%"
    end

    function ChapterData:GetCharacterBodyIcon()
        return XDataCenter.CharacterManager.GetCharHalfBodyImage(self.CharacterId)
    end

    function ChapterData:IsRewarded()
        return self.Rewarded
    end

    function ChapterData:CanReward()
        return (self:IsPass() and not self:IsRewarded())
    end

    function ChapterData:IsUnlock()
        for _, groupId in ipairs(self:GetGroupId()) do
            local groupData = XFubenAssignManager.GetGroupDataById(groupId)
            if groupData and groupData:IsUnlock() then
                return true
            end
        end
        return false
    end

    function ChapterData:CanAssign()
        return self:IsPass() and self:IsMatchAssignCondition()
    end

    -- server api
    function ChapterData:SetRewarded(state)
        self.Rewarded = state
    end

    function ChapterData:GetPassNum()
        local passNum = 0
        for _, groupId in ipairs(self:GetGroupId()) do
            local groupData = XFubenAssignManager.GetGroupDataById(groupId)
            if groupData and groupData:IsPass() then
                passNum = passNum + 1
            end
        end
        return passNum
    end

    function ChapterData:SetIsPassByServer(value)
        self.IsPassByServer = value
    end

    function ChapterData:IsPass()
        if self.IsPassByServer then
            return true
        end
        local groupNum = #self:GetGroupId()
        return (self:GetPassNum() >= groupNum)
    end

    function ChapterData:IsMatchAssignCondition()
        for _, conditionId in ipairs(self:GetAssignCondition()) do
            if not (XConditionManager.CheckCondition(conditionId)) then
                return false
            end
        end
        return true
    end

    function ChapterData:SetCharacterId(characterId)
        self.CharacterId = characterId
    end

    function ChapterData:IsOccupy()
        return (self.CharacterId and self.CharacterId ~= 0)
    end

    function ChapterData:GetCharacterId()
        return self.CharacterId
    end

    function ChapterData:GetOccupyCharacterIcon()
        return XDataCenter.CharacterManager.GetCharBigRoundnessNotItemHeadIcon(self:GetCharacterId())
    end

    function ChapterData:GetOccupyCharacterName()
        return XCharacterConfigs.GetCharacterFullNameStr(self:GetCharacterId())
    end

    -- 是否当前进度章节
    function XFubenAssignManager.IsCurrentChapter(chapterId)
        local passNum = XFubenAssignManager.GetAllChapterPassNum()
        local targetIndex = 0
        for i, id in ipairs(XFubenAssignManager.GetChapterIdList()) do
            if chapterId == id then
                targetIndex = i
                break
            end
        end
        if targetIndex == 0 then
            XLog.Debug("XFubenAssignManager.IsCurrentChapter参数传入了无效的chapterId: " .. tostring(chapterId))
        end
        return (targetIndex == passNum + 1)
    end

    function XFubenAssignManager.GetAllChapterPassNum()
        local passNum = 0
        for _, chapterId in ipairs(XFubenAssignManager.GetChapterIdList()) do
            local chapterData = XFubenAssignManager.GetChapterDataById(chapterId)
            if chapterData:IsPass() then
                passNum = passNum + 1
            end
        end
        return passNum
    end

    function XFubenAssignManager.GetCharacterOccupyChapterId(characterId)
        if characterId and characterId ~= 0 then
            for _, chapterId in ipairs(XFubenAssignManager.GetChapterIdList()) do
                local chapterData = XFubenAssignManager.GetChapterDataById(chapterId)
                if chapterData:GetCharacterId() == characterId then
                    return chapterId
                end
            end
        end
        return nil
    end

    function XFubenAssignManager.GetChapterIdList()
        if not ChapterIdList then
            ChapterIdList = {}
            for id, _ in pairs(XFubenAssignConfigs.GetChapterTemplates()) do
                table.insert(ChapterIdList, id)
            end
            table.sort(ChapterIdList, function(a, b) return a < b end)
        end
        return ChapterIdList
    end

    function XFubenAssignManager.GetUnlockChapterIdList()
        local idList = {}
        local data
        for _, id in ipairs(XFubenAssignManager.GetChapterIdList()) do
            data = XFubenAssignManager.GetChapterDataById(id)
            if data:IsUnlock() then
                table.insert(idList, id)
            end
        end
        return idList
    end

    -- 角色是否已在占领
    function XFubenAssignManager.CheckCharacterInOccupy(characterId)
        local chapterData
        for _, id in ipairs(XFubenAssignManager.GetChapterIdList()) do
            chapterData = XFubenAssignManager.GetChapterDataById(id)
            if chapterData:GetCharacterId() == characterId then
                return true
            end
        end
        return false
    end

    function XFubenAssignManager.GetChapterDataById(id)
        if not id then
            XLog.Error("XFubenAssignManager.GetChapterDataById函数参数id不能为空" .. tostring(id))
            return
        end
        if not ChapterDataDict then
            ChapterDataDict = {}
        end
        if not ChapterDataDict[id] then
            ChapterDataDict[id] = ChapterData.New(id)
        end
        return ChapterDataDict[id]
    end

    function XFubenAssignManager.GetCurrentChapterData()
        local idList = XFubenAssignManager.GetChapterIdList()
        for _, chapterId in ipairs(idList) do
            local chapterData = XFubenAssignManager.GetChapterDataById(chapterId)
            if not chapterData:IsPass() then
                return chapterData
            end
        end
        return XFubenAssignManager.GetChapterDataById(idList[#idList])
    end

    function XFubenAssignManager.GetChapterProgressTxt()
        local chapterData = XFubenAssignManager.GetCurrentChapterData()
        return CS.XTextManager.GetText("AssignChapterProgressTxt", chapterData:GetDesc())
    end
    ----------- 章节数据 end-----------
    ----------- 关卡组数据 begin-----------
    local GroupData = XClass(nil, "GroupData")
    function GroupData:Ctor(id)
        self.Id = id
        self.FightCount = 0
        self.GroupRebootCount = 0
        self.IsPerfect = false
    end
    function GroupData:GetCfg()
        return XFubenAssignConfigs.GetGroupTemplateById(self.Id)
    end
    function GroupData:GetId() return self.Id end
    function GroupData:GetPreGroupId() return self:GetCfg().PreGroupId end
    -- function GroupData:GetMaxFightCount() return self:GetCfg().ChallengeNum end
    function GroupData:GetTeamInfoId() return self:GetCfg().TeamInfoId end
    function GroupData:GetBaseStageId() return self:GetCfg().BaseStage end
    function GroupData:GetStageId() return self:GetCfg().StageId end
    function GroupData:GetName() return self:GetCfg().Name end
    function GroupData:GetIcon() return self:GetCfg().Icon end

    function GroupData:IsUnlock()
        if self:GetFightCount() > 0 then
            return true
        end
        local preGroupId = self:GetPreGroupId()
        return ((not preGroupId or preGroupId == 0) or XFubenAssignManager.GetGroupDataById(preGroupId):IsPass())
    end

    -- 刷新关卡解锁信息
    function GroupData:SyncStageInfo(isPass)
        local isUnlock = self:IsUnlock()
        for _, stageId in ipairs(self:GetStageId()) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            stageInfo.Unlock = isUnlock
            if isPass ~= nil then
                stageInfo.Passed = isPass
            end
        end
        local baseStageId = self:GetBaseStageId()
        local baseStageInfo = XDataCenter.FubenManager.GetStageInfo(baseStageId)
        baseStageInfo.Unlock = isUnlock
        if isPass ~= nil then
            baseStageInfo.Passed = isPass
        end

        if isUnlock then
            XFubenAssignManager.UnlockFollowGroupStage(self:GetId())
        end
    end

    -- server api
    function GroupData:SetFightCount(count)
        count = count or 0
        local oldCount = self.FightCount
        self.FightCount = count
        if (not oldCount or oldCount == 0) and (count > 0) then -- 新解锁
            self:SyncStageInfo(true)
        end
    end

    function GroupData:GetFightCount()
        -- do return 1 end -- for testing
        return self.FightCount
    end
    function GroupData:SetIsPerfect(isPerfect)
        self.IsPerfect = isPerfect
    end
    function GroupData:GetIsPerfect()
        return self.IsPerfect
    end
    function GroupData:SetGroupRebootCountAdd( rebootCount )
        self.GroupRebootCount = self.GroupRebootCount + rebootCount
    end
    function GroupData:GetGroupRebootCount()
        return self.GroupRebootCount
    end
    function GroupData:ResetGroupRebootCount()
        self.GroupRebootCount = 0
    end
    function GroupData:IsPass()
        if self:GetFightCount() > 0 then
            return true
        end
        return false
        -- -- 根据StageInfo来  来源于XFubenManager.InitFubenData
        -- local stageInfo = XDataCenter.FubenManager.GetStageInfo(self:GetBaseStageId())
        -- return (stageInfo and stageInfo.Passed)
    end

    function XFubenAssignManager.GetGroupDataById(id)
        if not GroupDataDict then
            GroupDataDict = {}
        end
        if not GroupDataDict[id] then
            GroupDataDict[id] = GroupData.New(id)
        end
        return GroupDataDict[id]
    end
    ----------- 关卡组数据 end-----------
    ----------- 队伍数据 begin-----------
    ------- 队员数据
    local MemberData = XClass(nil, "MemberData")
    function MemberData:Ctor(index)
        self.Index = index -- 队伍位置
        self.CharacterId = nil
    end
    function MemberData:GetIndex() return self.Index end
    function MemberData:GetCharacterId() return self.CharacterId end
    function MemberData:HasCharacter() return (self.CharacterId and self.CharacterId ~= 0) end

    function MemberData:SetCharacterId(characterId)
        self.CharacterId = characterId
    end

    function MemberData:GetCharacterAbility()
        return self:HasCharacter() and XDataCenter.CharacterManager.GetCharacterAbilityById(self.CharacterId) or 0
    end

    function MemberData:GetCharacterSkillInfo()
        return self:HasCharacter() and XDataCenter.CharacterManager.GetCaptainSkillInfo(self.CharacterId) or nil
    end

    function MemberData:GetCharacterType()
        return self:HasCharacter() and XCharacterConfigs.GetCharacterType(self.CharacterId)
    end

    -------队伍数据
    local TeamData = XClass(nil, "TeamData")
    function TeamData:Ctor(id)
        self.Id = id
        self.MemberList = nil
        self.LeaderIndex = nil
        self.FirstFightIndex = nil
    end
    function TeamData:GetCfg()
        return XFubenAssignConfigs.GetTeamInfoTemplateById(self.Id)
    end
    function TeamData:GetId() return self.Id end
    function TeamData:GetBuffId() return self:GetCfg().BuffId end
    function TeamData:GetNeedCharacter() return self:GetCfg().NeedCharacter end
    function TeamData:GetRequireAbility() return self:GetCfg().RequireAbility end
    function TeamData:GetCondition() return self:GetCfg().Condition end
    function TeamData:GetDesc() return self:GetCfg().Desc end

    function TeamData:GetMemberList()
        if not self.MemberList then
            self.MemberList = {}
            local count = self:GetNeedCharacter()
            for i = 1, count do
                self.MemberList[i] = MemberData.New(i)  -- 队伍位置
            end
            if count > 1 then -- 若是多人队伍则队长居中, 即队员索引为{2, 1, 3}
                self.MemberList[1], self.MemberList[2] = self.MemberList[2], self.MemberList[1]
            end
        end
        return self.MemberList
    end

    function TeamData:ClearMemberList()
        if not self.MemberList then return end
        for _, memberData in pairs(self.MemberList) do
            memberData:SetCharacterId(0)
        end
    end

    function TeamData:GetCharacterType()
        if not self.MemberList then return end
        for _, memberData in pairs(self.MemberList) do
            if memberData:HasCharacter() then
                return memberData:GetCharacterType()
            end
        end
    end

    function TeamData:GetMember(index)
        for _, member in ipairs(self:GetMemberList()) do
            if member:GetIndex() == index then
                return member
            end
        end
        XLog.Error("TeamData:GetMember函数无效参数index: " .. tostring(index))
        return nil
    end

    function TeamData:SetLeaderIndex(index)
        self.LeaderIndex = index
    end

    function TeamData:GetLeaderIndex()
        return self.LeaderIndex or XFubenAssignManager.CAPTIAN_MEMBER_INDEX
    end

    function TeamData:SetFirstFightIndex(index)
        self.FirstFightIndex = index
    end

    ---==========================================
    --- 得到队伍首发位
    --- 当首发位不为空时，直接返回首发位
    --- 不然查看队长位是否为空，不为空则返回队长位
    ---（因为服务器在之前只有队长位，后面区分了队长位与首发位，存在有队长位数据，没有首发位数据的情况）
    --- 如果队长位也为空，则返回默认首发位
    ---@return number
    ---==========================================
    function TeamData:GetFirstFightIndex()
        return self.FirstFightIndex or self.LeaderIndex or XFubenAssignManager.FIRSTFIGHT_MEMBER_INDEX
    end

    function TeamData:GetLeaderSkillDesc()
        local memberData = self:GetMember(self:GetLeaderIndex())
        if memberData then
            local captianSkillInfo = memberData:GetCharacterSkillInfo()
            if captianSkillInfo then
                return captianSkillInfo.Level > 0 and captianSkillInfo.Intro or string.format("%s%s", captianSkillInfo.Intro, CS.XTextManager.GetText("CaptainSkillLock"))
            end
        end
        return ""
    end

    function TeamData:IsEnoughAbility()
        local memberList = self:GetMemberList()
        local need = self:GetRequireAbility()
        for _, member in pairs(memberList) do
            if member:GetCharacterAbility() > need then
                return true
            end
        end
        return false
    end

    function TeamData:SetMember(order, characterId)
        self:GetMemberList()[order]:SetCharacterId(characterId)
    end

    -- 获得角色在队伍中的排序
    function TeamData:GetCharacterOrder(characterId)
        for order, v in pairs(self:GetMemberList()) do
            if v:GetCharacterId() == characterId then
                return order
            end
        end
        return nil
    end

    -- server api
    function TeamData:SetMemberList(characterIdList)
        if characterIdList then
            local memberList = self:GetMemberList()
            local memberCount = #memberList
            for index, v in pairs(memberList) do
                local order = XFubenAssignManager.GetMemberOrderByIndex(index, memberCount)
                v:SetCharacterId(characterIdList[order])
            end
        else
            for _, v in pairs(self:GetMemberList()) do
                v:SetCharacterId(nil)
            end
        end
    end

    -- 角色是否已在队伍中
    function XFubenAssignManager.CheckCharacterInTeam(characterId)
        for _, teamData in pairs(TeamDataDict) do
            if teamData:GetCharacterOrder(characterId) ~= nil then
                return true
            end
        end
        return false
    end

    -- 获取其他队伍的角色
    function XFubenAssignManager.GetOtherTeamCharacters(groupId, srcTeamId)
        local otherTeamCharacters = {}
        for _, teamId in pairs(GroupDataDict[groupId]:GetTeamInfoId()) do
            if teamId ~= srcTeamId and TeamDataDict[teamId] then
                for i, member in ipairs(TeamDataDict[teamId]:GetMemberList()) do
                    local characterId = member:GetCharacterId()
                    if characterId and characterId ~= 0 then
                        table.insert(otherTeamCharacters, { teamId, i, characterId })
                    end
                end
            end
        end
        return otherTeamCharacters
    end

    -- 获取某组里 角色对应的队伍编号
    function XFubenAssignManager.GetCharacterTeamOderMapByGroup(groupId)
        local teamOrderMap = {}
        local teamIdMap = {}
        for i, teamId in pairs(GroupDataDict[groupId]:GetTeamInfoId()) do
            local teamData = XFubenAssignManager.GetTeamDataById(teamId)
            for _, memberData in ipairs(teamData:GetMemberList()) do
                if memberData:HasCharacter() then
                    teamIdMap[memberData:GetCharacterId()] = teamId
                    teamOrderMap[memberData:GetCharacterId()] = i
                end
            end
        end
        return teamIdMap, teamOrderMap
    end


    function XFubenAssignManager.SetTeamMember(teamId, targetOrder, characterId)
        local targetTeamData = XFubenAssignManager.GetTeamDataById(teamId)
        -- -- 检查所有队伍并清除该characterId
        -- local order = nil
        -- for k, teamData in pairs(TeamDataDict) do
        --     order = teamData:GetCharacterOrder(characterId)
        --     if order ~= nil then
        --         teamData:SetMember(order, nil)
        --         break
        --     end
        -- end
        targetTeamData:SetMember(targetOrder, characterId)
    end

    function XFubenAssignManager.GetTeamDataById(id)
        if not TeamDataDict then
            TeamDataDict = {}
        end
        if not TeamDataDict[id] then
            TeamDataDict[id] = TeamData.New(id)
        end
        return TeamDataDict[id]
    end

    function XFubenAssignManager.GetTeamCharacterType(teamId)
        local teamData = XFubenAssignManager.GetTeamDataById(teamId)
        return teamData:GetCharacterType()
    end

    function XFubenAssignManager.IsCharacterInTeamById(teamId, characterId)
        local teamData = XFubenAssignManager.GetTeamDataById(teamId)
        return teamData:GetCharacterOrder(characterId) ~= nil
    end

    function XFubenAssignManager.GetGroupMemberCount(groupId)
        local count = 0
        for _, teamId in pairs(GroupDataDict[groupId]:GetTeamInfoId()) do
            for _, member in ipairs(XFubenAssignManager.GetTeamDataById(teamId):GetMemberList()) do
                if member:HasCharacter() then
                    count = count + 1
                end
            end
        end
        return count
    end

    -- 一键上阵
    function XFubenAssignManager.AutoTeam(groupId)
        local ownCharacters = XDataCenter.CharacterManager.GetOwnCharacterList()
        table.sort(ownCharacters, function(a, b)
            return a.Ability > b.Ability
        end)
        -- 保留当前角色
        -- local curCharacters = XFubenAssignManager.GetOtherTeamCharacters(groupId, nil)
        local count = 1
        local maxCount = #ownCharacters
        for _, teamId in pairs(GroupDataDict[groupId]:GetTeamInfoId()) do
            if count > maxCount then
                break
            end
            local teamData = XFubenAssignManager.GetTeamDataById(teamId)
            local needCount = teamData:GetNeedCharacter()
            for index = 1, needCount do
                local order = XFubenAssignManager.GetMemberOrderByIndex(index, needCount)
                local targetTeamData = XFubenAssignManager.GetTeamDataById(teamId)

                local stageId = teamId
                local characterLimitType = XFubenConfigs.GetStageCharacterLimitType(teamId)
                local defaultCharacterType = XDataCenter.FubenManager.GetDefaultCharacterTypeByCharacterLimitType(characterLimitType)

                local i
                for charIndex, char in ipairs(ownCharacters) do
                    local charType = XCharacterConfigs.GetCharacterType(char.Id)
                    if defaultCharacterType ~= XFubenConfigs.CharacterLimitType.All and defaultCharacterType ~= charType then
                        goto CONTINUE
                    end
                    XFubenAssignManager.SetTeamMember(teamId, order, char.Id)
                    i = charIndex
                    break
                    :: CONTINUE ::
                end
                if i then
                    table.remove(ownCharacters, i)
                end
            end
        end
    end

    -- 是否满足关卡所需战力
    function XFubenAssignManager.IsAbilityMatch(targetStageId, charIdList)
        local groupId = XFubenAssignManager.GetGroupIdByStageId(targetStageId)
        local groupData = XFubenAssignManager.GetGroupDataById(groupId)
        local isMatch = false
        local teamIdList = groupData:GetTeamInfoId()
        for i, stageId in pairs(groupData:GetStageId()) do
            if stageId == targetStageId then
                isMatch = true
                local teamId = teamIdList[i]
                local teamData = XFubenAssignManager.GetTeamDataById(teamId)
                for order = 1, teamData:GetNeedCharacter() do
                    local characterId = charIdList[order]
                    local character = XDataCenter.CharacterManager.GetCharacter(characterId)
                    if character.Ability < teamData:GetRequireAbility() then
                        isMatch = false
                        break
                    end
                end
                break
            end
        end
        return isMatch
    end
    ----------- 队伍数据 end-----------
    ----------- 战斗接口 begin-----------
    function XFubenAssignManager.SetCloseLoadingCb(cb)
        CloseLoadingCb = cb
    end

    function XFubenAssignManager.SetFinishFightCb(cb)
        FinishFightCb = cb
    end

    -- function XFubenAssignManager.GetMemberIndexByOrder(order)
    --     return MEMBER_INDEX_BY_ORDER[order]
    -- end
    function XFubenAssignManager.GetMemberOrderByIndex(index, maxCount)
        return maxCount > 1 and MEMBER_ORDER_BY_INDEX[index] or index
    end

    function XFubenAssignManager.GetGroupIdByStageId(stageId)
        if not GroupIdByStageId then
            GroupIdByStageId = {}
            local GroupTemplates = XFubenAssignConfigs.GetGroupTemplates()
            local groupData
            for groupId, _ in pairs(GroupTemplates) do
                groupData = XFubenAssignManager.GetGroupDataById(groupId)
                for _, id in ipairs(groupData:GetStageId()) do
                    GroupIdByStageId[id] = groupId
                end
            end
        end
        return GroupIdByStageId[stageId]
    end

    function XFubenAssignManager.CheckIsGroupLastStage(stageId)
        local groupId = XFubenAssignManager.GetGroupIdByStageId(stageId)
        local groupData = XFubenAssignManager.GetGroupDataById(groupId)
        local stageIdList = groupData:GetStageId()
        return (stageIdList[#stageIdList] == stageId)
    end

    ------ 以下是在FubenManager注册的函数
    function XFubenAssignManager.InitStageInfo()
        local stageType = XDataCenter.FubenManager.StageType.Assign
        local chapterData
        local groupData
        for _, chapterid in pairs(XFubenAssignManager.GetChapterIdList()) do
            chapterData = XFubenAssignManager.GetChapterDataById(chapterid)
            for _, groupId in pairs(chapterData:GetGroupId()) do
                groupData = XFubenAssignManager.GetGroupDataById(groupId)

                local isUnlock = groupData:IsUnlock()
                for _, stageId in ipairs(groupData:GetStageId()) do
                    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                    stageInfo.IsOpen = true
                    stageInfo.Type = stageType
                    stageInfo.Unlock = isUnlock
                    stageInfo.ChapterId = chapterid
                end

                local baseStageInfo = XDataCenter.FubenManager.GetStageInfo(groupData:GetBaseStageId())
                baseStageInfo.IsOpen = true
                baseStageInfo.Type = stageType
                baseStageInfo.Unlock = isUnlock
                baseStageInfo.ChapterId = chapterid
            end
        end
    end

    function XFubenAssignManager.FinishFight(settle)
        
        local groupId = XFubenAssignManager.GetGroupIdByStageId(settle.StageId)
        local groupData = XFubenAssignManager.GetGroupDataById(groupId)
        if not groupData:GetIsPerfect() then
            if settle.IsWin then
                groupData:SetGroupRebootCountAdd(CS.XFight.Instance.FightReboot.RebootCount)
            else
                groupData:ResetGroupRebootCount()
            end
        end

        XDataCenter.FubenManager.FinishFight(settle)

        if FinishFightCb then
            FinishFightCb(settle.IsWin)
        end
    end

    function XFubenAssignManager.OpenFightLoading()
        return
    end

    function XFubenAssignManager.CloseFightLoading()
        if CloseLoadingCb then
            CloseLoadingCb()
        end
    end

    function XFubenAssignManager.ShowReward(winData)
        if XFubenAssignManager.CheckIsGroupLastStage(winData.StageId) then
            -- 本地挑战次数自增
            local groupId = XFubenAssignManager.GetGroupIdByStageId(winData.StageId)
            local groupData = XFubenAssignManager.GetGroupDataById(groupId)
            groupData:SetFightCount(groupData:GetFightCount() + 1)
            if not groupData:GetIsPerfect() then
                if groupData:GetGroupRebootCount() <= 0 then
                    groupData:SetIsPerfect(true)
                end
                groupData:ResetGroupRebootCount()
            end
            XEventManager.DispatchEvent(XEventId.EVENET_ASSIGN_CAN_REWARD) -- 刷新红点
            XLuaUiManager.Open("UiAssignPostWarCount", winData)
        end
    end
    ----------- 战斗接口 end-----------
    -- 某角色某技能加成
    function XFubenAssignManager.GetSkillLevel(characterId, skillId)
        local character = XDataCenter.CharacterManager.GetCharacter(characterId)
        if not character then return 0 end

        local keys, levels = XFubenAssignManager.GetBuffKeysAndLevels()
        local npcTemplate = XCharacterConfigs.GetNpcTemplate(character.NpcId)
        local tragetCharacterType = npcTemplate.Type
        local targetSkilType = XCharacterConfigs.GetSkillType(skillId)
        local level = nil
        for _, key in pairs(keys) do
            local skillType = key % SKILLTYPE_BITS
            local characterType = (key - skillType) / SKILLTYPE_BITS
            if (characterType == tragetCharacterType or characterType == CHARACTERTYPE_ALL) and skillType == targetSkilType then
                level = levels[key]
            end
        end
        return level or 0
    end

    function XFubenAssignManager.GetSkillLevelByCharacterData(character, skillId, assignChapterRecords)
        local keys = {}
        local levels = {}
        for _, v in ipairs(assignChapterRecords) do
            local chapterData = ChapterData.New(v.ChapterId)
            chapterData:SetCharacterId(v.CharacterId)

            if chapterData:IsOccupy() then
                for _, key in ipairs(chapterData:GetBuffKeys()) do
                    if not levels[key] then
                        levels[key] = 1
                        table.insert(keys, key)
                    else
                        levels[key] = levels[key] + 1
                    end
                end
            end
        end
        local npcTemplate = XCharacterConfigs.GetNpcTemplate(character.NpcId)
        local tragetCharacterType = npcTemplate.Type
        local targetSkilType = XCharacterConfigs.GetSkillType(skillId)
        local level = nil
        for _, key in pairs(keys) do
            local skillType = key % SKILLTYPE_BITS
            local characterType = (key - skillType) / SKILLTYPE_BITS
            if (characterType == tragetCharacterType or characterType == CHARACTERTYPE_ALL) and skillType == targetSkilType then
                level = levels[key]
            end
        end
        return level or 0
    end

    -- 参数keys: {角色类型*1000+技能类型, ...}
    -- 参数levels: {[key] = level, ...}
    function XFubenAssignManager.GetBuffDescListByKeys(keys, levels)
        local descList = {}
        local GetCareerName = XCharacterConfigs.GetCareerName
        local GetSkillTypeName = XCharacterConfigs.GetSkillTypeName
        local GetText = CS.XTextManager.GetText
        for _, key in ipairs(keys) do
            local skillType = key % SKILLTYPE_BITS
            local characterType = (key - skillType) / SKILLTYPE_BITS
            local level = levels and levels[key] or 1
            local memberTypeName = characterType == CHARACTERTYPE_ALL and "" or GetCareerName(characterType)
            local str = GetText("AssignSkillPlus", memberTypeName, GetSkillTypeName(skillType), level) -- 全体{0}成员{1}等级+{2}
            table.insert(descList, str)
        end
        return descList
    end

    function XFubenAssignManager.GetBuffKeysAndLevels()
        local keys = {}
        local levels = {}
        for _, id in ipairs(XFubenAssignManager.GetChapterIdList()) do
            local chapterData = XFubenAssignManager.GetChapterDataById(id)
            if chapterData:IsOccupy() then
                for _, key in ipairs(chapterData:GetBuffKeys()) do
                    if not levels[key] then
                        levels[key] = 1
                        table.insert(keys, key)
                    else
                        levels[key] = levels[key] + 1
                    end
                end
            end
        end
        return keys, levels
    end

    function XFubenAssignManager.SortKeys(keys)
        table.sort(keys, function(a, b)
            local skillTypeA = a % SKILLTYPE_BITS
            local characterTypeA = (a - skillTypeA) / SKILLTYPE_BITS
            local skillTypeB = b % SKILLTYPE_BITS
            local characterTypeB = (b - skillTypeB) / SKILLTYPE_BITS
            if skillTypeA ~= skillTypeB then
                return skillTypeA < skillTypeB
            end
            return characterTypeA < characterTypeB
        end)
        return keys
    end

    function XFubenAssignManager.GetAllBuffList()
        local keys, levels = XFubenAssignManager.GetBuffKeysAndLevels()
        keys = XFubenAssignManager.SortKeys(keys)
        return XFubenAssignManager.GetBuffDescListByKeys(keys, levels)
    end

    function XFubenAssignManager.TryGetFightTeamCharList(groupId)
        local groupData = XFubenAssignManager.GetGroupDataById(groupId)
        local teamList = {}
        local captainPosList = {}
        local firstFightPosList = {}
        local teamIdList = groupData:GetTeamInfoId()
        local allTeamHasMember = (#teamIdList > 0)
        for i, teamId in ipairs(teamIdList) do
            teamList[i] = {}
            local count = 0
            local teamData = XFubenAssignManager.GetTeamDataById(teamId)
            captainPosList[i] = teamData:GetLeaderIndex()
            firstFightPosList[i] = teamData:GetFirstFightIndex()
            local memberList = teamData:GetMemberList()
            for _, memberData in ipairs(memberList) do
                local characterId = memberData:GetCharacterId() or 0
                teamList[i][memberData:GetIndex()] = characterId
                if characterId ~= 0 then
                    count = count + 1
                end
            end
            if count < #memberList then
                allTeamHasMember = false
            end
        end
        return allTeamHasMember, teamList, captainPosList, firstFightPosList
    end

    -- 刷新后面关卡的解锁信息
    function XFubenAssignManager.UnlockFollowGroupStage(preGroupId)
        local followGroupIdList = XFubenAssignManager.GetFollowGroupIdList(preGroupId)
        if not followGroupIdList then
            -- XLog.Debug(" 没有后置关卡id列表：" .. tostring(preGroupId))
            return
        end
        for _, followGroupId in ipairs(followGroupIdList) do
            local followGroupData = XFubenAssignManager.GetGroupDataById(followGroupId)
            followGroupData:SyncStageInfo()
        end
    end

    -- 获得后置关卡组
    function XFubenAssignManager.GetFollowGroupIdList(preGroupId)
        if not FollowGroupDict then
            XFubenAssignManager.InitFollowGroupDict()
        end
        local ids = FollowGroupDict[preGroupId]
        -- if not ids then
        -- XLog.Debug("前置关卡id无效：" .. tostring(preGroupId))
        -- end
        return ids
    end

    -- 初始化关卡组后置数据
    function XFubenAssignManager.InitFollowGroupDict()
        if not FollowGroupDict then
            FollowGroupDict = {}
            local GroupTemplates = XFubenAssignConfigs.GetGroupTemplates()
            local groupData
            for groupId, _ in pairs(GroupTemplates) do
                groupData = XFubenAssignManager.GetGroupDataById(groupId)
                local preGroupId = groupData:GetPreGroupId()
                if not FollowGroupDict[preGroupId] then
                    FollowGroupDict[preGroupId] = {}
                end
                table.insert(FollowGroupDict[preGroupId], groupId)
            end
        end
    end

    -- Login登录后端初始化数据接口
    function XFubenAssignManager.InitServerData(chapterRecords)
        XFubenAssignManager.UpdateChapterRecords(chapterRecords)
        XFubenAssignManager.InitFollowGroupDict()

        -- 有数据代表已经通关
        local chapterData
        for _, v in pairs(chapterRecords) do
            chapterData = XFubenAssignManager.GetChapterDataById(v.ChapterId)
            chapterData:SetIsPassByServer(true)
        end
        XEventManager.DispatchEvent(XEventId.EVENET_ASSIGN_CAN_REWARD) -- 刷新红点
    end

    function XFubenAssignManager.UpdateChapterRecords(chapterRecords)
        if not chapterRecords then
            return
        end
        for _, v in pairs(chapterRecords) do
            local chapterData = XFubenAssignManager.GetChapterDataById(v.ChapterId)
            chapterData:SetCharacterId(v.CharacterId)
            chapterData:SetRewarded(v.IsGetReward)
        end
    end

    function XFubenAssignManager.IsRedPoint()
        for _, chapterId in ipairs(XFubenAssignManager.GetChapterIdList()) do
            local chapterData = XFubenAssignManager.GetChapterDataById(chapterId)
            if chapterData:CanReward() then
                return true
            end
        end
        return false
    end

    function XFubenAssignManager.GetCharacterListInTeam(inTeamIdMap, charType)
        local ownCharacters = XDataCenter.CharacterManager.GetOwnCharacterList(charType)
        -- 排序 未编队>已编队  等级＞品质＞优先级
        local weights = {} -- 编队[1位] + 等级[3位] + 品质[1位] + 优先级[5位]
        local GetCharacterPriority = XCharacterConfigs.GetCharacterPriority
        for _, character in ipairs(ownCharacters) do
            local teamOrder = inTeamIdMap[character.Id]
            local stateOrder = teamOrder and (9 - teamOrder) or 9
            local priority = GetCharacterPriority(character.Id)
            local weightOrder = stateOrder * 1000000000
            local weightLevel = character.Level * 1000000
            local weightQuality = character.Quality * 100000
            local weightPriority = priority
            weights[character.Id] = weightOrder + weightLevel + weightQuality + weightPriority
        end
        table.sort(ownCharacters, function(a, b)
            return weights[a.Id] > weights[b.Id]
        end)
        return ownCharacters
    end

    -- 是否满足关卡所需战力
    function XFubenAssignManager.IsStagePass(stageId)
        local groupId = XFubenAssignManager.GetGroupIdByStageId(stageId)
        local groupData = XFubenAssignManager.GetGroupDataById(groupId)
        return groupData:IsPass()
    end

    function XFubenAssignManager.GetAccountEnterKey()
        return KeyAccountEnterAssign .. XPlayer.Id
    end


    -----------------协议----------
    function XFubenAssignManager.AssignGetDataRequest(cb)
        -- if cb then cb() return end -- for testing
        XNetwork.Call(METHOD_NAME.AssignGetDataRequest, nil, function(res)
            local info = res.AssignInfo
            local chapterRecords = info.ChapterRecords -- 章节占领角色
            XFubenAssignManager.UpdateChapterRecords(chapterRecords)
           
            local groupRecords = info.GroupRecords -- 关卡组挑战次数
            for _, v in ipairs(groupRecords) do
                local groupData = XFubenAssignManager.GetGroupDataById(v.GroupId)
                groupData:SetFightCount(v.Count)
                groupData:SetIsPerfect(v.IsPerfect)
            end
            XEventManager.DispatchEvent(XEventId.EVENET_ASSIGN_CAN_REWARD) -- 刷新红点

            local groupTeamRecords = info.GroupTeamRecords -- 编队记录
            for _, v in ipairs(groupTeamRecords) do
                local groupData = XFubenAssignManager.GetGroupDataById(v.GroupId)
                local teamCount = #v.TeamInfoList
                local posCount = v.CaptainPosList and #v.CaptainPosList or 0
                local firstFightCount = v.FirstFightPosList and #v.FirstFightPosList or 0

                for i, teamId in ipairs(groupData:GetTeamInfoId()) do
                    local teamData = XFubenAssignManager.GetTeamDataById(teamId)
                    local charaterIds = (i <= teamCount) and v.TeamInfoList[i] or nil
                    local captainPos = (i <= posCount) and v.CaptainPosList[i] or XFubenAssignManager.CAPTIAN_MEMBER_INDEX
                    local firstFightPos = (i <= firstFightCount) and v.FirstFightPosList[i] or XFubenAssignManager.FIRSTFIGHT_MEMBER_INDEX
                    teamData:SetMemberList(charaterIds)
                    teamData:SetLeaderIndex(captainPos)
                    teamData:SetFirstFightIndex(firstFightPos)
                end
            end

            if cb then
                cb()
            end
        end)
    end

    function XFubenAssignManager.AssignSetTeamRequest(GroupId, TeamList, captainPosList, firstFightPosList, cb)
        -- if cb then cb() return end -- for testing
        XNetwork.Call(METHOD_NAME.AssignSetTeamRequest, { GroupId = GroupId, TeamList = TeamList, CaptainPosList = captainPosList, FirstFightPosList = firstFightPosList }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if cb then
                cb()
            end
        end)
    end

    function XFubenAssignManager.AssignSetCharacterRequest(ChapterId, CharacterId, cb)
        -- if cb then cb() return end -- for testing
        XNetwork.Call(METHOD_NAME.AssignSetCharacterRequest, { ChapterId = ChapterId, CharacterId = CharacterId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XEventManager.DispatchEvent(XEventId.EVENT_REFRESH_CHRACTER_ABLIITY) -- 重新计算角色战力
            if cb then
                cb()
            end
        end)
    end
    function XFubenAssignManager.AssignGetRewardRequest(ChapterId, cb)
        -- if cb then cb() return end -- for testing
        XNetwork.Call(METHOD_NAME.AssignGetRewardRequest, { ChapterId = ChapterId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local chapterData = XFubenAssignManager.GetChapterDataById(ChapterId)
            chapterData:SetRewarded(true)
            XUiManager.OpenUiObtain(res.RewardList or {})
            if cb then
                cb()
            end
        end)
    end

    function XFubenAssignManager.GetSkillPlusIdList()
        local list = {}
        for _, chapterId in ipairs(XFubenAssignManager.GetChapterIdList()) do
            local chapterData = XFubenAssignManager.GetChapterDataById(chapterId)
            if chapterData:IsOccupy() then
                table.insert(list, chapterData:GetSkillPlusId())
            end
        end
        return list
    end

    function XFubenAssignManager.GetSkillPlusIdListOther(assignChapterRecords)
        local list = {}
        if assignChapterRecords == nil then
            return list
        end
        for _, v in ipairs(assignChapterRecords) do
            local chapterData = ChapterData.New(v.ChapterId)
            chapterData:SetCharacterId(v.CharacterId)

            if chapterData:IsOccupy() then
                table.insert(list, chapterData:GetSkillPlusId())
            end
        end
        return list
    end

    -------------------------------
    XFubenAssignManager.Init()
    return XFubenAssignManager
end