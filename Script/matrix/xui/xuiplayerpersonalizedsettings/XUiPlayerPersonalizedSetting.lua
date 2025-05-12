local XUiPanelHeadPortrait = require("XUi/XUiPlayer/XUiPanelHeadPortrait")
local XUiPlayerPersonalizedSetting = XLuaUiManager.Register(XLuaUi, "UiPlayerPersonalizedSetting")

local XUiPanelHeadPortraitSetting = require('XUi/XUiPlayerPersonalizedSettings/XUiPanelHeadPortraitSetting')
local XUiPanelHeadFrameSetting = require('XUi/XUiPlayerPersonalizedSettings/XUiPanelHeadFrameSetting')
local XUiPanelHeadMedalSetting = require('XUi/XUiPlayerPersonalizedSettings/XUiPanelHeadMedalSetting')
local XUiPanelHeadNameplateSetting = require('XUi/XUiPlayerPersonalizedSettings/XUiPanelHeadNameplateSetting')
local XUiPanelChatBoardSetting = require('XUi/XUiPlayerPersonalizedSettings/XUiPanelChatBoardSetting')

local XUiPanelNoSelectInfo = require('XUi/XUiPlayerPersonalizedSettings/XUiPanelNoSelectInfo')
local XUiPanelNameplate = require("XUi/XUiNameplate/XUiPanelNameplate")
local XUiChatBoard = require('XUi/XUiChatServe/XUiChatBoard')

function XUiPlayerPersonalizedSetting:OnAwake()
    self.TempHeadPortraitId = 0
    self.TempHeadFrameId = 0
    self.TempHeadMedalId = 0
    self.TempHeadNameplateId = 0
    self.TempChatBoardId = 0
    self.CurrHeadPortraitId = 0
    self.CurrHeadFrameId = 0
    self.CurrHeadMedalId = 0
    self.CurrHeadNameplateId = 0
    self.CurrChatBoardId = 0
    self.OldPortraitSelectGrig = {}
    self.OldFrameSelectGrig = {}

    self._PanelHeadPortraitSetting = XUiPanelHeadPortraitSetting.New(self.HeadPortraitScrollView, self, self.PanelHeadPortraitInfoObj)
    self._PanelHeadFrameSetting = XUiPanelHeadFrameSetting.New(self.HeadFrameScrollView, self, self.PanelHeadFrameInfoObj)
    self._PanelHeadMedalSetting = XUiPanelHeadMedalSetting.New(self.HeadMedalScrollView, self, self.PanelHeadMedal)
    self._PanelHeadNameplateSetting = XUiPanelHeadNameplateSetting.New(self.HeadNameplateScrollView, self, self.PanelHeadNameplate)
    self._PanelChatBoardSetting = XUiPanelChatBoardSetting.New(self.HeadChatBoardScrollView, self, self.PanelHeadChatBoard)

    self._PanelNoSelectInfo = XUiPanelNoSelectInfo.New(self.PanelNoSelectInfoObj, self)
    self._PanelNameplate = XUiPanelNameplate.New(self.PanelNameplate, self)
    self._ChatBoradPreview = XUiChatBoard.New(self.ChatBoardPreview, self)
end

function XUiPlayerPersonalizedSetting:OnStart(defaultSelectIndex)
    self:AutoAddListener()
    self:BtnGroupInit(defaultSelectIndex)
    self:RefreshPreviewPanel()
    self:RefreshAllRedPoint()
end

function XUiPlayerPersonalizedSetting:OpenWithDefaultSelect(defaultSelectIndex)
    self:Open()
    if XTool.IsNumberValid(defaultSelectIndex) and defaultSelectIndex<=5 then
        self.PanelTouxiangGroup:SelectIndex(defaultSelectIndex)
    end
end

function XUiPlayerPersonalizedSetting:Reset()
    self.CurType = XHeadPortraitConfigs.HeadType.HeadPortrait
    self.TempHeadFrameId = 0
    self.PanelTouxiangGroup:SelectIndex(self.CurType)
    self:RefreshAllRedPoint()
    XEventManager.AddEventListener(XEventId.EVENT_HEAD_PORTRAIT_TIMEOUT, self.TimeOutRefresh, self)
end

function XUiPlayerPersonalizedSetting:TimeOutRefresh()
    self.TempHeadFrameId = 0
    self.PanelTouxiangGroup:SelectIndex(self.CurType)
    self:RefreshAllRedPoint()
end

function XUiPlayerPersonalizedSetting:BtnGroupInit(defaultSelectIndex)
    self.CurType = XHeadPortraitConfigs.HeadType.HeadPortrait
    self.BtnList = {self.BtnTouxiang, self.BtnTouxiangKuang}
    
    -- 选项的Id是固定的，但多选框长度不一样导致实际按钮索引会变，因此需要做选项Id到多选框索引的映射
    self._BtnIdMapIndex = {
        [1] = 1,
        [2] = 2,
    }
    self._BtnIndexMapId = {
        [1] = 1,
        [2] = 2,
    }
    local index = 2

    index = self:InitBtnWithFunctionOpenCheck(self.BtnXunZhang, XFunctionManager.FunctionName.Medal, self.BtnList, index, XHeadPortraitConfigs.HeadType.Medal)
    index = self:InitBtnWithFunctionOpenCheck(self.BtnMMingPai, XFunctionManager.FunctionName.Nameplate, self.BtnList, index, XHeadPortraitConfigs.HeadType.Nameplate)
    index = self:InitBtnWithFunctionOpenCheck(self.BtnliaoTianKuang, XFunctionManager.FunctionName.SocialChat, self.BtnList, index, XHeadPortraitConfigs.HeadType.ChatBoard)
    
    -- 修正获得真实的索引
    defaultSelectIndex = self._BtnIdMapIndex[defaultSelectIndex]
    
    self.PanelTouxiangGroup:Init(self.BtnList, function(index) self:SelectType(index) end)
    if XTool.IsNumberValid(defaultSelectIndex) and defaultSelectIndex<=5 then
        self.PanelTouxiangGroup:SelectIndex(defaultSelectIndex)
    end
end

function XUiPlayerPersonalizedSetting:SelectType(index)
    -- 传入的是索引，需要获取其映射的Id
    self.CurType = self._BtnIndexMapId[index]
    
    --关闭全部切页
    self._PanelHeadPortraitSetting:Close()
    self._PanelHeadFrameSetting:Close()
    self._PanelHeadMedalSetting:Close()
    self._PanelHeadNameplateSetting:Close()
    self._PanelChatBoardSetting:Close()
    
    if self.CurType == XHeadPortraitConfigs.HeadType.HeadPortrait then
        self._PanelHeadPortraitSetting:Open()
        self._PanelHeadPortraitSetting:ShowHeadPortraitPanel()
        self._PanelHeadPortraitSetting:SetupHeadPortraitDynamicTable(XDataCenter.HeadPortraitManager.GetHeadPortraitNumById(self.CurrHeadPortraitId, self.CurType))
        self:PlayAnimation("QieHuan")
    elseif self.CurType == XHeadPortraitConfigs.HeadType.HeadFrame then
        self._PanelHeadFrameSetting:Open()
        self._PanelHeadFrameSetting:ShowHeadFramePanel()
        self._PanelHeadFrameSetting:SetupHeadFrameDynamicTable(XDataCenter.HeadPortraitManager.GetHeadPortraitNumById(self.CurrHeadPortraitId, self.CurType))
        self:PlayAnimation("QieHuan")
    elseif self.CurType == XHeadPortraitConfigs.HeadType.Medal then
        self._PanelHeadMedalSetting:Open()
        self._PanelHeadMedalSetting:ShowHeadMedalPanel()
        self._PanelHeadMedalSetting:SetupHeadMedalDynamicTable(XDataCenter.MedalManager.GetMedalIndexById(self.CurrHeadMedalId))
        self:PlayAnimation("QieHuan")
    elseif self.CurType == XHeadPortraitConfigs.HeadType.Nameplate then
        self._PanelHeadNameplateSetting:Open()
        self._PanelHeadNameplateSetting:ShowHeadNameplatePanel()
        self._PanelHeadNameplateSetting:SetupHeadNameplateDynamicTable()
        self:PlayAnimation("QieHuan")
    elseif self.CurType == XHeadPortraitConfigs.HeadType.ChatBoard then
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SocialChat) then
            self._PanelChatBoardSetting:Open()
            self._PanelChatBoardSetting:ShowChatBoardPanel()
            self._PanelChatBoardSetting:SetupChatBoardDynamicTable()
            self:PlayAnimation("QieHuan")
        end
    end
end

function XUiPlayerPersonalizedSetting:AutoAddListener()
    self.BtnClose.CallBack = function()
        self:OnBtnCancelClick()
    end
end

function XUiPlayerPersonalizedSetting:SetHeadTime(info, panel, headId, type)
    if not panel then
        return
    end
    if info.LimitType == XHeadPortraitConfigs.HeadTimeLimitType.FixedTime then
        local beginTime = XDataCenter.HeadPortraitManager.GetBeginTimestamp(headId)
        local endTime = XDataCenter.HeadPortraitManager.GetEndTimestamp(headId)

        panel.PanelTime.gameObject:SetActiveEx(true)
        panel.TxtTime.text = XTime.TimestampToGameDateTimeString(beginTime, "yyyy/MM/dd") .. "-" .. XTime.TimestampToGameDateTimeString(endTime, "yyyy/MM/dd")
    elseif info.LimitType == XHeadPortraitConfigs.HeadTimeLimitType.Duration then
        panel.PanelTime.gameObject:SetActiveEx(true)
        if XDataCenter.HeadPortraitManager.IsHeadPortraitValid(headId) then
            panel.TxtTime.text = XDataCenter.HeadPortraitManager.GetHeadLeftTime(headId)
        else
            panel.TxtTime.text = XDataCenter.HeadPortraitManager.GetHeadValidDuration(headId)
        end
    elseif XTool.IsNumberValid(info.KeepTime) then -- 勋章
        panel.PanelTime.gameObject:SetActiveEx(true)
        if XPlayer.IsMedalUnlock(info.Id) then
            local data = XDataCenter.MedalManager.GetMedalById(info.Id)
            if data then
                if not XDataCenter.MedalManager.CheckMedalIsExpired(info.Id) then
                    panel.TxtTime.text = XUiHelper.GetText('HeadLeftTimeText', XUiHelper.GetTime(data.KeepTime + data.Time - XTime.GetServerNowTimestamp(), XUiHelper.TimeFormatType.HEADPORTRAIT))
                else
                    panel.TxtTime.text = XUiHelper.GetText('MedalOverdue')
                end
            end
        else
            panel.TxtTime.text = XUiHelper.GetText('HeadValidTimeText', XUiHelper.GetTime(info.KeepTime, XUiHelper.TimeFormatType.HEADPORTRAIT))
        end
    elseif type == XHeadPortraitConfigs.HeadType.Nameplate then -- 铭牌
        local data = XDataCenter.MedalManager.CheckNameplateGroupUnluck(info.Group)
        if data and not data:IsNamepalteForever() then
            panel.PanelTime.gameObject:SetActiveEx(true)
            local leftTime = data:GetNamepalteLeftTime()

            if leftTime >0 then
                panel.TxtTime.text = XUiHelper.GetText('HeadLeftTimeText', XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.HEADPORTRAIT))
            else
                panel.TxtTime.text = XUiHelper.GetText('NameplateOutTime')
            end
        else
            panel.PanelTime.gameObject:SetActiveEx(false)
        end
    elseif type == XHeadPortraitConfigs.HeadType.ChatBoard then -- 聊天框
        local data = XDataCenter.ChatManager.GetChatBoardDataById(info.Id)
        if data and XTool.IsNumberValid(data.EndTime) then
            panel.PanelTime.gameObject:SetActiveEx(true)
            if not XDataCenter.ChatManager.CheckChatBoardIsLockById(info.Id) then
                local leftTime = data.EndTime - XTime.GetServerNowTimestamp()
                if leftTime < 0 then
                    leftTime = 0
                end
                panel.TxtTime.text = XUiHelper.GetText('HeadLeftTimeText', XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.HEADPORTRAIT))
            else
                panel.TxtTime.text = XUiHelper.GetText('ChatBoardOverdue')
            end
        else
            panel.PanelTime.gameObject:SetActiveEx(false)
        end
    else
        panel.PanelTime.gameObject:SetActiveEx(false)
    end
end

function XUiPlayerPersonalizedSetting:SetHeadTimeText(panel, text)
    panel.PanelTime.gameObject:SetActiveEx(true)
    panel.TxtTime.text = text
end
--region 红点
function XUiPlayerPersonalizedSetting:RefreshAllRedPoint()
    self:ShowHeadPortraitRedPoint()
    self:ShowHeadFrameRedPoint()
    self:ShowHeadMedalRedPoint()
    self:ShowHeadNameplateRedPoint()
    self:ShowHeadChatBoardRedPoint()
end

function XUiPlayerPersonalizedSetting:ShowHeadPortraitRedPoint()
    local IsShowRed = XDataCenter.HeadPortraitManager.CheckIsNewHeadPortrait(XHeadPortraitConfigs.HeadType.HeadPortrait)
    self.BtnTouxiang:ShowReddot(IsShowRed)
end

function XUiPlayerPersonalizedSetting:ShowHeadFrameRedPoint()
    local IsShowRed = XDataCenter.HeadPortraitManager.CheckIsNewHeadPortrait(XHeadPortraitConfigs.HeadType.HeadFrame)
    self.BtnTouxiangKuang:ShowReddot(IsShowRed)
end

function XUiPlayerPersonalizedSetting:ShowHeadMedalRedPoint()
    self.BtnXunZhang:ShowReddot(XDataCenter.MedalManager.CheckHaveNewMedalByType(XMedalConfigs.MedalType.Normal))
end

function XUiPlayerPersonalizedSetting:ShowHeadNameplateRedPoint()
    self.BtnMMingPai:ShowReddot(XDataCenter.MedalManager.CkeckHaveNewNameplate())
end

function XUiPlayerPersonalizedSetting:ShowHeadChatBoardRedPoint()
    self.BtnliaoTianKuang:ShowReddot(XDataCenter.ChatManager.CheckHasNewChatBoard())
end
--endregion
function XUiPlayerPersonalizedSetting:Release()
end

function XUiPlayerPersonalizedSetting:OnEnable()
    XDataCenter.UiPcManager.OnUiEnable(self, "OnBtnCancelClick")
end

function XUiPlayerPersonalizedSetting:OnDisable()
    XDataCenter.UiPcManager.OnUiDisableAbandoned(true, self)
end

function XUiPlayerPersonalizedSetting:OnBtnCancelClick()
    self.TempHeadFrameId = XPlayer.CurrHeadFrameId or 0
    self.TempHeadPortraitId = XPlayer.CurrHeadPortraitId or 0
    XEventManager.DispatchEvent(XEventId.EVENT_HEAD_PORTRAIT_RESETINFO)
    XEventManager.RemoveEventListener(XEventId.EVENT_HEAD_PORTRAIT_TIMEOUT, self.TimeOutRefresh, self)
    self:Close()
end

function XUiPlayerPersonalizedSetting:RefreshPreviewPanel()
    self._PanelHeadPortraitSetting:ShowPreviewHeadPortraitInPreviewPanelOnly()
    self._PanelHeadFrameSetting:ShowPreviewHeadFrameInPreviewPanelOnly()
    self._PanelHeadMedalSetting:ShowPreviewHeadMedalInPreviewPanelOnly()
    self._PanelHeadNameplateSetting:ShowPreviewHeadNameplateInPreviewPanelOnly()
    self._PanelChatBoardSetting:ShowPreviewChatBoardInPreviewPanelOnly()
    self:RefreshBaseData()
end

--有些切页按钮开启有条件，通用处理这些按钮
function XUiPlayerPersonalizedSetting:InitBtnWithFunctionOpenCheck(btn, functionId, btnList, index, id)
    if XFunctionManager.DetectionFunction(functionId, false, true) then
        index = index + 1
        table.insert(btnList, btn)
        btn:SetButtonState(CS.UiButtonState.Normal)
        self._BtnIdMapIndex[id] = index
        self._BtnIndexMapId[index] = id
    else
        btn:SetButtonState(CS.UiButtonState.Disable)
        btn.CallBack = function()
            XUiManager.TipError(XFunctionManager.GetFunctionOpenCondition(functionId))
        end
    end
    
    return index
end

--设置名称公会等在设置界面不会变更的预览数据
function XUiPlayerPersonalizedSetting:RefreshBaseData()
    self.TxtName.text = XPlayer.Name
    self:RefreshGuildRankLevel()
    self:RefreshBabelTowerLevel()
end

function XUiPlayerPersonalizedSetting:RefreshBabelTowerLevel()
    local babelTowerScoreTitleCfg = XDataCenter.FubenBabelTowerManager.GetCurBableScoreTitleCfg()

    if XTool.IsTableEmpty(babelTowerScoreTitleCfg) or not XDataCenter.MedalManager.CheckScoreTitleIsShow(XMedalConfigs.MedalType.Babel) then
        self.ImgBabelTowerLv.gameObject:SetActiveEx(false)
        return
    else
        self.ImgBabelTowerLv.gameObject:SetActiveEx(true)
    end
    
    local babelTowerIcon = babelTowerScoreTitleCfg.MedalIcon
    local babelTowerLevel = XDataCenter.FubenBabelTowerManager.GetCurrentActivityMaxScore()

    if babelTowerIcon then
        self.ImgBabelTowerLv:SetRawImage(babelTowerIcon)
        self.TxtBabelTowerLv.text = babelTowerLevel
        self.ImgBabelTowerLv.gameObject:SetActiveEx(true)
    else
        self.ImgBabelTowerLv.gameObject:SetActiveEx(false)
    end

end

function XUiPlayerPersonalizedSetting:RefreshGuildRankLevel()
    local guildName = XDataCenter.GuildManager.GetGuildName()
    if guildName and guildName ~= "" then
        self.TxtNameGuild.gameObject:SetActiveEx(true)
        self.TxtNameGuild.text = string.format("[%s]", guildName)
    else
        self.TxtNameGuild.gameObject:SetActiveEx(false)
    end
end

return XUiPlayerPersonalizedSetting