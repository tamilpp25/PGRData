---@class XUiGWSelectDifficultGrid
local XUiGWSelectDifficultGrid = XClass(nil, "XUiGWSelectDifficultGrid")

function XUiGWSelectDifficultGrid:Ctor(prefab)
    self:Init(prefab)
end

function XUiGWSelectDifficultGrid:Init(prefab)
    XTool.InitUiObjectByUi(self, prefab)
    self.GridBuff.gameObject:SetActiveEx(false)
    self.GridBuffs = {}
end
--[[
local data = {
Id = id,
Name = cfg.Name,
RecommendActive = cfg.RecommendActive,
FightEventIds = cfg.FightEventIds,
PreId = cfg.PreId}
]]--
function XUiGWSelectDifficultGrid:Refresh(data)
    self.Data = data
    self.RImgSelectLevel:SetRawImage(data.BgPath)
    self.TxtLevelName.text = data.Name
    local recommendActive = data.RecommendActive
    if recommendActive > 0 then
        self.TxtRecommendActive.text = XUiHelper.GetText("GuildWarRecommendActive", data.RecommendActive)
    else
        self.TxtRecommendActive.text = ""
    end
    self.ImgClear.gameObject:SetActiveEx(XDataCenter.GuildWarManager.CheckDifficultyIsPass(self.Data.Id))
    self.IsUnLock = XDataCenter.GuildWarManager.CheckDifficultyIsPass(self.Data.PreId)
    self.TxtLock.text = data.LockText
    self.PanelLock.gameObject:SetActiveEx(not self.IsUnLock)
    local preSelect = self:IsDifficultySelected()
    self.TxtOpenTime.gameObject:SetActiveEx(preSelect)
    if preSelect then
        self:StartOpenTimeCount()
    end
    self:RefreshBuff()
    self:UpdatePanelDifficultyNextRound()
end

function XUiGWSelectDifficultGrid:IsDifficultySelected()
    return XDataCenter.GuildWarManager.GetNextDifficultyId(true) == self.Data.Id
end

function XUiGWSelectDifficultGrid:RefreshBuff()
    for index, fightEventId in pairs(self.Data.FightEventIds or {}) do
        local buff = self:GetBuff(index)
        buff:Show()
        buff:Refresh(fightEventId, self.Data.FightEventIds)
    end
    for index = #self.Data.FightEventIds + 1, #self.GridBuffs do
        local buff = self:GetBuff(index)
        buff:Hide()
    end
end

function XUiGWSelectDifficultGrid:StartOpenTimeCount()
    if self.TimeId then return end
    self:RefreshOpenTime()
    self.TimeId = XScheduleManager.ScheduleForever(function()
            if XTool.UObjIsNil(self.GameObject) then self:StopCount() return end
            self:RefreshOpenTime()
        end, 1000)
end

function XUiGWSelectDifficultGrid:RefreshOpenTime()
    local leftTime = XDataCenter.GuildWarManager.GetNextRoundTime(true)
    if not leftTime or not self:IsDifficultySelected() then
        self.TxtOpenTime.gameObject:SetActiveEx(false)
        return
    end
    if leftTime and leftTime <= 1 then
        self:StopCount()
        XLuaUiManager.RunMain()
        XUiManager.TipText("GuildWarAutoSelectDifficultComplete")
        return
    end
    self.TxtOpenTime.gameObject:SetActiveEx(true)
    self.TxtOpenTime.text = XUiHelper.GetText(
        "GuildWarSelectDifficultAutoOpen",
        XUiHelper.GetTime(
            leftTime,
            XUiHelper.TimeFormatType.CHALLENGE
        )
    )
end

function XUiGWSelectDifficultGrid:StopCount()
    XScheduleManager.UnSchedule(self.TimeId)
    self.TimeId = nil
end

function XUiGWSelectDifficultGrid:GetBuff(index)
    local buff = self.GridBuffs[index]
    if buff then
        return buff
    end
    local newGo = XUiHelper.Instantiate(self.GridBuff, self.PanelBuff)
    if newGo then
        local buffGridScript = require("XUi/XUiGuildWar/DifficultSelect/XUiGWSelectBuffGrid")
        local newBuff = buffGridScript.New(newGo)
        self.GridBuffs[index] = newBuff
    end
    return self.GridBuffs[index]
end

function XUiGWSelectDifficultGrid:OnClick()
    -- if not self.IsUnLock then
    --     return
    -- end
    
    -- XDataCenter.GuildWarManager.SelectDifficulty(self.Data.Id, function()
    --         CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUILD_WAR_DIFFICULTY_SELECTED)
    --         XDataCenter.GuildWarManager.GetActivityData(function ()
    --                 XLuaUiManager.Open("UiGuildWarStageMain")
    --             end)
    --     end)
    --region 二期
    XLuaUiManager.Open("UiGuildWarMap", self.Data.Id)
    --endregion
end

--region 二期
-- 下期难度
function XUiGWSelectDifficultGrid:UpdatePanelDifficultyNextRound()
    if XDataCenter.GuildWarManager.IsOnPreselectionStage() then
        self.TxtNextSelect.text = XUiHelper.GetText("GuildWarDifficultySelect2")
    else
        self.TxtNextSelect.text = XUiHelper.GetText("GuildWarDifficultySelect1")
    end

    local id = self.Data.Id
    local nextDifficultyId = XDataCenter.GuildWarManager.GetNextDifficultyId(true)
    if XDataCenter.GuildWarManager.IsLastRound() then
        nextDifficultyId = false
    end
    self.PanelNextSelect.gameObject:SetActiveEx(id == nextDifficultyId)
end

--endregion

return XUiGWSelectDifficultGrid
