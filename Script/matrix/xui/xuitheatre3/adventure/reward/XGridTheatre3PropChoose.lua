---@class XGridTheatre3PropChoose : XUiNode
---@field Parent XUiTheatre3PropChoose
---@field _Control XTheatre3Control
local XGridTheatre3PropChoose = XClass(XUiNode, "XGridTheatre3PropChoose")

function XGridTheatre3PropChoose:OnStart()

end

function XGridTheatre3PropChoose:Refresh(id)
    if not XTool.IsNumberValid(id) then
        self.ImgEmpty.gameObject:SetActiveEx(true)
        return
    end
    self.ImgEmpty.gameObject:SetActiveEx(false)

    self._Id = id
    local itemGroupConfig = self._Control:GetItemGroupConfigById(id)
    self._ItemId = itemGroupConfig.ItemId
    local config = self._Control:GetItemConfigById(self._ItemId)
    self.TxtTitle.text = config.Name
    self.TxtDescribe.text = XUiHelper.ConvertLineBreakSymbol(config.Description)
    if not self._Grid then
        ---@type XUiGridTheatre3Reward
        self._Grid = require("XUi/XUiTheatre3/Adventure/Prop/XUiGridTheatre3Reward").New(self.PropGrid, self)
    end
    self._Grid:SetData(self._ItemId, XEnumConst.THEATRE3.EventStepItemType.InnerItem)
    self._Grid:ShowRed(false)
    --self.ImgError.gameObject:SetActiveEx(config.IsFireItem == 1)
    if XTool.IsNumberValid(itemGroupConfig.InitialCondition) then
        local isUnlock, desc = XConditionManager.CheckCondition(itemGroupConfig.InitialCondition)
        self.ImgMask.gameObject:SetActiveEx(not isUnlock)
        self.TxtUnlock.text = desc
    else
        self.ImgMask.gameObject:SetActiveEx(false)
        self.TxtUnlock.text = ""
    end
end

function XGridTheatre3PropChoose:SetSelect(bo)
    self.PanelSelect.gameObject:SetActiveEx(bo)
end

return XGridTheatre3PropChoose