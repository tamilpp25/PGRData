local XUiPlanetFilterDetail = XLuaUiManager.Register(XLuaUi, "UiPlanetFilterDetail")

function XUiPlanetFilterDetail:OnAwake()
    self:AddBtnClickListener()
end

function XUiPlanetFilterDetail:OnStart()
    
end

function XUiPlanetFilterDetail:OnEnable()
    
end

function XUiPlanetFilterDetail:OnDisable()
    
end

--region 对象初始化
function XUiPlanetFilterDetail:InitObj()
    
end
--endregion


--region 按钮绑定
function XUiPlanetFilterDetail:AddBtnClickListener()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
end
--endregion