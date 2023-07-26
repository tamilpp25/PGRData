local MAX_ECHELON_NUM = 5

local XUiPanelEchelon = XClass(nil, "XUiPanelEchelon")

function XUiPanelEchelon:Ctor(ui, stageId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.StageId = stageId

    XTool.InitUiObject(self)
    self:Refresh()
end

function XUiPanelEchelon:Refresh()
    local groupId = XDataCenter.BfrtManager.GetGroupIdByBaseStage(self.StageId)

    local fightInfoList = XDataCenter.BfrtManager.GetFightInfoIdList(groupId)
    local echelonNum = #fightInfoList
    for i = 1, echelonNum do
        local go = self["ImgEchelon" .. i]
        if go then
            go.gameObject:SetActiveEx(true)
        end
    end
    for i = echelonNum + 1, MAX_ECHELON_NUM do
        local go = self["ImgEchelon" .. i]
        if go then
            go.gameObject:SetActiveEx(false)
        end
    end

    local logisticsInfoList = XDataCenter.BfrtManager.GetLogisticsInfoIdList(groupId)
    local logisticsNum = #logisticsInfoList
    for i = 1, logisticsNum do
        local go = self["ImgEchelonLogiistics" .. i]
        if go then
            go.gameObject:SetActiveEx(true)
        end
    end
    for i = logisticsNum + 1, MAX_ECHELON_NUM do
        local go = self["ImgEchelonLogiistics" .. i]
        if go then
            go.gameObject:SetActiveEx(false)
        end
    end
end

return XUiPanelEchelon