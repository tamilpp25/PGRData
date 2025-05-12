

---@class XUiPanelSGValueChange
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
local XUiPanelSGValueChange = XClass(nil, "XUiPanelSGValueChange")

local ColorEnum = {
    Equal = CS.UnityEngine.Color.white,
    Less = XUiHelper.Hexcolor2Color("F54024"),
    Great = XUiHelper.Hexcolor2Color("84E745"),
}

function XUiPanelSGValueChange:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiPanelSGValueChange:RefreshView(num, originNum)
    self:RefreshViewWithTxtComponent(num, originNum, self.TxtNum)
end

function XUiPanelSGValueChange:RefreshViewWithTxtComponent(num, originNum, txtComponent)
    originNum = originNum or num
    txtComponent.gameObject:SetActiveEx(num ~= 0)
    local txt
    if num > 0 then
        txt = string.format("+%d", num)
    elseif num < 0 then
        txt = num
    end

    if txt then
        txtComponent.text = txt
        local color
        if num >= 0 then
            if num > originNum then
                color = ColorEnum.Great
            elseif num == originNum then
                color = ColorEnum.Equal
            else
                color = ColorEnum.Less
            end
        else
            color = ColorEnum.Less
        end
        txtComponent.color = color
    end
end

return XUiPanelSGValueChange