local stringFormat = string.format

local MAX_UI_STAGE_COUNT = 10
local ANIMATION_OPEN = "UiBfrtInfoBegan%d"
local ANIMATION_LOOP = "UiBfrtInfoLoop%d"
local ANIMATION_PANEL = "PanelStageList0%d"

---@class XUiBfrtInfo:XLuaUi
local XUiBfrtInfo = XLuaUiManager.Register(XLuaUi, "UiBfrtInfo")

function XUiBfrtInfo:OnStart(uiBfrtInfoArgs)
    self.GroupId = uiBfrtInfoArgs.GroupId
    self.FightTeam = uiBfrtInfoArgs.FightTeam -- {IdList = {}, CaptainPos, FirstFightPos, GeneralSkillId, EnterCgIndex, SettleCgIndex}
    self.CurIndex = uiBfrtInfoArgs.StageIndex or 1
    self.ChapterId = XDataCenter.BfrtManager.GetChapterIdByGroupId(uiBfrtInfoArgs.GroupId)
    self.ChapterCfg = XDataCenter.BfrtManager.GetChapterCfg(self.ChapterId)
    self.StageIdList = XDataCenter.BfrtManager.GetStageIdList(uiBfrtInfoArgs.GroupId)

    self.TxtZhangjie.text = self.ChapterCfg.ChapterName
    self.TxtGroupName.text = self.ChapterCfg.ChapterEn
    self:UpdateAnimationNode()
    self:PlayBeginAnimation()
    self:SetBfrtTeam(self.FightTeam.IdList)
    self.TxtName.text = CS.XTextManager.GetText("BfrtInfoTeamName", self.CurIndex)

    local stageId = self.StageIdList[self.CurIndex]
    local fightEvents = XDataCenter.BfrtManager.GetEchelonInfoShowFightEventIds(stageId)
    if XDataCenter.BfrtManager.CheckIsShowFightEventTips(stageId) and next(fightEvents) then
        XLuaUiManager.Open("UiBfrtEchelonFightEvent", stageId, function()
            self:DoEnterFight(stageId)
        end)
    else
        self:DoEnterFight(stageId)
    end
end

function XUiBfrtInfo:DoEnterFight(stageId)
    local captainPos = self.FightTeam.CaptainPos
    local firstFightPos = self.FightTeam.FirstFightPos
    local generalSkillId = self.FightTeam.GeneralSkillId
    local enterCgIndex = self.FightTeam.EnterCgIndex
    local settleCgIndex = self.FightTeam.SettleCgIndex

    XDataCenter.FubenManager.EnterBfrtFight(stageId, self.FightTeam.IdList, captainPos, firstFightPos, generalSkillId, enterCgIndex, settleCgIndex)
end

function XUiBfrtInfo:SetBfrtTeam(teamIdList)
    local count = #teamIdList
    if count <= 0 then
        self.GridTeam.gameObject:SetActiveEx(false)
        return
    end

    for i = 1, count do
        local viewIndex = XDataCenter.BfrtManager.TeamPosConvert(i)
        if teamIdList[i] > 0 then
            self["RImgCharIcon" .. viewIndex]:SetRawImage(XMVCA.XCharacter:GetCharBigRoundnessNotItemHeadIcon(teamIdList[i]))
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

    local parent = self.Transform:FindGameObject(stringFormat(ANIMATION_PANEL, self.CurIndex))
    if not XTool.UObjIsNil(parent) then
        for i = #self.StageIdList + 2, MAX_UI_STAGE_COUNT do
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