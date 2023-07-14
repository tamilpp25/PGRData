local XUiRewardEventNodePanel = XClass(nil, "XUiRewardEventNodePanel")

function XUiRewardEventNodePanel:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)
    self.RootUi = rootUi
    -- XALocalRewardEventNode | XAGlobalRewardEventNode
    self.Node = nil
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.OnBtnComfirmClicked)
end

-- node : XALocalRewardEventNode | XAGlobalRewardEventNode
function XUiRewardEventNodePanel:SetData(node)
    self.Node = node
    self.TxtContent.text = node:GetDesc()
    self.BtnConfirm:SetNameByGroup(0, node:GetBtnConfirmText())
    -- 创建奖励 目前只有一个
    XUiGridCommon.New(self.RootUi, self.GridReward):Refresh({
        TemplateId = node:GetItemId(),
        Count = node:GetItemCount()
    })
end

function XUiRewardEventNodePanel:OnBtnComfirmClicked()
    self.Node:RequestTriggerNode(function(newEventNode)
        self.RootUi:RefreshNode(newEventNode)
    end)
end

return XUiRewardEventNodePanel
