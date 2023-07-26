local XAssignGroup = XClass(nil, "XAssignGroup")

function XAssignGroup:Ctor(id)
    self.Id = id
    self.FightCount = 0
    self.GroupRebootCount = 0
    self.IsPerfect = false
end

function XAssignGroup:GetCfg()
    return XFubenAssignConfigs.GetGroupTemplateById(self.Id)
end
function XAssignGroup:GetId() return self.Id end
function XAssignGroup:GetPreGroupId() return self:GetCfg().PreGroupId end
-- function XAssignGroup:GetMaxFightCount() return self:GetCfg().ChallengeNum end
function XAssignGroup:GetTeamInfoId() return self:GetCfg().TeamInfoId end
function XAssignGroup:GetBaseStageId() return self:GetCfg().BaseStage end
function XAssignGroup:GetStageId() return self:GetCfg().StageId end
function XAssignGroup:GetName() return self:GetCfg().Name end
function XAssignGroup:GetIcon() return self:GetCfg().Icon end

-- 该group属于哪个chapter
function XAssignGroup:GetChapter()
    local list = XDataCenter.FubenAssignManager.GetChapterIdList()
    for k, chapterId in pairs(list) do
        local chapterData = XDataCenter.FubenAssignManager.GetChapterDataById(chapterId)
        local groupList = chapterData:GetGroupId()
        for k, groupId in pairs(groupList) do
            if groupId == self:GetId() then
                return chapterData
            end
        end
    end
    return nil
end

function XAssignGroup:IsLastGroup()
    local data = self:GetChapter()
    local currChapterGroupList = data:GetGroupId()
    if currChapterGroupList[#currChapterGroupList] == self:GetId() then
        return true
    end
    return false
end

function XAssignGroup:IsUnlock()
    if self:GetFightCount() > 0 then
        return true
    end
    local preGroupId = self:GetPreGroupId()
    return ((not preGroupId or preGroupId == 0) or XDataCenter.FubenAssignManager.GetGroupDataById(preGroupId):IsPass())
end

-- 刷新关卡解锁信息
function XAssignGroup:SyncStageInfo(isPass)
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
        XDataCenter.FubenAssignManager.UnlockFollowGroupStage(self:GetId())
    end
end

-- server api
function XAssignGroup:SetFightCount(count)
    count = count or 0
    local oldCount = self.FightCount
    self.FightCount = count
    if (not oldCount or oldCount == 0) and (count > 0) then -- 新解锁
        self:SyncStageInfo(true)
    end
end

function XAssignGroup:GetFightCount()
    -- do return 1 end -- for testing
    return self.FightCount
end
function XAssignGroup:SetIsPerfect(isPerfect)
    self.IsPerfect = isPerfect
end
function XAssignGroup:GetIsPerfect()
    return self.IsPerfect
end
function XAssignGroup:SetGroupRebootCountAdd( rebootCount )
    self.GroupRebootCount = self.GroupRebootCount + rebootCount
end
function XAssignGroup:GetGroupRebootCount()
    return self.GroupRebootCount
end
function XAssignGroup:ResetGroupRebootCount()
    self.GroupRebootCount = 0
end
function XAssignGroup:IsPass()
    if self:GetFightCount() > 0 then
        return true
    end
    return false
    -- -- 根据StageInfo来  来源于XFubenManager.InitFubenData
    -- local stageInfo = XDataCenter.FubenManager.GetStageInfo(self:GetBaseStageId())
    -- return (stageInfo and stageInfo.Passed)
end

return XAssignGroup