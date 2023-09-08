---@desc 提示类型
---@field YK number 月卡提示
---@field Gift number 礼包提示
local TipsType = {
    YK = 1,
    Gift = 2,
    DormTerminal = 3, -- 宿舍终端提示
}

local XUiGridTip = XClass(nil, "XUiGridTip")

function XUiGridTip:Ctor(ui, clickCb)
    XTool.InitUiObjectByUi(self, ui)
    self.ClickCb = clickCb
    
    self.BtnTip.CallBack = function() self:OnClick() end
end

function XUiGridTip:Refresh(data)
    self.Data = data
    self.TxtTips.text = data.Tips
end

function XUiGridTip:OnClick()
    if self.Data.Config.Id == XEnumConst.Ui_MAIN.TerminalTipType.ExpensiveItem then
        XMVCA.XUiMain:RecordPanelTipClicked(self.Data.Config.Id)
    end
    if self.ClickCb then self.ClickCb(self.Data.Config.SkipId) end
end

--=========================================类分界线=========================================--
--主界面会频繁打开，采用常量缓存
local RedPointConditionGroup = {
    Week = {
        XRedPointConditions.Types.CONDITION_MAIN_WEEK
    },
    Friend = {
        XRedPointConditions.Types.CONDITION_MAIN_FRIEND
    },
    Set = {
        XRedPointConditions.Types.CONDITION_MAIN_SET
    },
    Screen={
        XRedPointConditions.Types.CONDITION_SCENE_SETTING
    }
}

local XUiMainPanelBase = require("XUi/XUiMain/XUiMainPanelBase")

---@class XUiMainTerminal 终端界面类
---@field uiMain XUiMain 主界面引用
local XUiMainTerminal = XClass(XUiMainPanelBase, "XUiMainTerminal")

-- 一分钟
local Minute = XScheduleManager.SECOND * 60
-- Unity Time
local CsTime = CS.UnityEngine.Time
-- 音乐图标 旋转速度
local RotateSpeed = CS.XGame.ClientConfig:GetFloat("MusicPlayerIconRotateSpeed")
-- 音乐名滚动速度
local SubtitleSpeed = CS.XGame.ClientConfig:GetFloat("MusicPlayerTextScrollSpeed")

local CsVector3 = CS.UnityEngine.Vector3

function XUiMainTerminal:OnStart(uiMain)
    self.UiMain = uiMain
    -- XTool.InitUiObjectByUi(self, self.UiMain.PanelRightMidSecond)
    self.GridTips = {}
    self:InitUi()
    self:InitCb()
end

function XUiMainTerminal:OnEnable(uiMain)
    XEventManager.AddEventListener(XEventId.EVENT_SIGN_IN_FIVE_OCLOCK_REFRESH, self.RefreshGridTips, self)
    self:Show()
end

function XUiMainTerminal:Show()
    --时间刷新
    self:RefreshTime()
    if not self.TimerId then
        self.TimerId = XScheduleManager.ScheduleForever(function()
            self:RefreshTime()
        end, Minute)
    end
    
    --刷新播放器
    self:RefreshMusicPlayer()
    --刷新子菜单
    self:RefreshSubMenu()
    --刷新提示栏
    self:RefreshGridTips()
    
    
    --Update Timer
    if not self.UpdateTimer then
        self.UpdateTimer = XScheduleManager.ScheduleForever(function()
            self:Update()
        end, 0, XScheduleManager.SECOND)
    end

    --改变状态-触发红点检查
    XEventManager.DispatchEvent(XEventId.EVENT_MAINUI_TERMINAL_STATUS_CHANGE)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_MAINUI_TERMINAL_STATUS_CHANGE)
    XRedPointManager.Check(self.ScreenPointId)
    XDataCenter.UiPcManager.OnUiEnable(self, "OnBtnTanchuangCloseBig")
end

function XUiMainTerminal:Update()
    if not self.GameObject.activeInHierarchy then
        return
    end
    
    if self.NeedScroll then
        self:OnScrollTxtName(self.PanelAuthorName, self.OriginPos, self.ContentWidth, self.MaskWidth)
    end

    self:OnRotateMusicIcon()
end

function XUiMainTerminal:OnDisable()
    if self.TimerId then
        XScheduleManager.UnSchedule(self.TimerId)
        self.TimerId = nil
    end

    if self.UpdateTimer then
        XScheduleManager.UnSchedule(self.UpdateTimer)
        self.UpdateTimer = nil
    end
    --改变状态-触发红点检查
    XEventManager.DispatchEvent(XEventId.EVENT_MAINUI_TERMINAL_STATUS_CHANGE)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_MAINUI_TERMINAL_STATUS_CHANGE)
    XDataCenter.UiPcManager.OnUiDisableAbandoned(true, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SIGN_IN_FIVE_OCLOCK_REFRESH, self.RefreshGridTips, self)
end

function XUiMainTerminal:OnRelease()
    self:RemoveItemListener()
end

function XUiMainTerminal:InitCb()
    --界面关闭
    self.BtnTanchuangCloseBig.CallBack = function()
        self:OnBtnTanchuangCloseBig()
    end
    --音乐播放
    self.BtnMusicPlayer.CallBack = function() 
        self:OnBtnMusicPlayerClick()
    end
    --活动日历
    self.BtnWeek.CallBack = function() 
        self:OnBtnWeekClick()
    end
    --场景切换
    self.BtnScreen.CallBack=function()
        XDataCenter.PhotographManager.OpenUiSceneSetting()
    end
    --拍照分享
    self.BtnScreenShot.CallBack = function() 
        self:OnBtnScreenShotClick()
    end
    --好友/社交
    self.BtnSocial.CallBack = function() 
        self:OnBtnSocialClick() 
    end
    --系统设置
    self.BtnSet.CallBack = function() 
        self.OnBtnSetClick()
    end
end

function XUiMainTerminal:InitUi()
    self.OriginPos = self.PanelAuthorName.transform.localPosition

    self.GridTip.gameObject:SetActiveEx(false)
    
    --子菜单动态列表
    self.DynamicTable = XDynamicTableNormal.New(self.ScrollView)
    self.DynamicTable:SetProxy(require("XUi/XUiMain/XUiChildItem/XUiGridSubMenuItem"))
    self.DynamicTable:SetDelegate(self)

    --按钮筛选显示
    self.BtnWeek.gameObject:SetActiveEx(XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.ActivityCalendar) and not XUiManager.IsHideFunc)
    self.BtnScreenShot.gameObject:SetActiveEx(not XUiManager.IsHideFunc)
    self.BtnSocial.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.SocialFriend) and not XUiManager.IsHideFunc)
    self.BtnSet.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Setting))
    
    --红点注册
    --self.WeekPointId = self:AddRedPointEvent(self.BtnWeek, self.CheckBtnWeekRedPoint, self, RedPointConditionGroup.Week)
    self:AddRedPointEvent(self.BtnSocial.ReddotObj, self.CheckBtnSocialRedPoind, self, RedPointConditionGroup.Friend)
    self:AddRedPointEvent(self.BtnSet, self.CheckBtnSetRedPoint, self, RedPointConditionGroup.Set)

    self.ScreenPointId=self:AddRedPointEvent(self.BtnScreen,self.CheckBtnScreenRedPoint,self,RedPointConditionGroup.Screen)
end

function XUiMainTerminal:RefreshTime()
    local timeOfNow = XTime.GetServerNowTimestamp()
    local dayOfWeek = os.date("%A", timeOfNow)
    self.TxtDate.text = os.date("%m/%d", timeOfNow)
    self.TxtWeekday.text = CS.XTextManager.GetText(dayOfWeek)
    self.BtnWeek:SetNameByGroup(0, os.date("%d", timeOfNow))
    self.BtnWeek:SetNameByGroup(1, os.date("%a", timeOfNow))
    self.TxtTime.text = XTime.TimestampToGameDateTimeString(timeOfNow, "HH:mm")
end

function XUiMainTerminal:RefreshMusicPlayer()
    if XUiManager.IsHideFunc then
        self.BtnMusicPlayer.gameObject:SetActiveEx(false)
    end
    
    local albumId = XDataCenter.MusicPlayerManager.GetUiMainNeedPlayedAlbumId()
    local template = XMusicPlayerConfigs.GetAlbumTemplateById(albumId)
    if not template then
        return
    end
    self.TxtMusicName.text  = string.gsub(XUiHelper.ReplaceTextNewLine(template.Name), "\n", "")
    self.TxtAuthorName.text = string.gsub(XUiHelper.ReplaceTextNewLine(template.Composer), "\n", "")
    self.RImgMusicIcon:SetRawImage(template.Cover)
    self.RImgMusicBg:SetRawImage(template.Bg)

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelAuthorName)
    self.ContentWidth   = self.PanelAuthorName.sizeDelta.x
    self.MaskWidth      = self.PanelMusicName.sizeDelta.x

    self.NeedScroll = self.ContentWidth > self.MaskWidth
    self.PanelAuthorName.transform.localPosition = self.OriginPos
end

--音乐选择界面关闭回调
function XUiMainTerminal:OnMusicPlayerClose()
    self:RefreshMusicPlayer()
end

function XUiMainTerminal:RefreshSubMenu()
    local dataList = self:GetSubMenuList()
    if XTool.IsTableEmpty(dataList) then
        self.SubMenuList = {
            { Id = -1, Title = "Loading", SubTitle = "...", StyleType = XUiConfigs.SubMenuDefaultStyleType }
        }
    else
        self.SubMenuList = dataList
    end
    self.DynamicTable:SetDataSource(self.SubMenuList)
    self.DynamicTable:ReloadDataASync()
end

function XUiMainTerminal:GetSubMenuList()
    local func = function(list, subType)
        local newList = {}
        for _, item in ipairs(list or {}) do
            item = XTool.Clone(item)
            item.SubMenuType = subType
            table.insert(newList, item)
        end
        return newList
    end
    --系统相关按钮
    local systemList = func(XUiConfigs.GetSystemSubMenuList(), XUiConfigs.SubMenuType.System)
    --运营相关按钮
    local operateList = func(XDataCenter.NoticeManager.GetMainUiSubMenu(), XUiConfigs.SubMenuType.Operate)
    
    return appendArray(systemList, operateList)
end
 
function XUiMainTerminal:RefreshGridTips()
    local tips = XMVCA.XUiMain:GetScrollTipList(true)
    for idx, value in ipairs(tips) do
        local grid = self.GridTips[idx]
        if not grid then
            local ui = idx == 1 and self.GridTip or XUiHelper.Instantiate(self.GridTip, self.PanelMobileList)
            grid = XUiGridTip.New(ui, handler(self, self.OnGridTipClick))
            self.GridTips[idx] = grid
        end
        grid:Refresh(value)
    end

    local tipCount = #tips
    for idx, grid in ipairs(self.GridTips) do
        grid.GameObject:SetActiveEx(idx <= tipCount)
    end
    local childCount = self.PanelMobileList.childCount
    self.ScrollView.transform:SetSiblingIndex(childCount - 1)
end

function XUiMainTerminal:AddItemListener(itemId)
    XDataCenter.ItemManager.AddCountUpdateListener(itemId, function()
        self:RefreshGridTips()
        XEventManager.DispatchEvent(XEventId.EVENT_MAINUI_EXPENSIVE_ITEM_CHANGE)
    end, self)
end

function XUiMainTerminal:RemoveItemListener()
    XDataCenter.ItemManager.RemoveCountUpdateListener(self)
end

--region   ------------------界面事件 start-------------------

--界面关闭
function XUiMainTerminal:OnBtnTanchuangCloseBig()
    if self.UiMain.OnShowMain then
        self.UiMain:OnShowMain(true)
    end
    self:OnDisable()
end

--音乐播放器
function XUiMainTerminal:OnBtnMusicPlayerClick()
    if not XMVCA.XSubPackage:CheckSubpackage() then
        return
    end
    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnMusicPlayer)
    XLuaUiManager.Open("UiMusicPlayer", handler(self, self.OnMusicPlayerClose))
end

--活动日历
function XUiMainTerminal:OnBtnWeekClick()
    XDataCenter.ActivityCalendarManager.SaveWeekClick()
    if self.WeekPointId then
        XRedPointManager.Check(self.WeekPointId)
    end
    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnWeek)
    XLuaUiManager.Open("UiWeekCalendar")
end

--拍照分享
function XUiMainTerminal:OnBtnScreenShotClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Photograph) then
        return
    end

    if not XMVCA.XSubPackage:CheckSubpackage() then
        return
    end
    
    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnScreenShot)
    XLuaUiManager.Open("UiPhotograph")
end

--好友/社交
function XUiMainTerminal:OnBtnSocialClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SocialFriend) then
        return
    end
    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnSocial)
    XLuaUiManager.Open("UiSocial")
end

--系统设置
function XUiMainTerminal:OnBtnSetClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Setting) then
        return
    end
    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnSet)
    XLuaUiManager.Open("UiSet", false)
end

--歌名滚动
function XUiMainTerminal:OnScrollTxtName(transform, originPos, width, contentWidth)
    transform:Translate(CsVector3.left * CsTime.deltaTime * SubtitleSpeed)
    local pos = transform.localPosition
    local distance = math.abs(pos.x - originPos.x)
    if distance > width then
        pos.x = originPos.x + contentWidth
        pos.y = 0
        pos.z = 0
        transform.localPosition = pos
    end
end

--歌曲Icon旋转
function XUiMainTerminal:OnRotateMusicIcon()
    self.RImgMusicIcon.transform:Rotate(0, 0, CsTime.deltaTime * RotateSpeed);
end

function XUiMainTerminal:OnGridTipClick(SkipId)
    XFunctionManager.SkipInterface(SkipId)
    -- if tipType == XEnumConst.Ui_MAIN.TerminalTipType.MonthlyCard then
    --     XDataCenter.PurchaseManager.SetYKContinueBuy()
    --     XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.YK)
    -- elseif tipType == XEnumConst.Ui_MAIN.TerminalTipType.Gift then
    --     XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.LB)
    -- elseif tipType == XEnumConst.Ui_MAIN.TerminalTipType.Dorm then
    --     XHomeDormManager.EnterDorm(XPlayer.Id, nil, false, function()
    --         XLuaUiManager.Open("UiDormTerminalSystem")
    --     end)
    -- end
    XEventManager.DispatchEvent(XEventId.EVENT_MAINUI_TERMINAL_STATUS_CHANGE)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_MAINUI_TERMINAL_STATUS_CHANGE)
end

function XUiMainTerminal:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.SubMenuList[index]
        if not data then
            return
        end
        grid:OnRefresh(data)
    end
end
--endregion------------------界面事件 finish------------------

--region   ------------------红点检查 start-------------------
function XUiMainTerminal:CheckBtnWeekRedPoint(count)
    self.BtnWeek:ShowReddot(count >= 0 and XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.ActivityCalendar))
end

function XUiMainTerminal:CheckBtnSocialRedPoind(count)
    self.BtnSocial:ShowReddot(count >= 0 and XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.SocialFriend))
end

function XUiMainTerminal:CheckBtnSetRedPoint(count)
    self.BtnSet:ShowReddot(count >= 0)
end

function XUiMainTerminal:CheckBtnScreenRedPoint(count)
    self.BtnScreen:ShowReddot(count>=0)
end
--endregion------------------红点检查 finish------------------

return XUiMainTerminal