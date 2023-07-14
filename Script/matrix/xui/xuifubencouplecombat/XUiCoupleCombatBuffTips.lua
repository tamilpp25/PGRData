local XUiCoupleCombatBuffTips = XLuaUiManager.Register(XLuaUi, "UiCoupleCombatBuffTips")

local XUiBuffTipsItem = require("XUi/XUiFubenCoupleCombat/ChildItem/XUiBuffTipsItem")

--分光双星全域变量的词缀展示页面
function XUiCoupleCombatBuffTips:OnAwake()
    XTool.InitUiObject(self)
    self.GridBuff.gameObject:SetActiveEx(false)
    self:RegisterUiButtonEvent()
end

function XUiCoupleCombatBuffTips:OnStart(chapterId)
    local showFightEventIds = XFubenCoupleCombatConfig.GetChapterShowFightEventIds(chapterId)
    for _, showFightEventId in pairs(showFightEventIds) do
        local prefab = CS.UnityEngine.Object.Instantiate(self.GridBuff.gameObject, self.PanelContent)
        local tipItem = XUiBuffTipsItem.New(prefab, self)
        tipItem:RefreshData(showFightEventId)
        tipItem.GameObject:SetActiveEx(true)
    end
end

function XUiCoupleCombatBuffTips:RegisterUiButtonEvent()
    self:RegisterClickEvent(self.BtnClose, self.Close)
end