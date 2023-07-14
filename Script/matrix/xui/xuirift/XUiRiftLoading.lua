local XUiRiftLoading = XLuaUiManager.Register(XLuaUi, "UiRiftLoading")
local ANIMATION_OPEN = "UiBfrtInfoBegan%d"
local ANIMATION_LOOP = "UiBfrtInfoLoop%d"

local ANIMATION_PANEL = {
    "PanelStageList01",
    "PanelStageList02",
    "PanelStageList03",
    "PanelStageList04",
    "PanelStageList05",
}

function XUiRiftLoading:OnEnable()
    --进入关卡的缓存信息 都在manager里，不需要通过onstart传参
    local curXStage = XDataCenter.RiftManager.GetLastFightXStage()
    local curXStageGroup = curXStage:GetParent()
    local stageIndex = 1
    for k, xStage in pairs(curXStageGroup:GetAllEntityStages()) do
        if curXStage == xStage then
            stageIndex = k
            break
        end
    end
    self.CurIndex = stageIndex

    for index, name in pairs(ANIMATION_PANEL) do
        self[name].gameObject:SetActiveEx(index == stageIndex)
    end
    local xTeam = XDataCenter.RiftManager.GetMultiTeamData()[stageIndex]

    for index = 1, 3 do
        local roleId = xTeam:GetEntityIdByTeamPos(index)
        local xRole =  XDataCenter.RiftManager.GetEntityRoleById(roleId)
        local characterId = xRole and xRole:GetCharacterId()
        if XTool.IsNumberValid(characterId) and characterId > 0 then
            self["RImgCharIcon" .. index]:SetRawImage(XDataCenter.CharacterManager.GetCharBigRoundnessNotItemHeadIcon(characterId))
            self["PanelCharIcon" .. index].gameObject:SetActiveEx(true)
        else
            self["PanelCharIcon" .. index].gameObject:SetActiveEx(false)
        end
    end

    self.TxtZhangjie.text = curXStageGroup:GetParent():GetId().."km"
    self.TxtGroupName.text = curXStageGroup:GetName()
    self.TxtName.text = CS.XTextManager.GetText("STFightLoadingTeamText", stageIndex)

    self:PlayBeginAnimation()
end

function XUiRiftLoading:PlayBeginAnimation()
    local endCb = function()
        self:PlayLoopAnimation()
    end

    local animName = string.format(ANIMATION_OPEN, self.CurIndex)
    self:PlayAnimation(animName, endCb)
end

function XUiRiftLoading:PlayLoopAnimation()
    local animName = string.format(ANIMATION_LOOP, self.CurIndex)
    self:PlayAnimation(animName, nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
end