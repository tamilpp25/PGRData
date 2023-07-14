local XUiLifuActivitySingleDetail = XLuaUiManager.Register(XLuaUi,"UiLifuActivitySingleDetail")

function XUiLifuActivitySingleDetail:OnStart(stageId, skipId)
    self.StageId = stageId
    self.SkipId = skipId
    self.RewardPanelList = {}
    self.BtnEnter.CallBack = function()
        self:OnClickBtnEnterFight()
    end
    self.BtnDraw.CallBack = function() 
        self:OnClickBtnSkipDraw()
    end
end

function XUiLifuActivitySingleDetail:OnEnable()
    self:Refresh()
end

function XUiLifuActivitySingleDetail:Refresh()
    if not self.StageId then
        XLog.Error("XUiLifuActivitySingleDetail:Refresh error stageId为空")
        return
    end
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    local desc = XUiHelper.ConvertLineBreakSymbol(stageCfg.Description)
    self.TxtActive1.text = desc
    self.TxtATNums.text = XDataCenter.FubenManager.GetRequireActionPoint(self.StageId)
    
    local rewardId = 0
    local IsFirst = false
    for i = 1, #self.RewardPanelList do
        self.RewardPanelList[i]:Refresh()
    end
    rewardId = stageCfg.FirstRewardShow
    if not stageInfo.Passed then
        IsFirst = true
    end

    if not rewardId or rewardId == 0 then
        return
    end

    local rewardsList = XRewardManager.GetRewardList(rewardId)
    if not rewardsList then return end

    for i = 1, #rewardsList do
        local panel = self.RewardPanelList[i]
        if not panel then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
            ui.transform:SetParent(self.PanelDropContent, false)
            panel = XUiGridCommon.New(self, ui)
            table.insert(self.RewardPanelList, panel)
        end
        local temp = {
            ShowReceived = not IsFirst
        }
        panel:Refresh(rewardsList[i], temp)
    end
end

function XUiLifuActivitySingleDetail:OnClickBtnEnterFight()
    XLuaUiManager.Open("UiNewRoomSingle", self.StageId)
end

function XUiLifuActivitySingleDetail:OnClickBtnSkipDraw()
    if self.SkipId then
        XFunctionManager.SkipInterface(self.SkipId)
    end
end

return XUiLifuActivitySingleDetail