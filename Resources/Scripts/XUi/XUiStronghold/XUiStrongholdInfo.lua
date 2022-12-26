local pairs = pairs

local CHARACTER_NUM = 3
local ANIMATION_PANEL = {
    "PanelStageList01",
    "PanelStageList02",
    "PanelStageList03",
    "PanelStageList04",
    "PanelStageList05",
}

local XUiStrongholdInfo = XLuaUiManager.Register(XLuaUi, "UiStrongholdInfo")

function XUiStrongholdInfo:OnStart(groupId, stageIndex)
    for index, name in pairs(ANIMATION_PANEL) do
        self[name].gameObject:SetActiveEx(index == stageIndex)
    end

    local teamId = stageIndex
    local teamList = XDataCenter.StrongholdManager.GetTeamListClipTemp(groupId)
    local characterIds = XDataCenter.StrongholdManager.GetTeamShowCharacterIds(teamId, teamList)
    for index = 1, CHARACTER_NUM do
        local characterId = characterIds[index]
        if XTool.IsNumberValid(characterId) then
            self["RImgCharIcon" .. index]:SetRawImage(XDataCenter.CharacterManager.GetCharBigRoundnessNotItemHeadIcon(characterId))
            self["PanelCharIcon" .. index].gameObject:SetActiveEx(true)
        else
            self["PanelCharIcon" .. index].gameObject:SetActiveEx(false)
        end
    end

    self.TxtZhangjie.text = XStrongholdConfigs.GetGroupOrder(groupId)
    self.TxtGroupName.text = XStrongholdConfigs.GetGroupName(groupId)
    self.TxtName.text = CsXTextManagerGetText("StrongholdTeamIndex", stageIndex)
end