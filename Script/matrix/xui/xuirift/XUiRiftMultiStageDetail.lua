--大秘境关卡节点详情 多队伍
local XUiRiftMultiStageDetail = XLuaUiManager.Register(XLuaUi, "UiRiftMultiStageDetail")
local XUiGridRiftMultiMonster = require("XUi/XUiRift/Grid/XUiGridRiftMultiMonster")

function XUiRiftMultiStageDetail:OnAwake()
    self:InitButton()
    self:InitDynamicTable()
end

function XUiRiftMultiStageDetail:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnCloseMask, self.OnBtnCloseMaskClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFight, self.OnBtnFightClick)
end

function XUiRiftMultiStageDetail:InitDynamicTable()
    -- 选择作战层的滑动列表
    self.DynamicTable = XDynamicTableNormal.New(self.PanelMonsterList)
    self.DynamicTable:SetProxy(XUiGridRiftMultiMonster, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiRiftMultiStageDetail:OnStart(xStageGroup, closeCb)
    self.XStageGroup = xStageGroup
    self.CloseCb = closeCb
end

function XUiRiftMultiStageDetail:OnEnable()
    self:RefreshUiShow()
end

function XUiRiftMultiStageDetail:RefreshUiShow()
    -- 关卡信息
    self.TxtStageName.text = self.XStageGroup:GetName()
    self.TxtStageInfo.text = self.XStageGroup:GetDesc()
    local cur , total = self.XStageGroup:GetProgress()
    self.TxtProgress.text = cur.."/"..total
    local allStageList = self.XStageGroup:GetAllEntityStages()
    self.TxtTeamCount.text = #allStageList
    -- 敌人情报
    self:RefreshDynamicTable(allStageList)
end

function XUiRiftMultiStageDetail:RefreshDynamicTable(list)
    self.DataList = list
    self.DynamicTable:SetDataSource(list)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiRiftMultiStageDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index], self.XStageGroup, index)
    end
end

function XUiRiftMultiStageDetail:OnBtnFightClick()
    local doFun = function ()
        XLuaUiManager.PopThenOpen("UiRiftDeploy", self.XStageGroup)
    end

    local xChapter = self.XStageGroup:GetParent():GetParent()
    XDataCenter.RiftManager.CheckDayTipAndDoFun(xChapter, doFun)
end

function XUiRiftMultiStageDetail:OnBtnCloseMaskClick()
    self:Close()
end

function XUiRiftMultiStageDetail:OnDestroy()
    self.CloseCb()
end

return XUiRiftMultiStageDetail