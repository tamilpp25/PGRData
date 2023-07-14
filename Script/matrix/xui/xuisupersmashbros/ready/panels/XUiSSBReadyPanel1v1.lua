
local XUiSSBReadyPanel1v1 = XClass(nil, "XUiSSBReadyPanel1v1")

function XUiSSBReadyPanel1v1:Ctor(uiPrefab, mode, rootUi)
    self.Mode = mode
    self.RootUiCloseFunc = function() rootUi:Close() end
    self.RootUiRefresh = function() rootUi:Refresh() end
    self.RootUiNextEnemy = function() rootUi:ConfirmNextEnemy() end
    self.RootUiEnterFight = function() rootUi:OnEnterFight() end
    XTool.InitUiObjectByUi(self, uiPrefab)
    self:InitPanel()
end

function XUiSSBReadyPanel1v1:InitPanel()
    self:InitBtns()
    self:InitInfos()
end

function XUiSSBReadyPanel1v1:InitBtns()
    self.BtnNextFight.CallBack = function() self:OnClickBtnNextFight() end
    self.BtnReFight.CallBack = function() self:OnClickBtnReFight() end
end

function XUiSSBReadyPanel1v1:InitInfos()
    local isLine = self.Mode:GetIsLinearStage()
    if not isLine then
        self.TxtTime.gameObject:SetActiveEx(false)
        self.TxtProgress.gameObject:SetActiveEx(false)
    else
        self.TxtTime.gameObject:SetActiveEx(true)
        self.TxtProgress.gameObject:SetActiveEx(true)
        self.TxtTimeNumber.text = XUiHelper.GetTime(self.Mode:GetSpendTime(), XUiHelper.TimeFormatType.DEFAULT)
        self.TxtProgressNumber.text = self.Mode:GetLineProgress()
    end
end

function XUiSSBReadyPanel1v1:Refresh()
    local isStart = self.Mode:CheckIsStart()
    local isEnd = self.Mode:CheckIsEnd()
    local isWin = self.Mode:CheckIsWin()
    local buttonName = ""
    if isStart then
        buttonName = XUiHelper.GetText("SSBStartFight")
    elseif isEnd then
        buttonName = XUiHelper.GetText("SSBConfirmFight")
    else
        buttonName = XUiHelper.GetText("SSBNextFight")
    end
    self.BtnReFight.gameObject:SetActiveEx(not isStart)
    self.BtnNextFight.gameObject:SetActiveEx(not (isEnd and not isWin))
    self.BtnNextFight:SetName(buttonName)
    if self.Mode:GetIsLinearStage() then
        self.TxtTimeNumber.text = XUiHelper.GetTime(self.Mode:GetSpendTime(), XUiHelper.TimeFormatType.DEFAULT)
        self.TxtProgressNumber.text = self.Mode:GetLineProgress()
    end
end

function XUiSSBReadyPanel1v1:OnClickBtnNextFight()
    if self.Mode:GetIsLinearStage() then
        --检查是否已打完关卡
        if self.Mode:CheckIsEnd() then
            --再检查是赢了还是输了
            if self.Mode:CheckIsWin() then
                XDataCenter.SuperSmashBrosManager.BattleConfirm(function(rewardList)
                        XLuaUiManager.Open("UiSuperSmashBrosSettle", self.Mode)
                    end, false)
            else
                XDataCenter.SuperSmashBrosManager.BattleConfirm(function(rewardList)
                        XLuaUiManager.Open("UiSuperSmashBrosSettle", self.Mode)
                    end, false)
            end
        else
            if self.Mode:GetConfirmFlag() then
                XDataCenter.SuperSmashBrosManager.BattleConfirm(function(rewardList)
                        if self.RootUiNextEnemy then
                            self.RootUiNextEnemy()
                        end
                    end, false)
            else
                self.RootUiEnterFight()
            end
        end
        return
    end
    --检查是否已打完关卡
    if self.Mode:CheckIsEnd() then
        --再检查是赢了还是输了
        if self.Mode:CheckIsWin() then
            XDataCenter.SuperSmashBrosManager.BattleConfirm(function(rewardList, score, teamItem)
                    local isRewardList = rewardList and next(rewardList)
                    local isTeamItem = teamItem and teamItem > 0
                    if not isRewardList and not isTeamItem then
                        XDataCenter.SuperSmashBrosManager.ResetMode()
                        self.RootUiCloseFunc()
                    else
                        XLuaUiManager.Open("UiSuperSmashBrosObtain", score, rewardList, teamItem, function()
                                XDataCenter.SuperSmashBrosManager.ResetMode()
                                self.RootUiCloseFunc()
                            end)
                    end
                end, false)
        else
            XDataCenter.SuperSmashBrosManager.BattleConfirm(function(rewardList)
                    XDataCenter.SuperSmashBrosManager.ResetMode()
                    self.RootUiCloseFunc()
                end, false)
        end
        -- 重置彩蛋机器人数据
        XDataCenter.SuperSmashBrosManager.ResetEggRobotOpen()
    elseif self.Mode:CheckIsStart() then
        self.RootUiEnterFight()
    else
        if self.Mode:GetConfirmFlag() then
            XDataCenter.SuperSmashBrosManager.BattleConfirm(function(rewardList)
                    self.RootUiEnterFight()
                end, false)
        else
            self.RootUiEnterFight()
        end
    end
end

function XUiSSBReadyPanel1v1:OnClickBtnReFight()
    local stageConfig = XDataCenter.FubenManager.GetStageCfg(self.Mode:GetNextStageId())
    local isAssist = false
    local challengeCount = 1
    XDataCenter.FubenManager.EnterFight(stageConfig, nil, isAssist, challengeCount)
end

return XUiSSBReadyPanel1v1