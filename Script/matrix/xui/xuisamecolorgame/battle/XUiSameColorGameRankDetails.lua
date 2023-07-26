local XUiSameColorGameRankDetails = XLuaUiManager.Register(XLuaUi, "UiSameColorGameRankDetails")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiSameColorGameRankDetails:OnStart(boss)
    self.Boss = boss
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    self:SetButtonCallBack()
    self:InitDynamicTable()
end

function XUiSameColorGameRankDetails:OnEnable()
    self:SetupDynamicTable()
    self.TitleText.text = CSTextManagerGetText("SameColorGameRankTitle", self.Boss:GetName())
end

function XUiSameColorGameRankDetails:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelRank)
    
    local class = XClass(nil, "")
    class.Ctor = function(o, go) 
        XTool.InitUiObjectByUi(o, go) 
    end
    self.DynamicTable:SetProxy(class)
    
    self.DynamicTable:SetDelegate(self)
    self.GridRank.gameObject:SetActiveEx(false)
end

function XUiSameColorGameRankDetails:SetupDynamicTable()
    self.PageDatas = self.Boss:GetBossGradeDic()
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync()
end

function XUiSameColorGameRankDetails:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local rank = self.PageDatas[index]
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