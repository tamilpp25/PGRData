local XUiAssignInfo = XLuaUiManager.Register(XLuaUi, "UiAssignInfo")

local ANIMATION_OPEN = {
    "Began1",
    "Began2",
    "Began3",
    "Began4",
}

local ANIMATION_LOOP = {
    "Loop1",
    "Loop2",
    "Loop3",
    "Loop4",
}

local ANIMATION_PANEL = {
    "PanelStageList01",
    "PanelStageList02",
    "PanelStageList03",
    "PanelStageList04",
}
local MAX_MEMBER_INDEX = 3

function XUiAssignInfo:OnAwake()
    self:InitComponent()
end

function XUiAssignInfo:OnDestroy()
    XDataCenter.FubenAssignManager.SetCloseLoadingCb(nil)
    XDataCenter.FubenAssignManager.SetFinishFightCb(nil)
end

function XUiAssignInfo:OnStart(chapterId, groupId, teamCharIdList, captainPosList, firstFightPosList)
    self:Refresh(chapterId, groupId, teamCharIdList, captainPosList, firstFightPosList)
end

function XUiAssignInfo:InitComponent()
    -- self.SafeAreaContentPane = self.Transform:Find("SafeAreaContentPane")
    -- self.FullScreenBackground = self.Transform:Find("FullScreenBackground")
    self.TxtZhangjie.gameObject:SetActiveEx(false)
    self.PlayOpenAnimationCB = function() self:PlayLoopAnimation() end
    for _, objName in ipairs(ANIMATION_LOOP) do
        self[objName].gameObject:SetActiveEx(false)
    end
end

function XUiAssignInfo:OnGetEvents()
    return { CS.XEventId.EVENT_FIGHT_FORCE_EXIT, XEventId.EVENT_FUBEN_SETTLE_FAIL }
end

function XUiAssignInfo:OnNotify(evt)
    if evt == CS.XEventId.EVENT_FIGHT_FORCE_EXIT or evt == XEventId.EVENT_FUBEN_SETTLE_FAIL then
        self:Close()
    end
end

function XUiAssignInfo:LoadingEnd()
    XDataCenter.FubenAssignManager.SetCloseLoadingCb(nil)
    XDataCenter.FubenAssignManager.SetFinishFightCb(nil)
    self:Close()
end

function XUiAssignInfo:Refresh(chapterId, groupId, teamCharIdList, captainPosList, firstFightPosList)
    self.ChapterId = chapterId
    self.GroupId = groupId
    self.CurIndex = 1

    -- local chapterData = XDataCenter.FubenAssignManager.GetChapterDataById(chapterId)
    local groupData = XDataCenter.FubenAssignManager.GetGroupDataById(self.GroupId)
    local stageIdList = groupData:GetStageId()
    local maxIndex = #stageIdList

    -- self.TxtZhangjie.text = chapterData:GetName()
    self.TxtGroupName.text = groupData:GetName()

    local updateStageInfofunc = function()
        if self.CurIndex > maxIndex then
            self:LoadingEnd()
            return
        end
        self.FullScreenBackground.gameObject:SetActiveEx(false)
        self.SafeAreaContentPane.gameObject:SetActiveEx(false)

        local stageId = stageIdList[self.CurIndex]
        local charIdList = teamCharIdList[self.CurIndex]
        local captainPos = captainPosList[self.CurIndex]
        local firstFightPos = firstFightPosList[self.CurIndex]

        local startCb = function()
            self.FullScreenBackground.gameObject:SetActiveEx(true)
            self.SafeAreaContentPane.gameObject:SetActiveEx(true)
            self.TxtName.text = CS.XTextManager.GetText("AssignInfoTeamName", self.CurIndex)
            self:UpdateAnimationNode()
            self:PlayBeginAnimation()
            self:UpdateTeamMembers(charIdList)
        end
        local errorCb = function()
            self:LoadingEnd()
        end

        XDataCenter.FubenManager.EnterAssignFight(stageId, charIdList, captainPos, startCb, errorCb, firstFightPos)
    end

    XDataCenter.FubenAssignManager.SetCloseLoadingCb(function()
        self.FullScreenBackground.gameObject:SetActiveEx(false)
        self.SafeAreaContentPane.gameObject:SetActiveEx(false)
    end)

    XDataCenter.FubenAssignManager.SetFinishFightCb(function(result)
        if not result then
            self:LoadingEnd()
        else
            self.CurIndex = self.CurIndex + 1
            updateStageInfofunc()
        end
    end)

    updateStageInfofunc()
end

function XUiAssignInfo:UpdateTeamMembers(charIdList)
    local count = #charIdList
    if count <= 0 then
        self.GridTeam.gameObject:SetActiveEx(false)
        return
    end

    for index = 1, MAX_MEMBER_INDEX do
        local order = XDataCenter.FubenAssignManager.GetMemberOrderByIndex(index, count)
        self:AddTeamMember(order, charIdList[index])
    end
end

function XUiAssignInfo:AddTeamMember(order, charId)
    if charId and charId > 0 then
        self["RImgCharIcon" .. order]:SetRawImage(XMVCA.XCharacter:GetCharBigRoundnessNotItemHeadIcon(charId))
        self["PanelCharIcon" .. order].gameObject:SetActiveEx(true)
    else
        self["PanelCharIcon" .. order].gameObject:SetActiveEx(false)
    end
end

function XUiAssignInfo:UpdateAnimationNode()
    for k, v in pairs(ANIMATION_PANEL) do
        if k == self.CurIndex then
            self[v].gameObject:SetActiveEx(true)
        else
            self[v].gameObject:SetActiveEx(false)
        end
    end

    local groupData = XDataCenter.FubenAssignManager.GetGroupDataById(self.GroupId)
    local stageIdList = groupData:GetStageId()
    for i = #stageIdList + 2, 4 do
        local gridBfrtStage = XUiHelper.TryGetComponent(self[ANIMATION_PANEL[self.CurIndex]], "GridBfrtStage" .. i, nil)
        if gridBfrtStage then gridBfrtStage.gameObject:SetActiveEx(false) end
    end
end

function XUiAssignInfo:PlayBeginAnimation()
    if not ANIMATION_OPEN[self.CurIndex] then
        self.PlayOpenAnimationCB()
        return
    end
    self:PlayAnimation(ANIMATION_OPEN[self.CurIndex], self.PlayOpenAnimationCB)
end

function XUiAssignInfo:PlayLoopAnimation()
    -- TimeLine组件会重置PlayMode为Holde，不能循环播放，改用SetActive方式
    for i, objName in ipairs(ANIMATION_LOOP) do
        self[objName].gameObject:SetActiveEx(i == self.CurIndex)
    end
    --     if not ANIMATION_OPEN[self.CurIndex] then
    --         self.PlayLoopAnimationCB()
    --         return
    --     end
    --     self:PlayAnimation(ANIMATION_LOOP[self.CurIndex], self.PlayLoopAnimationCB)
end