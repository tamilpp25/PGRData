-- 通用关卡词缀列表详细页面
local XUiStageFightEvent = XLuaUiManager.Register(XLuaUi, "UiCommonStageEvent")
local XUiStageFightEventItem = require("XUi/XUiCommon/XUiStageFightEventItem")
function XUiStageFightEvent:OnAwake()
    XTool.InitUiObject(self)
    self.GridBuff.gameObject:SetActiveEx(false)
    self:RegisterUiButtonEvent()
end

function XUiStageFightEvent:RegisterUiButtonEvent()
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
end

function XUiStageFightEvent:OnBtnCloseClick()
    self:Close()
end

function XUiStageFightEvent:OnStart(dataList)
    self.DataList = dataList
    for _, eventCfg in pairs(self.DataList) do
        local prefab = CS.UnityEngine.Object.Instantiate(self.GridBuff.gameObject)
        prefab.transform:SetParent(self.PanelContent.transform, false)
        local tipItem = XUiStageFightEventItem.New(prefab, self)
        tipItem:RefreshData(eventCfg)
        tipItem.GameObject:SetActiveEx(true)
    end
end