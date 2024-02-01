local XUiFubenBossSingleChallengeRankRewardGrid = require(
    "XUi/XUiFubenBossSingle/XUiFubenBossSingleChallengeRankReward/XUiFubenBossSingleChallengeRankRewardGrid")

---@class XUiFubenBossSingleChallengeRankReward : XLuaUi
---@field BtnTanchuangClose XUiComponent.XUiButton
---@field GridBossRankReward UnityEngine.RectTransform
---@field BossScoreList UnityEngine.RectTransform
---@field BtnBlock UnityEngine.UI.Button
---@field _Control XFubenBossSingleControl
local XUiFubenBossSingleChallengeRankReward = XLuaUiManager.Register(XLuaUi, "UiFubenBossSingleChallengeRankReward")

-- region 生命周期
function XUiFubenBossSingleChallengeRankReward:OnStart(selfRankNumber, totalCount)
    self._SelfNumber = selfRankNumber
    self._TotalCount = totalCount
    self._DynamicTable = XDynamicTableNormal.New(self.BossScoreList)
    self._DynamicTable:SetDelegate(self)
    self._DynamicTable:SetProxy(XUiFubenBossSingleChallengeRankRewardGrid, self)

    self:_RegisterButtonClicks()
    self.GridBossRankReward.gameObject:SetActiveEx(false)
end

function XUiFubenBossSingleChallengeRankReward:OnEnable()
    self:_RefreshDynamicTable()
end

---@param grid XUiFubenBossSingleChallengeRankRewardGrid
function XUiFubenBossSingleChallengeRankReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable:GetData(index)

        grid:Refresh(data, self:_CheckCurrentRank(data))
    end
end

-- endregion

-- region 私有方法

function XUiFubenBossSingleChallengeRankReward:_RegisterButtonClicks()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close, true)
    self:RegisterClickEvent(self.BtnBlock, self.Close, true)
end

function XUiFubenBossSingleChallengeRankReward:_RefreshDynamicTable()
    local bossSingleData = self._Control:GetBossSingleData()
    local levelType = bossSingleData:GetBossSingleChallengeLevelType()
    local configs = self._Control:GetRankRewardConfig(levelType)

    self._DynamicTable:SetDataSource(configs)
    self._DynamicTable:ReloadDataASync(1)
end

function XUiFubenBossSingleChallengeRankReward:_CheckCurrentRank(config)
    if not XTool.IsNumberValid(self._SelfNumber) or not config or not XTool.IsNumberValid(self._TotalCount) then
        return false
    end

    local bossSingleData = self._Control:GetBossSingleData()
    local levelType = bossSingleData:GetBossSingleChallengeLevelType()
    local selfNumber = self._SelfNumber
    local totalCount = self._TotalCount

    if not levelType or not selfNumber or not totalCount then
        return false
    end 
    if levelType ~= config.LevelType then
        return false
    end
    if selfNumber >= 1 and totalCount > 0 then
        selfNumber = selfNumber / totalCount
    end

    return selfNumber > config.MinRank and selfNumber <= config.MaxRank
end

-- endregion

return XUiFubenBossSingleChallengeRankReward
