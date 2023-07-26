-- 新手任务二期
local XUiPanelNewbieTaskSuccess = XClass(nil, "XUiPanelNewbieTaskSuccess")

function XUiPanelNewbieTaskSuccess:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:RegisterUiEvents()
end

function XUiPanelNewbieTaskSuccess:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnTongBlack, self.OnBtnTongBlackClick)
end

function XUiPanelNewbieTaskSuccess:OnBtnTongBlackClick()
    XDataCenter.NewbieTaskManager.GetNewbieHonorReward(function(rewards)
        XUiManager.OpenUiObtain(rewards, CS.XTextManager.GetText("DailyActiveRewardTitle"), function()
            self.RootUi:OnRewardTaskFinish(rewards)
        end, nil)
    end)
end

return XUiPanelNewbieTaskSuccess