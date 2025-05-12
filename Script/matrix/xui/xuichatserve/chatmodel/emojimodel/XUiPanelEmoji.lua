--=======================
--以下脚本以废弃，由XUiPanelEmojiEx代替
--=======================
--[[
XUiPanelEmoji = XClass(nil, "XUiPanelEmoji")
local STR_RESIDUE = CS.XTextManager.GetText("Residue")
local interval = 1000
local XUiEmojiItem = require("XUi/XUiChatServe/ChatModel/EmojiModel/XUiEmojiItem")

function XUiPanelEmoji:Ctor(rootUi, ui)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.GameObject.gameObject:SetActive(false)
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:InitAutoScript()

    self.BtnBack.CallBack = function() self:Hide() end

    self.EmojiPrefab = self.EmojiItem.gameObject
    self.EmojiList = {}
    self.EmojiTimeLimitDic = {}
    self.NeedTimeCountDown = false
    self.EmojiScheduleTimer = false

    self:Init()
end

function XUiPanelEmoji:Init()
    self.EmojiPrefab:SetActive(false)
    if self.EmojiPrefab == nil then
        return
    end

    local templates = XDataCenter.ChatManager.GetEmojiTemplates()

    self.EmojiTimeLimitDic = {}
    --local serverTime = XTime.GetServerNowTimestamp()
    for _, emojiData in ipairs(templates) do
        local luaObj = self:CreateEmoji()
        if luaObj ~= nil then
            luaObj:Refresh(emojiData)
            luaObj:Show()
            table.insert(self.EmojiList, luaObj)

            if emojiData:IsLimitEmoji() then
                self.EmojiTimeLimitDic[emojiData:GetEmojiId()] = {luaObjT = luaObj, emojiDataT = emojiData}
            end
        end
    end
end

function XUiPanelEmoji:EmojiStartScheduleTime()

    local function CountDownFunc()
        local UnNeedTimerList = {}
        local serverTime = XTime.GetServerNowTimestamp()
        self.NeedTimeCountDown = false

        for emojiId, template in pairs(self.EmojiTimeLimitDic) do
            local luaObj = template.luaObjT
            local data = template.emojiDataT
            local lastTime = data:GetEmojiEndTime() - serverTime
            if lastTime > 0 then
                self.NeedTimeCountDown = true
                luaObj:ShowTimeLabel(STR_RESIDUE .. XUiHelper.GetTime(lastTime, XUiHelper.TimeFormatType.CHATEMOJITIMER))
            else
                luaObj:Hide()
                table.insert(UnNeedTimerList, emojiId)
            end
        end

        for _ , tempId in ipairs(UnNeedTimerList) do
            self.EmojiTimeLimitDic[tempId] = nil
        end
    end

    CountDownFunc()

    if self.NeedTimeCountDown and not self.EmojiScheduleTimer then

        self.EmojiScheduleTimer = XScheduleManager.ScheduleForever(function()
            CountDownFunc()
            if not self.NeedTimeCountDown then
                self:EmojiUnScheduleTime()
            end
        end, interval )
        
    end
end

function XUiPanelEmoji:EmojiUnScheduleTime()
    if self.EmojiScheduleTimer then
        XScheduleManager.UnSchedule(self.EmojiScheduleTimer)
        self.EmojiScheduleTimer = false
    end
end

function XUiPanelEmoji:SetClickCallBack(cb)
    for index = 1, #self.EmojiList do
        local emoji = self.EmojiList[index]
        if emoji ~= nil then
            emoji:SetClickCallBack(cb)
        end
    end
end

function XUiPanelEmoji:CreateEmoji()
    local parent = self.EmojiPrefab.transform.parent
    if parent ~= nil and self.EmojiPrefab ~= nil then
        local gameObject = CS.UnityEngine.GameObject.Instantiate(self.EmojiPrefab)
        if gameObject ~= nil then
            gameObject.transform:SetParent(parent, false)
            local luaObj = XUiEmojiItem.New(self.RootUi, gameObject)
            return luaObj
        end
    end
    return nil
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelEmoji:InitAutoScript()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiPanelEmoji:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiPanelEmoji:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then
        return
    end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiPanelEmoji:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XLuaAudioManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiPanelEmoji:AutoAddListener()
    self.AutoCreateListeners = {}
end
-- auto

function XUiPanelEmoji:Show()
    if not XTool.UObjIsNil(self.GameObject) then
        self.GameObject:SetActiveEx(true)
        self:EmojiStartScheduleTime()
    end
end

function XUiPanelEmoji:Hide()
    if not XTool.UObjIsNil(self.GameObject) then
        self.GameObject:SetActiveEx(false)
        self:EmojiUnScheduleTime()
    end
end

function XUiPanelEmoji:OpenOrClosePanel()
    if self.GameObject == nil then
        return
    end
    if not XTool.UObjIsNil(self.GameObject) then
        if not self.GameObject.activeSelf then
            self:Show()
        else
            self:Hide()
        end
    end
end
]]