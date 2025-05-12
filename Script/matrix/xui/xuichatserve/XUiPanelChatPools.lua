local XUiPanelChatPools = XClass(nil, "XUiPanelChatPools")

function XUiPanelChatPools:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self:InitAutoScript()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelChatPools:InitAutoScript()
    self:AutoInitUi()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiPanelChatPools:AutoInitUi()
    self.PanelWorldChatOhterMsgItem = self.Transform:Find("PanelWorldChatOhterMsgItem")
    self.PanelWorldChatOhterEmojiItem = self.Transform:Find("PanelWorldChatOhterEmojiItem")
    self.PanelWorldChatMyMsgItem = self.Transform:Find("PanelWorldChatMyMsgItem")
    self.PanelWorldChatMyMsgEmoji = self.Transform:Find("PanelWorldChatMyMsgEmoji")
    self.PanelWorldChatSystemItem = self.Transform:Find("PanelWorldChatPublic")
    self.PanelWorldChatMyHelp = self.Transform:Find("PanelWorldChatMyHelp")
    self.PanelWorldChatOtherHelp = self.Transform:Find("PanelWorldChatOtherHelp")
end

function XUiPanelChatPools:GetAutoKey(uiNode,eventName)
    if not uiNode then return end
    return eventName .. uiNode:GetHashCode()
end

function XUiPanelChatPools:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then return end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiPanelChatPools:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XLuaAudioManager.PlayBtnMusic(self.SpecialSoundMap[key],eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiPanelChatPools:AutoAddListener()
    self.AutoCreateListeners = {}
end

function XUiPanelChatPools:InitData(dynamicList)
    self.GameObject:SetActive(false)
    dynamicList:AddObjectPools("myMsg",self.PanelWorldChatMyMsgItem.gameObject)
    dynamicList:AddObjectPools("ohterMsg",self.PanelWorldChatOhterMsgItem.gameObject)
    dynamicList:AddObjectPools("myEmoji",self.PanelWorldChatMyMsgEmoji.gameObject)
    dynamicList:AddObjectPools("otherEmoji",self.PanelWorldChatOhterEmojiItem.gameObject)
    dynamicList:AddObjectPools("system", self.PanelWorldChatSystemItem.gameObject)
    dynamicList:AddObjectPools("myHelp",self.PanelWorldChatMyHelp.gameObject)
    dynamicList:AddObjectPools("otherHelp",self.PanelWorldChatOtherHelp.gameObject)
end


return XUiPanelChatPools