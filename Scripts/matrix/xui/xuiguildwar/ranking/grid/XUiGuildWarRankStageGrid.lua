--隐藏节点排行榜细节的子Grid
--父UI XUiGuildWarRankStage
---@class XUiGuildWarRankStageGrid
local XUiGuildWarRankStageGrid = XClass(nil, "XUiGuildWarRankStageGrid")
function XUiGuildWarRankStageGrid:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    --self.ConcealRank = XUiGuildWarConcealGrid.New(self.PanelPlayerRank)
end

---data XGuildWarHideAreaMeta(C#)
function XUiGuildWarRankStageGrid:RefreshData(data)
    self.TxtRankScore.text = data.Point
    self.TxtRankNormal.text = XGuildWarConfig.GetChildNodeIndex(data.NodeId)
    --队伍头像
    for i=1,3 do
        -- XGuildWarHideAreaCharacterMeta(C#)
        local memberData = data.Characters[i]
        local iconObject= self["Team" .. i]
        if memberData and not (memberData.PlayerId == 0) then
            --这个PlayerId其实是CharacterId 后端写的时候太随便了
            local icon = XDataCenter.CharacterManager.GetCharSmallHeadIcon(memberData.PlayerId)
            iconObject.gameObject:SetActiveEx(true)
            self["ImgSupport" .. i].gameObject:SetActiveEx(data.IsAssist == 1)
            self["RImgTeam" .. i]:SetRawImage(icon)
        else
            iconObject.gameObject:SetActiveEx(false)
        end
    end
end

return XUiGuildWarRankStageGrid