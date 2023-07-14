local XUiPanelLineChapter = require("XUi/XUiNewChar/XUiPanelLineChapter")
local XUiNewCharActivity = XLuaUiManager.Register(XLuaUi, "UiNewCharActivity")

local PageIndex = {
    Main = 1,
    Teaching = 2,
    Profile = 3,
}

local Delay = {
    [PageIndex.Teaching] = 500,
    [PageIndex.Profile] = 350,
}

function XUiNewCharActivity:OnAwake()
    if XLuaUiManager.IsUiLoad("UiNewCharActivity") then
        XLuaUiManager.Remove("UiNewCharActivity")
    end
    self:InitUiView()
    self:InitSceneRoot()
    self.CurrentView = PageIndex.Main
    self.StageGroup = {}
    self.TabBtns = {}
    self.SwitchEffect = {}
    -- self.InitEffect = {}
    -- self.MsgBtnAnimEnable = true
    --XEventManager.AddEventListener(XEventId.EVENT_ON_FESTIVAL_CHANGED, self.RefreshFestivalNodes, self)
    self:UpdateCamera(PageIndex.Main)
end

function XUiNewCharActivity:OnStart(actId)
    -- 进入活动时刷新
    local actTemplate = XFubenNewCharConfig.GetDataById(actId)
    self.ActTemplate = actTemplate
    self.ActId = actId
    -- 初始化prefab组件
    local chapterGo = self.PanelTeaching:LoadPrefab(actTemplate.FubenPrefab)
    self.PanelLineChapter = XUiPanelLineChapter.New(self, chapterGo, actTemplate)

    local now = XTime.GetServerNowTimestamp()
    local _, endTimeSecond = XFunctionManager.GetTimeByTimeId(actTemplate.TimeId)
    if endTimeSecond then
        self.TxtDay.text = XUiHelper.GetTime(endTimeSecond - now, XUiHelper.TimeFormatType.ACTIVITY)
        self:CreateActivityTimer(now, endTimeSecond)
    end
    --self.TxtChapterName.text = actTemplate.Name
    --self.TxtChapter.text = (self.ChapterId >= 10) and self.ChapterId or string.format("0%d", self.ChapterId)
    local itemId = XDataCenter.ItemManager.ItemId
    if self.PanelAsset then
        if not self.AssetPanel then
            self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, itemId.FreeGem, itemId.ActionPoint, itemId.Coin)
        end
    end
end

function XUiNewCharActivity:OnEnable()
    self:PlayAnimation("PanelMainEnable")

    if self.RedPointId then
        XRedPointManager.Check(self.RedPointId)
    end
    
    if self.CurrentView == PageIndex.Teaching then
        self.PanelLineChapter:OnShow(0)
    end
end

function XUiNewCharActivity:OnDestroy()
    self.IsOpenDetails = nil
    self:StopActivityTimer()
    --XEventManager.RemoveEventListener(XEventId.EVENT_ON_FESTIVAL_CHANGED, self.RefreshFestivalNodes, self)
end

function XUiNewCharActivity:InitUiView()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnProfile.CallBack = function() self:OnBtnProfileClick() end
    self.BtnReward.CallBack = function() self:OnBtnRewardClick() end
    self.BtnObtain.CallBack = function() self:OnBtnObtainClick() end
    self.BtnCharDetail.CallBack = function() self:OnBtnCharDetailClick() end
    self.BtnTeaching.CallBack = function() self:OnBtnTeachingClick() end
end

function XUiNewCharActivity:InitSceneRoot()
    local root = self.UiModelGo.transform
    self.CameraFar = {
        root:FindTransform("FarCamera1"),
        root:FindTransform("FarCamera2"),
        root:FindTransform("FarCamera3"),
    }
    self.CameraNear = {
        root:FindTransform("NearCamera1"),
        root:FindTransform("NearCamera2"),
        root:FindTransform("NearCamera3"),
    }
end

function XUiNewCharActivity:UpdateCamera(camera)
    for _, cameraIndex in pairs(PageIndex) do
        self.CameraNear[cameraIndex].gameObject:SetActive(cameraIndex == camera)
        self.CameraFar[cameraIndex].gameObject:SetActive(cameraIndex == camera)
    end
end

function XUiNewCharActivity:OnBtnBackClick()
    if self.CurrentView ~= PageIndex.Main then
        self:SwitchPanelProfile(false)
        self:UpdateCamera(PageIndex.Main)
        if self.CurrentView == PageIndex.Teaching then
            self.PanelLineChapter:OnHide()
        end
        
        self.AnimTimer = XScheduleManager.ScheduleOnce(function()
            self.PanelTeaching.gameObject:SetActiveEx(false)
            self:OnSwitchView()
        end, Delay[self.CurrentView])
        
        self.CurrentView = PageIndex.Main
    else
        self:Close()
    end
end

function XUiNewCharActivity:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiNewCharActivity:OnBtnTeachingClick()
    self.CurrentView = PageIndex.Teaching
    self:OnSwitchView()
    self.PanelTeaching.gameObject:SetActiveEx(true)
    self.PanelLineChapter:OnShow()
    self:UpdateCamera(PageIndex.Teaching)
end

function XUiNewCharActivity:OnBtnProfileClick()
    self.CurrentView = PageIndex.Profile
    self.CurrentMsgIndex = 0
    self:OnSwitchView()
    self:SwitchPanelProfile(true)
    self:UpdateCamera(PageIndex.Profile)
    self:PlayAnimation("MsgEnable")
    self:RefreshProfile()
end

function XUiNewCharActivity:OnBtnRewardClick()
    if XLuaUiManager.IsUiLoad("UiActivityBase") then
        XLuaUiManager.Remove("UiActivityBase")
    end
    -- 活动奖励，点击跳转活动任务界面
    XFunctionManager.SkipInterface(self.ActTemplate.SkipIdAct)
end

function XUiNewCharActivity:OnBtnCharDetailClick()
    -- 打开通用角色信息面板
    XLuaUiManager.Open("UiCharacterDetail", self.ActTemplate.CharacterId)
end

function XUiNewCharActivity:OnBtnObtainClick()
    -- 前往获取，点击跳转主题抽卡界面
    XFunctionManager.SkipInterface(self.ActTemplate.SkipIdDraw)
end

function XUiNewCharActivity:RefreshProfile()
    self.MsgList = XFubenNewCharConfig.GetMsgGroupById(self.ActId)
    for index, v in ipairs(self.MsgList) do
        if not self.TabBtns[index] then
            self.TabBtns[index] = self["BtnMsg"..index]
            -- self.InitEffect[index] = XUiHelper.TryGetComponent(self.TabBtns[index].transform, "Press/Effect", "RectTransform")
            self.SwitchEffect[index] = XUiHelper.TryGetComponent(self.TabBtns[index].transform, "Normal/Effect", "RectTransform")
            self.TabBtns[index]:SetNameByGroup(0, v.Title)
            --解锁条件
            local desc = XConditionManager.GetConditionDescById(v.ConditionId)
            self.TabBtns[index]:SetNameByGroup(1, desc)
            self.TabBtns[index]:SetRawImage(v.BtnBg)
        end

        if v.IsLock then
            local result = XConditionManager.CheckCondition(v.ConditionId)
            --  XUiButtonState.Press 是第二种Normal状态（只在还未选择任何线索时显示）
            self.TabBtns[index]:SetButtonState(result and XUiButtonState.Press or XUiButtonState.Disable)
        end
    end
    self.BtnGrp:Init(self.TabBtns, function(index) self:OnBtnMsg(index) end, 0)
    self.MsgContent.gameObject:SetActiveEx(false)
    self.MsgContentBg.gameObject:SetActiveEx(false)
end

function XUiNewCharActivity:OnBtnMsg(index)
    local btn = self.TabBtns[index]
    if btn.ButtonState == CS.UiButtonState.Disable then
        local desc = XConditionManager.GetConditionDescById(self.MsgList[index].ConditionId)
        XUiManager.TipMsg(desc)
        return
    end

    for i, v in ipairs(self.TabBtns) do
        if v.ButtonState ~= CS.UiButtonState.Disable then
            -- 点击线索后，其他线索变为第一种Normal状态（置为灰色）
            v:SetButtonState(self.CurrentMsgIndex == i and XUiButtonState.Select or XUiButtonState.Normal)
        end
        -- 特效只在切换时显示
        self.SwitchEffect[i].gameObject:SetActive(self.CurrentMsgIndex == i)
        -- self.InitEffect[i].gameObject:SetActive(MsgBtnAnimEnable)
    end

    --if self.MsgBtnAnimEnable then
    --    self.MsgBtnAnimEnable = false
    --end
    if self.CurrentMsgIndex == index then
        -- 点击已选中线索则为取消选中
        self:RefreshProfile()
        self.CurrentMsgIndex = 0
        return
    end

    self.MsgContent.gameObject:SetActiveEx(true)
    self.MsgContentBg.gameObject:SetActiveEx(true)
    -- 将选中的线索层级置为内容区之上，其他层级置为内容区之下
    self.MsgContent:SetSiblingIndex(self.MsgContent.parent.childCount - 1)
    btn.transform:SetSiblingIndex(btn.transform.parent.childCount - 1)
    self.TxtSerial.text = string.format("NO.%d", index)
    self.TxtMsg.text = string.gsub(self.MsgList[index].Content, "\\n", "\n")
    -- 每次查看线索时，文本都从最开头进行显示
    self.MsgScrollRect.verticalNormalizedPosition = 1
    self.CurrentMsgIndex = index
    -- 用于将Press状态的按钮强制转换为Select状态，且需确保其位于判等返回函数之后
    self.BtnGrp:SelectIndex(index, false)
    self:PlayAnimation("MsgContentEnable")
end

function XUiNewCharActivity:OnSwitchView(nextView)
    if self.CurrentView == PageIndex.Main then
        self.PanelMain.gameObject:SetActiveEx(true)
        self:PlayAnimation("PanelMainEnable", function ()
        end)
    else
        self:PlayAnimation("PanelMainDisable", function ()
            self.PanelMain.gameObject:SetActiveEx(false)
        end)
        -- self.MsgBtnAnimEnable = true
    end
end

function XUiNewCharActivity:SwitchPanelProfile(state)
    self.PanelProfile.gameObject:SetActiveEx(state)
    self.PanelProfileBg.gameObject:SetActiveEx(state)
    self.MsgContentBg.gameObject:SetActiveEx(false)
end

function XUiNewCharActivity:ReopenAssetPanel()
    if self.IsOpenDetails then
        return
    end
    if self.AssetPanel then
        self.AssetPanel.GameObject:SetActiveEx(true)
    end
end

-- 背景
function XUiNewCharActivity:SwitchBg(actTemplate)
    if not actTemplate or not actTemplate.MainBackgound then return end
    self.RImgFestivalBg:SetRawImage(actTemplate.MainBackgound)
end

-- 计时器
function XUiNewCharActivity:CreateActivityTimer(startTime, endTime)
    local time = XTime.GetServerNowTimestamp()
    self:StopActivityTimer()
    self.ActivityTimer = XScheduleManager.ScheduleForever(function()
            time = XTime.GetServerNowTimestamp()
            if time > endTime then
                self:Close()
                XUiManager.TipError(CS.XTextManager.GetText("ActivityMainLineEnd"))
                self:StopActivityTimer()
                return
            end
            self.TxtDay.text = XUiHelper.GetTime(endTime - time, XUiHelper.TimeFormatType.ACTIVITY)
        end, XScheduleManager.SECOND, 0)
end

function XUiNewCharActivity:StopActivityTimer()
    if self.ActivityTimer then
        XScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
    if self.AnimTimer then
        XScheduleManager.UnSchedule(self.AnimTimer)
        self.AnimTimer = nil
    end
end

function XUiNewCharActivity:OnCheckBtnGameRedPoint(count)
    self.BtnSkip:ShowReddot(count>=0)
end
