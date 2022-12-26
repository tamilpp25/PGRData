--虚像地平线主界面子页面：玩法关卡点击后的关卡详细
local XUiExpeditionStageDetail = XLuaUiManager.Register(XLuaUi, "UiExpeditionStageDetail")
function XUiExpeditionStageDetail:OnAwake()
    XTool.InitUiObject(self)
    self.GridCommon.gameObject:SetActive(false)
    self.PanelAsset = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint)
end

function XUiExpeditionStageDetail:OnStart(detailComponent)
    self.Chapter = detailComponent.ChapterComponent
    self.RootUi = detailComponent.RootUi
end

function XUiExpeditionStageDetail:OnEnable()
    self.Component = self.Chapter.StageSelected
    self.EStage = self.Component.EStage
    self.Component.Ui = self
    self.Component:OnUiEnable(self)
end

function XUiExpeditionStageDetail:OnDisable()
    if self.Component then self.Component:OnUiDisable(self) end
end

function XUiExpeditionStageDetail:Hide()
    self:Close()
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL)
end

function XUiExpeditionStageDetail:OnEnterBattle()
    if not XDataCenter.ExpeditionManager.CheckHaveMember() then
        XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionNeedRecruitMember"))
        return
    end
    if not XDataCenter.FubenManager.CheckPreFight(self.EStage:GetStageCfg()) then
        return
    end
    self:Hide()
    XLuaUiManager.Open("UiNewRoomSingle", self.EStage:GetStageId())
end

function XUiExpeditionStageDetail:RefreshChapter(detailComponent)
    self.Chapter = detailComponent.ChapterComponent
end

function XUiExpeditionStageDetail:OnStoryEnterClick()
    self:Hide()
    if self.EStage:GetIsPass() then
        XDataCenter.MovieManager.PlayMovie(self.EStage:GetBeginStoryId())
    else
        XDataCenter.FubenManager.FinishStoryRequest(self.EStage:GetStageId(), function()
                XDataCenter.MovieManager.PlayMovie(self.EStage:GetBeginStoryId(), function()
                        self.EStage:SetPass()
                        self.RootUi:OnSyncStage()
                    end)
            end)
    end
end
return XUiExpeditionStageDetail