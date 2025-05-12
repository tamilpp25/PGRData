local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridSubMenuItem = require("XUi/XUiMain/XUiChildItem/XUiGridSubMenuItem")
local XUiMainRightMidSecond = XClass(nil, "XUiMainRightMidSecond")

function XUiMainRightMidSecond:Ctor(rootUi, Ui)
    self.Transform = rootUi.PanelRightMidSecond.gameObject.transform
    XTool.InitUiObject(self)
    self:InitList()

    XRedPointManager.AddRedPointEvent(self.ImgRedTargetSub, self.OnCheckSubMenuRedPoint, self,
    {
        XRedPointConditions.Types.CONDITION_SUBMENU_NEW_NOTICES,
    })
end

function XUiMainRightMidSecond:OnEnable()
    -- 主页相关红点
    self.MainRedId = self:AddRedPointEvent(self.ImgRedTargetMain, self.OnCheckMainRedPoint, self,
    {
        ---- 公会相关 ----
        XRedPointConditions.Types.CONDITION_GUILD_APPLYLIST,
        XRedPointConditions.Types.CONDITION_GUILD_ACTIVEGIFT,
        XRedPointConditions.Types.CONDITION_GUILD_NEWS,
        XRedPointConditions.Types.CONDITION_GUILDBOSS_BOSSHP,
        XRedPointConditions.Types.CONDITION_GUILDBOSS_SCORE,
        ------ 其他 ------
        XRedPointConditions.Types.CONDITION_REGRESSION,
        XRedPointConditions.Types.CONDITION_DORM_RED,
        XRedPointConditions.Types.CONDITION_MAIN_NEWPLAYER_TASK,
        XRedPointConditions.Types.CONDITION_MAIN_TASK
    })

    self:UpdateSubMenuList()
    self:UpdateTime()
    -- 每分钟更新一次日期显示
    self.InfoUpdateTimer = XScheduleManager.ScheduleForever(function()
        self:UpdateTime()
    end, 60 * 1000, XTime.GetServerNowTimestamp() % 60 * 1000)
end

function XUiMainRightMidSecond:OnDisable()
    if self.InfoUpdateTimer then
        XScheduleManager.UnSchedule(self.InfoUpdateTimer)
        self.InfoUpdateTimer = nil
    end

    if self.MainRedId then
        XRedPointManager.RemoveRedPointEvent(self.MainRedId)
        self.MainRedId = nil
    end
end

function XUiMainRightMidSecond:UpdateSubMenuList()
    self.SubMenuList = {}
    local dataList = XDataCenter.NoticeManager.GetMainUiSubMenu() or {}
    if #dataList > 0 then
        for _, v in ipairs(dataList) do
            table.insert(self.SubMenuList, v)
        end
    else
        -- 当未加载成功时显示loading占位符
        self.SubMenuList = { { Id = -1, Title = "Loading", SubTitle = "...", StyleType = 1 } }
    end
end

function XUiMainRightMidSecond:UpdateTime()
    local dayOfWeek = os.date("%A", XTime.GetServerNowTimestamp())
    self.TxtDate.text = os.date("%m/%d", XTime.GetServerNowTimestamp())
    self.TxtWeekday.text = CS.XTextManager.GetText(dayOfWeek)
end

function XUiMainRightMidSecond:InitList()
    self.DynamicTable = XDynamicTableNormal.New(self.ScrollView)
    self.DynamicTable:SetProxy(XUiGridSubMenuItem)
    self.DynamicTable:SetDelegate(self)
end

-- 更新菜单
function XUiMainRightMidSecond:RefreshMenu()
    self.DynamicTable:SetDataSource(self.SubMenuList)
    self.DynamicTable:ReloadDataASync()
end

function XUiMainRightMidSecond:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.SubMenuList[index]
        if not data then
            return
        end
        grid:OnRefresh(data)
    end
end

--更新菜单按钮红点显示
function XUiMainRightMidSecond:OnCheckSubMenuRedPoint(count)
    self.ImgRedTargetSub.gameObject:SetActiveEx(count >= 0)
    self:UpdateSubMenuList()
end

--更新主页按钮红点显示
function XUiMainRightMidSecond:OnCheckMainRedPoint(count)
    self.ImgRedTargetMain.gameObject:SetActiveEx(count >= 0)
end

return XUiMainRightMidSecond