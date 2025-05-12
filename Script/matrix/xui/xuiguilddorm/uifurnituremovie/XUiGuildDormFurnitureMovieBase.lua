---@class XUiGuildDormFurnitureMovieBase
local XUiGuildDormFurnitureMovieBase = XLuaUiManager.Register(XLuaUi, 'UiGuildDormFurnitureMovieBase')

function XUiGuildDormFurnitureMovieBase:OnAwake()
    self.IconNext = self.Transform:Find('SafeAreaContentPane/PanelDialog/IconNext')
    if self.IconNext then
        self.IconNext.gameObject:SetActiveEx(false)
    end
end

function XUiGuildDormFurnitureMovieBase:SetDialog(speakerName, content)
    if self.TxtName then
        self.TxtName.text = speakerName
    end

    if self.TxtWords then
        self.TxtWords.text = content
    end
end

function XUiGuildDormFurnitureMovieBase:SetOptions(optionLabels)
    XUiHelper.RefreshCustomizedList(self.TabBtnSelectGroup.transform, self.BtnSelect, optionLabels and #optionLabels or 0, function(i, go)
        local button = go:GetComponent("XUiButton")
        button:SetNameByGroup(0, optionLabels[i])
        XUiHelper.RegisterClickEvent(self, button, function()
            self:OnBtnOptionClicked(i)
        end)
    end)
end

---@param func function @function(index)
function XUiGuildDormFurnitureMovieBase:SetOptionCallBackProxyFunc(func)
    self._OptionCallBackProxyFunc = func
end

function XUiGuildDormFurnitureMovieBase:OnBtnOptionClicked(index)
    if self._OptionCallBackProxyFunc then
        self._OptionCallBackProxyFunc(index)
    end
end

return XUiGuildDormFurnitureMovieBase