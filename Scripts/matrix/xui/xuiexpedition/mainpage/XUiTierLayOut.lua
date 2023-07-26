local XUiTierLayOff = require("XUi/XUiExpedition/MainPage/XUiTierLayOff")
local XUiTierStage = require("XUi/XUiExpedition/MainPage/XUiTierStage")
--展开的关卡层
local XUiTierLayOut = XClass(XUiTierLayOff, "XUiTierLayOut")

function XUiTierLayOut:Ctor()
    self.Stages = {}
end

function XUiTierLayOut:RefreshData(tier)
    XUiTierLayOut.Super.RefreshData(self, tier)
    self:RefreshStages()
end

function XUiTierLayOut:RefreshStages()
    self.GridStage.gameObject:SetActiveEx(false)
    local stages = self.Tier:GetStages()
    if stages then
        for index, stage in pairs(stages) do
            if not self.Stages[index] then
                local obj = CS.UnityEngine.Object.Instantiate(self.GridStage)
                obj.transform:SetParent(self.PanelStageContent, false)
                obj.gameObject:SetActiveEx(false)
                self.Stages[index] = XUiTierStage.New(obj, self.TierUi)
            end
            self.Stages[index]:RefreshData(stage)
        end
    end
end

function XUiTierLayOut:OnClick()
    self.TierUi:OnClickLayOut()
end

function XUiTierLayOut:PlayAnimEnable(onStageShowCb)
    if self.AnimEnable then
        self.AnimEnable:Stop()
        --播放进入界面动画时要先把关卡隐藏
        for _, stage in pairs(self.Stages) do
            stage.GameObject:SetActiveEx(false)
        end
        if self.AnimEnable then
            self.AnimEnable:stopped('+', function()
                    for _, stage in pairs(self.Stages) do
                        stage:OnShow()
                    end
                    if onStageShowCb then
                        onStageShowCb()
                    end
                end)
        end
        self.AnimEnable:Play()
    end
end

function XUiTierLayOut:Show(isEnable)
    XUiTierLayOut.Super.Show(self)
    if not isEnable then --如果是界面启动时则调用另一个动画，不默认直接调用关卡出现动画
        for _, stage in pairs(self.Stages) do
            stage:OnShow()
        end
    end
end

function XUiTierLayOut:Hide(callBack)
    for _, stage in pairs(self.Stages) do
        stage:OnDisable()
    end
    if callBack then
        XScheduleManager.ScheduleOnce(function()
                XUiTierLayOut.Super.Hide(self)
                callBack()
            end, 300)
    else
        XUiTierLayOut.Super.Hide(self)
    end
end

return XUiTierLayOut