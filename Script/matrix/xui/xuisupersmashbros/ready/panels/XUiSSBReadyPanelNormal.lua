
local XUiSSBReadyPanelNormal = XClass(nil, "XUiSSBReadyPanelNormal")

function XUiSSBReadyPanelNormal:Ctor(uiPrefab, mode, rootUi)
    self.Mode = mode
    self.RootUiCloseFunc = function() rootUi:Close() end
    self.RootUiEnterFight = function() rootUi:OnEnterFight() end
    XTool.InitUiObjectByUi(self, uiPrefab)
    self:InitPanel()
end

function XUiSSBReadyPanelNormal:InitPanel()
    self.BtnFight.CallBack = function() self:OnClickBtnFight() end
    self.BtnReFight.CallBack = function() self:OnClickBtnReFight() end
end

function XUiSSBReadyPanelNormal:Refresh()
    local isStart = self.Mode:CheckIsStart()
    local isEnd = self.Mode:CheckIsEnd()
    local buttonName = ""
    if isStart then
        buttonName = XUiHelper.GetText("SSBStartFight")
    elseif isEnd then
        buttonName = XUiHelper.GetText("SSBConfirmFight")
    else
        buttonName = XUiHelper.GetText("SSBNextFight")
    end
    self.BtnReFight.gameObject:SetActiveEx(not isStart)
    self.BtnFight:SetName(buttonName)
end

function XUiSSBReadyPanelNormal:OnClickBtnFight()
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

function XUiSSBReadyPanelNormal:OnClickBtnReFight()
    self.RootUiEnterFight()
end

return XUiSSBReadyPanelNormal