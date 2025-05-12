local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiDormWork = XLuaUiManager.Register(XLuaUi, "UiDormWork")
local XUiDormWorkListItem = require("XUi/XUiDormWork/XUiDormWorkListItem")
local XUiDormWorkMember = require("XUi/XUiDormWork/XUiDormWorkMember")
local DormWorkMaxCount = 0
local Next = next
local RowMax = 3
local TextManager = CS.XTextManager
local MathFmod = math.fmod

function XUiDormWork:OnAwake()
    self.TimerWorkDic = {}
    self.DaiGongDataCache = {}
    XTool.InitUiObject(self)
    self:InitMaxCount()
    self:InitUI()
    self:InitList()
end

function XUiDormWork:InitMaxCount()
    DormWorkMaxCount = 0
    local cfgWork = XDormConfig.GetDormCharacterWorkData() or {}
    local count = XDataCenter.DormManager.GetDormitoryCount()
    local index = count
    local temple = #cfgWork
    self.IsFullWorkPos = false --是否所有工位都开了
    if count > temple then
        index = temple
        self.IsFullWorkPos = true
    end

    local totalcount = XDormConfig.GetTotalDormitortCountCfg()
    self.IsLastSecond = count + 1 == totalcount -- 倒数第二个
    self.CurWorkIndex = index
    local data = XDormConfig.GetDormCharacterWorkById(index)
    local finishcfg = XDormConfig.GetDormCharacterWorkById(totalcount) or {}
    self.LastDormSeatCount = finishcfg.Seat or 0
    if data then
        DormWorkMaxCount = data.Seat or 0
    end
end

function XUiDormWork:InitList()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemCommon.gameObject)
    self.DynamicTable:SetProxy(XUiDormWorkListItem)
    self.DynamicTable:SetDelegate(self)
end

-- [监听动态列表事件]
function XUiDormWork:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ListData[index]
        local i = (index - 1) * RowMax + 1
        grid:OnRefresh(data, i)
    end
end

-- 从上到下从左到右排序。每一列最多排3个，排满DormWorkMaxCount为止。
function XUiDormWork:SetListData()
    local data = XDataCenter.DormManager.GetDormWorkData()
    if Next(data) == nil then--所有工位都是空的,自己填充数据
        self.CurWorkCount = 0
        local havecount = XDataCenter.DormManager.GetDormitoryCount()
        if havecount > self.LastDormSeatCount then
            havecount = self.LastDormSeatCount
        end
        for _ = 1, havecount do
            table.insert(data, XDormConfig.WorkPosState.Empty)
        end

        self.ListData = self:GetListMemberListDatas(data)

        if self.WorkTimer then
            XScheduleManager.UnSchedule(self.WorkTimer)
            self.WorkTimer = nil
        end
    else
        self.ListData = self:GetListMemberListDatas(data)
        if not self.WorkTimer then
            self.WorkTimer = XScheduleManager.ScheduleForever(self.UpdateWorkTimerCb, 1000)
        end
    end
    
    self.DynamicTable:SetDataSource(self.ListData)
    self.DynamicTable:ReloadDataASync(1)
    self.RefreshTime = XDataCenter.DormManager.GetDormWorkRefreshTime()
    self.TextCount.text = TextManager.GetText("DormWorkRefreshTime", XTime.TimestampToGameDateTimeString(self.RefreshTime, "HH:mm"))
    self.TxtWorkCount.text = CS.XTextManager.GetText("DormWorkCount", self.CurWorkCount, DormWorkMaxCount)
end

function XUiDormWork:UpdateWorkList()
    local data = XDataCenter.DormManager.GetDormWorkData()
    self.ListData = self:GetListMemberListDatas(data)
    for index, itemData in pairs(self.ListData) do
        local item = self.DynamicTable:GetGridByIndex(index)
        local i = (index - 1) * RowMax + 1
        if item then
            item:OnRefresh(itemData, i)
        end
    end
    if not self.WorkTimer then
        self.WorkTimer = XScheduleManager.ScheduleForever(self.UpdateWorkTimerCb, 1000)
    end

    self.TxtWorkCount.text = CS.XTextManager.GetText("DormWorkCount", self.CurWorkCount, DormWorkMaxCount)
end

function XUiDormWork:UpdateDaiGong()
    self:UpdateWorkList()
    self:CloseChildUi("UiDormFoundryDetail")
end

-- 通知打工刷新时间
function XUiDormWork:DormWorkRefresh()
    local WorkRefreshTime = XDataCenter.DormManager.GetDormWorkRefreshTime()
    local t = (WorkRefreshTime - XTime.GetServerNowTimestamp()) * 1000
    if t <= 0 or XDataCenter.DormManager.NotifyDormWorkRefreshFlag == true then
        XDataCenter.DormManager.NotifyDormWorkRefreshFlag = false
        self:DormWorkRefreshReq()
    else
        self.DormWorkTimer = XScheduleManager.ScheduleOnce(self.DormWorkRefreshReqCb, t)
    end
end

-- 更新打工倒计时
function XUiDormWork:UpdateWorkTimer()
    for _, v in pairs(self.TimerWorkDic) do
        if v then
            v()
        end
    end
end

function XUiDormWork:RegisterWorkTimer(cb, index)
    if not cb or not index then
        return
    end

    self.TimerWorkDic[index] = cb
end

function XUiDormWork:RemoveWorkTimer(index)
    self.TimerWorkDic[index] = nil
end

function XUiDormWork:DormWorkRefreshReq()
    if self.DormWorkTimer ~= nil then
        XScheduleManager.UnSchedule(self.DormWorkTimer)
        self.DormWorkTimer = nil
    end
    self.CurWorkCount = 0
    local data = {}
    for _, itemDatas in pairs(self.ListData) do
        local d = {}
        for _, itemData in pairs(itemDatas) do
            if itemData ~= XDormConfig.WorkPosState.Empty and itemData ~= XDormConfig.WorkPosState.Lock then
                if itemData.WorkEndTime and itemData.WorkEndTime == 0 then
                    table.insert(d, XDormConfig.WorkPosState.Empty)
                else
                    self.CurWorkCount = self.CurWorkCount + 1
                    table.insert(d, itemData)
                end
            else
                table.insert(d, itemData)
            end
        end
        if Next(d) then
            table.insert(data, d)
        else
            table.insert(data, itemDatas)
        end
    end

    self.TxtWorkCount.text = CS.XTextManager.GetText("DormWorkCount", self.CurWorkCount, DormWorkMaxCount)
    self.ListData = data
    for index, itemData in pairs(self.ListData) do
        local item = self.DynamicTable:GetGridByIndex(index)
        if item then
            local i = (index - 1) * RowMax + 1
            item:OnRefresh(itemData, i)
        end
    end
    XDataCenter.DormManager.ResetDormWorkPos()
end

function XUiDormWork:GetListMemberListDatas(data)
    self:FillListData(data)
    local listitems = {}
    local itemdatas = {}
    local count = 0

    for index, v in pairs(data) do
        local mod = MathFmod(index, RowMax)
        table.insert(itemdatas, v)
        if mod == 0 then
            table.insert(listitems, itemdatas)
            itemdatas = {}
        end
        if v ~= XDormConfig.WorkPosState.Lock and v ~= XDormConfig.WorkPosState.Empty then
            count = count + 1
        end
    end

    if Next(itemdatas) ~= nil then
        table.insert(listitems, itemdatas)
    end
    self.CurWorkCount = count
    return listitems
end

-- 填充数据
function XUiDormWork:FillListData(listitems)
    -- 填空工位
    local totallen = #listitems
    if DormWorkMaxCount > totallen then
        local rowcount = DormWorkMaxCount - totallen
        for _ = 1, rowcount do
            table.insert(listitems, XDormConfig.WorkPosState.Empty)
        end
    end

    -- 填充lock数据
    if self.IsFullWorkPos then
        return
    end

    local lockcount = RowMax -- 正常填3个
    local residue = MathFmod(DormWorkMaxCount, RowMax)
    if residue > 0 then
        lockcount = RowMax + (RowMax - residue)
    end

    if self.IsLastSecond then -- 倒数第二个填与最后一个的差值
        local cfg = XDormConfig.GetDormCharacterWorkById(self.CurWorkIndex + 1)
        if cfg then
            lockcount = cfg.Seat - DormWorkMaxCount
        else
            lockcount = 0
        end
    else
        local cfg = XDormConfig.GetDormCharacterWorkById(self.CurWorkIndex + 1)
        if not cfg then
            lockcount = 0
        end
    end
    if DormWorkMaxCount + lockcount > self.LastDormSeatCount then
        lockcount = self.LastDormSeatCount - DormWorkMaxCount
    end
    for _ = 1, lockcount do
        table.insert(listitems, XDormConfig.WorkPosState.Lock)
    end
end

-- 打开人员列表
function XUiDormWork:OpenMemeberList()
    self.PanelMember.gameObject:SetActive(true)
    if not self.InitMember then
        self.InitMember = true
        self.MemberUI = XUiDormWorkMember.New(self.PanelMember, self)
    end
    self.MemberUI:OnEnable()
    self.MemberUI:OnRefresh(self.CurWorkCount)
end

function XUiDormWork:OnStart()
    self:SetListData()
end

function XUiDormWork:OnEnable()
    self:DormWorkRefresh()
    if self.MemberUI then
        self.MemberUI:OnRefresh(self.CurWorkCount)
    end
    XEventManager.AddEventListener(XEventId.EVENT_DORM_WORK_RESET, self.DormWorkRefreshReq, self)
    XEventManager.AddEventListener(XEventId.EVENT_DORM_DAI_GONE_REWARD, self.UpdateDaiGong, self)
    -- XEventManager.AddEventListener(XEventId.EVENT_DORM_SKIP, self.SkipFun, self)
end

-- function XUiDormWork:SkipFun()
--     -- XLuaUiManager.Close("UiSkip")
--     -- XLuaUiManager.Close("UiTip")
-- end
function XUiDormWork:OnDisable()
    if self.DormWorkTimer then
        XScheduleManager.UnSchedule(self.DormWorkTimer)
        self.DormWorkTimer = nil
    end
    if self.WorkTimer then
        XScheduleManager.UnSchedule(self.WorkTimer)
        self.WorkTimer = nil
    end
    XEventManager.RemoveEventListener(XEventId.EVENT_DORM_WORK_RESET, self.DormWorkRefreshReq, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DORM_DAI_GONE_REWARD, self.UpdateDaiGong, self)
    -- XEventManager.RemoveEventListener(XEventId.EVENT_DORM_SKIP, self.SkipFun, self)
end

function XUiDormWork:InitUI()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.DormCoin, XDataCenter.ItemManager.ItemId.FurnitureCoin)
    self.TxtDaigong.text = TextManager.GetText("DormTxtDaigongDes")
    self:Initfun()
    self.PanelMember.gameObject:SetActiveEx(false)
end

function XUiDormWork:Initfun()
    self.OnBtnMainUIClickCb = function() self:OnBtnMainUIClick() end
    self.OnBtnReturnClickCb = function() self:OnBtnReturnClick() end
    self.OnBtnHelpClickCb = function() self:OnBtnHelpClick() end
    self.DormWorkRefreshReqCb = function() self:DormWorkRefreshReq() end
    self.UpdateWorkTimerCb = function() self:UpdateWorkTimer() end
    self.OnBtnTotalGetCb = function() self:OnBtnTotalGet() end
    self.OnUpdateListDataCb = function() self:SetListData() end
    self.OnUpdateWorkListDataCb = function() self:UpdateWorkList() end

    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUIClickCb)
    self:RegisterClickEvent(self.BtnBack, self.OnBtnReturnClickCb)
    self:RegisterClickEvent(self.BtnHelp, self.OnBtnHelpClickCb)
    self:RegisterClickEvent(self.BtnTotalGet, self.OnBtnTotalGetCb)
    self.BtnDaigong.CallBack = function() self:OnBtnDaigong() end
end

function XUiDormWork:OnBtnDaigong()
    local count = XDataCenter.DormManager.GetDormitoryCount()
    local daiGongData = XDormConfig.GetDormCharacterWorkById(count)
    local data = XDataCenter.DormManager.GetDormWorkData()
    local daigongList = {}
    for _, v in pairs(data) do
        if v.WorkEndTime > 0 and v.WorkEndTime > XTime.GetServerNowTimestamp() then
            local mood = XDataCenter.DormManager.GetMoodById(v.CharacterId)
            if math.floor(daiGongData.Mood / 100) <= mood then
                if not self.DaiGongDataCache[v.CharacterId] then
                    local d = {}
                    d.DaiGongData = daiGongData
                    d.WorkPos = v.WorkPos
                    d.CurIconpath = XDormConfig.GetCharacterStyleConfigQIconById(v.CharacterId)
                    self.DaiGongDataCache[v.CharacterId] = d
                end
                if self.PreDormCount ~= count then
                    self.PreDormCount = count
                    self.DaiGongDataCache[v.CharacterId].DaiGongData = daiGongData
                end
                table.insert(daigongList, self.DaiGongDataCache[v.CharacterId])
            end
        end
    end

    if not Next(daigongList) then
        XUiManager.TipText("DormDaiGongWarnTips")
        return
    end

    self:OpenOneChildUi("UiDormFoundryDetail", self, daigongList)
    if not self.FundryDetail then
        self.FundryDetail = self:FindChildUiObj("UiDormFoundryDetail")
    end
    self.FundryDetail:OnRefreshData(daigongList)
    self.PanelWork.gameObject:SetActiveEx(false)
end

function XUiDormWork:OnBtnHelpClick()
    XUiManager.UiFubenDialogTip("", TextManager.GetText("DormDesWork") or "")
end

function XUiDormWork:OnBtnTotalGet()
    local poslist = {}
    local data = XDataCenter.DormManager.GetDormWorkData()

    for _, v in pairs(data) do
        if v.WorkEndTime > 0 and v.WorkEndTime - XTime.GetServerNowTimestamp() < 0 then
            table.insert(poslist, v.WorkPos)
        end
    end

    if Next(poslist) == nil then
        XUiManager.TipMsg(TextManager.GetText("DormWorkNoRewardTips"))
        return
    end

    XDataCenter.DormManager.RequestDormitoryWorkReward(poslist, self.OnUpdateWorkListDataCb)
end

function XUiDormWork:OnBtnMainUIClick()
    XDataCenter.DormManager.ExitDormitoryBackToMain()
end

function XUiDormWork:OnBtnReturnClick()
    XLuaUiManager.Close("UiDormWork")
end