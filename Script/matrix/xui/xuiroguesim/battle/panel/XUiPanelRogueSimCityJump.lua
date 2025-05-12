local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridRogueSimCityJump = require("XUi/XUiRogueSim/Battle/Grid/XUiGridRogueSimCityJump")
---@class XUiPanelRogueSimCityJump : XUiNode
---@field private _Control XRogueSimControl
local XUiPanelRogueSimCityJump = XClass(XUiNode, "XUiPanelRogueSimCityJump")

function XUiPanelRogueSimCityJump:OnStart()
    self.GridCity.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnDetail, self.OnBtnDetailClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    self:InitDynamicTable()
end

function XUiPanelRogueSimCityJump:Refresh()
    -- 已获得区域的数量
    self.TxtNun.text = self._Control.MapSubControl:GetObtainAreaCount()
    -- 刷新区域列表
    self:SetupDynamicTable()
    self:PlayAnimationWithMask("PanelCityEnable")
end

function XUiPanelRogueSimCityJump:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.ListCity)
    self.DynamicTable:SetProxy(XUiGridRogueSimCityJump, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelRogueSimCityJump:SetupDynamicTable()
    self.AreaIds = self._Control.MapSubControl:GetObtainAreaIds()
    self.DynamicTable:SetDataSource(self.AreaIds)
    self.DynamicTable:ReloadDataASync()
end

---@param grid XUiGridRogueSimCityJump
function XUiPanelRogueSimCityJump:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.AreaIds[index])
    end
end

function XUiPanelRogueSimCityJump:OnBtnDetailClick()
    -- 没有城邦时提示
    local cityCount = self._Control.MapSubControl:GetOwnCityCount()
    if cityCount <= 0 then
        XUiManager.TipMsg(self._Control:GetClientConfig("NoCityTip"))
        return
    end
    self:PlayDisableAnima(function()
        XLuaUiManager.Open("UiRogueSimCityBag")
    end)
end

function XUiPanelRogueSimCityJump:OnBtnCloseClick()
    self:PlayDisableAnima()
end

-- 播放隐藏动画
function XUiPanelRogueSimCityJump:PlayDisableAnima(callback)
    self:PlayAnimationWithMask("PanelCityDisable", function()
        if callback then
            callback()
        end
        self:Close()
    end)
end

return XUiPanelRogueSimCityJump
