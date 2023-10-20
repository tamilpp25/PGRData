---@class XUiPanelScoreInfo : XUiNode
---@field _RootUi XUiFubenBossSingle
local XUiPanelScoreInfo = XClass(XUiNode, "XUiPanelScoreInfo")
local XUiGridBossScore = require("XUi/XUiFubenBossSingle/XUiGridBossScore")

function XUiPanelScoreInfo:OnStart(rootUi)
    self._RootUi = rootUi
    ---@type XUiGridBossScore[]
    self._GridBossScoreList = {}
    self.GridBossScore.gameObject:SetActive(false)
    self:_RegisterButtonListeners()
end

function XUiPanelScoreInfo:OnEnable()
    self:_Refresh()
end

function XUiPanelScoreInfo:_RegisterButtonListeners()
    XUiHelper.RegisterClickEvent(self, self.BtnBlock, self.OnBtnBlockClick, true)
end

function XUiPanelScoreInfo:_Refresh()
    local bossSingleData = self._RootUi:GetBossSingleData()
    local cfgs = XDataCenter.FubenBossSingleManager.GetScoreRewardCfg(bossSingleData.LevelType)
    local canGetList = {}
    local unGetList = {}
    local gotList = {}

    for i = 1, #cfgs do
        local canGet = bossSingleData.TotalScore >= cfgs[i].Score
        local isGet = XDataCenter.FubenBossSingleManager.CheckRewardGet(cfgs[i].Id)
        if canGet and not isGet then
            table.insert(canGetList, cfgs[i])
        elseif not canGet then
            table.insert(unGetList, cfgs[i])
        else
            table.insert(gotList, cfgs[i])
        end
    end

    for i = 1, #unGetList do
        table.insert(canGetList, unGetList[i])
    end

    for i = 1, #gotList do
        table.insert(canGetList, gotList[i])
    end

    local curScore = CS.XTextManager.GetText("BossSingleScore2", bossSingleData.TotalScore)
    self.TxtCurScore.text = curScore

    for i = 1, #canGetList do
        local grid = self._GridBossScoreList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridBossScore)
            grid = XUiGridBossScore.New(ui, self, self._RootUi)
            grid.Transform:SetParent(self.PanelScoreContent, false)
            self._GridBossScoreList[i] = grid
        end

        grid:SetData(canGetList[i], bossSingleData.TotalScore)
        grid:Open()
    end

    for i = #canGetList + 1, #self._GridBossScoreList do
        self._GridBossScoreList[i]:Close()
    end
end

function XUiPanelScoreInfo:OnBtnBlockClick()
    self._RootUi:PlayAnimation("AnimScoreInfoDisable", function()
        self:Close()
    end)
end

return XUiPanelScoreInfo