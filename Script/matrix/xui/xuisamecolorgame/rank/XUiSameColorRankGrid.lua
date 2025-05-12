---@class XUiSameColorRankGrid:XUiNode
---@field _Control XSameColorControl
local XUiSameColorRankGrid = XClass(XUiNode, "XUiSameColorRankGrid")

function XUiSameColorRankGrid:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.RankInfo = nil
    XUiHelper.RegisterClickEvent(self, self.BtnDetail, self.OnBtnDetailClicked)
end

function XUiSameColorRankGrid:SetData(rankInfo)
    self.RankInfo = rankInfo
    local sameColorActivityManager = XDataCenter.SameColorActivityManager
    local roleManager = sameColorActivityManager.GetRoleManager()
    
    local showSpecialRank = rankInfo.Rank <= XEnumConst.SAME_COLOR_GAME.RANK_MAX_SPECIAL_INDEX
    self.TxtRank.text = rankInfo.Rank
    self.TxtRank.gameObject:SetActiveEx(not showSpecialRank)
    self.ImgRankSpecial.gameObject:SetActiveEx(showSpecialRank)
    if showSpecialRank then
        local rankIcons = self._Control:GetClientCfgValue("RankIcons")
        self.ImgRankSpecial:SetSprite(rankIcons[rankInfo.Rank])
    end
    
    local roleId = rankInfo.RoleId > 0 and rankInfo.RoleId or 1
    XUiPlayerHead.InitPortrait(rankInfo.HeadPortraitId, rankInfo.HeadFrameId, self.Head)
    self.TxtRankScore.text = XUiHelper.GetText("SCRankScoreTips", rankInfo.Score)
    self.TxtPlayerName.text = rankInfo.Name
    -- 五期不显示角色头像
    if self.RImgRoleIcon then
        self.RImgRoleIcon.gameObject:SetActiveEx(false)
    end
    --local role = roleManager:GetRole(roleId)
    --self.RImgRoleIcon:SetRawImage(role:GetCharacterViewModel():GetSmallHeadIcon())

    -- v2.12 没有商店技能
    local skillGroupId, rImgSkillIcon, panelSkill
    for i = 1, 3 do
        skillGroupId = rankInfo.RoleSkillId[i]
        rImgSkillIcon = self["RImgSkillIcon" .. i]
        panelSkill = self["PanelSkill" .. i]
        --if skillGroupId then
        --    local skill = sameColorActivityManager.GetRoleShowSkill(skillGroupId)
        --    rImgSkillIcon:SetRawImage(skill:GetIcon())
        --    rImgSkillIcon.gameObject:SetActiveEx(true)
        --    panelSkill.gameObject:SetActiveEx(true)
        --    XUiHelper.RegisterClickEvent(self, self["BtnSkill" .. i], function()
        --        XEventManager.DispatchEvent(XEventId.EVENT_SC_OPEN_SKILL_DETAIL, skill)
        --    end)
        --else
        rImgSkillIcon.gameObject:SetActiveEx(false)
        panelSkill.gameObject:SetActiveEx(false)
        --end
    end
end

function XUiSameColorRankGrid:OnBtnDetailClicked()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.RankInfo.PlayerId)
end

return XUiSameColorRankGrid