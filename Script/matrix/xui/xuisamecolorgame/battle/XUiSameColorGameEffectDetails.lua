local XUiSameColorGameEffectDetails = XLuaUiManager.Register(XLuaUi, "UiSameColorGameEffectDetails")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiSameColorGameEffectDetails:OnStart()
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    self:SetButtonCallBack()
    self:InitDynamicTable()
end

function XUiSameColorGameEffectDetails:OnEnable()
    self:SetupDynamicTable()
end

function XUiSameColorGameEffectDetails:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelBuff)

    local class = XClass(nil, "")
    class.Ctor = function(o, go)
        XTool.InitUiObjectByUi(o, go)
    end
    self.DynamicTable:SetProxy(class)

    self.DynamicTable:SetDelegate(self)
    self.GridBuff.gameObject:SetActiveEx(false)
end

function XUiSameColorGameEffectDetails:SetupDynamicTable()
    self.PageDatas = self.BattleManager:GetShowBuffList()
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync()
end

function XUiSameColorGameEffectDetails:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local buff = self.PageDatas[index]
        if buff then
            grid.TxtName.text = buff:GetName()
            grid.TxtDesc.text = buff:GetDesc()
            grid.TxtCount.text = buff:GetCountDown()
            grid.IconImage:SetRawImage(buff:GetIcon())
        end
    end
end

function XUiSameColorGameEffectDetails:SetButtonCallBack()
    self.BtnClose.CallBack = function() self:OnClickBtnBack() end
end

function XUiSameColorGameEffectDetails:OnClickBtnBack()
    self:Close()
end