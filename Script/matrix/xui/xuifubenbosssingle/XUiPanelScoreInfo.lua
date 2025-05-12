---@class XUiPanelScoreInfo : XUiNode
---@field _RootUi XUiFubenBossSingle
---@field _Control XFubenBossSingleControl
local XUiPanelScoreInfo = XClass(XUiNode, "XUiPanelScoreInfo")
local XUiGridBossScore = require("XUi/XUiFubenBossSingle/XUiGridBossScore")

function XUiPanelScoreInfo:OnStart(rootUi)
    self._RootUi = rootUi
    ---@type XUiGridBossScore[]
    self._GridBossScoreList = {}
    ---@type XUiGridBossScore
    self._GridAllReceive = nil
    self.GridBossScore.gameObject:SetActive(false)
    self:_RegisterButtonListeners()
end

function XUiPanelScoreInfo:OnEnable()
    self:_Refresh()
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_SYNC, self._Refresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_BOSS_SINGLE_GET_REWARD, self._Refresh, self)
end

function XUiPanelScoreInfo:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_SYNC, self._Refresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_BOSS_SINGLE_GET_REWARD, self._Refresh, self)
end

function XUiPanelScoreInfo:_RegisterButtonListeners()
    XUiHelper.RegisterClickEvent(self, self.BtnBlock, self.OnBtnBlockClick, true)
end

function XUiPanelScoreInfo:_Refresh()
    ---@type XBossSingle
    local bossSingleData = self._RootUi:GetBossSingleData()
    local configs = self._Control:GetScoreRewardConfig(bossSingleData:GetBossSingleLevelType())
    local canGetList = {}
    local unGetList = {}
    local gotList = {}

    for i = 1, #configs do
        local canGet = bossSingleData:GetBossSingleTotalScore() >= configs[i].Score
        local isGet = self._Control:CheckRewardGet(configs[i].Id)
        if canGet and not isGet then
            table.insert(canGetList, configs[i])
        elseif not canGet then
            table.insert(unGetList, configs[i])
        else
            table.insert(gotList, configs[i])
        end
    end

    for i = 1, #unGetList do
        table.insert(canGetList, unGetList[i])
    end

    for i = 1, #gotList do
        table.insert(canGetList, gotList[i])
    end

    local isCanReceiveCount = 0
    local totalScore = bossSingleData:GetBossSingleTotalScore()
    local curScore = XUiHelper.GetText("BossSingleScore2", bossSingleData:GetBossSingleTotalScore())
    self.TxtCurScore.text = curScore

    for i = 1, #canGetList do
        local grid = self._GridBossScoreList[i]

        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridBossScore)
            grid = XUiGridBossScore.New(ui, self, self._RootUi)
            grid.Transform:SetParent(self.PanelScoreContent, false)
            self._GridBossScoreList[i] = grid
        end

        local scoreConfig = canGetList[i]
        local isGet = self._Control:CheckRewardGet(scoreConfig.Id)

        if not isGet and totalScore >= scoreConfig.Score then
            isCanReceiveCount = isCanReceiveCount + 1
        end

        grid:SetData(scoreConfig, totalScore)
        grid:Open()
    end
    for i = #canGetList + 1, #self._GridBossScoreList do
        self._GridBossScoreList[i]:Close()
    end

    self:_RefreshAllReceive(isCanReceiveCount > 0)
end

function XUiPanelScoreInfo:_RefreshAllReceive(isShow)
    if isShow then
        if not self._GridAllReceive then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridBossScore, self.PanelScoreContent)

            self._GridAllReceive = XUiGridBossScore.New(ui, self, self._RootUi, true)
        end
        self._GridAllReceive.Transform:SetAsFirstSibling()
        self._GridAllReceive:Open()
    else
        if self._GridAllReceive then
            self._GridAllReceive:Close()
        end
    end
end

function XUiPanelScoreInfo:OnBtnBlockClick()
    self._RootUi:PlayAnimation("AnimScoreInfoDisable", function()
        self:Close()
    end)
end

return XUiPanelScoreInfo