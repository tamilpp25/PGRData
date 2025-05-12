---@class XUiTheatre4DifficultyGrid : XUiNode
---@field _Control XTheatre4Control
local XUiTheatre4DifficultyGrid = XClass(XUiNode, "UiTheatre4DifficultyGrid")

---@param data XTheatre4SetControlDifficultyData
function XUiTheatre4DifficultyGrid:Update(data)
    ---@type XUiComponent.XUiButton
    local button = self.Button
    button:SetNameByGroup(1, data.Name)
    button:SetNameByGroup(0, data.Temperature)
    if data.IsUnlock then
        button:SetSpriteVisible(false)

        if data.IsSelected then
            button:SetButtonState(CS.UiButtonState.Select)
        else
            button:SetButtonState(CS.UiButtonState.Normal)
        end
    else
        button:SetButtonState(CS.UiButtonState.Disable)
        button:SetSpriteVisible(true)
    end
    if data.IsSelected then
        button:SetNameByGroup(2, data.ExtraDesc)
        button:ActiveTextByGroup(2, true)
    else
        --button:SetButtonState(CS.UiButtonState.Normal)
        button:ActiveTextByGroup(2, false)
    end
end

return XUiTheatre4DifficultyGrid