---@class XUiPanelRankReward : XUiNode
local XUiPanelRankReward = XClass(XUiNode, "XUiPanelRankReward")
local XUiGridBossRankReward = require("XUi/XUiFubenBossSingle/XUiGridBossRankReward")

function XUiPanelRankReward:OnStart(rootUi)
    self._RootUi = rootUi
    ---@type XUiGridBossRankReward[]
    self._GridBossRankList = {}
    self:_RegisterButtonListeners()
    self.GridBossRankReward.gameObject:SetActive(false)
end

function XUiPanelRankReward:OnEnable()
    self:_Refresh()
end

function XUiPanelRankReward:_RegisterButtonListeners()
    XUiHelper.RegisterClickEvent(self, self.BtnBlock, self.Close, true)
end

function XUiPanelRankReward:_Refresh()
    if not self._LevelType or not self._MyRankData then
        return
    end

    local levelType = self._LevelType
    local myRankData = self._MyRankData
    local cfgs = XDataCenter.FubenBossSingleManager.GetRankRewardCfg(levelType)

    for i = 1, #cfgs do
        local grid = self._GridBossRankList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridBossRankReward)
            grid = XUiGridBossRankReward.New(ui, self, self.Parent)
            grid.Transform:SetParent(self.PanelRankContent, false)
            self._GridBossRankList[i] = grid
        end

        grid:Open()
        grid:Refresh(cfgs[i], self:_CheckCurrentRank(cfgs[i], myRankData))
    end

    for i = #cfgs + 1, #self._GridBossRankList do
        self._GridBossRankList[i]:Close()
    end

    self.Parent:PlayAnimation("AnimRankRewardEnable")
end

function XUiPanelRankReward:_CheckCurrentRank(config, myRankData)
    if not myRankData or not config then
        return false
    end

    local myLevelType = myRankData.MylevelType
    local myRankNum = myRankData.MineRankNum
    local totalCount = myRankData.TotalCount

    if not myLevelType or not myRankNum or not totalCount then
        return false
    end 
    if myLevelType ~= config.LevelType then
        return false
    end
    if myRankNum >= 1 and totalCount > 0 then
        myRankNum = myRankNum / totalCount
    end

    return myRankNum > config.MinRank and myRankNum <= config.MaxRank
end

function XUiPanelRankReward:SetData(levelType, myRankData)
    self._LevelType = levelType
    self._MyRankData = myRankData
end

return XUiPanelRankReward

