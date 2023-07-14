local XUiNieREasterEgg = XLuaUiManager.Register(XLuaUi, "UiNieREasterEgg")
local XPanelNieREasterEggChat = require("XUi/XUiNieR/XUiNieREasterEgg/XPanelNieREasterEggChat")

local XPanelNieREasterEggChatList = require("XUi/XUiNieR/XUiNieREasterEgg/XPanelNieREasterEggChatList")
local XPanelNieREasterEggAge = require("XUi/XUiNieR/XUiNieREasterEgg/XPanelNieREasterEggAge")
local XPanelNieREasterEggTag = require("XUi/XUiNieR/XUiNieREasterEgg/XPanelNieREasterEggTag")

local WinTagType = {
    Age = 1,
    Tag = 2,
    ChatList = 3,
    Reward = 4
}

function XUiNieREasterEgg:OnAwake()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end 
    self.BtnLeft.CallBack = function() self:OnBtnLeftClick() end
    self.BtnRight.CallBack = function() self:OnBtnRightClick() end
    self.BtnClick.CallBack = function() self:OnBtnClickClick() end

    self.PanelChat = XPanelNieREasterEggChat.New(self.Chat, self)
    self.PanelChatList = XPanelNieREasterEggChatList.New(self.ChatList, self)
    self.PanelAge = XPanelNieREasterEggAge.New(self.Age, self)
    self.PanelTag = XPanelNieREasterEggTag.New(self.Tag, self)

    self.BtnBack.gameObject:SetActiveEx(false)
    self.Age.gameObject:SetActiveEx(false)
    self.Tag.gameObject:SetActiveEx(false)
    self.ChatList.gameObject:SetActiveEx(false)
    self.Chat.gameObject:SetActiveEx(false)

    self.WinTagOpen = {}
end

function XUiNieREasterEgg:OnStart(isWin, isFirstDied)

    self.Age.gameObject:SetActiveEx(false)
    self.Tag.gameObject:SetActiveEx(false)
    self.ChatList.gameObject:SetActiveEx(false)
    self.Chat.gameObject:SetActiveEx(true)
    self.IsWin = isWin
    local storyConfig
    if not isWin then
        if isFirstDied then
            storyConfig = XNieRConfigs.GetNieREasterEggClientConfigByGroupId(1)
        else
            storyConfig = XNieRConfigs.GetNieREasterEggClientConfigByGroupId(2)
        end
        self.CurStoryConfig = storyConfig
        self.PanelChat:PlayStoryInfo(storyConfig)
    else
        storyConfig = XNieRConfigs.GetNieREasterEggClientConfigByGroupId(3)
        self.PanelChat:ResetAll()
        self.CurStoryConfig = storyConfig
        self.PanelChat:PlayStoryInfo(storyConfig)
    end
   
end

function XUiNieREasterEgg:OnDestroy()
    self.PanelChat:StopBulletTimer()
end

function XUiNieREasterEgg:OpenNierEasterEggChatList()
    self.Age.gameObject:SetActiveEx(false)
    self.Tag.gameObject:SetActiveEx(false)
    self.Chat.gameObject:SetActiveEx(false)
    self.ChatList.gameObject:SetActiveEx(true)
    if not self.WinTagOpen[WinTagType.ChatList] then
        self.PanelChatList:Init()
    end
    self.CurWinTagType = WinTagType.ChatList
    self.WinTagOpen[WinTagType.ChatList] = true
    self.BtnLeft.gameObject:SetActiveEx(false)
    --self.BtnLeft:SetNameByGroup(0, CS.XTextManager.GetText("NieREasterEggLeftBtnStr"))
    self.BtnRight.gameObject:SetActiveEx(true)
    self.BtnRight:SetNameByGroup(0, CS.XTextManager.GetText("NieREasterEggRightBtnStr", 1, 3))
end

function XUiNieREasterEgg:SetNieREasterEggMessageId(id)
    self.NieREasteEggMessageId = id
end

function XUiNieREasterEgg:OpenNierEasterEggAge()
    self.ChatList.gameObject:SetActiveEx(false)
    self.Chat.gameObject:SetActiveEx(false)
    self.Tag.gameObject:SetActiveEx(false)
    self.Age.gameObject:SetActiveEx(true)
    if not self.WinTagOpen[WinTagType.Age] then
        self.PanelAge:Init()
    end
    self.CurWinTagType = WinTagType.Age
    self.WinTagOpen[WinTagType.Age] = true
    self.BtnLeft.gameObject:SetActiveEx(true)
    self.BtnLeft:SetNameByGroup(0, CS.XTextManager.GetText("NieREasterEggLeftBtnStr"))
    self.BtnRight.gameObject:SetActiveEx(true)
    self.BtnRight:SetNameByGroup(0, CS.XTextManager.GetText("NieREasterEggRightBtnStr", 2, 3))
end

function XUiNieREasterEgg:SetNieREasterEggAge(age)
    self.NieREasteEggAge = age
end

function XUiNieREasterEgg:OpenNierEasterEggTag()
    self.Age.gameObject:SetActiveEx(false)
    self.ChatList.gameObject:SetActiveEx(false)
    self.Chat.gameObject:SetActiveEx(false)
    self.Tag.gameObject:SetActiveEx(true)
    
    if not self.WinTagOpen[WinTagType.Tag] then
        self.PanelTag:Init()
    end
    self.CurWinTagType = WinTagType.Tag
    self.WinTagOpen[WinTagType.Tag] = true

    self.BtnLeft.gameObject:SetActiveEx(true)
    self.BtnLeft:SetNameByGroup(0, CS.XTextManager.GetText("NieREasterEggLeftBtnStr"))
    self.BtnRight.gameObject:SetActiveEx(true)
    self.BtnRight:SetNameByGroup(0, CS.XTextManager.GetText("NieREasterEggOkBtnStr"))
end

function XUiNieREasterEgg:SetNieREasterEggTagId(id)
    self.NieREasteEggTagId = id
end

function XUiNieREasterEgg:OnBtnBackClick()
    self:Close()
end

function XUiNieREasterEgg:HideBtn()
    self.BtnLeft.gameObject:SetActiveEx(false)
    self.BtnRight.gameObject:SetActiveEx(false)
    self.BtnClick.gameObject:SetActiveEx(false)
end

function XUiNieREasterEgg:ShowStoryBtn()
    local storyConfig = self.CurStoryConfig
    local btnNum = #storyConfig.BtnStr
    self.ShowBtnNum = btnNum
    if btnNum > 0 then
        for index, btnName in ipairs(storyConfig.BtnStr) do
            if index == 1 then
                self.BtnLeft.gameObject:SetActiveEx(true)
                self.BtnLeft:SetNameByGroup(0, btnName)
            else
                self.BtnRight.gameObject:SetActiveEx(true)
                self.BtnRight:SetNameByGroup(0, btnName)
            end
        end
    else
        local btnStr = storyConfig.BtnExStr or ""
        self.BtnClick.gameObject:SetActiveEx(true)
        self.BtnClick:SetNameByGroup(0, btnStr)
    end 
end

function XUiNieREasterEgg:OnBtnMainUiClick()
    
end

function XUiNieREasterEgg:OnBtnLeftClick()
    if not self.PlayerInput then
        if self.ShowBtnNum > 0 then
            local nextStoryId = self.CurStoryConfig.BtnTag[1]
            self:RealNieREasterEggStoryClick(nextStoryId)
        end
    else
        if self.CurWinTagType == WinTagType.ChatList then
        elseif self.CurWinTagType == WinTagType.Age then
            self:OpenNierEasterEggChatList()
        elseif self.CurWinTagType == WinTagType.Tag then
            self:OpenNierEasterEggAge()
        end
    end
end

function XUiNieREasterEgg:OnBtnRightClick()
    if not self.PlayerInput then
        if self.ShowBtnNum > 1 then
            local nextStoryId = self.CurStoryConfig.BtnTag[2]
            self:RealNieREasterEggStoryClick(nextStoryId)
        end
    else
        if self.CurWinTagType == WinTagType.ChatList then
            self:OpenNierEasterEggAge()
        elseif self.CurWinTagType == WinTagType.Age then
            self:OpenNierEasterEggTag()
        elseif self.CurWinTagType == WinTagType.Tag then
            XUiManager.DialogTip("", CS.XTextManager.GetText("NieREasterEggSaveToServer"), XUiManager.DialogType.NormalAndNoBtnTanchuangClose,function()
                --XLuaUiManager.PopThenOpen("UiNieRSaveData")
            end ,function ()
                XDataCenter.NieRManager.NieREasterEggLeaveMessage(self.NieREasteEggMessageId, self.NieREasteEggAge, self.NieREasteEggTagId, function(rewardgodList)
                    XDataCenter.NieRManager.NieREasterEggDataRealPass()
                    self.RealEasterEggWin = true
                    self.PlayerInput = nil
                    self.Tag.gameObject:SetActiveEx(false)
                    self.Chat.gameObject:SetActiveEx(true)
                    self.PanelChat:ResetAll()
                    local storyConfig = XNieRConfigs.GetNieREasterEggClientConfigByGroupId(4)
                    self.CurStoryConfig = storyConfig
                    self.PanelChat:PlayStoryInfo(storyConfig)
                    self.RewardGodList = rewardgodList
                end)
            end)
            
        end
    end
end

function XUiNieREasterEgg:OnBtnClickClick()
    if not self.PlayerInput then
        if self.ShowBtnNum == 0 then
            local nextStoryId = self.CurStoryConfig.BtnTag[1]
            self:RealNieREasterEggStoryClick(nextStoryId)
        end
    else
        self:Close()
    end
end

function XUiNieREasterEgg:RealNieREasterEggStoryClick(nextStoryId)
    local storyConfig = XNieRConfigs.GetNieREasterEggClientConfigById(nextStoryId)
    if storyConfig.Type == XNieRConfigs.EasterEggStoryType.NoThing then
        self.CurStoryConfig = storyConfig
        self.PanelChat:PlayStoryInfo(storyConfig)
        if storyConfig.ShowBullet == 1 then
            self.PanelChat:PlayBulletChat()
        end
    elseif storyConfig.Type == XNieRConfigs.EasterEggStoryType.Leave then
        if self.IsWin then
        else
            if CS.XFight.Instance ~= nil then
                CS.XFight.Instance.InputControl:OnClick(CS.XNpcOperationClickKey.NieREasterLeave, CS.XNpcOperationClickType.KeyDown)
                CS.XFight.Instance.InputControl:OnClick(CS.XNpcOperationClickKey.NieREasterLeave, CS.XNpcOperationClickType.KeyUp)
            end
        end
        self:Close()
    elseif storyConfig.Type == XNieRConfigs.EasterEggStoryType.Revive then
        if self.RealEasterEggWin then
            if self.RewardGodList then
                XUiManager.OpenUiObtain(self.RewardGodList)
            end
            self:Close()
        elseif self.IsWin then
            self.BtnClick.gameObject:SetActiveEx(false)
            self:OpenNierEasterEggChatList()
            self.PlayerInput = true
        else
            if  CS.XFight.Instance ~= nil then
                CS.XFight.Instance.InputControl:OnClick(CS.XNpcOperationClickKey.NieREasterRevive, CS.XNpcOperationClickType.KeyDown)
                CS.XFight.Instance.InputControl:OnClick(CS.XNpcOperationClickKey.NieREasterRevive, CS.XNpcOperationClickType.KeyUp)
            end
            self:Close()
        end
    end
end
