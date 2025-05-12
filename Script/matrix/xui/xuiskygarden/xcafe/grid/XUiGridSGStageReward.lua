---@class XUiGridSGStageReward : XUiNode
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Parent XUiSkyGardenCafeMain
---@field _Control XSkyGardenCafeControl
local XUiGridSGStageReward = XClass(XUiNode, "XUiGridSGStageReward")

local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

function XUiGridSGStageReward:OnStart()
    self:InitCb()
    self:InitView()
end

function XUiGridSGStageReward:InitCb()
end

function XUiGridSGStageReward:InitView()
    self._GridCommon = XUiGridBWItem.New(self.UiBigWorldItemGrid, self)
end

function XUiGridSGStageReward:Update(data, i)
    if not data then
        self:Close()
        return
    end
    self._GridCommon:Refresh(data.Reward)
    self.TxtCoffeeNum.text = data.Target
end

return XUiGridSGStageReward