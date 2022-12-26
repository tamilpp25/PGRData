local stringFormat = string.format

local XUiBfrtInfo = XLuaUiManager.Register(XLuaUi, "UiBfrtInfo")

local ANIMATION_OPEN = "UiBfrtInfoBegan%d"
local ANIMATION_LOOP = "UiBfrtInfoLoop%d"

local ANIMATION_PANEL = {
    "PanelStageList01",
    "PanelStageList02",
    "PanelStageList03",
    "PanelStageList04",
}

function XUiBfrtInfo:OnGetEvents()
    return { CS.XEventId.EVENT_FIGHT_FORCE_EXIT, XEventId.EVENT_FUBEN_SETTLE_FAIL }
end

function XUiBfrtInfo:OnNotify(evt)
    if evt == CS.XEventId.EVENT_FIGHT_FORCE_EXIT or evt == XEventId.EVENT_FUBEN_SETTLE_FAIL then
        self:Close()
    end
end

function XUiBfrtInfo:OnStart(groupId, fightTeams)
    self:ShowBfrtInfo(groupId, fightTeams)
end

function XUiBfrtInfo:ShowBfrtInfo(groupId, fightTeams)
    self.GroupId = groupId
    self.CurIndex = 1

    local chapterId = XDataCenter.BfrtManager.GetChapterIdByGroupId(groupId)
    local chapterCfg = XDataCenter.BfrtManager.GetChapterCfg(chapterId)
    local stageIdList = XDataCenter.BfrtManager.GetStageIdList(groupId)
    local maxIndex = #stageIdList

    self.TxtZhangjie.text = chapterCfg.ChapterName
    self.TxtGroupName.text = chapterCfg.ChapterEn

    local updateStageInfofunc = function()
        if self.CurIndex > maxIndex then
            XDataCenter.BfrtManager.SetCloseLoadingCb()
            XDataCenter.BfrtManager.SetFightCb()
            self:Close()
            return
        end

        self.FullScreenBackground.gameObject:SetActive(true)
        self.SafeAreaContentPane.gameObject:SetActive(true)

        local stageId = stageIdList[self.CurIndex]
        local team = fightTeams[self.CurIndex]
        self:UpdateAnimationNode()
        self:PlayBeginAnimation()
        self:SetBfrtTeam(team)

        local fightInfoIdList = XDataCenter.BfrtManager.GetFightInfoIdList(groupId)
        local echelonId = fightInfoIdList[self.CurIndex]
        local captainPos = XDataCenter.BfrtManager.GetTeamCaptainPos(echelonId)
        local firstFightPost = XDataCenter.BfrtManager.GetTeamFirstFightPos(echelonId)
        XDataCenter.FubenManager.EnterBfrtFight(stageId, team, captainPos, firstFightPost)

        self.TxtName.text = CS.XTextManager.GetText("BfrtInfoTeamName", self.CurIndex)
    end

    XDataCenter.BfrtManager.SetCloseLoadingCb(function()
        self.FullScreenBackground.gameObject:SetActive(false)
        self.SafeAreaContentPane.gameObject:SetActive(false)
    end)

    XDataCenter.BfrtManager.SetFightCb(function(result)
        if not result then
            XDataCenter.BfrtManager.SetCloseLoadingCb()
            XDataCenter.BfrtManager.SetFightCb()
            self:Close()
        else
            self.CurIndex = self.CurIndex + 1
            updateStageInfofunc()
        end
    end)

    updateStageInfofunc()
end

function XUiBfrtInfo:SetBfrtTeam(team)
    local count = #team
    if count <= 0 then
        self.GridTeam.gameObject:SetActive(false)
        return
    end

    for i = 1, count do
        local viewIndex = XDataCenter.BfrtManager.TeamPosConvert(i)
        if team[i] > 0 then
            self["RImgCharIcon" .. viewIndex]:SetRawImage(XDataCenter.CharacterManager.GetCharBigRoundnessNotItemHeadIcon(team[i]))
            self["PanelCharIcon" .. viewIndex].gameObject:SetActive(true)
        else
            self["PanelCharIcon" .. viewIndex].gameObject:SetActive(false)
        end
    end
end

function XUiBfrtInfo:UpdateAnimationNode()
    for k, v in pairs(ANIMATION_PANEL) do
        if k == self.CurIndex then
            self[v].gameObject:SetActive(true)
        else
            self[v].gameObject:SetActive(false)
        end
    end

    local stageList = XDataCenter.BfrtManager.GetStageIdList(self.GroupId)
    for i = #stageList + 2, 4 do
        local gridBfrtStage = XUiHelper.TryGetComponent(self[ANIMATION_PANEL[self.CurIndex]], "GridBfrtStage" .. i, nil)
        if gridBfrtStage then gridBfrtStage.gameObject:SetActive(false) end
    end
end

function XUiBfrtInfo:PlayBeginAnimation()
    local endCb = function()
        self:PlayLoopAnimation()
    end

    local animName = stringFormat(ANIMATION_OPEN, self.CurIndex)
    self:PlayAnimation(animName, endCb)
end

function XUiBfrtInfo:PlayLoopAnimation()
    local animName = stringFormat(ANIMATION_LOOP, self.CurIndex)
    self:PlayAnimation(animName)
end