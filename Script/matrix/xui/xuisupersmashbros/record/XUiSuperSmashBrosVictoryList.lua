--==============
--超限乱斗 支援角色选人页面
--==============
local XUiSuperSmashBrosVictoryListGrid = require("XUi/XUiSuperSmashBros/Record/XUiSuperSmashBrosVictoryListGrid")

---@class XUiSuperSmashBrosVictoryList:XLuaUi
local XUiSuperSmashBrosVictoryList = XLuaUiManager.Register(XLuaUi, "UiSuperSmashBrosVictoryList")

function XUiSuperSmashBrosVictoryList:Ctor()
    ---@type XSmashBMode
    self._Mode = false
    self._Index = -1
    ---@type XUiSuperSmashBrosVictoryListGrid[]
    self._GridRecordList = {}
    ---@type XUiSuperSmashBrosVictoryListGrid
    self._GridFighting = false
end

function XUiSuperSmashBrosVictoryList:OnAwake()
    self:BindExitBtns()
    self:RegisterClickEvent(self.BtnCancel, self.RollBack)
end

function XUiSuperSmashBrosVictoryList:OnStart()
    self:UpdateByMode()
end

function XUiSuperSmashBrosVictoryList:UpdateByMode()
    self._Mode = XDataCenter.SuperSmashBrosManager.GetPlayingMode()
    self:UpdateByList(self._Mode:GetResultList())
    self.PanelSlide.verticalNormalizedPosition = 0
end

function XUiSuperSmashBrosVictoryList:UpdateByList(resultList)
    local amountResult = #resultList
    if amountResult == 0 then
        self.Line.gameObject:SetActiveEx(false)
    else
        self.Line.gameObject:SetActiveEx(true)
    end

    for i = #self._GridRecordList + 1, amountResult do
        local grid = CS.UnityEngine.Object.Instantiate(self.GridRecord, self.GridRecord.transform.parent)
        grid.gameObject:SetActiveEx(true)
        self._GridRecordList[#self._GridRecordList + 1] = XUiSuperSmashBrosVictoryListGrid.New(grid, self._Mode, resultList[i], i, function()
            if self._Index == i then
                self._Index = -1
            else
                self._Index = i
            end
            self:UpdateSelected()
        end)
    end
    self.GridRecord.gameObject:SetActiveEx(false)

    for i = amountResult + 1, #self._GridRecordList do
        self._GridRecordList[i].GameObject:SetActiveEx(false)
    end

    for i = 1, amountResult do
        self._GridRecordList[i]:Refresh()
    end

    self._GridFighting = XUiSuperSmashBrosVictoryListGrid.New(self.GridFighting, self._Mode)
    self._GridFighting:Refresh()
    self.GridFighting:SetAsLastSibling()
end

function XUiSuperSmashBrosVictoryList:Select(index)
    self._Index = index
end

function XUiSuperSmashBrosVictoryList:RollBack()
    if self._Index <= 0 then
        XUiManager.TipMsg(XUiHelper.GetText("SuperSmashRollbackNothing"))
        return
    end
    XDataCenter.SuperSmashBrosManager.DialogRollBack(function()
        XDataCenter.SuperSmashBrosManager.RollBackRecord(self._Index, function()
            if XTool.UObjIsNil(self.GameObject) then
                return
            end
            self:Close()
            --if self._Index >= #self._GridRecordList then
            --    return
            --end
            --self:UpdateByMode()
        end)
    end)
end

function XUiSuperSmashBrosVictoryList:UpdateSelected()
    for i = 1, #self._GridRecordList do
        local grid = self._GridRecordList[i]
        grid:UpdateSelected(self._Index == i, self._Index > 0 and self._Index <= i)
    end
end

return XUiSuperSmashBrosVictoryList