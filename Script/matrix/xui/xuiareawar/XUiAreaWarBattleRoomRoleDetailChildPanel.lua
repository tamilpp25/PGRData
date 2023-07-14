local XUiAreaWarBattleRoomRoleDetailChildPanel = XClass(nil, "XUiAreaWarBattleRoomRoleDetailChildPanel")

function XUiAreaWarBattleRoomRoleDetailChildPanel:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.ConditionGrids = {}
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    XDataCenter.ItemManager.AddCountUpdateListener(
        {
            XDataCenter.ItemManager.ItemId.AreaWarCoin,
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        },
        handler(self, self.UpdateAssets),
        self.AssetActivityPanel
    )
    self:UpdateAssets()
    self.GridCondition.gameObject:SetActiveEx(false)
end

function XUiAreaWarBattleRoomRoleDetailChildPanel:UpdateAssets()
    self.AssetActivityPanel:Refresh(
        {
            XDataCenter.ItemManager.ItemId.AreaWarCoin,
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        },
        {
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        }
    )
end

function XUiAreaWarBattleRoomRoleDetailChildPanel:Refresh(currentEntityId)
    --派遣条件
    local conditions = XAreaWarConfigs.GetDispatchCharacterCondtionIds(currentEntityId)
    for index, conditionId in ipairs(conditions) do
        local grid = self.ConditionGrids[index]
        if not grid then
            local go =
                index == 1 and self.GridCondition or CSObjectInstantiate(self.GridCondition, self.PanelConditionList)
            grid = XTool.InitUiObjectByUi({}, go)
            self.ConditionGrids[index] = grid
        end

        --条件描述
        local conditionDesc = XAreaWarConfigs.GetDispatchConditionDesc(conditionId)
        grid.Text.text = conditionDesc

        grid.GameObject:SetActiveEx(true)
    end
    for index = #conditions + 1, #self.ConditionGrids do
        self.ConditionGrids[index].GameObject:SetActiveEx(false)
    end
end

return XUiAreaWarBattleRoomRoleDetailChildPanel
