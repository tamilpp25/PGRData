---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by heyupeng.
--- DateTime: 2024/4/11 18:09
---
local TWEEN_ANI_TOTAL_DELAY = 700

local XUiDormAutoEventRewardsTipCharGrid = require("XUi/XUiDormMain/XUiDormAutoEventRewardsTipCharGrid")
local XUiDormAutoEventRewardsTipRewardGrid = require("XUi/XUiDormMain/XUiDormAutoEventRewardsTipRewardGrid")

-- 一键完成事件提示界面
---@class XUiDormAutoEventRewardsTip : XLuaUi
local XUiDormAutoEventRewardsTip = XLuaUiManager.Register(XLuaUi, "UiDormAutoEventRewardsTip")

function XUiDormAutoEventRewardsTip:OnAwake()

end

function XUiDormAutoEventRewardsTip:OnStart(characterMoodsChangeList, rewardGoodsMergeDic)
    self:InitViewData()
    self._CharacterMoodsChangeList = characterMoodsChangeList
    self._RewardGoodsMergeDic = rewardGoodsMergeDic
    self._CharacterMoodAniScheduleId = 0

    self:RegisterBtnListener()

    self.GridTeamMember.gameObject:SetActiveEx(false)
    self.GridFurnitureRecycle.gameObject:SetActiveEx(false)
end

function XUiDormAutoEventRewardsTip:OnEnable()
    self:Refresh()
end

function XUiDormAutoEventRewardsTip:OnDestroy()
    self:ReleaseViewData()
end

function XUiDormAutoEventRewardsTip:InitViewData()
    self._CharacterMoodsChangeGrids = {}
    self._RewardGoodGrids = {}
end

-- 释放视图数据
function XUiDormAutoEventRewardsTip:ReleaseViewData()
    if self._CharacterMoodAniScheduleId > 0 then
        XScheduleManager.UnSchedule(self._CharacterMoodAniScheduleId)
        self._CharacterMoodAniScheduleId = 0
    end
    self._CharacterMoodsChangeGrids = nil
    self._RewardGoodGrids = nil
end

function XUiDormAutoEventRewardsTip:RegisterBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, function()
        self:Close()
    end)
end

function XUiDormAutoEventRewardsTip:Refresh()
    self:RefreshCharacterMood()
    self:RefreshRewardGoods()
end

function XUiDormAutoEventRewardsTip:RefreshCharacterMood()
    local characterMoodsChangeListCount = XTool.GetTableCount(self._CharacterMoodsChangeList)
    if characterMoodsChangeListCount > 0 then
        self.TeamMembersContent.gameObject:SetActiveEx(true)
        self.NoTeamFile.gameObject:SetActiveEx(false)
    else
        self.TeamMembersContent.gameObject:SetActiveEx(false)
        self.NoTeamFile.gameObject:SetActiveEx(true)
    end

    -- 为角色心情变化列表按变化后的心情值从大到小排序,如果心情值相同则按角色ID从大到小排序
    table.sort(self._CharacterMoodsChangeList, function(a, b)
        local moodA = XDataCenter.DormManager.GetMoodById(a.CharacterId)
        local moodB = XDataCenter.DormManager.GetMoodById(b.CharacterId)
        if moodA == moodB then
            return a.CharacterId > b.CharacterId
        else
            return moodA > moodB
        end
    end)
    
    for index, characterMoodChangeValue in ipairs(self._CharacterMoodsChangeList) do
        local grid = self._CharacterMoodsChangeGrids[index]
        if not grid then
            if index == 1 then
                grid = XUiDormAutoEventRewardsTipCharGrid.New(self.GridTeamMember, self)
                self._CharacterMoodsChangeGrids[index] = grid
            else
                local go = XUiHelper.Instantiate(self.GridTeamMember, self.TeamMembersContent)
                grid = XUiDormAutoEventRewardsTipCharGrid.New(go, self)
            end
            self._CharacterMoodsChangeGrids[index] = grid
        end
        grid:Open()
        grid:OnRefresh(characterMoodChangeValue)
    end

    self._CharacterMoodAniScheduleId = XScheduleManager.ScheduleOnce(function()
        for _, grid in pairs(self._CharacterMoodsChangeGrids) do
            grid:PlayTweenAnimation()
        end
        self._CharacterMoodAniScheduleId = 0
    end, TWEEN_ANI_TOTAL_DELAY)
end

function XUiDormAutoEventRewardsTip:RefreshRewardGoods()
    local rewardGoodsMergeDicCount = XTool.GetTableCount(self._RewardGoodsMergeDic)
    if rewardGoodsMergeDicCount > 0 then
        self.PanelReward.gameObject:SetActiveEx(true)
        self.NoFile.gameObject:SetActiveEx(false)
    else
        self.PanelReward.gameObject:SetActiveEx(false)
        self.NoFile.gameObject:SetActiveEx(true)
    end

    local index = 1
    for _, rewardGoodInfo in pairs(self._RewardGoodsMergeDic) do
        local grid = self._RewardGoodGrids[index]
        if not grid then
            if index == 1 then
                grid = XUiDormAutoEventRewardsTipRewardGrid.New(self.GridFurnitureRecycle, self)
                self._RewardGoodGrids[index] = grid
            else
                local go = XUiHelper.Instantiate(self.GridFurnitureRecycle, self.PanelReward)
                grid = XUiDormAutoEventRewardsTipRewardGrid.New(go, self)
            end
            self._RewardGoodGrids[index] = grid
        end
        grid:Open()
        grid:OnRefresh(rewardGoodInfo)

        index = index + 1
    end
end