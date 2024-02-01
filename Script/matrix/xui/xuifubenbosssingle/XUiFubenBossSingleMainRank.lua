local XUiGridBossRankReward = require("XUi/XUiFubenBossSingle/XUiGridBossRankReward")

---@class XUiFubenBossSingleMainRank : XUiNode
---@field TxtRank UnityEngine.UI.Text
---@field BtnRank XUiComponent.XUiButton
---@field GridBossRankReward UnityEngine.UI.Button
---@field PanelRankEmpty UnityEngine.RectTransform
---@field PanelRankInfo UnityEngine.RectTransform
---@field TxtRankEmpty UnityEngine.UI.Text
---@field TxtNoneRank UnityEngine.UI.Text
---@field _Control XFubenBossSingleControl
local XUiFubenBossSingleMainRank = XClass(XUiNode, "XUiFubenBossSingleMainRank")

function XUiFubenBossSingleMainRank:OnStart(rootUi)
    self._RootUi = rootUi
    ---@type XUiGridBossRankReward
    self.RankGrid = XUiGridBossRankReward.New(self.GridBossRankReward, self, self._RootUi)
    self.RankGrid:Close()
    self:_RegisterButtonClicks()
end

function XUiFubenBossSingleMainRank:Init()
    local bossSingleData = self._Control:GetBossSingleData()
    local levelType = bossSingleData:GetBossSingleLevelType()

    if not self._Control:CheckHasRankData(levelType) then
        self.PanelRankEmpty.gameObject:SetActiveEx(true)
        self.PanelRankInfo.gameObject:SetActiveEx(false)
        self.TxtRankEmpty.text = XUiHelper.GetText("FubenBossSingleRankEmpty")
    else
        self.PanelRankEmpty.gameObject:SetActiveEx(false)
        self.PanelRankInfo.gameObject:SetActiveEx(true)
    end
end

function XUiFubenBossSingleMainRank:RefreshRank()
    local bossSingleData = self._Control:GetBossSingleData()
    local levelType = bossSingleData:GetBossSingleLevelType()
    
    if not self._Control:GetRankIsOpenByType(levelType) 
        or not self._Control:CheckHasRankData(levelType) then
        self.TxtRank.gameObject:SetActiveEx(false)
        self.TxtNoneRank.gameObject:SetActiveEx(true)
    else
        local rank = bossSingleData:GetSelfRankInfoRank()
        local totalRank = bossSingleData:GetSelfRankInfoTotalRank()
        local maxCount = self._Control:GetMaxRankCount()
        if rank <= maxCount and rank > 0 then
            self.TxtRank.text = math.floor(rank)
            self.TxtRank.gameObject:SetActiveEx(true)
            self.TxtNoneRank.gameObject:SetActiveEx(false)
        else
            if not totalRank or totalRank <= 0 or rank <= 0 then
                self.TxtRank.gameObject:SetActiveEx(false)
                self.TxtNoneRank.gameObject:SetActiveEx(true)
            else
                self.TxtRank.gameObject:SetActiveEx(true)
                self.TxtNoneRank.gameObject:SetActiveEx(false)
                local num = math.floor(rank / totalRank * 100)
                if num < 1 then
                    num = 1
                end

                self.TxtRank.text = XUiHelper.GetText("BossSinglePercentDesc", num)
            end
        end
    end
end

function XUiFubenBossSingleMainRank:RefreshRankReward()
    local levelType = self._Control:GetBossSingleData():GetBossSingleLevelType()

    if not self._Control:CheckHasRankData(levelType) then
        return
    end

    XMVCA.XFubenBossSingle:RequestRankData(function(rankData)
        if not rankData then
            return
        end

        local config = nil
        local configs = self._Control:GetRankRewardConfig(levelType)

        for i = 1, #configs do
            if self._Control:CheckCurrentRank(levelType, configs[i], rankData) then
                config = configs[i]
            end
        end
    
        config = config or configs[#configs]
    
        self.RankGrid:Open()
        self.RankGrid:Refresh(config, false, Handler(self, self.OnBtnGridBossRankRewardClick))
    end, levelType)
end

function XUiFubenBossSingleMainRank:OnBtnRankClick()
    local levelType = self._Control:GetBossSingleData():GetBossSingleLevelType()

    if not self._Control:CheckHasRankData(levelType) then
        return
    end

    XMVCA.XFubenBossSingle:RequestRankData(function()
        self._RootUi:ShowBossRank()
    end, levelType)
end

function XUiFubenBossSingleMainRank:OnBtnGridBossRankRewardClick()
    local levelType = self._Control:GetBossSingleData():GetBossSingleLevelType()

    if not self._Control:CheckHasRankData(levelType) then
        return
    end
    XMVCA.XFubenBossSingle:RequestRankData(function(rankData)
        self:_ShowRankRewardPanel(rankData)
    end, levelType)
end

function XUiFubenBossSingleMainRank:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnRank, self.OnBtnRankClick, true)
    XUiHelper.RegisterClickEvent(self, self.GridBossRankReward, self.OnBtnGridBossRankRewardClick, true)
end

---@param rankData XBossSingleRankData
function XUiFubenBossSingleMainRank:_ShowRankRewardPanel(rankData)
    local levelType = self._Control:GetBossSingleData():GetBossSingleLevelType()
    local rank = {
        MylevelType = levelType,
        MineRankNum = rankData:GetRankNumber(),
        HistoryMaxRankNum = rankData:GetHistoryNumber(),
        TotalCount = rankData:GetTotalCount(),
    }

    self._RootUi:ShowRankRewardPanel(levelType, rank)
end

return XUiFubenBossSingleMainRank
