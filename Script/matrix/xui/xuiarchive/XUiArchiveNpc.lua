local XUiGridArchiveNpc = require("XUi/XUiArchive/XUiGridArchiveNpc")
local XUiGridArchive = require("XUi/XUiArchive/XUiGridArchive")
local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiArchiveNpc = XLuaUiManager.Register(XLuaUi, "UiArchiveNpc")
local FirstIndex = 1
function XUiArchiveNpc:OnEnable()
    self:SetupDynamicTable()
    self:SetRoteData()
    self.BtnCloseGird.gameObject:SetActiveEx(false)
    if self.IsInit then
        self.GridState = XEnumConst.Archive.NpcGridState.Open
        self.CurIndex = #self.PageDatas + 1
        self.IsInit = false
    end
end

function XUiArchiveNpc:OnStart()
    self.IsInit = true
    self.GridDic = {}
    self:SetButtonCallBack()
    self:InitDynamicTable()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiArchiveNpc:OnDestroy()

end

function XUiArchiveNpc:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelArchiveList)
    self.DynamicTable:SetProxy(XUiGridArchiveNpc,self)
    self.DynamicTable:SetDelegate(self)
    self.GridArchiveNpc.gameObject:SetActiveEx(false)
end

function XUiArchiveNpc:SetupDynamicTable()
    self.PageDatas = self._Control:GetArchiveStoryNpcList()
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiArchiveNpc:OnlyReloadDataSync()
    self.DynamicTable:ReloadDataSync(-1)
end

function XUiArchiveNpc:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index], self, index)
        self:SetGridDic(index,grid)
    end
end

function XUiArchiveNpc:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.BtnCloseGird.CallBack = function()
        self:OnBtnCloseGirdClick()
    end
end

function XUiArchiveNpc:OnBtnBackClick()
    self:Close()
end

function XUiArchiveNpc:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiArchiveNpc:SetGridDic(npcIndex,npcGrid)
    for index,grid in pairs(self.GridDic) do
        if grid == npcGrid then
            self.GridDic[index] = nil
            break
        end
    end
    self:CheckGirdState(npcIndex,npcGrid)
    self.GridDic[npcIndex] = npcGrid
end

function XUiArchiveNpc:CheckGirdState(index,grid)
    if self.GridState == XEnumConst.Archive.NpcGridState.Open then
        if index < self.CurIndex then
            grid:SetLeftEndPos()
            grid:SetStartScale()
            grid:SetEndAlpha()
            grid:SetDetailStartAlpha()
            grid:StopTween()
        elseif index > self.CurIndex then
            grid:SetRightEndPos()
            grid:SetStartScale()
            grid:SetEndAlpha()
            grid:SetDetailStartAlpha()
            grid:StopTween()
        else
            grid:SetStartPos()
            grid:SetEndScale()
            grid:SetStartAlpha()
            grid:SetDetailEndAlpha()
            grid:StopTween()
        end
    elseif self.GridState == XEnumConst.Archive.NpcGridState.Close then
        grid:SetStartPos()
        grid:SetStartScale()
        grid:SetEndAlpha()
        grid:SetDetailStartAlpha()
        grid:StopTween()
    end
end

function XUiArchiveNpc:SelectNpc(Index)
    if self.CurIndex then
        if self.CurIndex ~= Index then
            if Index > self.CurIndex then
                self:RightOpenGird(function ()
                        self.CurIndex = Index
                    end)
            else
                self:LeftOpenGird(function ()
                        self.CurIndex = Index
                    end)
            end
        end
    else
        self.CurIndex = Index
        self:OpenGird()
    end
    self.GridState = XEnumConst.Archive.NpcGridState.Open
end

function XUiArchiveNpc:UnSelectNpc()
    if self.CurIndex then
        self:CloseGird(nil)
        self.CurIndex = nil
    end
    self.GridState = XEnumConst.Archive.NpcGridState.Close
end

function XUiArchiveNpc:LeftOpenGird(cb)
    local curGrid = self.GridDic[self.CurIndex]
    XLuaUiManager.SetMask(true)
    if curGrid then
        curGrid:SetItemDailyDisable(function ()
                curGrid:SetStartPos()
                curGrid:SetItemEnable(function ()
                        XLuaUiManager.SetMask(false)
                    end)
                if cb then cb() end
                self:OpenGird()
            end)
    else
        XLuaUiManager.SetMask(false)
        if cb then cb() end
        self:OpenGird()
    end
end

function XUiArchiveNpc:RightOpenGird(cb)
    local curGrid = self.GridDic[self.CurIndex]
    XLuaUiManager.SetMask(true)
    if curGrid then
        curGrid:SetItemDailyDisable(function ()
                curGrid:SetStartPos()
                curGrid:SetItemEnable(function ()
                        XLuaUiManager.SetMask(false)
                    end)
                if cb then cb() end
                self:OpenGird()
            end)
    else
        XLuaUiManager.SetMask(false)
        if cb then cb() end
        self:OpenGird()
    end
end

function XUiArchiveNpc:OpenGird()
    local curGrid = self.GridDic[self.CurIndex]
    XLuaUiManager.SetMask(true)
    local IsPlayed = false
    if curGrid then
        self.DynamicTable:CenterToSelected(curGrid.GameObject,0.5)
        curGrid:SetItemDisable(function ()
                local fun = function ()
                    if not IsPlayed then
                        IsPlayed = true
                        curGrid:SetItemDailyEnable(function ()
                                XLuaUiManager.SetMask(false)
                            end)
                    end
                end
                for index,grid in pairs(self.GridDic) do
                    if index < self.CurIndex then
                        grid:GoLeft(fun)
                    elseif index > self.CurIndex then
                        grid:GoRight(fun)
                    end
                end
            end)
    else
        local fun = function ()
            if not IsPlayed then
                IsPlayed = true
                XLuaUiManager.SetMask(false)
            end
        end
        for index,grid in pairs(self.GridDic) do
            if index < self.CurIndex then
                grid:GoLeft(fun)
            elseif index > self.CurIndex then
                grid:GoRight(fun)
            end
        end
    end
end

function XUiArchiveNpc:CloseGird(cb)
    local curGrid = self.GridDic[self.CurIndex]
    XLuaUiManager.SetMask(true)
    if curGrid then
        curGrid:SetItemDailyDisable(function ()
                curGrid:SetItemEnable()
                self:GirdGoBack(function ()
                        if cb then cb() end
                        XLuaUiManager.SetMask(false)
                    end,true)
            end)
    else
        self:GirdGoBack(function ()
                if cb then cb() end
                XLuaUiManager.SetMask(false)
            end,false)
    end
end

function XUiArchiveNpc:GirdGoBack(cb,IsMove)
    local IsOver = false
    for index,grid in pairs(self.GridDic) do
        if index ~= self.CurIndex then
            grid:GoBack(function ()
                    if not IsOver then
                        IsOver = true
                        if cb then cb() end
                    end
                end,IsMove)
        end
    end
end

function XUiArchiveNpc:SetRoteData()
    local unLockCount = 0
    for _,data in pairs(self.PageDatas) do
        if not data:GetIsLock() then
            unLockCount = unLockCount + 1
        end
    end
    self.RateNum.text = string.format("%d/%d", unLockCount, #self.PageDatas)
end