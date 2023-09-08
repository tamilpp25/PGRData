---@class XUiGridTheatreGenius : XUiNode
---@field _Control XTheatre3Control
local XUiGridTheatreGenius = XClass(XUiNode, "XUiGridTheatreGenius")

function XUiGridTheatreGenius:OnStart(index, callBack)
    self.Index = index
    self.CallBack = callBack
    self.Select.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnGenuis, self.OnBtnGenuisClick)
end

function XUiGridTheatreGenius:Refresh(geniusId)
    self.GeniusId = geniusId
    -- 图标
    local icon = self._Control:GetStrengthenTreeIconById(geniusId)
    if self.ImgGenuis and icon then
        self.ImgGenuis:SetRawImage(icon)
    end
    -- 是否解锁
    local isShow = self._Control:CheckAnyPreStrengthenTreeUnlock(self.GeniusId)
    local isOpen = self._Control:CheckStrengthenTreeCondition(self.GeniusId)
    self.PanelLock.gameObject:SetActiveEx(not isShow or not isOpen)
    -- 是否激活
    local isActive = self._Control:CheckStrengthTreeUnlock(self.GeniusId)
    if self.PanelActive then
        self.PanelActive.gameObject:SetActiveEx(isActive)
    end
    if self.ImgBg then
        self.ImgBg.gameObject:SetActiveEx(not isActive)
    end
    -- 刷新红点
    local isRedPoint = self._Control:CheckStrengthenTreeRedPoint(geniusId)
    self.BtnGenuis:ShowReddot(isRedPoint)
end

-- 是否显示选中框
function XUiGridTheatreGenius:SetGeniusSelect(isSelect)
    if self.Select then
        self.Select.gameObject:SetActiveEx(isSelect)
    end
end

function XUiGridTheatreGenius:OnBtnGenuisClick()
    if self.CallBack then
        self.CallBack(self)
    end
end

return XUiGridTheatreGenius