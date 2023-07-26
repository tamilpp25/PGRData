
local XUiSuperSmashBrosOrder = XLuaUiManager.Register(XLuaUi, "UiSuperSmashBrosOrder")

function XUiSuperSmashBrosOrder:OnStart(mode, onCloseCb)
    self.Mode = mode
    self.OnCloseCb = onCloseCb
    local teamData = XDataCenter.SuperSmashBrosManager.GetDefaultTeamInfoByModeId(self.Mode:GetId())
    self.ColorDic = {}
    for index, color in pairs(teamData.Color) do
        self.ColorDic[index] = color
    end
    self.CaptainPos = teamData.CaptainPos
    self:InitBtns()
    self:InitTitle()
    self:InitPanels()
end

function XUiSuperSmashBrosOrder:InitBtns()
    self.BtnTanchuangClose.CallBack = function() self:OnClickBtnClose() end
    self.BtnConfirm.CallBack = function() self:OnClickBtnConfirm() end
end

function XUiSuperSmashBrosOrder:OnClickBtnClose()
    self:Close()
end

function XUiSuperSmashBrosOrder:OnClickBtnConfirm()
    if not self:CheckColor() then
        return
    end
    if not self:CheckCaptain() then
        return
    end
    XDataCenter.SuperSmashBrosManager.SaveDefaultTeamByModeId(self.Mode:GetId(), self.CaptainPos, nil, nil, self.ColorDic)
    self:Close()
end

function XUiSuperSmashBrosOrder:CheckColor()
    local checkDic = {}
    for _, colorIndex in pairs(self.ColorDic) do
        if checkDic[colorIndex] == nil then
            checkDic[colorIndex] = true
        elseif checkDic[colorIndex] == true then
            XUiManager.TipText("SSBRepeatColor")
            return false
        end
    end
    return true
end

function XUiSuperSmashBrosOrder:CheckCaptain()
    if not self.CaptainPos or self.CaptainPos < 1 then
        XUiManager.TipText("SSBNoCaptain")
        return false
    end
    return true
end

function XUiSuperSmashBrosOrder:InitTitle()
    if self.TxtTitle then
        self.TxtTitle.text = XUiHelper.GetText("SSBOrderSortBtnName")
    end
end

function XUiSuperSmashBrosOrder:InitPanels()
    self:InitOrderPanels()
end

function XUiSuperSmashBrosOrder:InitOrderPanels()
    self.OrderPanels = {}
    local script = require("XUi/XUiSuperSmashBros/Pick/Grids/XUiSSBOrderGrid")
    local roleNum = self.Mode:GetRoleMaxPosition()
    for index = 1, roleNum do
        local prefab = CS.UnityEngine.Object.Instantiate(self.GridOrder, self.OrderContent)
        self.OrderPanels[index] = script.New(prefab, index,
            function(colorIndex, gridIndex) self:OnSelectColor(colorIndex, gridIndex) end,
            function(isOn, gridIndex) self:OnSelectCaptain(isOn, gridIndex) end)
        self.OrderPanels[index]:SetColor(self.ColorDic[index])
        self.OrderPanels[index]:SetCaptainPos(self.CaptainPos)
    end
    self.GridOrder.gameObject:SetActiveEx(false)
end

function XUiSuperSmashBrosOrder:OnSelectColor(colorIndex, gridIndex)
    self.ColorDic[gridIndex] = colorIndex
end

function XUiSuperSmashBrosOrder:OnSelectCaptain(isOn, gridIndex)
    if isOn then
        self.CaptainPos = gridIndex
    else
        self.CaptainPos = 0
    end
end

function XUiSuperSmashBrosOrder:OnDestroy()
    if self.OnCloseCb then
        self.OnCloseCb()
    end
end