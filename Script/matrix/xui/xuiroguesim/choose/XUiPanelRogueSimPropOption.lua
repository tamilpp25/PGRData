---@class XUiPanelRogueSimPropOption : XUiNode
---@field private _Control XRogueSimControl
---@field Parent XUiRogueSimChoose
local XUiPanelRogueSimPropOption = XClass(XUiNode, "XUiPanelRogueSimPropOption")

function XUiPanelRogueSimPropOption:OnStart()
    self.GridProp.gameObject:SetActiveEx(false)
    ---@type XUiGridRogueSimProp[]
    self.GridPropList = {}
end

function XUiPanelRogueSimPropOption:OnDisable()
    self:CancelPropSelect()
end

---@param id number 奖励自增Id
function XUiPanelRogueSimPropOption:Refresh(id)
    self.Id = id
    self.PropData = self._Control:GetMultiSelectPropRewardListById(id)
    self:RefreshProp()
end

-- 刷新道具
function XUiPanelRogueSimPropOption:RefreshProp()
    for index, data in ipairs(self.PropData) do
        local grid = self.GridPropList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridProp, self.ListProp)
            grid = require("XUi/XUiRogueSim/Common/XUiGridRogueSimProp").New(go, self,
                handler(self, self.OnBtnSelectClick), handler(self, self.OnBtnSureClick))
            self.GridPropList[index] = grid
        end
        grid:Open()
        grid:SetIndex(index)
        grid:Refresh(data.ItemId)
    end
    for i = #self.PropData + 1, #self.GridPropList do
        self.GridPropList[i]:Close()
    end
end

-- 选择道具
---@param grid XUiGridRogueSimProp
function XUiPanelRogueSimPropOption:OnBtnSelectClick(grid)
    local curGrid = self.CurPropGrid
    if curGrid and curGrid:GetIndex() == grid:GetIndex() then
        return
    end
    -- 取消上一次选择
    if curGrid then
        curGrid:OnUnSelect()
    end
    -- 选中当前选择
    grid:OnSelect()
    self.CurPropGrid = grid
end

-- 取消选择
function XUiPanelRogueSimPropOption:CancelPropSelect()
    if not self.CurPropGrid then
        return
    end
    -- 取消选择
    self.CurPropGrid:OnUnSelect()
    self.CurPropGrid = nil
end

-- 确定选择
function XUiPanelRogueSimPropOption:OnBtnSureClick()
    if not self.CurPropGrid then
        return
    end
    local index = self.CurPropGrid:GetIndex()
    if not XTool.IsNumberValid(index) then
        return
    end
    -- 服务端下标是从0开始的
    index = index - 1
    self._Control:RogueSimPickRewardRequest(self.Id, { index }, function(rewardIds)
        local rewardId = 0
        if rewardIds and #rewardIds == 1 then
            rewardId = rewardIds[1] or 0
        end
        local typeData = {
            NextType = XEnumConst.RogueSim.PopupType.Reward,
            ArgType = XEnumConst.RogueSim.PopupType.Reward,
        }
        self._Control:CheckNeedShowNextPopup(self.Parent.Name, true, typeData, rewardId)
    end)
end

return XUiPanelRogueSimPropOption
