local BaseProxy = require("XUi/XUiExpedition/MainPage/DetailProxy/XUiExpeditionDetailProxy")
--故事关卡详细代理
local XUiExpeditionStoryDetailProxy = XClass(BaseProxy, "XUiExpeditionStoryDetailProxy")

function XUiExpeditionStoryDetailProxy:InitPanel()
    self.Ui.PanelBattle.gameObject:SetActiveEx(false)
    self.Ui.PanelStory.gameObject:SetActiveEx(true)
    self:InitPanelStory()
end

function XUiExpeditionStoryDetailProxy:InitPanelStory()
    self.PanelStory = {}
    XTool.InitUiObjectByUi(self.PanelStory, self.Ui.PanelStory)
    self.PanelStory.TxtStoryName.text = self.Ui.EStage:GetStageName()
    self.PanelStory.TxtStoryDec.text = self.Ui.EStage:GetStageDes()
    self.PanelStory.TxtRecruit.text = self.Ui.EStage:GetDrawTimesRewardStr()
    self.PanelStory.BtnEnterStory.CallBack = function()
        self:OnClickBtnEnterStory()
    end
end

function XUiExpeditionStoryDetailProxy:OnClickBtnEnterStory()
    self.Ui:Close()
    if self.Ui.EStage:GetIsPass() then
        XDataCenter.MovieManager.PlayMovie(self.Ui.EStage:GetBeginStoryId())
    else
        XDataCenter.FubenManager.FinishStoryRequest(self.Ui.EStage:GetStageId(), function()
                XDataCenter.MovieManager.PlayMovie(self.Ui.EStage:GetBeginStoryId(), function()
                        if self.Ui and self.Ui.EStage then
                            self.Ui.EStage:SetPass()
                        end
                    end)
            end)
    end
end

return XUiExpeditionStoryDetailProxy