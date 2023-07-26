local XUiPlanetActiveBuildView = XLuaUiManager.Register(XLuaUi, "UiPlanetActiveBuildView")

function XUiPlanetActiveBuildView:OnAwake()
    self:AddBtnClickListener()
end

function XUiPlanetActiveBuildView:OnStart()
    
end

function XUiPlanetActiveBuildView:OnEnable()
    
end

function XUiPlanetActiveBuildView:OnDisable()
    
end


--#region 按钮绑定
function XUiPlanetActiveBuildView:AddBtnClickListener()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
end
--endregion