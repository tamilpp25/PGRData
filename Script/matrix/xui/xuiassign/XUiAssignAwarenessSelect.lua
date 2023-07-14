local XUiAssignAwarenessSelect = XLuaUiManager.Register(XLuaUi, "UiAssignAwarenessSelect")

function XUiAssignAwarenessSelect:OnAwake()
    self:InitButton()
end

function XUiAssignAwarenessSelect:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    XUiHelper.RegisterClickEvent(self, self.PanelSelect01, function() XDataCenter.FubenAssignManager.OpenUi() end)
    XUiHelper.RegisterClickEvent(self, self.PanelSelect02, function() XDataCenter.FubenAwarenessManager.OpenUi() end)
end

function XUiAssignAwarenessSelect:OnEnable()
    self:RefreshAssignPanel()
    self:RefreshAwarenessPanel()
end

-- 边界
function XUiAssignAwarenessSelect:RefreshAssignPanel()
    local panelAssign = self.PanelSelect01.transform:GetComponent("UiObject")

    local curr = XDataCenter.FubenAssignManager.GetAllChapterOccupyNum()
    local total = #XDataCenter.FubenAssignManager.GetChapterIdList()
    panelAssign:GetObject("TxtProgress").text = curr.."/"..total
    panelAssign:GetObject("ImgRedDot").gameObject:SetActiveEx(XDataCenter.FubenAssignManager.CheckIsShowRedPoint())
end

-- 意识
function XUiAssignAwarenessSelect:RefreshAwarenessPanel()
    local panelAwareness = self.PanelSelect02.transform:GetComponent("UiObject")

    local curr = XDataCenter.FubenAwarenessManager.GetAllChapterOccupyNum()
    local total = #XDataCenter.FubenAwarenessManager.GetChapterIdList()
    panelAwareness:GetObject("TextDes").text = CS.XTextManager.GetText("AwarenessOccupyProgressOnCover")
    panelAwareness:GetObject("TxtProgress").text = curr.."/"..total
    panelAwareness:GetObject("TxtBlackTitel").text = CS.XTextManager.GetText("AwarenessOccupyDesc")
    local isLock = not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.FubenAwareness)
    panelAwareness:GetObject("PanelUnlock").gameObject:SetActiveEx(isLock)
    if isLock then
        local desc = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.FubenAwareness)
        panelAwareness:GetObject("TxtUnlockCondition").text = desc
    end
    panelAwareness:GetObject("ImgRedDot").gameObject:SetActiveEx(XDataCenter.FubenAwarenessManager.CheckIsShowRedPoint())
end