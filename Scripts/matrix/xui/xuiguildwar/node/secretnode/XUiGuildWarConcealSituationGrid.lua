--
local XUiGuildWarConcealSituationGrid = XClass(nil, "XUiGuildWarConcealSituationGrid")

function XUiGuildWarConcealSituationGrid:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
end

-- data:XTerm3SecretRootGWNode:GetAreaSituation()
function XUiGuildWarConcealSituationGrid:RefreshData(data)
    --作战区域索引
    self.TxtNodeIndex.text = data.ChildIndex
    self.TxtScore.text = data.Score
    for i=1,3 do
        self["Team" .. i].gameObject:SetActiveEx(false)
    end
    for _, XGuildWarTeamCharacterInfo in pairs(data.CharactorInfo or {}) do
        local characterId = XGuildWarTeamCharacterInfo.Id
        if not (characterId == 0) then
            local playerId = XGuildWarTeamCharacterInfo.PlayerId
            local pos = XGuildWarTeamCharacterInfo.Pos
            self["Team" .. pos].gameObject:SetActiveEx(true)
            local icon = XDataCenter.CharacterManager.GetCharSmallHeadIcon(characterId)
            self["RImgTeam" .. pos]:SetRawImage(icon)
            self["ImgSupport" .. pos].gameObject:SetActiveEx(not (playerId == XPlayer.Id))
        end
    end
end


return XUiGuildWarConcealSituationGrid