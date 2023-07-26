local XUiSuperTowerLoading = XLuaUiManager.Register(XLuaUi, "UiSuperTowerLoading")
local CSTextManagerGetText = CS.XTextManager.GetText
local CHARACTER_NUM = 3

local ANIMATION_OPEN = "UiBfrtInfoBegan%d"
local ANIMATION_LOOP = "UiBfrtInfoLoop%d"

local ANIMATION_PANEL = {
    "PanelStageList01",
    "PanelStageList02",
    "PanelStageList03",
    "PanelStageList04",
    "PanelStageList05",
}

function XUiSuperTowerLoading:OnStart(stStage, stageIndex)
    self.CurIndex = stageIndex
    
    for index, name in pairs(ANIMATION_PANEL) do
        self[name].gameObject:SetActiveEx(index == stageIndex)
    end

    local roleManager = XDataCenter.SuperTowerManager.GetRoleManager()
    local stageId = stStage:GetStageId()[stageIndex]
    local team = XDataCenter.SuperTowerManager.GetTeamByStageId(stageId)
    local characterIds = XDataCenter.SuperTowerManager.GetCharacterIdListByTeamEntity(team)
    
    for index = 1, CHARACTER_NUM do
        local characterId = characterIds[index]
        if XTool.IsNumberValid(characterId) and characterId > 0 then
            self["RImgCharIcon" .. index]:SetRawImage(XDataCenter.CharacterManager.GetCharBigRoundnessNotItemHeadIcon(characterId))
            self["PanelCharIcon" .. index].gameObject:SetActiveEx(true)
        else
            self["PanelCharIcon" .. index].gameObject:SetActiveEx(false)
        end
    end

    self.TxtZhangjie.text = stStage:GetSimpleName()
    self.TxtGroupName.text = stStage:GetStageName()
    self.TxtName.text = CsXTextManagerGetText("STFightLoadingTeamText", stageIndex)
    
    self:PlayBeginAnimation()
end

function XUiSuperTowerLoading:PlayBeginAnimation()
    local endCb = function()
        self:PlayLoopAnimation()
    end

    local animName = string.format(ANIMATION_OPEN, self.CurIndex)
    self:PlayAnimation(animName, endCb)
end

function XUiSuperTowerLoading:PlayLoopAnimation()
    local animName = string.format(ANIMATION_LOOP, self.CurIndex)
    self:PlayAnimation(animName, nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
end