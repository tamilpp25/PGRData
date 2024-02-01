local XUiReformListGridBuff = require("XUi/XUiReform2nd/Reform/Main/XUiReformListGridBuff")

---@field _Control XReformControl
---@class XUiReformListGrid:XUiNode
local XUiReformListGrid = XClass(XUiNode, "XUiReformListGrid")

function XUiReformListGrid:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnAdd, self.OnClickAdd)
    XUiHelper.RegisterClickEvent(self, self.BtnReform, self.OnClickAdd)

    ---@type XViewModelReform2ndList
    self._ViewModel = self._Control:GetViewModelList()
    self._Data = false

    ---@type XUiReformListGridBuff[]
    self._UiBuff = {
        XUiReformListGridBuff.New(self.BtnBuff1),
        XUiReformListGridBuff.New(self.BtnBuff2),
        XUiReformListGridBuff.New(self.BtnBuff3),
    }

    if self.Effect then
        self.Effect.gameObject:SetActiveEx(false)
    end
end

function XUiReformListGrid:SetViewModel(viewModel)
    self._ViewModel = viewModel
end

---@param data UiReformMobData
function XUiReformListGrid:Update(data)
    self._Data = data
    if data.IsAdd then
        self.GridEntity.gameObject:SetActiveEx(false)
        self.GirdAdd.gameObject:SetActiveEx(true)
        self.TxtEnemyLevel2.text = data.Text
    else
        self.GridEntity.gameObject:SetActiveEx(true)
        self.GirdAdd.gameObject:SetActiveEx(false)
        self.TxtEnemyName.text = data.Name
        self.RImgIcon:SetRawImage(data.Icon)
        self.TxtEnemyLevel.text = data.TextLevel
        self.TxtCost.text = data.Pressure
        local dataBuff = data.IconBuff
        for i = 1, #self._UiBuff do
            local uiBuff = self._UiBuff[i]
            local icon = dataBuff[i]
            uiBuff:Update(icon)
        end
        if self.Select then
            self.Select.gameObject:SetActiveEx(data.IsSelected)
        end
    end
    if data.IsPlayMobUpdateEffect then
        self.Effect.gameObject:SetActiveEx(false)
        self.Effect.gameObject:SetActiveEx(true)
    else
        self.Effect.gameObject:SetActiveEx(false)
    end
end

function XUiReformListGrid:OnClickAdd()
    self._ViewModel:SetSelectedMobGroup(self._Data)
end

return XUiReformListGrid
