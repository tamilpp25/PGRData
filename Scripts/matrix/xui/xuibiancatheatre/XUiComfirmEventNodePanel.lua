local XUiComfirmEventNodePanel = XClass(nil, "XUiComfirmEventNodePanel")

function XUiComfirmEventNodePanel:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)
    self.RootUi = rootUi
    -- XATalkEventNode | XABattleEventNode | XMovieEventNode
    self.Node = nil
end

-- node : XATalkEventNode | XABattleEventNode | XMovieEventNode
function XUiComfirmEventNodePanel:SetData(node)
    self.Node = node
    self.TxtContent.text = node:GetDesc()
    self.BtnOK:SetNameByGroup(0, node:GetBtnConfirmText())
    XUiHelper.RegisterClickEvent(self, self.BtnOK, self.OnBtnComfirmClicked)
end

function XUiComfirmEventNodePanel:OnBtnComfirmClicked()
    self.Node:RequestTriggerNode(function(newEventNode)
        self.RootUi:RefreshNode(newEventNode)
    end)
end

return XUiComfirmEventNodePanel
