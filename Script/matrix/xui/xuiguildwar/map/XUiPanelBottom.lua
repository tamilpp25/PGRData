---@class XUiPanelBottom:XUiNode
local XUiPanelBottom = XClass(XUiNode, "XUiPanelBottom")
local CSTextManagerGetText = CS.XTextManager.GetText
local MAX_CHAT_WIDTH = 470
local CHAT_SUB_LENGTH = 30
local Normal = CS.UiButtonState.Normal
local Select = CS.UiButtonState.Select

function XUiPanelBottom:OnStart(battleManager)
    ---@type XGWBattleManager
    self.BattleManager = battleManager
    self:InitButton()
    self.IsMenuOn = false
end

function XUiPanelBottom:OnEnable()
    self:UpdateRedPoint()
end

function XUiPanelBottom:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_RECEIVE_CHAT, self.UpdateChart, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.CheckRedDotTask, self)
end

function XUiPanelBottom:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_RECEIVE_CHAT, self.UpdateChart, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.CheckRedDotTask, self)
end

function XUiPanelBottom:InitButton()
    self.BtnTask.CallBack = function()
        self:OnBtnTaskClick()
    end
    self.BtnRole.CallBack = function()
        self:OnBtnRoleClick()
    end
    self.BtnReport.CallBack = function()
        self:OnBtnReportClick()
    end
    self.BtnMap.CallBack = function()
        self:OnBtnMapClick()
    end
    self.BtnMenu.CallBack = function()
        self:OnBtnMenuClick()
    end
    self.BtnChat.CallBack = function()
        self:OnBtnChatClick()
    end
    self.BtnMe.CallBack = function()
        self:OnBtnMeClick()
    end
    self.BtnInformation.CallBack = function()
        self:OnBtnInformationClick()
    end
    self.BtnSupport.CallBack = function()
        self:OnBtnSupportClick()
    end
    self.BtnLz.CallBack = function()
        self:OnBtnBossRewardClick()
    end
    self:AddRedPointEvent(self.BtnSupport, self.OnSupportRedPointEvent, self, {
        XRedPointConditions.Types.CONDITION_GUILDWAR_SUPPLY,
        XRedPointConditions.Types.CONDITION_GUILDWAR_ASSISTANT
    })
    self.BtnDifficulty.CallBack = function()
        self:OnBtnDifficultyClick()
    end
    self.BtnShop.CallBack = handler(self, self.OnBtnShopClick)
    
    self.BtnShopReddotId = self:AddRedPointEvent(self.BtnShop, self.OnBtnShopRedPointEvent, self, {XRedPointConditions.Types.CONDITION_GUILDWAR_MONEY})

    self.BtnMenuReddotId = self:AddRedPointEvent(self.BtnMenu, self.OnMenuRedPointEvent, self, {XRedPointConditions.Types.CONDITION_GUILDWAR_MENU})

    -- 判断Boss的类型
    local bossNode = self.BattleManager:GetBossNode()
    -- Boss节点不是复刷类型，则不显示领主入口
    if not bossNode or bossNode:GetNodeType() ~= XGuildWarConfig.NodeType.Term4BossRoot then
        self.BtnLz.gameObject:SetActiveEx(false)
    end
end

function XUiPanelBottom:UpdatePanel()
    self:UpdateChart()
    self:UpdateMenu()
    self:UpdateBossReward()
    local GuildLeader = XDataCenter.GuildWarManager.IsCanSelectDifficulty()
    self.BtnMap.gameObject:SetActiveEx(GuildLeader)
end

function XUiPanelBottom:UpdateMenu()
    self.BtnMenu:SetButtonState(self.IsMenuOn and Normal or Select)

    if self.IsMenuOn then
        self.PanelBtn.gameObject:SetActiveEx(true)
        self.Parent:PlayAnimationWithMask("ButtonEnable")
    else
        self.Parent:PlayAnimationWithMask("ButtonDisable", function()
            self.PanelBtn.gameObject:SetActiveEx(false)
        end)
    end
    self:CheckRedDotTask()
end

--更新聊天
function XUiPanelBottom:UpdateChart()
    local chatList = XDataCenter.ChatManager.GetGuildChatList()
    if not chatList then
        return
    end
    local lastChat = chatList[1]
    if not lastChat then
        self.TxtMessage.text = ""
        return
    end

    local nameRemark = XDataCenter.SocialManager.GetPlayerRemark(lastChat.SenderId, lastChat.NickName)
    local content = lastChat.Content
    if lastChat.MsgType == ChatMsgType.System then
        content = string.format("%s：%s", CS.XTextManager.GetText("GuildChannelTypeAll"), lastChat.Content)
        self.TxtMessage.text = content
    else
        content = lastChat.Content
        if lastChat.MsgType == ChatMsgType.Emoji then
            content = CS.XTextManager.GetText("GuildEmojiReplace")
        end
        self.TxtMessage.text = string.format("%s：%s", nameRemark, content)
    end

    if XUiHelper.CalcTextWidth(self.TxtMessage) > MAX_CHAT_WIDTH then
        self.TxtMessage.text = string.Utf8Sub(self.TxtMessage.text, 1, CHAT_SUB_LENGTH) .. [[...]]
    end
end

function XUiPanelBottom:OnBtnTaskClick()
    XLuaUiManager.Open("UiGuildWarTask")
end

function XUiPanelBottom:OnBtnRoleClick()
    XLuaUiManager.Open("UiGuildWarUpCharacter")
end

function XUiPanelBottom:OnBtnReportClick()
    XLuaUiManager.Open("UiGuildWarRank")
end

function XUiPanelBottom:OnBtnMapClick()
    if not XDataCenter.GuildWarManager.CheckRoundIsInTime() then
        XUiManager.TipText("GuildWarNoInRound")
        return
    end
    self.Parent:PathEdit()
end

function XUiPanelBottom:OnBtnMenuClick()
    self.IsMenuOn = not self.IsMenuOn
    self:UpdateMenu()
end

function XUiPanelBottom:OnBtnChatClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SocialChat) then
        return
    end

    XUiHelper.OpenUiChatServeMain(false, ChatChannelType.Guild, ChatChannelType.World)
end

function XUiPanelBottom:OnBtnMeClick()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_LOOKAT_ME)
end

function XUiPanelBottom:OnBtnInformationClick()
    XLuaUiManager.Open("UiGuildWarInformation")
end

function XUiPanelBottom:ShowPanel()
    self:Open()
    self:UpdateRedPoint()
end

function XUiPanelBottom:HidePanel()
    self:Close()
end

function XUiPanelBottom:CheckRedDotTask()
    local IsHasAchievedTask = XDataCenter.GuildWarManager.CheckTaskAchieved()
    self.BtnTask:ShowReddot(IsHasAchievedTask)
end

function XUiPanelBottom:OnBtnSupportClick()
    if XDataCenter.GuildWarManager.CheckIsPlayerSkipRound() then
        XUiManager.TipText("GuildWarNotQualifySupport")
        return
    end
    XLuaUiManager.Open("UiGuildWarSupport")
end

function XUiPanelBottom:OnBtnDifficultyClick()
    XLuaUiManager.Open("UiGuildWarSelect")
end

function XUiPanelBottom:OnSupportRedPointEvent(count)
    self.BtnSupport:ShowReddot(count >= 0)
end

function XUiPanelBottom:OnBtnBossRewardClick()
    if XDataCenter.GuildWarManager.CheckIsSkipCurrentRound() then
        XUiManager.TipMsg(XGuildWarConfig.GetClientConfigValues('BossRewardEntranceIntercept')[1])
        return
    end
    
    local bossNode = XDataCenter.GuildWarManager.GetBattleManager():GetNodeBossRoot()
    XLuaUiManager.Open("UiGuildWarLzTask", bossNode)
end

function XUiPanelBottom:UpdateBossReward()
    local isShowRedPoint = XDataCenter.GuildWarManager.IsShowRedPointBossReward()
    self.BtnLz:ShowReddot(isShowRedPoint)
end

function XUiPanelBottom:OnBtnShopClick()
    local values=XGuildWarConfig.GetClientConfigValues('ShopSkipId','Int')
    if XTool.IsNumberValid(values[1]) then
        if XFunctionManager.IsCanSkip(values[1]) then
            XFunctionManager.SkipInterface(values[1])
        else
            local skipCfg = XFunctionConfig.GetSkipFuncCfg(values[1])
            if skipCfg and XTool.IsNumberValid(skipCfg.FunctionalId) then
                local desc = XFunctionManager.GetFunctionOpenCondition(skipCfg.FunctionalId)
                XUiManager.TipMsg(desc)
            end
        end
    else
        XLog.Error('公会战商店跳转Id配置为无效值:'..tostring(values[1]),'配置Id: ShopSkipId','配置路径:','Client/GuildWar/GuildWarClientConfig')
    end
end

function XUiPanelBottom:OnBtnShopRedPointEvent(count)
    self.BtnShop:ShowReddot(count >= 0)
end

function XUiPanelBottom:OnMenuRedPointEvent(count)
    self.BtnMenu:ShowReddot(count >= 0)
end

function XUiPanelBottom:UpdateRedPoint()
    XRedPointManager.Check(self.BtnShopReddotId)
    XRedPointManager.Check(self.BtnMenuReddotId)
end

return XUiPanelBottom