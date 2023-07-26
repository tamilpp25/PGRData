--===========================
--超级爬塔子面板控件基类
--===========================
local XUiSTChildPanel = XClass(nil, "XUiSTChildPanel")

function XUiSTChildPanel:Ctor(uiGameObject, rootUi)
    XTool.InitUiObjectByUi(self, uiGameObject)
    self.RootUi = rootUi
    self:InitPanel()
end
--===============
--初始化面板(在构筑函数最后调用)
--===============
function XUiSTChildPanel:InitPanel()

end
--===============
--刷新面板
--===============
function XUiSTChildPanel:RefreshPanel()

end
--===============
--显示面板(会调用AddEventListener加入事件，OnEnable方法)
--===============
function XUiSTChildPanel:ShowPanel()
    self.GameObject:SetActiveEx(true)
    if not self.EventAdded then
        self.EventAdded = true
        self:AddEventListener()
    end
    self:OnEnable()
    self:OnShowPanel()
end
--===============
--隐藏面板(会调用RemoveEventListener移除事件，OnDisable方法)
--===============
function XUiSTChildPanel:HidePanel()
    self.GameObject:SetActiveEx(false)
    if self.EventAdded then
        self:RemoveEventListener()
        self.EventAdded = false
    end
    self:OnDisable()
    self:OnHidePanel()
end
--===============
--子类复写用，在ShowPanel里面AddEventListener,OnEnable之后调用
--===============
function XUiSTChildPanel:OnShowPanel()

end
--===============
--子类复写用，在HidePanel里面RemoveEventListener,OnDisable之后调用
--===============
function XUiSTChildPanel:OnHidePanel()

end
--===============
--面板对象OnEnble时，若用作生命周期需外部统一调用
--===============
function XUiSTChildPanel:OnEnable()

end
--===============
--面板对象OnDisable时，若用作生命周期需外部统一调用
--===============
function XUiSTChildPanel:OnDisable()

end
--===============
--面板对象OnDestroy时，若用作生命周期需外部统一调用
--===============
function XUiSTChildPanel:OnDestroy()
    self:RemoveEventListener()
end

function XUiSTChildPanel:AddEventListener()

end

function XUiSTChildPanel:RemoveEventListener()

end

return XUiSTChildPanel