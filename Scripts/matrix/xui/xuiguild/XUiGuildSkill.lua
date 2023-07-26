local XUiGuildSkill = XLuaUiManager.Register(XLuaUi, "UiGuildSkill")

local XUiGridTalentItem = require("XUi/XUiGuild/XUiChildItem/XUiGridTalentItem")
local vectorOffset = CS.UnityEngine.Vector3.zero --(-2, 0, 0)
local ShowGuildTalentHelp = "ShowGuildTalentHelp"

function XUiGuildSkill:OnAwake()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self:BindHelpBtn(self.BtnHelp, "GuildTalentHelp")
    
    self.TalentPointList = {}
end

function XUiGuildSkill:OnGetEvents()
    return {
        XEventId.EVENT_GUILD_TALENT_ASYNC,
    }
end

function XUiGuildSkill:OnNotify(evt, ...)
    if evt == XEventId.EVENT_GUILD_TALENT_ASYNC then
        self:OnTalentAsync()
    end
end

function XUiGuildSkill:OnDestroy()
    if self.DelayTimer then
        XScheduleManager.UnSchedule(self.DelayTimer)
        self.DelayTimer = nil
    end
end

function XUiGuildSkill:OnStart()
    --首次进入展示帮助
    if not XSaveTool.GetData(ShowGuildTalentHelp) then
        XSaveTool.SaveData(ShowGuildTalentHelp, true)
        XUiManager.ShowHelpTip("GuildTalentHelp")
    end
    
    -- PanelDrag
    self.TalentPoints = XGuildConfig.GetSortedTalentPoints()
    for i = 1, #self.TalentPoints do
        local talentPoint = self.TalentPoints[i]
        talentPoint.IsSelect = false
        if not self.TalentPointList[i] then
            local ui = self.LayerLevel:Find(string.format("%d", i))
            self.TalentPointList[i] = XUiGridTalentItem.New(ui, self)
        end
        self.TalentPointList[i]:Refresh(talentPoint)
    end

    -- by default
    -- if self.TalentPointList[1] then
    --     self:FocusTargetDelay(self.TalentPointList[1].Transform)
    -- end
end

function XUiGuildSkill:OnTalentAsync()
    if not self.TalentPoints or not self.TalentPointList then return end
    if XDataCenter.GuildManager.CheckAllTalentLevelMax() then
        XLuaUiManager.Close("UiGuildSkillDetail")
        XLuaUiManager.PopThenOpen("UiGuildGloryLevel")
        return
    end
    for i = 1, #self.TalentPoints do
        local talentPoint = self.TalentPoints[i]
        if self.TalentPointList[i] then
            self.TalentPointList[i]:Refresh(talentPoint)
        end
    end
end

function XUiGuildSkill:OnTalentPointSelect(indexInMap)
    for i = 1, #self.TalentPointList do
        if self.TalentPointList[i] and self.TalentPoints[i] then
            local talentPoint = self.TalentPoints[i]
            talentPoint.IsSelect = talentPoint.IndexInMap == indexInMap
            self.TalentPointList[i]:SetSelect(talentPoint.IsSelect)
        end
    end
end

function XUiGuildSkill:ResetTalentPointSelect()
    self:OnTalentPointSelect(0)
end

function XUiGuildSkill:FocusTargetDelay(transform)
    self.DelayTimer = XScheduleManager.ScheduleOnce(function()
        self.PanelDrag:FocusTarget(transform, 1, 1, vectorOffset, function()
            XScheduleManager.UnSchedule(self.DelayTimer)
        end)
    end, 50)
end

function XUiGuildSkill:OnBtnBackClick()
    self:Close()
end

function XUiGuildSkill:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end