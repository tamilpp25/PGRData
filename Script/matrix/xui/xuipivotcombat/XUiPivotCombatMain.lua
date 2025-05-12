local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")

local XSecondaryButton = XClass(nil, "XSecondaryButton")
--===========================================================================
 ---@desc 次级按钮
--===========================================================================
function XSecondaryButton:Ctor(ui, region)
    self.Region = region
    --头像脚本列表
    self.HeadList = {}
    XTool.InitUiObjectByUi(self, ui)
    self:Init()
end

--===========================================================================
 ---@desc 更新整个按钮显示样式
--===========================================================================
function XSecondaryButton:Refresh(region, isShow)
    if not isShow then
        self.GameObject:SetActiveEx(false)
        self.ImgLineCharge.gameObject:SetActiveEx(false)
        self.ImgLineUnCharge.gameObject:SetActiveEx(false)
        return
    end
    self.Region = region or self.Region
    if not self.Region then
        return
    end
    self.GameObject:SetActiveEx(true)
    local stage = region:GetLockCharacterStage()
    local lockCharIds = stage:GetCharacterList()
    local energyPercent = region:GetPercentEnergy()
    local isOpen, _ = region:IsOpen()
    
    self:RefreshButtonState(self.Region, isOpen)
    self:RefreshHeadIcon(lockCharIds)
    self:RefreshEnergy(energyPercent)
   
end

--===========================================================================
 ---@desc 更新按钮状态
--===========================================================================
function XSecondaryButton:RefreshButtonState(region, isOpen)
    if not region then return end
    local regionName = region:GetRegionName()
    local icon = region:GetIcon()
    local openTime = region:GetRegionOpenTime()

    self:RefreshBtn(regionName, icon, isOpen)
    self:RefreshOpenTime(isOpen, openTime)
end

--===========================================================================
 ---@desc 刷新解锁时间
--===========================================================================
function XSecondaryButton:RefreshOpenTime(isOpen, time)
    if isOpen then return end
    local localTimer = CSXTextManagerGetText("PivotCombatLockTimeTxt", time)
    self.Button:SetNameByGroup(1, localTimer)
end

--===========================================================================
 ---@desc 刷新按钮文本
--===========================================================================
function XSecondaryButton:RefreshBtn(name, icon, isOpen)
    self.Button:SetNameByGroup(0, name)
    self.Button:SetSprite(icon)
    self.Button:SetDisable(not isOpen)
end

--===========================================================================
 ---@desc 刷新锁角色头像
--===========================================================================
function XSecondaryButton:RefreshHeadIcon(characterList)
    characterList = characterList or {}
    self.HeadList = XDataCenter.PivotCombatManager.RefreshHeadIcon(characterList, self.HeadList, self.HeadUiList)
end

--===========================================================================
 ---@desc 刷新能量
--===========================================================================
function XSecondaryButton:RefreshEnergy(energyPercent)
    energyPercent = XMath.Clamp(energyPercent, 0, 1)
    self.ImgProgress.fillAmount = energyPercent
    self.ImgProgressPress.fillAmount = energyPercent
    local isChange = energyPercent > 0
    self.ImgLineCharge.gameObject:SetActiveEx(isChange)
    self.ImgLineUnCharge.gameObject:SetActiveEx( not isChange)
end

function XSecondaryButton:OnClickBtnSecondary()
    if not self.Region then
        XLog.Error("XSecondaryButton:OnClickSecondaryRegion Error: Not Region ")
        return
    end

    local isOpen, desc = self.Region:IsOpen()
    if not isOpen then
        XUiManager.TipMsg(desc)
        return
    end
    XDataCenter.PivotCombatManager.OnEnterRegion(self.Region)
end

function XSecondaryButton:OnCheckRedPoint(count)
    self.Button:ShowReddot(count >= 0)
end

function XSecondaryButton:Init()
    self.Button = self.Transform:GetComponent("XUiButton")
    
    --头像UI控件列表
    self.HeadUiList = { self.Head01, self.Head02, self.Head03,}

    self.Button.CallBack = function()
        self:OnClickBtnSecondary()
    end
    
    --注册红点
    self.RedPointId = XRedPointManager.AddRedPointEvent(self.Button, self.OnCheckRedPoint, self, {
        XRedPointConditions.Types.CONDITION_PIVOTCOMBAT_NEW_AREA_OPEN_RED_POINT,
    })
end

function XSecondaryButton:CheckRedPoint()
    XRedPointManager.Check(self.RedPointId, self.Region:GetRegionId())
end


--===========================================================================
 ---@desc 枢纽作战主界面
--===========================================================================
local XUiPivotCombatMain = XLuaUiManager.Register(XLuaUi, "UiPivotCombatMain")

local MAX_SECONDARY_MEMBERS = 5 --次级区域按钮数量
local TIME_REFRESH_MINUTE = XScheduleManager.SECOND * 60 --一分钟刷新一次

--region 生命周期

function XUiPivotCombatMain:OnAwake()
    self:InitUI()
    self:InitCB()
end

function XUiPivotCombatMain:OnStart()
    --次级区域按钮
    self.SecondaryButtons   = {}
    --次级区域
    self.SecondaryRegions   = XDataCenter.PivotCombatManager.GetSecondaryRegions()
    --中心区域
    self.CenterRegion       = XDataCenter.PivotCombatManager.GetCenterRegion()
    --初始化资产
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.PivotCombatManager.GetActivityCoinId())
    --初始化标题
    self.TxtTitle.text = XDataCenter.PivotCombatManager.GetActivityName()
    --注册红点
    self.TargetRedPoint = XRedPointManager.AddRedPointEvent(self.BtnTarget, self.OnCheckTargetRedDot, self, {
        XRedPointConditions.Types.CONDITION_PIVOTCOMBAT_TASK_REWARD_RED_POINT,
    })
    --次级区域的按钮
    for idx = 1, MAX_SECONDARY_MEMBERS do
        local btn = self.SecondaryButtons[idx]
        if not btn then
            btn = XSecondaryButton.New(self["BtnRegion"..idx])
            self.SecondaryButtons[idx] = btn
        end
        btn:Refresh(nil, false)
    end
    --中心区域图标
    self.BtnCenter:SetSprite(self.CenterRegion:GetIcon())

    local timeOfEnd = XDataCenter.PivotCombatManager.GetActivityEndTime()
    self:SetAutoCloseInfo(timeOfEnd, function(isClose)
        if isClose then
            XDataCenter.PivotCombatManager.OnActivityEnd()
        end
        XDataCenter.PivotCombatManager.CheckNeedClose()
    end)
end

function XUiPivotCombatMain:OnEnable()
    XUiPivotCombatMain.Super.OnEnable(self)
    --活动剩余时间
    self.TxtTitleDate.text  = XDataCenter.PivotCombatManager.GetActivityLeftTime()
    --中心区域分数
    self.TxtNum.text        = XDataCenter.PivotCombatManager.GetMaxScore()
    --刷新次级区域按钮状态
    self:RefreshCenterBtn()
    --刷新中心区域状态
    local isOpenCenter, _ = self.CenterRegion:IsOpen()
    self.BtnCenter:SetDisable(not isOpenCenter)
    self.CenterEffectShine.gameObject:SetActiveEx(false)
    --播放进入动画
    self:PlayAnimation("AnimStart", function()
        self.CenterEffectShine.gameObject:SetActiveEx(isOpenCenter)
    end)
    --未完全解锁次级区域
    if not XDataCenter.PivotCombatManager.IsAllSecondaryOpen() then
        --更新解锁时间
        self:RefreshTimer()
        self.LockTimeSchedule = XScheduleManager.ScheduleForever(function()
            self:RefreshTimer()
        end, TIME_REFRESH_MINUTE)
    end
    --检测红点
    self:CheckRedPoint()
end

function XUiPivotCombatMain:OnDisable()
    --界面关闭时让UIMove动画重置
    if self.UiMoveTimeLine then
        self.UiMoveTimeLine:Stop(true)
    end
    if self.LockTimeSchedule then
        XScheduleManager.UnSchedule(self.LockTimeSchedule)
        self.LockTimeSchedule = nil
    end
end


--endregion

--region 红点检测

--检测奖励红点
function XUiPivotCombatMain:CheckTargetRedDot()
    XRedPointManager.Check(self.TargetRedPoint)
end

--检测次级区域红点
function XUiPivotCombatMain:CheckRegionRedPoint()
    local regions = self.SecondaryRegions
    for _, region in ipairs(regions) do
        local index = region:GetSecondaryRegionIndex()
        local btn = self.SecondaryButtons[index]
        if btn then
            btn:CheckRedPoint()
        end
    end
end

--检测所有红点
function XUiPivotCombatMain:CheckRedPoint()
    self:CheckRegionRedPoint()
    self:CheckTargetRedDot()
end

--endregion

--更新时间显示
function XUiPivotCombatMain:RefreshTimer()
    if XDataCenter.PivotCombatManager.IsAllSecondaryOpen() then
        if self.LockTimeSchedule then
            XScheduleManager.UnSchedule(self.LockTimeSchedule)
        end
        self.LockTimeSchedule = nil
        return
    end
    local regions = self.SecondaryRegions
    for _, region in ipairs(regions) do
        local index = region:GetSecondaryRegionIndex()
        local isOpen, _ = region:IsOpen()
        local btn = self.SecondaryButtons[index]
        if not isOpen and btn then
            btn:RefreshButtonState(region, isOpen)
        end
    end
end

--刷新次级区域按钮
function XUiPivotCombatMain:RefreshCenterBtn()
    --更新按钮显示状态
    local regions = self.SecondaryRegions
    for _, region in ipairs(regions) do
        local index = region:GetSecondaryRegionIndex()
        local btn = self.SecondaryButtons[index]
        if not btn then
            btn = XSecondaryButton.New(self["BtnRegion"..index], region)
            self.SecondaryButtons[index] = btn
        end
        btn:Refresh(region, true)
    end
end

function XUiPivotCombatMain:OnGetEvents()
    return { 
        XEventId.EVENT_ACTIVITY_ON_RESET, 
        XEventId.EVENT_PIVOTCOMBAT_ACTIVITY_END, 
        XEventId.EVENT_PIVOTCOMBAT_GET_TASK_REWARD
    }
end

function XUiPivotCombatMain:OnNotify(evt, ...)
    local args = { ... }
    --通用处理事件
    XDataCenter.PivotCombatManager.OnNotify(evt, args)
    if evt == XEventId.EVENT_PIVOTCOMBAT_GET_TASK_REWARD then
        self:CheckTargetRedDot()
    end
end

--region 初始化

function XUiPivotCombatMain:InitUI()
    self.CenterEffectShine = self.BtnCenter.transform:Find("EffectShine")
    
    self.UiMove = self.Transform:Find("Animation/UiMove"):GetComponent("PlayableDirector")
    
    
end

function XUiPivotCombatMain:InitCB()
    self:BindHelpBtn(self.BtnHelp, "PivotCombatHelp")
    self.BtnBack.CallBack = function() 
        self:Close() 
    end
    self.BtnMainUi.CallBack = function() 
        XLuaUiManager.RunMain() 
    end
    self.BtnTarget.CallBack = function() 
        self:OnClickBtnTarget()
    end
    self.BtnEffect.CallBack = function()
        self:OnClickBtnEffect()
    end
    self.BtnRank.CallBack = function()
        self:OnClickBtnRank()
    end
    self.BtnShop.CallBack = function()
        self:OnClickBtnShop()
    end
    self.BtnCenter.CallBack = function()
        self:OnClickBtnCenter()
    end
    self.BtnTeaching.CallBack = function()
        XDataCenter.PracticeManager.OpenUiFubenPratice(XPracticeConfigs.CharacterTabIndex.Isomer)
    end
end

--点击奖励任务
function XUiPivotCombatMain:OnClickBtnTarget()
    --XLuaUiManager.Open("UiPivotCombatTask")
    self:OpenChildUi("UiPivotCombatTask")
end

--点击供能效果
function XUiPivotCombatMain:OnClickBtnEffect()
    self:OpenChildUi("UiPivotCombatEffect")
end

--点击排行榜
function XUiPivotCombatMain:OnClickBtnRank()
    XLuaUiManager.Open("UiPivotCombatRankingList")
end

--商店
function XUiPivotCombatMain:OnClickBtnShop()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon)
            or XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopActive) then
        XLuaUiManager.Open("UiShop", XDataCenter.PivotCombatManager.GetActivityShopType())
    end
    
end

--点击中心区域
function XUiPivotCombatMain:OnClickBtnCenter()
    local isOpen, desc = self.CenterRegion:IsOpen()
    if not isOpen then
        XUiManager.TipMsg(desc)
        return
    end
    self:PlayAnimation("UiMove", function()
        if not self.UiMoveTimeLine then
            self.UiMoveTimeLine = self.UiMove.transform:GetComponent("XUiPlayTimelineAnimation")
        end
        self:OpenChildUi(
                "UiPivotCombatNormalDetail", self.CenterRegion:GetCenterStage(), handler(self, self.OnPlayUiBack))
    end)
end

function XUiPivotCombatMain:OnPlayUiBack()
    self:PlayAnimation("UiBack", function()
        self:RefreshCenterBtn()
    end)
end

--检测奖励是否显示红点
function XUiPivotCombatMain:OnCheckTargetRedDot(count)
    self.BtnTarget:ShowReddot(count >= 0)
end

--endregion