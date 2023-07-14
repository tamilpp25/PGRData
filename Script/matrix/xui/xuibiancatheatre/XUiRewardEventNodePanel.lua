local XUiBiancaTheatreItemGrid = require("XUi/XUiBiancaTheatre/Common/XUiBiancaTheatreItemGrid")
local XUiRewardEventNodePanel = XClass(nil, "XUiRewardEventNodePanel")

function XUiRewardEventNodePanel:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)
    self.RootUi = rootUi
    -- XALocalRewardEventNode | XAGlobalRewardEventNode
    self.Node = nil
    XUiHelper.RegisterClickEvent(self, self.BtnOK, self.OnBtnComfirmClicked)
    self.PanelIcon = XUiHelper.TryGetComponent(ui.transform, "PanelIcon")
    self.Bg = XUiHelper.TryGetComponent(ui.transform, "Bg")
    self.ItemGridList = {}
end

-- node : XALocalRewardEventNode | XAGlobalRewardEventNode
function XUiRewardEventNodePanel:SetData(node)
    self.Node = node
    self.TxtContent.text = node:GetDesc()
    self.BtnOK:SetName(node:GetBtnConfirmText())
    if self.Node.EventConfig.StepRewardItemType == XBiancaTheatreConfigs.XEventStepItemType.OpenVision or
        self.Node.EventConfig.StepRewardItemType == XBiancaTheatreConfigs.XEventStepItemType.ObtainVision
    then
        self.Bg.gameObject:SetActiveEx(false)
        self.PanelReward.gameObject:SetActiveEx(false)
        return
    end
    -- 创建奖励
    local itemIdList = node:GetItemIdList()
    local itemType = node:GetStepRewardItemType()
    local count
    for i, itemId in ipairs(itemIdList) do
        count = node:GetItemCount(i)
        local itemGrid = self.ItemGridList[i]
        if not itemGrid then
            local gridPanel = i ~= 1 and XUiHelper.Instantiate(self.PanelReward, self.PanelIcon.transform)
            itemGrid = XUiBiancaTheatreItemGrid.New(i == 1 and self.GridReward or XUiHelper.TryGetComponent(gridPanel.transform, "Grid256New"), nil, gridPanel)
            self.ItemGridList[i] = itemGrid
        end
        itemGrid:Refresh(itemId, nil, count, itemType)
        if itemGrid.RootUi then
            itemGrid.RootUi.gameObject:SetActiveEx(true)
        end
    end
    for i = #itemIdList + 1, #self.ItemGridList do
        if self.ItemGridList[i].RootUi then
            self.ItemGridList[i].RootUi.gameObject:SetActiveEx(false)
        end
    end
end

function XUiRewardEventNodePanel:OnBtnComfirmClicked()
    self.Node:RequestTriggerNode(function(newEventNode)
        self.RootUi:RefreshNode(newEventNode)
    end)
end

return XUiRewardEventNodePanel
