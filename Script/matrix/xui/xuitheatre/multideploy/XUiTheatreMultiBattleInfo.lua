--多队伍进入战斗前Loading
local CHARACTER_NUM = 3
local stringFormat = string.format

local MAX_UI_STAGE_COUNT = 10
local ANIMATION_OPEN = "UiBfrtInfoBegan%d"
local ANIMATION_LOOP = "UiBfrtInfoLoop%d"
local ANIMATION_PANEL = "PanelStageList0%d"

local XUiTheatreMultiBattleInfo = XLuaUiManager.Register(XLuaUi, "UiTheatreMultiBattleInfo")

function XUiTheatreMultiBattleInfo:OnAwake()
    self.AdventureManager = XDataCenter.TheatreManager.GetCurrentAdventureManager()
    self.AdventureChapter = self.AdventureManager:GetCurrentChapter()
end

function XUiTheatreMultiBattleInfo:OnStart(stageIndex, stageId)
    self.StageIndex = stageIndex

    local teamId = stageIndex
    local team = self.AdventureManager:GetMultipleTeamByIndex(teamId)
    local entityIds = team:GetCharacterAndRobotIds()
    for index = 1, CHARACTER_NUM do
        local entityId = entityIds[index]
        if XTool.IsNumberValid(entityId) then
            self["RImgCharIcon" .. index]:SetRawImage(XEntityHelper.GetCharBigRoundnessNotItemHeadIcon(entityId))
            self["PanelCharIcon" .. index].gameObject:SetActiveEx(true)
        else
            self["PanelCharIcon" .. index].gameObject:SetActiveEx(false)
        end
    end

    local currChapter = self.AdventureManager:GetCurrentChapter()
    local chapterId = currChapter:GetCurrentChapterId()
    self.TxtZhangjie.text = XTheatreConfigs.GetChapterTitle(chapterId)

    self.TxtGroupName.text = XFubenConfigs.GetStageName(stageId)
    self.TxtName.text = XUiHelper.GetText("StrongholdTeamIndex", stageIndex)

    local chapterId = self.AdventureChapter:GetCurrentChapterId()
    local bg = XTheatreConfigs.GetChapterMultiFightLoadingBg(chapterId)
    if bg then
        self.RImgChapterBg:SetRawImage(bg)
    end

    self:UpdateAnimationNode()
    self:PlayBeginAnimation()
end

function XUiTheatreMultiBattleInfo:UpdateAnimationNode()
    local stageIndex = self.StageIndex
    for i = 1, MAX_UI_STAGE_COUNT do
        local go = self.Transform:FindGameObject(stringFormat(ANIMATION_PANEL, i))
        if not XTool.UObjIsNil(go) then
            go:SetActiveEx(i == stageIndex)
        end
    end

    local node = self.AdventureChapter:GetCurrentNode()
    if not node then
        return
    end

    local stageCount = node:GetTeamCount()
    local parent = self.Transform:FindGameObject(stringFormat(ANIMATION_PANEL, stageIndex))
    if not XTool.UObjIsNil(parent) then
        for i = stageCount + 2, MAX_UI_STAGE_COUNT do
            local go = parent.transform:FindGameObject("GridBfrtStage" .. i)
            if not XTool.UObjIsNil(go) then
                go:SetActiveEx(false)
            end
        end
    end
end

function XUiTheatreMultiBattleInfo:PlayBeginAnimation()
    local endCb = function()
        self:PlayLoopAnimation()
    end

    local animName = stringFormat(ANIMATION_OPEN, self.StageIndex)
    self:PlayAnimation(animName, endCb)
end

function XUiTheatreMultiBattleInfo:PlayLoopAnimation()
    local animName = stringFormat(ANIMATION_LOOP, self.StageIndex)
    self:PlayAnimation(animName)
end