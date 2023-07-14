--===========================
--爬塔掉落页面 插件插槽 控件
--===========================
local XUiStCpSlotGrid = XClass(nil, "XUiStCpSlotGrid")
local GridPlugin = require("XUi/XUiSuperTower/Plugins/XUiSuperTowerPluginGrid")
function XUiStCpSlotGrid:Ctor(uiGameObject, index, onUnEquipCallBack)
    XTool.InitUiObjectByUi(self, uiGameObject)
    self.Index = index
    self.PluginGrid = GridPlugin.New(self.GridPlugin)
    self.UnEquipCallBack = onUnEquipCallBack
    self.BtnPos.CallBack = function() self:OnClick() end
    self:Reset()
end

function XUiStCpSlotGrid:RefreshData(data, isStartShow)
    if not data then self:Reset() end
    if type(data) == "table" then --data可能是占位符0或plugin对象
        self.Plugin = data
        --self.PanelNoPlugin.gameObject:SetActiveEx(false)
        self.PluginGrid:RefreshData(self.Plugin)
        self.PluginGrid:ShowPanel()
        if not isStartShow then
            self.PanelEffect.gameObject:SetActiveEx(true)
        end
    else
        self:Reset()
    end
end

function XUiStCpSlotGrid:Reset()
    self.Plugin = nil
    self.PanelNoPlugin.gameObject:SetActiveEx(true)
    self.PluginGrid:HidePanel()
    self.ImgSelect.gameObject:SetActiveEx(false)
    self.PanelEffect.gameObject:SetActiveEx(false)
end

function XUiStCpSlotGrid:SetSelect(value)
    self.ImgSelect.gameObject:SetActiveEx(value)
end

function XUiStCpSlotGrid:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiStCpSlotGrid:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiStCpSlotGrid:OnClick()
    if not self.Plugin then return end
    self:SetSelect(true)
    XLuaUiManager.Open("UiSuperTowerPluginDetails",
        self.Plugin, 0,
        function()
            if not XTool.UObjIsNil(self.Transform) then
                self:SetSelect(false)
            end
        end, false,
        function(pluginId)
            if self.UnEquipCallBack then
                self.UnEquipCallBack(self)
            end
        end)
end

return XUiStCpSlotGrid