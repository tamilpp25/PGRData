local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiPanelArenaSelfRank = require("XUi/XUiArenaNew/XUiArenaRank/XUiPanelArenaSelfRank")

---@class XUiArenaTeamRank : XLuaUi
---@field _Control XArenaControl
local XUiArenaTeamRank = XLuaUiManager.Register(XLuaUi, "UiArenaTeamRank")

function XUiArenaTeamRank:OnAwake()
    ---@type XUiPanelArenaSelfRank
    self._SelfRankUi = nil
    self._GroupData = nil
    self:_RegisterEventClicks()
    self:_InitTagGroup()
    self:_InitUi()
end

---@param groupData XArenaGroupDataBase
function XUiArenaTeamRank:OnStart(groupData)
    self._GroupData = groupData
    self._SelfRankUi = XUiPanelArenaSelfRank.New(self.PanelSelfRank, self, self._GroupData)

    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiArenaTeamRank:OnEnable()
    self:_Refresh()
end

function XUiArenaTeamRank:Close()
    self.Super.Close(self)
    XEventManager.DispatchEvent(XEventId.EVENT_ARENA_RESHOW_MAIN_UI)
end

function XUiArenaTeamRank:RefreshTime(beginTime, endTime)
    self.TxtTime.text = self._Control:GetRankStatisticalTimeStr(beginTime, endTime)
end

function XUiArenaTeamRank:OnTagsGroupSelect(index)
    local challengeId = self._Control:GetMaxChallengeId()
    
    if index == 1 then
        challengeId = self._Control:GetActivityChallengeId()
    end

    self._SelfRankUi:Refresh(challengeId)
end

function XUiArenaTeamRank:_RegisterEventClicks()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
end

function XUiArenaTeamRank:_Refresh()
    self.TxtTime.text = ""
    self.TagsButtonGroup:SelectIndex(1)
end

function XUiArenaTeamRank:_InitTagGroup()
    local tagGroup = {}
    local tagObject = XUiHelper.Instantiate(self.GridRankLevel, self.PanelTags)
    ---@type XUiComponent.XUiButton
    local buttonComponent = tagObject:GetComponent("XUiButton")
    local challengeId = self._Control:GetActivityChallengeId()
    local arenaLv = self._Control:GetChallengeArenaLvById(challengeId)

    buttonComponent:SetNameByGroup(0, self._Control:GetArenaLevelNameById(arenaLv))
    buttonComponent:SetNameByGroup(1, self._Control:GetCurrentChallengeLevelNotDescStr())
    buttonComponent:SetRawImage(self._Control:GetArenaLevelIconById(arenaLv))
    buttonComponent:ShowTag(true)
    buttonComponent.gameObject:SetActiveEx(true)

    table.insert(tagGroup, buttonComponent)

    if not self._Control:CheckIsMaxArenaLevel(arenaLv) then
        tagObject = XUiHelper.Instantiate(self.GridRankLevel, self.PanelTags)
        buttonComponent = tagObject:GetComponent("XUiButton")
        challengeId = self._Control:GetMaxChallengeId()
        arenaLv = self._Control:GetChallengeArenaLvById(challengeId)

        buttonComponent:SetNameByGroup(0, self._Control:GetArenaLevelNameById(arenaLv))
        buttonComponent:SetNameByGroup(1, self._Control:GetChallengeLevelNotDescStrByChallengeId(challengeId))
        buttonComponent:SetRawImage(self._Control:GetArenaLevelIconById(arenaLv))
        buttonComponent:ShowTag(false)
        buttonComponent.gameObject:SetActiveEx(true)

        table.insert(tagGroup, buttonComponent)
    end

    self.TagsButtonGroup:Init(tagGroup, Handler(self, self.OnTagsGroupSelect))
end

function XUiArenaTeamRank:_InitUi()
    self.GridRankLevel.gameObject:SetActiveEx(false)
end

return XUiArenaTeamRank
