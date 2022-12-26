local XUiPanelSetHeadPortrait = XClass(nil, "XUiPanelSetHeadPortrait")
local XUiGridHeadPortrait = require("XUi/XUiPlayer/XUiGridHeadPortrait")
local XUiGridHeadFrame = require("XUi/XUiPlayer/XUiGridHeadFrame")
function XUiPanelSetHeadPortrait:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)

    self.TempHeadPortraitId = 0
    self.TempHeadFrameId = 0
    self.CurrHeadPortraitId = 0
    self.CurrHeadFrameId = 0
    self.OldPortraitSelectGrig = {}
    self.OldFrameSelectGrig = {}
    self.PanelHeadPortraitInfo = {}
    self.PanelHeadFrameInfo = {}
    self.PanelNoSelectInfo = {}
    self:InitHeadInfoObj(self.PanelHeadPortraitInfo, self.PanelHeadPortraitInfoObj)
    self:InitHeadInfoObj(self.PanelHeadFrameInfo, self.PanelHeadFrameInfoObj)
    self:InitHeadInfoObj(self.PanelNoSelectInfo, self.PanelNoSelectInfoObj)
    self:AutoAddListener()
    self:InitHeadPortraitDynamicTable()
    self:InitHeadFrameDynamicTable()
    self:BtnGroupInit()


end

function XUiPanelSetHeadPortrait:InitHeadInfoObj(info, obj)
    info.GameObject = obj.gameObject
    info.Transform = obj.transform
    XTool.InitUiObject(info)
end

function XUiPanelSetHeadPortrait:Reset()
    self.CurType = XHeadPortraitConfigs.HeadType.HeadPortrait
    self.TempHeadFrameId = 0
    self.PanelTouxiangGroup:SelectIndex(self.CurType)
    self:ShowHeadPortraitRedPoint()
    self:ShowHeadFrameRedPoint()
    XEventManager.AddEventListener(XEventId.EVENT_HEAD_PORTRAIT_TIMEOUT, self.TimeOutRefresh, self)
end

function XUiPanelSetHeadPortrait:TimeOutRefresh()
    self.TempHeadFrameId = 0
    self.PanelTouxiangGroup:SelectIndex(self.CurType)
    self:ShowHeadPortraitRedPoint()
    self:ShowHeadFrameRedPoint()
end

function XUiPanelSetHeadPortrait:BtnGroupInit()
    self.CurType = XHeadPortraitConfigs.HeadType.HeadPortrait
    self.BtnList = {self.BtnTouxiang, self.BtnTouxiangKuang}
    self.PanelTouxiangGroup:Init(self.BtnList, function(index) self:SelectType(index) end)
end

function XUiPanelSetHeadPortrait:SelectType(index)
    self.CurType = index
    local IsTrueHeadPortrait = self:ShowPreviewHeadPortrait()
    local IsTrueHeadFrame = self:ShowPreviewHeadFrame()

    if self.CurType == XHeadPortraitConfigs.HeadType.HeadPortrait then
        self:ShowHeadPortraitPanel(IsTrueHeadPortrait)
        self:SetupHeadPortraitDynamicTable(XDataCenter.HeadPortraitManager.GetHeadPortraitNumById(self.CurrHeadPortraitId, self.CurType))
        self.Base:PlayAnimation("PortraitInfoEnable")
    elseif self.CurType == XHeadPortraitConfigs.HeadType.HeadFrame then
        self:ShowHeadFramePanel(IsTrueHeadFrame)
        self:SetupHeadFrameDynamicTable(XDataCenter.HeadPortraitManager.GetHeadPortraitNumById(self.CurrHeadFrameId, self.CurType))
        self.Base:PlayAnimation("FrameInfoEnable")
    end
end

function XUiPanelSetHeadPortrait:AutoAddListener()
    self.PanelHeadPortraitInfo.BtnHeadSure.CallBack = function()
        self:OnBtnHeadPortraitSureClick()
    end
    self.PanelHeadPortraitInfo.BtnHeadCancel.CallBack = function()
        self:OnBtnCancelClick()
    end
    self.PanelHeadFrameInfo.BtnHeadSure.CallBack = function()
        self:OnBtnHeadFrameSureClick()
    end
    self.PanelHeadFrameInfo.BtnHeadCancel.CallBack = function()
        self:OnBtnCancelClick()
    end
    self.BtnClose.CallBack = function()
        self:OnBtnCancelClick()
    end
end

function XUiPanelSetHeadPortrait:OnBtnCancelClick()
    self.TempHeadFrameId = XPlayer.CurrHeadFrameId or 0
    self.TempHeadPortraitId = XPlayer.CurrHeadPortraitId or 0
    self.Base:HidePanelSetHeadPortrait()
    XEventManager.DispatchEvent(XEventId.EVENT_HEAD_PORTRAIT_RESETINFO)
    XEventManager.RemoveEventListener(XEventId.EVENT_HEAD_PORTRAIT_TIMEOUT, self.TimeOutRefresh, self)
end

------------------------------------HeadPortrait-----------------------------------------------
function XUiPanelSetHeadPortrait:InitHeadPortraitDynamicTable()
    self.HeadPortraitDynamicTable = XDynamicTableNormal.New(self.HeadPortraitScrollView)
    self.HeadPortraitDynamicTable:SetProxy(XUiGridHeadPortrait)
    self.HeadPortraitDynamicTable:SetDelegate(self)
    self.HeadPortraitDynamicTable:SetDynamicEventDelegate(function(event, index, grid)
            self:OnHeadPortraitDynamicTableEvent(event, index, grid)
        end)
    self.GridHeadPortrait.gameObject:SetActiveEx(false)
end

function XUiPanelSetHeadPortrait:SetupHeadPortraitDynamicTable(index)
    self.PageDatas = XDataCenter.HeadPortraitManager.GetUnlockedHeadPortraitIds(XHeadPortraitConfigs.HeadType.HeadPortrait)
    self.HeadPortraitDynamicTable:SetDataSource(self.PageDatas)
    self.HeadPortraitDynamicTable:ReloadDataSync(index and index or 1)
end

function XUiPanelSetHeadPortrait:RefreshHeadPortraitDynamicTable()
    self.CurrHeadPortraitId = XPlayer.CurrHeadPortraitId or 0
    self.HeadPortraitDynamicTable:ReloadDataSync()
end

function XUiPanelSetHeadPortrait:OnHeadPortraitDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index], self)
        self:SetHeadPortraitRedPoint(grid)
    end
end

function XUiPanelSetHeadPortrait:SetHeadPortraitRedPoint(grid)
    grid:ShowRedPoint(XDataCenter.HeadPortraitManager.CheckIsNewHeadPortraitById(grid.HeadPortraitId), false)
end

function XUiPanelSetHeadPortrait:OnBtnHeadPortraitSureClick()
    if self.PanelHeadPortraitInfo.BtnHeadSure.ButtonState == CS.UiButtonState.Disable then
        return
    end
    if self.TempHeadPortraitId ~= nil then
        if self.TempHeadPortraitId == XPlayer.CurrHeadPortraitId then
            return
        end

        XDataCenter.HeadPortraitManager.ChangeHeadPortrait(self.TempHeadPortraitId, function()
                self:RefreshHeadPortraitDynamicTable()
                self:SetHeadPortraitImgRole(self.TempHeadPortraitId)
                XUiManager.TipText("HeadPortraitUsecomplete")
            end)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_HEAD_PORTRAIT_RESETINFO)
end

function XUiPanelSetHeadPortrait:ShowPreviewHeadPortrait()
    self.CurrHeadPortraitId = XPlayer.CurrHeadPortraitId or 0
    self.OldPortraitSelectGrig = nil
    local IsTrueHeadPortrait = self:SetHeadPortraitImgRole(self.TempHeadPortraitId ~= 0 and self.TempHeadPortraitId or self.CurrHeadPortraitId)
    return IsTrueHeadPortrait
end
function XUiPanelSetHeadPortrait:ShowHeadPortraitPanel(IsTrueHeadPortrait)
    self.HeadFrameScrollView.gameObject:SetActiveEx(false)
    self.PanelHeadFrameInfo.GameObject:SetActiveEx(false)

    self.HeadPortraitScrollView.gameObject:SetActiveEx(true)
    self.PanelHeadPortraitInfo.GameObject:SetActiveEx(IsTrueHeadPortrait)
    self.PanelNoSelectInfo.GameObject:SetActiveEx(not IsTrueHeadPortrait)
    self.PanelNoSelectInfo.TxtHeadName.text = CS.XTextManager.GetText("HeadFrameNoSelectTitle")
    self.PanelNoSelectInfo.TxtDecs.text = CS.XTextManager.GetText("HeadPortraitNoSelectHint")
end

function XUiPanelSetHeadPortrait:SetHeadPortraitImgRole(headId)
    local info = XPlayerManager.GetHeadPortraitInfoById(headId)
    XUiPLayerHead.InitPortrait(headId, nil, self.Head)
    if (info ~= nil) then
        self.TempHeadPortraitId = headId
        if self.CurType == XHeadPortraitConfigs.HeadType.HeadPortrait then
            self:SetHeadTime(info, self.PanelHeadPortraitInfo, headId)
            self:SetHeadPortraitDesc(info, self.PanelHeadPortraitInfo, headId, self.CurrHeadPortraitId)
        end
        return true
    else
        return false
    end
end

function XUiPanelSetHeadPortrait:SetHeadPortraitDesc(info, panel, Id ,curId)
    local isValid = XDataCenter.HeadPortraitManager.IsHeadPortraitValid(Id)

    panel.TxtHeadName.text = info.Name
    panel.TxtDecs.text = info.WorldDesc
    panel.TxtCondition.text = info.LockDesc
    self.TxetTitle.text = CS.XTextManager.GetText("HeadPortraitSelect")

    if Id == curId then
        panel.TxtCondition.gameObject:SetActiveEx(false)
        panel.BtnHeadSure:SetButtonState(CS.UiButtonState.Disable)
        panel.BtnIsUsing.gameObject:SetActiveEx(true)
        panel.BtnIsNotHave.gameObject:SetActiveEx(false)
    elseif not isValid then
        panel.BtnHeadSure:SetButtonState(CS.UiButtonState.Disable)
        panel.BtnIsUsing.gameObject:SetActiveEx(false)
        panel.BtnIsNotHave.gameObject:SetActiveEx(true)
        panel.TxtCondition.gameObject:SetActiveEx(true)
    else
        panel.BtnHeadSure:SetButtonState(CS.UiButtonState.Normal)
        panel.TxtCondition.gameObject:SetActiveEx(false)
    end
end
------------------------------------HeadPortrait-----------------------------------------------
------------------------------------HeadFrame-----------------------------------------------
function XUiPanelSetHeadPortrait:InitHeadFrameDynamicTable()
    self.HeadFrameDynamicTable = XDynamicTableNormal.New(self.HeadFrameScrollView)
    self.HeadFrameDynamicTable:SetProxy(XUiGridHeadFrame)
    self.HeadFrameDynamicTable:SetDelegate(self)
    self.HeadFrameDynamicTable:SetDynamicEventDelegate(function(event, index, grid)
            self:OnHeadFrameDynamicTableEvent(event, index, grid)
        end)
    self.GridHeadFrame.gameObject:SetActiveEx(false)
end

function XUiPanelSetHeadPortrait:SetupHeadFrameDynamicTable(index)
    self.PageDatas = XDataCenter.HeadPortraitManager.GetUnlockedHeadPortraitIds(XHeadPortraitConfigs.HeadType.HeadFrame)
    self.HeadFrameDynamicTable:SetDataSource(self.PageDatas)
    self.HeadFrameDynamicTable:ReloadDataSync(index and index or 1)
end

function XUiPanelSetHeadPortrait:RefreshHeadFrameDynamicTable()
    self.CurrHeadFrameId = XPlayer.CurrHeadFrameId or 0
    self.HeadFrameDynamicTable:ReloadDataSync()
end

function XUiPanelSetHeadPortrait:OnHeadFrameDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index], self)
        self:SetHeadFrameRedPoint(grid)
    end
end

function XUiPanelSetHeadPortrait:SetHeadFrameRedPoint(grid)
    grid:ShowRedPoint(XDataCenter.HeadPortraitManager.CheckIsNewHeadPortraitById(grid.HeadFrameId), false)
end

function XUiPanelSetHeadPortrait:OnBtnHeadFrameSureClick()
    if self.PanelHeadFrameInfo.BtnHeadSure.ButtonState == CS.UiButtonState.Disable then
        return
    end
    if self.TempHeadFrameId ~= nil then
        local id = 0
        if self.PanelHeadFrameInfo.BtnType == XHeadPortraitConfigs.BtnState.Use then
            id = self.TempHeadFrameId
        end
        XDataCenter.HeadPortraitManager.ChangeHeadFrame(id, function()
                if id == 0 then
                    XUiManager.TipText("HeadFrameNonUsecomplete")
                else
                    XUiManager.TipText("HeadFrameUsecomplete")
                end
                self:RefreshHeadFrameDynamicTable()
                self:SetHeadFrameImgRole(self.TempHeadFrameId)
            end)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_HEAD_PORTRAIT_RESETINFO)
end

function XUiPanelSetHeadPortrait:ShowPreviewHeadFrame()
    self.CurrHeadFrameId = XPlayer.CurrHeadFrameId or 0
    self.OldFrameSelectGrig = nil
    local IsTrueHeadFrame =self:SetHeadFrameImgRole(self.TempHeadFrameId ~= 0 and self.TempHeadFrameId or self.CurrHeadFrameId)
    return IsTrueHeadFrame
end

function XUiPanelSetHeadPortrait:ShowHeadFramePanel(IsTrueHeadFrame)
    self.HeadPortraitScrollView.gameObject:SetActiveEx(false)
    self.PanelHeadPortraitInfo.GameObject:SetActiveEx(false)

    self.HeadFrameScrollView.gameObject:SetActiveEx(true)
    self.PanelHeadFrameInfo.GameObject:SetActiveEx(IsTrueHeadFrame)
    self.PanelNoSelectInfo.GameObject:SetActiveEx(not IsTrueHeadFrame)
    self.PanelNoSelectInfo.TxtHeadName.text = CS.XTextManager.GetText("HeadFrameNoSelectTitle")
    self.PanelNoSelectInfo.TxtDecs.text = CS.XTextManager.GetText("HeadFrameNoSelectHint")
end

function XUiPanelSetHeadPortrait:SetHeadFrameImgRole(headId)
    local info = XPlayerManager.GetHeadPortraitInfoById(headId)
    XUiPLayerHead.InitPortrait(nil, headId, self.Head)
    if (info ~= nil) then
        self.TempHeadFrameId = headId
        if self.CurType == XHeadPortraitConfigs.HeadType.HeadFrame then
            self:SetHeadTime(info,self.PanelHeadFrameInfo, headId)
            self:SetHeadFrameDesc(info, self.PanelHeadFrameInfo, headId, self.CurrHeadFrameId)
        end
        return true
    else
        return false
    end
end

function XUiPanelSetHeadPortrait:SetHeadFrameDesc(info, panel, Id ,curId)
    local isValid = XDataCenter.HeadPortraitManager.IsHeadPortraitValid(Id)

    panel.TxtHeadName.text = info.Name
    panel.TxtDecs.text = info.WorldDesc
    panel.TxtCondition.text = info.LockDesc
    self.TxetTitle.text = CS.XTextManager.GetText("HeadFrameSelect")

    if Id == curId then
        panel.TxtCondition.gameObject:SetActiveEx(false)
        panel.BtnHeadSure:SetButtonState(CS.UiButtonState.Normal)
        panel.BtnHeadSure:SetName(CS.XTextManager.GetText("HeadFrameNonUse"))
        panel.BtnType = XHeadPortraitConfigs.BtnState.NonUse
    elseif not isValid then
        panel.BtnHeadSure:SetButtonState(CS.UiButtonState.Disable)
        panel.BtnIsUsing.gameObject:SetActiveEx(false)
        panel.BtnIsNotHave.gameObject:SetActiveEx(true)
        panel.TxtCondition.gameObject:SetActiveEx(true)
    else
        panel.BtnHeadSure:SetButtonState(CS.UiButtonState.Normal)
        panel.TxtCondition.gameObject:SetActiveEx(false)
        panel.BtnHeadSure:SetName(CS.XTextManager.GetText("HeadFrameUse"))
        panel.BtnType = XHeadPortraitConfigs.BtnState.Use
    end
end
------------------------------------HeadFrame-----------------------------------------------

function XUiPanelSetHeadPortrait:SetHeadTime(info, panel, headId)
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
    else
        panel.PanelTime.gameObject:SetActiveEx(false)
    end
end

function XUiPanelSetHeadPortrait:ShowHeadPortraitRedPoint()
    local IsShowRed = XDataCenter.HeadPortraitManager.CheckIsNewHeadPortrait(XHeadPortraitConfigs.HeadType.HeadPortrait)
    self.BtnTouxiang:ShowReddot(IsShowRed)
end

function XUiPanelSetHeadPortrait:ShowHeadFrameRedPoint()
    local IsShowRed = XDataCenter.HeadPortraitManager.CheckIsNewHeadPortrait(XHeadPortraitConfigs.HeadType.HeadFrame)
    self.BtnTouxiangKuang:ShowReddot(IsShowRed)
end

function XUiPanelSetHeadPortrait:Release()
end

return XUiPanelSetHeadPortrait