local XUiGuildMain = XLuaUiManager.Register(XLuaUi, "UiGuildMain")

local CSXTextManagerGetText = CS.XTextManager.GetText

local RequestMemberGap = 10
local MAX_CHAT_WIDTH = 470
local CHAT_SUB_LENGTH = 18

local XUiGuildViewSetHeadPortrait = require("XUi/XUiGuild/XUiChildView/XUiGuildViewSetHeadPortrait")
local XUiGridGuildBoxItem = require("XUi/XUiGuild/XUiChildItem/XUiGridGuildBoxItem")
local GuildBuildIntervalWhenMaxLevel = CS.XGame.Config:GetInt("GuildBuildIntervalWhenMaxLevel")
local GlobalLastRequestMember = 0
local GlobalRequestGap = CS.XGame.ClientConfig:GetInt("GuildGlobalRequestMember")

local MaxPanelBgWidth = 682 --背景最大宽度
local MaxPanelBtnCount = 5 --设置最大按钮数
-- 子页面枚举
local PARENT_PAGE
-- 子页面控件脚本字典
local ChildUiPage
function XUiGuildMain:OnAwake()
    self.GiftBoxes = {}
    self.LastRequestMember = 0
    self:InitChildView()
    self.ChildPage = {}
    self:InitChildUiPageData()
    self:InitModel()
end

function XUiGuildMain:OnDestroy()
    self:ChildPageOnDestroy()
    self.GuildWarEntry:OnDestroy()
end

function XUiGuildMain:OnStart(defaultIndex)
    self:SetGuildInfo()
    self:SetUiVisable()
    self:SetActiveGift()
    self:UpdateGuildNews()
    self:OnDeclarationChanged()
    self:OnInterComChanged()
    self:UpdateGuildMemberCount()

    -- 获取成员,测试要求
    local now = XTime.GetServerNowTimestamp()
    -- 第一次进入的时候AsyncGuildData会派发更新
    if GlobalLastRequestMember == 0 then
        GlobalLastRequestMember = now
    end
    if now - GlobalLastRequestMember >= GlobalRequestGap then
        GlobalLastRequestMember = now
        local guildId = XDataCenter.GuildManager.GetGuildId()
        XDataCenter.GuildManager.GetGuildMembers(guildId)
    end
end

function XUiGuildMain:OnEnable()
    --self.BtnTabChallenge:ShowReddot(XDataCenter.GuildBossManager.IsReward())
    --local timeLeft = XDataCenter.GuildManager.GuildBossEndTime() - XTime.GetServerNowTimestamp()
    --if timeLeft < 0 then
    --    timeLeft = 0
    --end
    --local timeStr = XUiHelper.GetTime(timeLeft, XUiHelper.TimeFormatType.MAINBATTERY)
    --self.BtnTabChallenge:SetNameByGroup(1, CS.XTextManager.GetText("GuildBossCountDown", timeStr))
    self.GuildWarEntry:OnEnable()
    self.GuildBossHallEntry:OnEnable()
    self:OpenChildPage(self.CurrentPageIndex or PARENT_PAGE.MAIN)
    if XDataCenter.GuildWarManager.CheckActivityIsInTime() then
        XDataCenter.GuildWarManager.GetActivityData(function()
                XDataCenter.GuildWarManager.RequestPopup()
            end)
    end
end

function XUiGuildMain:OnGetEvents()
    return {
        XEventId.EVENT_GUILD_RECEIVE_CHAT,
        XEventId.EVENT_GUILD_RANKLEVEL_CHANGED,
        XEventId.EVENT_GUILD_WEEKLY_RESET,
        XEventId.EVENT_GUILD_LEVEL_CHANGED,
        XEventId.EVENT_GUILD_GIFT_CONTRIBUTE_CHANGED,
        XEventId.EVENT_GUILD_CONTRIBUTE_CHANGED,
        XEventId.EVNET_GUILD_LEADER_NAME_CHANGED,
        XEventId.EVENT_GUILD_MEMBERCOUNT_CHANGED,
        XEventId.EVENT_GUILD_NAME_CHANGED,
        XEventId.EVENT_GUILD_DECLARATION_CHANGED,
        XEventId.EVENT_GUILD_INTERCOM_CHANGED,
        XEventId.EVENT_GUILD_WAR_DIFFICULTY_SELECTED,
    }
end

function XUiGuildMain:OnNotify(evt, ...)
    if evt == XEventId.EVENT_GUILD_RECEIVE_CHAT  then
        self:OnGuildChannelDispatchChat()
    elseif evt == XEventId.EVENT_GUILD_RANKLEVEL_CHANGED then
        self:OnGuildRankLevelChanged()
    elseif evt == XEventId.EVENT_GUILD_WEEKLY_RESET then
        self:OnGuildWeeklyReset()
    elseif evt == XEventId.EVENT_GUILD_CONTRIBUTE_CHANGED or
        evt == XEventId.EVENT_GUILD_GIFT_CONTRIBUTE_CHANGED then
        self:UpdateGuildGiftContribute()
    elseif evt == XEventId.EVENT_GUILD_LEVEL_CHANGED then
        self:UpdateInformationInfo()
    elseif evt == XEventId.EVNET_GUILD_LEADER_NAME_CHANGED then
        self:OnLeaderChanged()
    elseif evt == XEventId.EVENT_GUILD_MEMBERCOUNT_CHANGED then
        self:UpdateGuildMemberCount()
    elseif evt == XEventId.EVENT_GUILD_NAME_CHANGED then
        self:OnGuildNameChanged()
    elseif evt == XEventId.EVENT_GUILD_DECLARATION_CHANGED then
        self:OnDeclarationChanged()
    elseif evt == XEventId.EVENT_GUILD_INTERCOM_CHANGED then
        self:OnInterComChanged()
    elseif evt == XEventId.EVENT_GUILD_WAR_DIFFICULTY_SELECTED then
        -- self:OpenChildPage(PARENT_PAGE.MAIN)
        self:OpenChildPage(PARENT_PAGE.GUILDWAR)
    end
end

-- 周重置
function XUiGuildMain:OnGuildWeeklyReset()
    self:SetGuildInfo()
    self:SetActiveGift()
    self:UpdateGuildMemberCount()
end

-- 玩家职位变化
function XUiGuildMain:OnGuildRankLevelChanged()
    self:SetGuildInfo()
    self:UpdateGuildMemberCount()
end

-- 公会频道消息
function XUiGuildMain:OnGuildChannelDispatchChat()
    self:UpdateGuildNews()
end

-- 更新礼包建设度
function XUiGuildMain:UpdateGuildGiftContribute()
    self:SetGuildInfo()
    self:SetActiveGift()
end

-- 更新主界面信息
function XUiGuildMain:UpdateInformationInfo()
    self:SetGuildInfo()
end

-- 更新紧急维护状态
function XUiGuildMain:UpdateMaintainState()
    if self.tabViews[XDataCenter.GuildManager.GuildFunctional.Info] then
        self.tabViews[XDataCenter.GuildManager.GuildFunctional.Info]:UpdateInformationInfo()
    end
end

-- custom method

function XUiGuildMain:InitChildView()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    --self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self:BindHelpBtn(self.BtnHelp, "GuildMainHelp")
    self.BtnHelp.CallBack = function() self:OnBtnHelpClick() end
    self:AddRedPointEvent(self.RedSetting, self.RefreshSettingRed, self, { XRedPointConditions.Types.CONDITION_GUILD_APPLYLIST })
    self:AddRedPointEvent(self.RedNews, self.RefreshNewsRed, self, { XRedPointConditions.Types.CONDITION_GUILD_APPLYLIST })
    
    self.SettingBtnWidth = self.BtnGuildTuchu.transform.sizeDelta.x
    
    self.TxtMemberNum = self.TxtLeader.transform.parent.parent.transform:Find("TxtMember/TxtLeader"):GetComponent("Text")

    -- 设置面板 ---
    self.BtnAdministration.CallBack = function()
        if self.GuildSet.gameObject.activeInHierarchy then
            return
        end
        local showCount = XGuildConfig.RefreshSetView(self.BtnGuildTuchu, self.BtnGuildZhiwei, self.BtnGuildShenqinghan, self.BtnGuildSetName, self.BtnGuildReport)
        self.GuildSet.gameObject:SetActiveEx(true)
        local width = MaxPanelBgWidth - (MaxPanelBtnCount - showCount) * self.SettingBtnWidth
        width = CS.UnityEngine.Mathf.Clamp(width, 0, MaxPanelBgWidth)
        self.UiGuildBg:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Horizontal, width)
    end
    self.BtnDarkCloseBg.CallBack = function()
        self.GuildSet.gameObject:SetActiveEx(false)
    end
    -- 退出公会
    self.BtnGuildTuchu.CallBack = function() self:OnQuickGuildClick() end
    -- 职位自定义名称
    self.BtnGuildZhiwei.CallBack = function() self:OnJobChangeClick() end
    -- 招募设置
    self.BtnGuildZhaomu.CallBack = function() self:OnRecruitClick() end
    -- 申请函
    self.BtnGuildShenqinghan.CallBack = function() self:OnApplyClick() end
    -- 设置
    self.BtnGuildShezhi.CallBack = function() self:OnSettingClick() end
    -- 改名
    self.BtnGuildSetName.CallBack = function() self:OnSetGuildName() end
    --举报
    if self.BtnGuildReport then
        self.BtnGuildReport.CallBack = function() self:OnBtnGuildReportClick() end
    end
    --- end ---

    -- 公会宣言
    self.BtnAnnounce.CallBack = function() self:OnBtnAnnounceClick() end
    -- 内部通讯
    self.BtnInterCom.CallBack = function() self:OnBtnInterComClick() end
    -- 三个按钮
    self.BtnRanking.CallBack = function() self:OnBtnRaningClick() end
    self.BtnJournal.CallBack = function() self:OnBtnJournalClick() end
    self.BtnDeclaration.CallBack = function() self:OnBtnDeclarationClick() end

    -- 更换头像
    --self.GuildViewSetHeadPortrait = XUiGuildViewSetHeadPortrait.New(self.PanelSetHeadPotrait,self)
    self.BtnSetFace.CallBack = function() self:OnBtnSetFaceClick() end

    -- 其他模块
    self.BtnTabMember.CallBack = function() self:OnBtnTabMemberClick() end
    self.BtnTabMember:ShowReddot(false)
    --self.BtnTabChallenge.CallBack = function() self:OnBtnTalentClick() end
    --self.BtnTabGift.CallBack = function() self:OnBtnTabGiftClick() end
    self.BtnChat.CallBack = function() self:OnBtnChatClick() end
    if self.SwitchGuildDorm then
        local btn = require("XUi/XUiGuildDorm/XUiGuildSwitchBtn")
        self.BtnSwitchGuild = btn.New(self, self.SwitchGuildDorm, false)
        self.SwitchGuildDorm.gameObject:SetActiveEx(not XDataCenter.GuildDormManager.GetIsHaveTempError())
    end
    --公会战入口
    local guildWarEntryButtonScript = require("XUi/XUiGuildWar/XUiGuildWarEntryButton")
    self.GuildWarEntry = guildWarEntryButtonScript.New(self.BtnGuildWarEntry,function() self:OnBtnGuildWarEntryClick() end)
    self:AddRedPointEvent(self.BtnGuildWarEntry, self.OnCheckGuildWarEntryRedPoint, self,
        {
            XRedPointConditions.Types.CONDITION_GUILDWAR_Main,
        })
    --拟真围剿入口
    local guildBossHallButtonScript = require("XUi/XUiGuildBoss/XUiGuildBossHallEntryButton")
    self.GuildBossHallEntry = guildBossHallButtonScript.New(self.BtnGuildBossHall, handler(self, self.OnBtnChallengeClick))
    --等级界面入口
    self.BtnSee.CallBack = function()
        if not XDataCenter.GuildManager.IsJoinGuild() then
            return
        end
        XLuaUiManager.Open("UiGuildGrade")
    end
    
    --任務
    self.BtnGift.CallBack = function()
        XLuaUiManager.Open("UiGuildTaskGroup")
    end
    self:AddRedPointEvent(self.BtnGift, self.CheckBtnGiftRedPoint, self, {
        XRedPointConditions.Types.CONDITION_GUILD_ACTIVEGIFT,
        XRedPointConditions.Types.CONDITION_GUILDBOSS_BOSSHP,
        XRedPointConditions.Types.CONDITION_GUILDBOSS_SCORE,
    })
    --商店
    self.BtnTabShop.CallBack = function()
        XLuaUiManager.Open("UiShop", XShopManager.ShopType.Guild)
    end
    --信标
    self.BtnTabBeacon.CallBack = function() self:OnBtnTalentClick() end
    --复制Id
    self.BtnCopy.CallBack = function() 
        XTool.CopyToClipboard(self.TxtID.text)
    end
end

function XUiGuildMain:CheckBtnGiftRedPoint(count)
    self:SetActiveGift()
    self.BtnGift:ShowReddot(count >= 0)
end

function XUiGuildMain:RefreshSettingRed(count)
    self.RedSetting.gameObject:SetActiveEx(count >= 0)
end

function XUiGuildMain:RefreshNewsRed(count)
    self.RedNews.gameObject:SetActiveEx(count >= 0)
end

function XUiGuildMain:OnBtnBackClick()
    if self.CurrentPageIndex ~= PARENT_PAGE.MAIN then
        self:OpenChildPage(PARENT_PAGE.MAIN)
    else
        XLuaUiManager.RunMain()
    end
end

function XUiGuildMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiGuildMain:OnBtnHelpClick()
    if self.CurrentPageIndex == PARENT_PAGE.GUILDWAR then
        XUiManager.ShowHelpTip("GuildWarHelp")
    else
        XUiManager.ShowHelpTip("GuildMainHelp")
    end
end

-- 退出公会
function XUiGuildMain:OnQuickGuildClick()
    if self:ChecKickOut() then return end

    self.GuildSet.gameObject:SetActiveEx(false)
    local isLeader = XDataCenter.GuildManager.IsGuildLeader()
    if isLeader then
        local memberCount = XDataCenter.GuildManager.GetMemberCount()
        if memberCount > 1 then
            XUiManager.TipMsg(CS.XTextManager.GetText("GuildQuitRemovePosition"))
            return
        else
            local title = CS.XTextManager.GetText("GuildDialogTitle")
            local content = CS.XTextManager.GetText("GuildQuitLastMember")
            XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, function()
                end, function()
                    XDataCenter.GuildManager.QuitGuild(function()
                            if XLuaUiManager.IsUiShow("UiGuildMain") then
                                XLuaUiManager.Close("UiGuildMain")
                            end
                        end)
                end)
        end
    else
        local title = CS.XTextManager.GetText("GuildDialogTitle")
        local content = CS.XTextManager.GetText("GuildQuitMemberQuit")
        
        --判断工会战是否开启 如果开启 置换退出提示
        if XDataCenter.GuildWarManager.CheckActivityIsInTime() then
            content = CS.XTextManager.GetText("GuildQuitMemberQuitInGuildWarTime")
        end
        
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, function()
            end, function()
                XDataCenter.GuildManager.QuitGuild(function()
                        if XLuaUiManager.IsUiShow("UiGuildMain") then
                            XLuaUiManager.Close("UiGuildMain")
                        end
                    end)
            end)
    end
end

-- 职位
function XUiGuildMain:OnJobChangeClick()
    if self:ChecKickOut() then return end
    if self:HasModifyAccess() then return end

    XLuaUiManager.Open("UiGuildCustomName")
    self.GuildSet.gameObject:SetActiveEx(false)
end

-- 招募
function XUiGuildMain:OnRecruitClick()
    if self:ChecKickOut() then return end
    if self:HasModifyAccess() then return end

    local currentPageNo = XDataCenter.GuildManager.GetRecommendPageNo()
    XDataCenter.GuildManager.GuildRecruitRecommendRequest(currentPageNo, function()
            XLuaUiManager.Open("UiGuildRecruit", XGuildConfig.EnlistType.Recruit)
            self.GuildSet.gameObject:SetActiveEx(false)
        end)
end

-- 邀请函
function XUiGuildMain:OnApplyClick()
    if self:ChecKickOut() then return end
    if self:HasModifyAccess() then return end

    local currentPageNo = XDataCenter.GuildManager.GetRecommendPageNo()
    XDataCenter.GuildManager.GuildRecruitRecommendRequest(currentPageNo, function()
            XLuaUiManager.Open("UiGuildRecruit", XGuildConfig.EnlistType.News)
            self.GuildSet.gameObject:SetActiveEx(false)
        end)
end

-- 招募设置
function XUiGuildMain:OnSettingClick()
    if self:ChecKickOut() then return end
    if self:HasModifyAccess() then return end

    XLuaUiManager.Open("UiGuildChangePosition", XGuildConfig.TipsType.ApplySetting)
    self.GuildSet.gameObject:SetActiveEx(false)
end

-- 公会改名
function XUiGuildMain:OnSetGuildName()
    if self:ChecKickOut() then return end
    if not XDataCenter.GuildManager.IsGuildLeader() then
        local leaderName = XDataCenter.GuildManager.GetRankNameByLevel(XGuildConfig.GuildRankLevel.Leader)
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildNotAccessSetName", leaderName))
        return
    end

    XLuaUiManager.Open("UiGuildChangePosition", XGuildConfig.TipsType.SetName)
    self.GuildSet.gameObject:SetActiveEx(false)
end

--举报公会
function XUiGuildMain:OnBtnGuildReportClick()
    local guildId = XDataCenter.GuildManager.GetGuildId()
    local titleName = XDataCenter.GuildManager.GetGuildName()
    local guildDesclaration = XDataCenter.GuildManager.GetGuildDeclaration()
    local guildInsideIntroduction = XDataCenter.GuildManager.GetGuildInterCom()
    local data = {Id = guildId, TitleName = titleName, GuildOuterIntroduction = guildDesclaration, GuildInsideIntroduction = guildInsideIntroduction}
    XLuaUiManager.Open("UiReport", data, nil, nil, XReportConfigs.EnterType.Guild)
end

-- 公会排名
function XUiGuildMain:OnBtnRaningClick()
    XLuaUiManager.Open("UiGuildRankingListSwitch")
end

-- 成员
function XUiGuildMain:OnBtnTabMemberClick()
    local guildId = XDataCenter.GuildManager.GetGuildId()
    local now = XTime.GetServerNowTimestamp()
    if now - self.LastRequestMember >= RequestMemberGap then
        self.LastRequestMember = now
        XDataCenter.GuildManager.GetGuildMembers(guildId, function()
                XLuaUiManager.Open("UiGuildRongyu")
            end)
    else
        XLuaUiManager.Open("UiGuildRongyu")
    end
end

-- 挑战
function XUiGuildMain:OnBtnChallengeClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.GuildBoss) then
        return
    end
    XDataCenter.GuildBossManager.SetFirstEnterMark(true)
    XDataCenter.GuildBossManager.OpenGuildBossHall()
end

-- 福利
function XUiGuildMain:OnBtnTabGiftClick()
    XLuaUiManager.Open("UiGuildPanelWelfare")
end

--信标
function XUiGuildMain:OnBtnTalentClick()
    XDataCenter.GuildManager.EnterGuildTalent()
end

-- 聊天
function XUiGuildMain:OnBtnChatClick()
    XUiHelper.OpenUiChatServeMain(false, ChatChannelType.Guild, ChatChannelType.World)
end

--公会宿舍
function XUiGuildMain:OnBtnGuildDormClick()
    if XLuaUiManager.IsUiLoad("UiGuildDormMain") then
        --由于Ui底层问题，若公会宿舍主页已经打开，需要重新恢复该页面而不是打开一个新的
        --这里跟设计约定若要实现此功能，只能用类似“返回”的做法(即保持上一个页面是公会宿舍主页，这里直接关闭)
        self:Close()
    else
        XDataCenter.GuildDormManager.EnterGuildDorm()
    end
end

-- 日志、动态
function XUiGuildMain:OnBtnJournalClick()
    -- 中途被踢出公会
    if self:ChecKickOut() then
        return
    end

    XLuaUiManager.Open("UiGuildLog")
end

-- 迎新
function XUiGuildMain:OnBtnDeclarationClick()
    if XDataCenter.GuildManager.IsGuildTourist() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildTourstAccess"))
        return
    end
    XLuaUiManager.Open("UiGuildWelcomeWord")
end

-- 切换公会图标
function XUiGuildMain:OnBtnSetFaceClick()
    if not XDataCenter.GuildManager.IsGuildAdminister() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildNotAdministor"))
        return
    end
    XLuaUiManager.Open("UiGuildDormHeadPotrait", function()
        self.RImgGuildIcon:SetRawImage(XDataCenter.GuildManager.GetGuildIconId())
    end)
    --self.PanelSetHeadPotrait.gameObject:SetActiveEx(true)
    --local curHeadPortrait = XDataCenter.GuildManager.GetGuildHeadPortrait()
    --self.GuildViewSetHeadPortrait:OnRefresh(curHeadPortrait)
end

-- 新图标
function XUiGuildMain:RecordGuildIconId(selectHeadPortraitId)
    local curHeadPortrait = XDataCenter.GuildManager.GetGuildHeadPortrait()
    if selectHeadPortraitId ~= curHeadPortrait then
        XDataCenter.GuildManager.GuildChangeIconRequest(selectHeadPortraitId, function()
                local cfg = XGuildConfig.GetGuildHeadPortraitById(selectHeadPortraitId)
                if cfg then
                    self.RImgGuildIcon:SetRawImage(cfg.Icon)
                end
            end)
    end
end

-- 新名字
function XUiGuildMain:OnGuildNameChanged()
    self.TxtGuildName.text = XDataCenter.GuildManager.GetGuildName()
end

-- 新宣言
function XUiGuildMain:OnDeclarationChanged()
    self.TxtAnnounce.text = XDataCenter.GuildManager.GetGuildDeclaration()
end

-- 新内部通讯
function XUiGuildMain:OnInterComChanged()
    local notice = XDataCenter.GuildManager.GetGuildInterCom()
    if notice == nil or notice == "" then
        self.TxtInterCom.text = CS.XTextManager.GetText("GuildInterComDes")
    else
        self.TxtInterCom.text = notice
    end
end

-- 修改公会宣言
function XUiGuildMain:OnBtnAnnounceClick()
    -- 中途被踢出公会
    if self:ChecKickOut() then
        return
    end
    -- 职位变更
    if self:HasModifyAccess() then
        return
    end

    XLuaUiManager.Open("UiGuildInformation", XGuildConfig.InformationType.Announcement)
end

-- 修改内部通讯
function XUiGuildMain:OnBtnInterComClick()
    -- 中途被踢出公会
    if self:ChecKickOut() then
        return
    end
    -- 职位变更
    if self:HasModifyAccess() then
        return
    end

    XLuaUiManager.Open("UiGuildInformation", XGuildConfig.InformationType.InternalCommunication)
end

-- 公会信息
function XUiGuildMain:SetGuildInfo()
    local guildId = XDataCenter.GuildManager.GetGuildId()
    local guildLevel = XDataCenter.GuildManager.GetGuildLevel()
    local curBuild = XDataCenter.GuildManager.GetBuild()
    self.RImgGuildIcon:SetRawImage(XDataCenter.GuildManager.GetGuildIconId())
    self.TxtGuildName.text = XDataCenter.GuildManager.GetGuildName()
    self.TxtLeader.text = XDataCenter.GuildManager.GetGuildLeaderName()
    self.TxtID.text = string.format("%08d",guildId)
    self.GuildLevelTemplate = XGuildConfig.GetGuildLevelDataBylevel(guildLevel)
    self:RefreshGuildMember()
    if XDataCenter.GuildManager.CheckAllTalentLevelMax() then
        local gloryLevel = XDataCenter.GuildManager.GetGloryLevel()
        self.TxtLvNum.text = string.format("<size=28>%d</size><color=#FFF400>(%d)</color>", guildLevel, gloryLevel)
    else
        self.TxtLvNum.text = string.format("<size=28>%d</size>", guildLevel)
    end
    if XDataCenter.GuildManager.IsGuildLevelMax(guildLevel) then
        -- 达到最高等级
        self.ImgProgress.fillAmount = curBuild * 1.0 / GuildBuildIntervalWhenMaxLevel
        self.TxtNum.text = string.format("<color=#008FFF>%s</color>/%s", tostring(curBuild), tostring(GuildBuildIntervalWhenMaxLevel))
    else
        -- 未到达最高等级
        self.TxtLvNum.text = guildLevel
        self.ImgProgress.fillAmount = curBuild * 1.0 / self.GuildLevelTemplate.Build
        self.TxtNum.text = string.format("<color=#008FFF>%s</color>/%s", tostring(curBuild), tostring(self.GuildLevelTemplate.Build))
    end
end

-- 隐藏非管理员图标
function XUiGuildMain:SetUiVisable()
    if not XDataCenter.GuildManager.IsGuildAdminister() then
        self.BtnInterCom.gameObject:SetActiveEx(false)
        self.BtnAnnounce.gameObject:SetActiveEx(false)
    end
    if not XDataCenter.GuildManager.IsGuildLeader() then
        self.BtnSetFace.gameObject:SetActiveEx(false)
    end
end

function XUiGuildMain:OnLeaderChanged()
    self.TxtLeader.text = XDataCenter.GuildManager.GetGuildLeaderName()
end

function XUiGuildMain:RefreshGuildMember()
    self.TxtMemberNum.text = string.format("<color=#008FFF>%s</color>/%s", XDataCenter.GuildManager.GetMemberCount(), XDataCenter.GuildManager.GetMemberMaxCount())
end

-- 公会频道
function XUiGuildMain:UpdateGuildNews()
    local chatList = XDataCenter.ChatManager.GetGuildChatList()
    if not chatList then return end
    local lastChat = chatList[1]
    if not lastChat then return end
    if not string.IsNilOrEmpty(lastChat.CustomContent) then
        self.TxtMessageContent.supportRichText = true
    else
        self.TxtMessageContent.supportRichText = false
    end

    local nameRemark = XDataCenter.SocialManager.GetPlayerRemark(lastChat.SenderId, lastChat.NickName)
    local content = lastChat.Content
    if lastChat.MsgType == ChatMsgType.System then
        content = string.format("%s：%s", CS.XTextManager.GetText("GuildChannelTypeAll"), lastChat.Content)
        self.TxtMessageContent.text = content
    else
        content = lastChat.Content
        if lastChat.MsgType == ChatMsgType.Emoji then
            content = CS.XTextManager.GetText("GuildEmojiReplace")
        end
        self.TxtMessageContent.text = string.format("%s：%s", nameRemark, content)
    end

    if XUiHelper.CalcTextWidth(self.TxtMessageContent) > MAX_CHAT_WIDTH then
        self.TxtMessageContent.text = string.Utf8Sub(self.TxtMessageContent.text, 1, CHAT_SUB_LENGTH) .. [[...]]
    end
end

-- 活跃度礼包
function XUiGuildMain:SetActiveGift()
    self.PanelGift.gameObject:SetActiveEx(false)
    local giftContribute = XDataCenter.GuildManager.GetGiftContribute()
    self.BtnGift:SetNameByGroup(0, giftContribute)
    --local giftGuildLevel = XDataCenter.GuildManager.GetGiftGuildLevel()
    --
    --self.AllBoxesConfig = XGuildConfig.GetGuildGiftByGuildLevel(giftGuildLevel)
    --if not self.AllBoxesConfig then return end
    --self.MaxContribute = 0
    --for _, v in pairs(self.AllBoxesConfig) do
    --    if v.GiftContribute > self.MaxContribute then
    --        self.MaxContribute = v.GiftContribute
    --    end
    --end
    --
    --for i = 1, #self.AllBoxesConfig do
    --    if not self.GiftBoxes[i] then
    --        local ui = CS.UnityEngine.Object.Instantiate(self.PanelActive)
    --        local grid = XUiGridGuildBoxItem.New(ui, self)
    --        grid.Transform:SetParent(self.PanelGift, false)
    --        self.GiftBoxes[i] = grid
    --    end
    --    self.GiftBoxes[i].GameObject:SetActiveEx(true)
    --    self.GiftBoxes[i]:RefreshGift(self.AllBoxesConfig[i], i, self.MaxContribute)
    --end
    --for i = #self.AllBoxesConfig + 1, #self.GiftBoxes do
    --    self.GiftBoxes[i].GameObject:SetActiveEx(false)
    --end
    --self.TxtDailyActive.text = giftContribute
    --if self.MaxContribute > 0 then
    --    self.ImgDaylyActiveProgress.fillAmount = giftContribute * 1.0 / self.MaxContribute
    --end
end

-- 公会人数
function XUiGuildMain:UpdateGuildMemberCount()
    local curCount = XDataCenter.GuildManager.GetOnlineMemberCount()
    --local maxCount = XDataCenter.GuildManager.GetMemberMaxCount()
    self.BtnTabMember:SetNameByGroup(1, CSXTextManagerGetText("GuildMemberOnlineCount", curCount))
    self:RefreshGuildMember()
end

function XUiGuildMain:HasModifyAccess()
    if not XDataCenter.GuildManager.IsGuildAdminister() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildNotAdministor"))
        return true
    end
    return false
end

function XUiGuildMain:ChecKickOut()
    if not XDataCenter.GuildManager.IsJoinGuild() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildKickOutByAdministor"))
        self:Close()
        return true
    end
    return false
end

--==================================
--以下为加入公会战后的修改
--公会战界面以子场景的形式，追加了镜头变更的操作
--==================================

--=============
--显示主界面
--=============
function XUiGuildMain:ShowMain()
    --主界面关闭镜头模糊
    self:SetActiveScene3DBlur(false)
    self:UpdateCamera(PARENT_PAGE.MAIN)
    self.PanelInfo.gameObject:SetActiveEx(true)
    self.PanelLeftBtn.gameObject:SetActiveEx(true)
    self.PanelRightBtn.gameObject:SetActiveEx(true)
    self.GuildWarEntry:OnShow()
end
--=============
--隐藏主界面
--=============
function XUiGuildMain:HideMain()
    self.PanelInfo.gameObject:SetActiveEx(false)
    self.PanelLeftBtn.gameObject:SetActiveEx(false)
    self.PanelRightBtn.gameObject:SetActiveEx(false)
    --self.PanelGuildWarEntry.gameObject:SetActiveEx(false)
    self.GuildWarEntry.GameObject:SetActiveEx(false)
end
--================
--初始化枚举与字典
--================
function XUiGuildMain:InitChildUiPageData()
    PARENT_PAGE = {
        MAIN = 1, -- 主页面
        GUILDWAR = 2, -- 公会战页面
    }
    ChildUiPage = {
        [PARENT_PAGE.GUILDWAR] = require("XUi/XUiGuild/ChildPage/XUiGuildWarPage"),
    }
end
--================
--打开子页面，打开新页面时会关闭旧的子页面
--由于这是后来新的需求的原因，这里主页面作特殊处理
--================
function XUiGuildMain:OpenChildPage(pageIndex, ...)
    if self.CurrentPageIndex == pageIndex then
        if self.CurrentPageIndex ~= PARENT_PAGE.MAIN then
            self.ChildPage[self.CurrentPageIndex]:OnRepeatOpen()
        end
        return
    end
    if self.CurrentPageIndex then
        if self.CurrentPageIndex ~= PARENT_PAGE.MAIN then
            self.ChildPage[self.CurrentPageIndex]:HidePage()
        else
            self:HideMain()
        end
    end
    if self.ChildPage[pageIndex] then
        self.CurrentPageIndex = pageIndex
        if pageIndex ~= PARENT_PAGE.MAIN then
            self.ChildPage[self.CurrentPageIndex]:ShowPage(...)
        else
            self:ShowMain()
        end
        return
    end
    self.CurrentPageIndex = pageIndex
    if pageIndex ~= PARENT_PAGE.MAIN then
        self.ChildPage[pageIndex] = ChildUiPage[pageIndex].New(self)
        self.ChildPage[pageIndex]:ShowPage(...)
    else
        self:ShowMain()
    end
end
-- 3D场景相机数量
local CAMERA_NUM = 2
--================
--初始化角色模型和场景相机
--================
function XUiGuildMain:InitModel()
    local root = self.UiModelGo.transform
    local camera = root:FindTransform("NearCamera")
    self.Scene3DBlur = camera and camera:GetComponent("XUiScene3DBlur")
    self.CameraNear = {
        [PARENT_PAGE.MAIN] = root:FindTransform("UiMainCamera"),
        [PARENT_PAGE.GUILDWAR] = root:FindTransform("UiGuildWarCamera"),
    }
end
--================
--刷新场景相机
--================
function XUiGuildMain:UpdateCamera(pageIndex)
    self.CurCameraIndex = pageIndex
    for i = 1, CAMERA_NUM do
        if self.CurCameraIndex ~= i then
            self.CameraNear[i].gameObject:SetActiveEx(false)
        end
    end
    if self.CameraNear[self.CurCameraIndex] then
        self.CameraNear[self.CurCameraIndex].gameObject:SetActiveEx(true)
    end
end
--================
--读取面板控件
--================
function XUiGuildMain:LoadChildPrefab(pageIndex, assetPath)
    return self["Panel" .. pageIndex]:LoadPrefab(assetPath)
end
--================
--销毁子页面
--================
function XUiGuildMain:ChildPageOnDestroy()
    for _, page in pairs(self.ChildPage) do
        if page.OnDestroy then page:OnDestroy() end
    end
end
--================
--设置镜头模糊
--================
function XUiGuildMain:SetActiveScene3DBlur(value)
    if self.Scene3DBlur then
        self.Scene3DBlur.enabled = value
    end
end

function XUiGuildMain:OnCheckGuildWarEntryRedPoint(count)
    self.BtnGuildWarEntry:ShowReddot(count >= 0)
end
--================
--点击公会战入口
--================
function XUiGuildMain:OnBtnGuildWarEntryClick()
    XDataCenter.GuildWarManager.OpenUiGuildWarMain(function()
        self:OpenChildPage(PARENT_PAGE.GUILDWAR)
    end)
end