local XUiFubenMaintaineractionFighting = XLuaUiManager.Register(XLuaUi, "UiFubenMaintaineractionFighting")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiFubenMaintaineractionFighting:OnStart(stageId)
    self:SetButtonCallBack()
    self.GridCommon.gameObject:SetActiveEx(false)
    self.StageId = stageId
    self:ShowInfo()
end

function XUiFubenMaintaineractionFighting:OnEnable()
    self:PlayAnimation("AnimBegin")
end

function XUiFubenMaintaineractionFighting:SetButtonCallBack()
    self.BtnEnter.CallBack = function()
        self:OnBtnEnterClick()
    end
    self.BtnRun.CallBack = function()
        self:OnBtnRunClick()
    end
    self.BtnClose.CallBack = function()
        self:OnBtnRunClick()
    end
end

function XUiFubenMaintaineractionFighting:OnBtnEnterClick()
    local IsFightComplete = XDataCenter.MaintainerActionManager.CheckIsFightComplete()
    if IsFightComplete then
        XUiManager.TipText("MaintainerActionFightCompleteText")
        return
    end
    if XTool.USENEWBATTLEROOM then
        XLuaUiManager.PopThenOpen("UiBattleRoleRoom", self.StageId)
    else
        XLuaUiManager.PopThenOpen("UiNewRoomSingle", self.StageId)
    end

end

function XUiFubenMaintaineractionFighting:OnBtnRunClick()
    XLuaUiManager.SetMask(true)
    self:PlayAnimation("AnimEnd", function()
        XLuaUiManager.SetMask(false)
        self:Close()
    end)
end

function XUiFubenMaintaineractionFighting:ShowInfo()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local stageLevelcfg = XDataCenter.FubenManager.GetStageLevelControl(self.StageId)
    local rewardId = (stageLevelcfg and stageLevelcfg.FinishRewardShow > 0 and stageLevelcfg.FinishRewardShow) or
    (stageCfg and stageCfg.FinishRewardShow > 0 and stageCfg.FinishRewardShow) or 0

    self.TxtTitle.text = stageCfg.Name
    self.TextDesc.text = stageCfg.Description

    local rewards = XRewardManager.GetRewardList(rewardId)
    if rewards then
        for i, item in pairs(rewards) do
            local obj = CS.UnityEngine.Object.Instantiate(self.GridCommon, self.PanelDropContent)
            local grid = XUiGridCommon.New(self, obj)
            grid:Refresh(item)
            grid.GameObject:SetActive(true)
        end
    end
end

function XUiFubenMaintaineractionFighting:TipDialog(cancelCb, confirmCb)
    local tipTitle = CSTextManagerGetText("TipTitle")
    local content = CSTextManagerGetText("MaintainerActionFightHint")

    XLuaUiManager.Open("UiDialog", tipTitle, content, XUiManager.DialogType.Normal, cancelCb, confirmCb)
end