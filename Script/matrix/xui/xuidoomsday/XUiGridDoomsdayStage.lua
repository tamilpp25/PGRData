local MAX_STAR_NUM = 3 --关卡最大目标星数

local XUiGridDoomsdayStage = XClass(nil, "XUiGridDoomsdayStage")

function XUiGridDoomsdayStage:Ctor(clickCb)
    self.ClickCb = clickCb
end

function XUiGridDoomsdayStage:Init()
    self.BtnStage.CallBack = handler(self, self.OnClickBtn)
    self:SetSelect(false)
end

function XUiGridDoomsdayStage:Refresh(stageId)
    self.StageId = stageId
    local stageData = XDataCenter.DoomsdayManager.GetStageData(stageId)
    self.StageData = stageData

    self.TxtStageOrder.text = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "Order")

    local canFight, leftTime = stageData:CanFight()
    self.Parent:BindViewModelPropertyToObj(
        stageData,
        function(isFighting)
            self.PanelStars.gameObject:SetActiveEx(canFight and not isFighting)
            self.PanelProgress.gameObject:SetActiveEx(canFight and isFighting)
            self.PanelStageLock.gameObject:SetActiveEx(not canFight)
            self.PanelStagePass.gameObject:SetActiveEx(false)

            if canFight then
                if isFighting then
                    --当前进度（当前天数/总天数）
                    local maxDay = stageData:GetProperty("_MaxDay")
                    self.Parent:BindViewModelPropertyToObj(
                        stageData,
                        function(day)
                            self.TxtPercentNormal.text = string.format("%s/%s", day, maxDay)
                            self.ImgPercentNormal.fillAmount = day / maxDay
                        end,
                        "_Day"
                    )

                    self.PanelStagePass.gameObject:SetActiveEx(false)
                else
                    --通关状态
                    self.Parent:BindViewModelPropertyToObj(
                        stageData,
                        function(passed)
                            self.PanelStagePass.gameObject:SetActiveEx(passed)
                        end,
                        "_Passed"
                    )

                    --最大星数
                    local maxStar = #XDoomsdayConfigs.StageConfig:GetProperty(stageId, "SubTaskId")
                    for i = 1, MAX_STAR_NUM do
                        self["Star" .. i].gameObject:SetActiveEx(i <= maxStar)
                    end

                    --当前星数
                    self.Parent:BindViewModelPropertyToObj(
                        stageData,
                        function(star)
                            for i = 1, maxStar do
                                self["Img" .. i].gameObject:SetActiveEx(i <= star)
                            end
                        end,
                        "_Star"
                    )
                end
            else
                local leftDay, timeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.DOOMSDAY)
                leftDay = leftDay .. timeStr
                self.TxtLockTime.text = CsXTextManagerGetText("DoomsdayStageStartLeftDay", leftDay)
            end
        end,
        "_Fighting"
    )
end

function XUiGridDoomsdayStage:SetSelect(value)
    self.ImageSelected.gameObject:SetActiveEx(value)
end

function XUiGridDoomsdayStage:OnClickBtn()
    local canFight, leftTime = self.StageData:CanFight()
    if not canFight then
        local leftDay, timeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.DOOMSDAY)
        leftDay = leftDay .. timeStr
        XUiManager.TipMsg(CsXTextManagerGetText("DoomsdayStageStartLeftDay", leftDay))
        return
    end
    self.ClickCb(self.StageId)
end

return XUiGridDoomsdayStage
