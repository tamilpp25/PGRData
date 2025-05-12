local XUiAssignLoading = XLuaUiManager.Register(XLuaUi, "UiAssignLoading")
local ANIMATION_OPEN = "UiBfrtInfoBegan%d"
local ANIMATION_LOOP = "UiBfrtInfoLoop%d"

local ANIMATION_PANEL = {
    "PanelStageList01",
    "PanelStageList02",
    "PanelStageList03",
    "PanelStageList04",
    "PanelStageList05",
}

function XUiAssignLoading:OnStart(loadingData)
    self.LoadingData = loadingData
end

function XUiAssignLoading:OnEnable()
    local stageIndex = self.LoadingData.StageIndex
    local teamCharList = self.LoadingData.TeamCharList
    local groupData = self.LoadingData.GroupData
    local chapterData = self.LoadingData.ChapterData
    self.CurIndex = stageIndex

    for index, name in pairs(ANIMATION_PANEL) do
        self[name].gameObject:SetActiveEx(index == stageIndex)
    end

    for index = 1, 3 do
        local characterId = teamCharList[index]
        if XTool.IsNumberValid(characterId) and characterId > 0 then
            self["RImgCharIcon" .. index]:SetRawImage(XMVCA.XCharacter:GetCharBigRoundnessNotItemHeadIcon(characterId))
            self["PanelCharIcon" .. index].gameObject:SetActiveEx(true)
        else
            self["PanelCharIcon" .. index].gameObject:SetActiveEx(false)
        end
    end

    self.TxtZhangjie.text = chapterData and chapterData:GetDesc() or nil
    self.TxtGroupName.text = groupData and groupData:GetName() or nil
    self.TxtName.text = CS.XTextManager.GetText("AssignInfoTeamName", self.CurIndex)

    self:PlayBeginAnimation()
end

function XUiAssignLoading:PlayBeginAnimation()
    local endCb = function()
        self:PlayLoopAnimation()
    end

    local animName = string.format(ANIMATION_OPEN, self.CurIndex)
    self:PlayAnimation(animName, endCb)
end

function XUiAssignLoading:PlayLoopAnimation()
    local animName = string.format(ANIMATION_LOOP, self.CurIndex)
    self:PlayAnimation(animName, nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
end