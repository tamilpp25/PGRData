---@class XUiPanelRogueSimPropOption : XUiNode
---@field private _Control XRogueSimControl
---@field Parent XUiRogueSimChoose
local XUiPanelRogueSimPropOption = XClass(XUiNode, "XUiPanelRogueSimPropOption")

function XUiPanelRogueSimPropOption:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnProp, self.OnBtnPropClick)
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
                handler(self, self.OnBtnSelectClick),
                handler(self, self.OnBtnSureClick))
            self.GridPropList[index] = grid
        end
        grid:Open()
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
    if curGrid and curGrid:GetPropId() == grid:GetPropId() then
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
function XUiPanelRogueSimPropOption:OnBtnSureClick(propId)
    local index = 0
    for i, grid in pairs(self.GridPropList) do
        if grid:GetPropId() == propId then
            index = i
            break
        end
    end
    if not XTool.IsNumberValid(index) then
        return
    end
    -- 服务端下标是从0开始的
    index = index - 1
    self._Control:RogueSimPickRewardRequest(self.Id, { index }, function(rewardIds)
        local type = self._Control:GetHasPopupDataType()
        if type == XEnumConst.RogueSim.PopupType.None then
            self.Parent:Close()
            return
        end

        local rewardId = 0
        if rewardIds and #rewardIds == 1 then
            rewardId = rewardIds[1] or 0
        end

        -- 是否是奖励弹窗
        if type == XEnumConst.RogueSim.PopupType.Reward then
            self._Control:ShowNextPopup(self.Parent.Name, type, rewardId)
        else
            -- 显示下一个弹框
            self._Control:ShowNextPopup(self.Parent.Name, type)
        end
    end)
end

function XUiPanelRogueSimPropOption:OnBtnPropClick()
    XLuaUiManager.Open("UiRogueSimPropBag")
end

return XUiPanelRogueSimPropOption