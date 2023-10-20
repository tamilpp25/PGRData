local stringFormat = string.format

local MAX_UI_STAGE_COUNT = 10
local ANIMATION_OPEN = "UiBfrtInfoBegan%d"
local ANIMATION_LOOP = "UiBfrtInfoLoop%d"
local ANIMATION_PANEL = "PanelStageList0%d"

---@class XUiBfrtInfo:XLuaUi
local XUiBfrtInfo = XLuaUiManager.Register(XLuaUi, "UiBfrtInfo")

function XUiBfrtInfo:OnGetEvents()
    return { CS.XEventId.EVENT_FIGHT_FORCE_EXIT, XEventId.EVENT_FUBEN_SETTLE_FAIL }
end

function XUiBfrtInfo:OnNotify(evt)
    if evt == CS.XEventId.EVENT_FIGHT_FORCE_EXIT or evt == XEventId.EVENT_FUBEN_SETTLE_FAIL then
        self:Close()
    end
end

function XUiBfrtInfo:OnStart(groupId, fightTeams, stageIndex)
    self:ShowBfrtInfo(groupId, fightTeams, stageIndex)
end

function XUiBfrtInfo:ShowBfrtInfo(groupId, fightTeams, stageIndex)
    self.GroupId = groupId
    self.CurIndex = stageIndex or 1

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

        self.FullScreenBackground.gameObject:SetActiveEx(true)
        self.SafeAreaContentPane.gameObject:SetActiveEx(true)

        local stageId = stageIdList[self.CurIndex]
        local team = fightTeams[self.CurIndex]
        self:UpdateAnimationNode()
        self:PlayBeginAnimation()
        self:SetBfrtTeam(team)

        local fightInfoIdList = XDataCenter.BfrtManager.GetFightInfoIdList(groupId)
        local echelonId = fightInfoIdList[self.CurIndex]
        local captainPos = XDataCenter.BfrtManager.GetTeamCaptainPos(echelonId, groupId, self.CurIndex)
        local firstFightPost = XDataCenter.BfrtManager.GetTeamFirstFightPos(echelonId, groupId, self.CurIndex)
        XDataCenter.FubenManager.EnterBfrtFight(stageId, team, captainPos, firstFightPost)

        self.TxtName.text = CS.XTextManager.GetText("BfrtInfoTeamName", self.CurIndex)
    end

    XDataCenter.BfrtManager.SetCloseLoadingCb(function()
        self.FullScreenBackground.gameObject:SetActiveEx(false)
        self.SafeAreaContentPane.gameObject:SetActiveEx(false)
    end)

    XDataCenter.BfrtManager.SetFightCb(function(result)
        if not result then
            XDataCenter.BfrtManager.SetCloseLoadingCb()
            XDataCenter.BfrtManager.SetFightCb()
            self:Close()
        else
            self.CurIndex = XDataCenter.BfrtManager.GetGroupStageRecordIndex(groupId) or self.CurIndex + 1
            updateStageInfofunc()
        end
    end)

    updateStageInfofunc()
end

function XUiBfrtInfo:SetBfrtTeam(team)
    local count = #team
    if count <= 0 then
        self.GridTeam.gameObject:SetActiveEx(false)
        return
    end

    for i = 1, count do
        local viewIndex = XDataCenter.BfrtManager.TeamPosConvert(i)
        if team[i] > 0 then
            self["RImgCharIcon" .. viewIndex]:SetRawImage(XDataCenter.CharacterManager.GetCharBigRoundnessNotItemHeadIcon(team[i]))
            self["PanelCharIcon" .. viewIndex].gameObject:SetActiveEx(true)
        else
            self["PanelCharIcon" .. viewIndex].gameObject:SetActiveEx(false)
        end
    end
end

function XUiBfrtInfo:UpdateAnimationNode()
    for i = 1, MAX_UI_STAGE_COUNT do
        local go = self.Transform:FindGameObject(stringFormat(ANIMATION_PANEL, i))
        if not XTool.UObjIsNil(go) then
            go:SetActiveEx(i == self.CurIndex)
        end
    end

    local stageList = XDataCenter.BfrtManager.GetStageIdList(self.GroupId)
    local parent = self.Transform:FindGameObject(stringFormat(ANIMATION_PANEL, self.CurIndex))
    if not XTool.UObjIsNil(parent) then
        for i = #stageList + 2, MAX_UI_STAGE_COUNT do
            local go = parent.transform:FindGameObject("GridBfrtStage" .. i)
            if not XTool.UObjIsNil(go) then
                go:SetActiveEx(false)
            end
        end
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