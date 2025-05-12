local XUiTheatre3EquipmentTip = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentTip")

---@class XUiTheatre3BubbleEquipment : XLuaUi 装备Tip、套装Tip
---@field _Control XTheatre3Control
local XUiTheatre3BubbleEquipment = XLuaUiManager.Register(XLuaUi, "UiTheatre3BubbleEquipment")

function XUiTheatre3BubbleEquipment:OnAwake()
    self:RegisterClickEvent(self.BtnEmpty, self.Close)
end

function XUiTheatre3BubbleEquipment:OnStart(param, isAdventure, isQuantum)
    self._Param = param
    self._IsAdventure = isAdventure
    self._IsQuantum = isQuantum
    self:InitComponent()
    self:UpdateView()
end

function XUiTheatre3BubbleEquipment:OnDestroy()
    if self._Param.closeCallBack then
        self._Param.closeCallBack()
    end
end

function XUiTheatre3BubbleEquipment:InitComponent()
    self.BubbleQuantumEquipment.gameObject:SetActiveEx(self._IsQuantum)
    self.BubbleEquipment.gameObject:SetActiveEx(not self._IsQuantum)
    ---@type XUiTheatre3EquipmentTip
    self._Tip = XUiTheatre3EquipmentTip.New(self._IsQuantum and self.BubbleQuantumEquipment or self.BubbleEquipment, self)
    self._Tip:SetIsAdventureDesc(self._IsAdventure)
end

function XUiTheatre3BubbleEquipment:UpdateView()
    if self._Param.btnCallBack then
        self._Tip:ShowEquipTip(self._Param.equipId, self._Param.btnTxt or "", handler(self, self.DoCallBack), nil, self._IsQuantum)
    else
        self._Tip:ShowEquipTip(self._Param.equipId, nil, nil, nil, self._IsQuantum)
    end
    if self._Param.tipWorldPos then
        self._Tip:SetPosition(self._Param.tipWorldPos)
    elseif self._Param.Align and self._Param.DimObj then
        -- 异形屏适配
        self._Tip:Close()
        XScheduleManager.ScheduleOnce(function()
            self._Tip:Open()
            self._Tip:SetPositionByAlign(self._Param.DimObj, self._Param.Align)
        end, 1)
    end
end

function XUiTheatre3BubbleEquipment:DoCallBack()
    self:Close()
    self._Param.btnCallBack()
end

return XUiTheatre3BubbleEquipment