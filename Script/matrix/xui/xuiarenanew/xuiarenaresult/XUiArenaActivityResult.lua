local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiArenaActivityResult : XLuaUi
---@field _Control XArenaControl
local XUiArenaActivityResult = XLuaUiManager.Register(XLuaUi, "UiArenaActivityResult")

function XUiArenaActivityResult:OnAwake()
    self:AutoAddListener()
    self.GridCommon.gameObject:SetActiveEx(false)
    self.BtnRanking.gameObject:SetActiveEx(not self._Control:IsInActivityFightStatus())
end

---@param data XArenaActivityResultData
function XUiArenaActivityResult:OnStart(data, closeCb)
    self._DynamicTable = XDynamicTableNormal.New(self.SViewReward.transform)
    self._DynamicTable:SetProxy(XUiGridCommon)
    self._DynamicTable:SetDelegate(self)

    self._Data = data
    self._CloseCb = closeCb

    self:_Refresh()
end

function XUiArenaActivityResult:AutoAddListener()
    self:RegisterClickEvent(self.BtnBg, self.OnBtnBgClick)
    self:RegisterClickEvent(self.BtnRanking, self.OnBtnRankingClick)
end

function XUiArenaActivityResult:OnBtnBgClick()
    self._Control:ClearActivityResultData()
    self:Close()
    if self._CloseCb then
        self._CloseCb()
    end
end

function XUiArenaActivityResult:OnBtnRankingClick()
    self._Control:ClearActivityResultData()
    self:Close()
    if not XLuaUiManager.IsUiLoad("UiArenaNew") then
        XMVCA.XArena:ExOpenMainUi()
    end
end

function XUiArenaActivityResult:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable:GetData(index)

        grid.RootUi = self
        grid:Refresh(data)
    end
end

function XUiArenaActivityResult:_Refresh()
    if not self._Data then
        return
    end

    local arenaLevel = self._Data:GetNewArenaLevel()
    local arenaName = self._Control:GetArenaLevelNameById(arenaLevel)
    local infoText = ""

    -- 降级保护
    if self._Data:GetIsProtected() then
        infoText = XUiHelper.GetText("ArenaActivityProtected", arenaName)
    else
        if self._Data:GetOldArenaLevel() < self._Data:GetNewArenaLevel() then
            infoText = XUiHelper.GetText("ArenaActivityResultUp", arenaName)
        elseif self._Data:GetOldArenaLevel() == self._Data:GetNewArenaLevel() then
            local challengeId = self._Data:GetChallengeId()
            local arenaLv = self._Control:GetChallengeArenaLvById(challengeId)
            local danUpCostScore = self._Control:GetChallengeDanUpRankCostContributeScoreById(challengeId)
            local danUpRank = self._Control:GetChallengeDanUpRankByChallengeId(challengeId)
            local groupRank = self._Data:GetGroupRank()

            infoText = XUiHelper.GetText("ArenaActivityResultKeep", arenaName)
            -- 英雄小队
            if arenaLv == self._Control:GetArenaHeroLv() and danUpCostScore > 0 and groupRank <= danUpRank then
                infoText = XUiHelper.GetText("ArenaActivityResultNotContributeScore", danUpCostScore, arenaName)
            end
        else
            infoText = XUiHelper.GetText("ArenaActivityResultDown", arenaName)
        end
    end

    self.TxtInfo.text = infoText
    self.RImgArenaLevel:SetRawImage(self._Control:GetArenaLevelWordIconById(arenaLevel))
    self._DynamicTable:SetDataSource(self:_GetRewardGoodsList())
    self._DynamicTable:ReloadDataASync()
end

function XUiArenaActivityResult:_GetRewardGoodsList()
    local result = {}
    local rewardGoods = self._Data:GetRewardGoodsList()
    local challengeId = self._Data:GetChallengeId()
    local point = self._Data:GetPoint() or 0
    local groupRank = self._Data:GetGroupRank() or 0
    local contributeScore = self._Control:GetContributeScoreByChallengeId(groupRank, challengeId, point)

    for i, v in ipairs(rewardGoods) do
        table.insert(result, v)
    end

    -- 显示战区贡献积分
    if contributeScore then
        table.insert(result, {
            TemplateId = self._Control:GetContributeScoreItemId(),
            Count = contributeScore,
        })
    end

    return result
end

return XUiArenaActivityResult
