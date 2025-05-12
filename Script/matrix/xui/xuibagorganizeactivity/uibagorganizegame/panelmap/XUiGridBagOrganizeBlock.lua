---@class XUiGridBagOrganizeBlock
---@field _Control XBagOrganizeActivityControl
---@field _GameControl XBagOrganizeActivityGameControl
local XUiGridBagOrganizeBlock = XClass(XUiNode, 'XUiGridBagOrganizeBlock')

local focusColor = nil
local disableColor = CS.UnityEngine.Color(1,1,1,0)

function XUiGridBagOrganizeBlock:OnStart(x, y)
    self.X = x
    self.Y = y
    self._DefaultColor = self.Image.color
    self:Init()

    if not focusColor then
        local colorStr = string.gsub(self._Control:GetClientConfigText('BlockFocusColor'), '#', '')
        focusColor = XUiHelper.Hexcolor2Color(colorStr)
    end
end

function XUiGridBagOrganizeBlock:Init()
    self._GameControl = self._Control:GetGameControl()
    self._Enabled = self._GameControl.MapControl:GetBlockIsEnabled(self.X, self.Y)

    self:RefreshEnableStateShow()
    
    return self._Enabled
end

function XUiGridBagOrganizeBlock:RefreshEnableStateShow()
    if not self._Enabled then
        self.Image.color = disableColor
    else
        self.Image.color = self._DefaultColor
    end
end

function XUiGridBagOrganizeBlock:SetFocusState(isFocus)
    if isFocus and self._Enabled then
        self.Image.color = focusColor
    else
        self:RefreshEnableStateShow()
    end
end

function XUiGridBagOrganizeBlock:GetIsEnabled()
    return self._Enabled
end

return XUiGridBagOrganizeBlock