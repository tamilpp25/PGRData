---@class XUiSameColorGameRankDetails:XLuaUi
local XUiSameColorGameRankDetails = XLuaUiManager.Register(XLuaUi, "UiSameColorGameRankDetails")
---@param boss XSCBoss
function XUiSameColorGameRankDetails:OnStart(boss)
    self.Boss = boss
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    self:SetButtonCallBack()
    self:InitDynamicTable()
end

function XUiSameColorGameRankDetails:OnEnable()
    self:SetupDynamicTable()
    self.TitleText.text = XUiHelper.GetText("SameColorGameRankTitle", self.Boss:GetName())
end

function XUiSameColorGameRankDetails:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelRank)
    
    ---@class XUiSameColorGameRankDetailGrid
    local class = XClass(nil, "")
    class.Ctor = function(o, go) 
        XTool.InitUiObjectByUi(o, go) 
    end
    self.DynamicTable:SetProxy(class)
    self.DynamicTable:SetDelegate(self)
    self.GridRank.gameObject:SetActiveEx(false)
end

function XUiSameColorGameRankDetails:SetupDynamicTable()
    self.PageData = self.Boss:GetBossGradeDic()
    self.DynamicTable:SetDataSource(self.PageData)
    self.DynamicTable:ReloadDataSync()
end

---@param grid XUiSameColorGameRankDetailGrid
function XUiSameColorGameRankDetails:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local rank = self.PageData[index]
        if rank then
            grid.TxtDamage.text = rank.Damage
            grid.RankImage:SetRawImage(self.Boss:GetCurGradeIcon(rank.Damage))
        end
    end
end

function XUiSameColorGameRankDetails:SetButtonCallBack()
    self.BtnClose.CallBack = function() self:OnClickBtnBack() end
end

function XUiSameColorGameRankDetails:OnClickBtnBack()
    self:Close()
end