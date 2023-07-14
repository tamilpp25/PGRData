local XUiGuildSkillDetail = XLuaUiManager.Register(XLuaUi, "UiGuildSkillDetail")
local blueColor = CS.UnityEngine.Color(59 / 255, 170 / 255, 1, 1)
local redColor = CS.UnityEngine.Color(1, 0, 0, 1)

function XUiGuildSkillDetail:OnAwake()
    -- PanelAsset
    self.BtnLevelEnter.CallBack = function() self:OnBtnLevelClick() end
    self.BtnMask.CallBack = function() self:OnBtnMaskClick() end

    self.GuildLevelCondition = XUiGridStageStar.New(self.GridStageStar1)
    self.TalentParentConditoin = XUiGridStageStar.New(self.GridStageStar2)
end
function XUiGuildSkillDetail:OnGetEvents()
    return {
        XEventId.EVENT_GUILD_TALENT_ASYNC,
    }
end

function XUiGuildSkillDetail:OnNotify(evt, ...)
    if evt == XEventId.EVENT_GUILD_TALENT_ASYNC then
        self:RefreshTalent()
    end
end

function XUiGuildSkillDetail:OnStart(talentId, callback)
    self.TalentId = talentId
    self.OnCloseCallBack = callback

    self:RefreshTalent()
end

function XUiGuildSkillDetail:RefreshTalent()
    if not self.TalentId then return end

    self.TalentTemplate = XGuildConfig.GetGuildTalentById(self.TalentId)
    self.TalentConfig = XGuildConfig.GetGuildTalentConfigById(self.TalentId)

    local curTalentLevel = XDataCenter.GuildManager.GetTalentLevel(self.TalentId)
    local isCurMax = XDataCenter.GuildManager.IsTalentMaxLevel(self.TalentId)
    local isCurUnlock = XDataCenter.GuildManager.IsTalentUnlock(self.TalentId)

    self.RImgSkillIcon:SetRawImage(self.TalentConfig.TalentIcon)
    self.TxtSkillName.text = self.TalentConfig.Name
    self.TxtSkillNum.text = string.format("<color=#3BAAFF>%d</color>/%d", curTalentLevel, #self.TalentTemplate.CostPoint)
    
    self.TxtCurLevel.text = curTalentLevel
    self.TxtCurDescription.text = self.TalentConfig.Descriptions[curTalentLevel+1]

    self.PanelNextLevel.gameObject:SetActiveEx(not isCurMax)
    if not isCurMax then
        local nextLevel = curTalentLevel + 1
        self.TxtNextLevel.text = nextLevel
        self.TxtNextDescription.text = self.TalentConfig.Descriptions[nextLevel + 1]
    end

    self.PanelLevelBtnMax.gameObject:SetActiveEx(isCurMax)
    self.PanelLevelBtnLock.gameObject:SetActiveEx(not isCurUnlock)
    self.PanelLevelBtn.gameObject:SetActiveEx(not isCurMax and isCurUnlock)
    self.PanelCondition.gameObject:SetActiveEx(not isCurMax)
    self.UnlockTitle.gameObject:SetActiveEx(isCurUnlock)
    self.LockTitle.gameObject:SetActiveEx(not isCurUnlock)
    if not isCurMax then
        self.RImgCostIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XGuildConfig.GuildTalent))
        local ownNum = XDataCenter.GuildManager.GetTalentPoint()
        local needNum = self.TalentTemplate.CostPoint[curTalentLevel + 1] or 0
        self.TxtNeedNums.text = ownNum
        self.TxtTotalNums.text = string.format("/%d", needNum)
        local color = (ownNum >= needNum) and blueColor or redColor
        self.TxtNeedNums.color = color

        self.GuildLevelCondition:Refresh(CS.XTextManager.GetText("GuildTalentConditionLevel", self.TalentTemplate.GuildLevel), isCurUnlock)
        self.TalentParentConditoin.GameObject:SetActiveEx(not XDataCenter.GuildManager.IsTalentParentAllZero(self.TalentId))
        self.TalentParentConditoin:Refresh(CS.XTextManager.GetText("GuildTalentConditionPoint", curTalentLevel + 1), XDataCenter.GuildManager.CheckParentTalent(self.TalentId))
    end
    
    self.PanelTips.gameObject:SetActiveEx(not XDataCenter.GuildManager.IsGuildAdminister())
end

function XUiGuildSkillDetail:OnBtnLevelClick()
    if not XDataCenter.GuildManager.IsGuildAdminister() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildNotAdministor"))
        return
    end
    -- 前置条件
    local curTalentLevel = XDataCenter.GuildManager.GetTalentLevel(self.TalentId)
    if not XDataCenter.GuildManager.CheckParentTalent(self.TalentId) then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildTalentConditionPoint", curTalentLevel + 1))
        return
    end
    -- 消耗数量
    local ownNum = XDataCenter.GuildManager.GetTalentPoint()
    self.TalentTemplate = XGuildConfig.GetGuildTalentById(self.TalentId)
    local needNum = self.TalentTemplate.CostPoint[curTalentLevel + 1] or 0
    if ownNum < needNum then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildTalentPointNotEnough"))
        return
    end

    XDataCenter.GuildManager.GuildUpgradeTalent(self.TalentId, function()
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildTalentUpgradeComplete"))
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUILD_TALENT_ASYNC)
    end)
end

function XUiGuildSkillDetail:OnBtnMaskClick()
    if self.OnCloseCallBack then
        self.OnCloseCallBack()
    end
    self:Close()
end