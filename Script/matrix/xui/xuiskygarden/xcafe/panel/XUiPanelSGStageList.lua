local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiPanelSGStageList : XUiNode
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Parent XUiSkyGardenCafeMain
---@field _Control XSkyGardenCafeControl
local XUiPanelSGStageList = XClass(XUiNode, "XUiPanelSGStageList")

function XUiPanelSGStageList:OnStart(isChallenge)
    self._IsChallenge = isChallenge
    self:InitCb()
    self:InitView()
end

function XUiPanelSGStageList:OnEnable()
    local cur, total
    if self._IsChallenge then
        cur, total = self._Control:GetChallengeProgress()
    else
        cur, total = self._Control:GetHistoryProgress()
    end
    self.TxtNum.text = string.format("%d/%d", cur, total)
    
    self:SetupDynamicTable()

    --if self._GridEndless then
    --    self._GridEndless:Refresh()
    --end
end

function XUiPanelSGStageList:InitCb()
    self.BtnReturn.CallBack = function() self.Parent:ChangePanel(1) end

    if self.BtnHandBook then
        self.BtnHandBook.CallBack = function() self:OnBtnHandBookClick() end
    end
end

function XUiPanelSGStageList:InitView()
    self._DynamicTable = XDynamicTableNormal.New(self.ListStage)
    self._DynamicTable:SetProxy(require("XUi/XUiSkyGarden/XCafe/Grid/XUiGridSGStageListItem"), self)
    self._DynamicTable:SetDelegate(self)
    
    self.GridStage.gameObject:SetActiveEx(false)
    if self.GridEndlessStage then
        self.GridEndlessStage.gameObject:SetActiveEx(false)
    end

    --if self._IsChallenge then
    --    self._GridEndless = require("XUi/XUiSkyGarden/XCafe/Grid/XUiGridSGStageEndless").New(self.GridEndlessStage, self)
    --    self._GridEndless:Open()
    --end
end

function XUiPanelSGStageList:GetDataList()
    if self._IsChallenge then
        return self._Control:GetChallengeStageIds()
    end
    return self._Control:GetHistoryStageIds()
end

function XUiPanelSGStageList:SetupDynamicTable()
    self._DataList = self:GetDataList()
    self._DynamicTable:SetDataSource(self._DataList)
    self._DynamicTable:ReloadDataSync()
end

---@param grid XUiGridSGStageListItem
function XUiPanelSGStageList:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self._DataList[index])
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:PlayClickAnimation(function()
            self:OnBtnItemClick(self._DataList[index])
        end)
    end
end

function XUiPanelSGStageList:OnBtnHandBookClick()
    self._Control:OpenHandBook(XMVCA.XSkyGardenCafe.UIType.HandleBook)
end

function XUiPanelSGStageList:OnBtnItemClick(stageId)
    if not self._Control:IsStageUnlock(stageId) then
        local preStageId = self._Control:GetPreStageId(stageId)
        XUiManager.TipMsg(self._Control:GetStageLockText(preStageId))
        return
    end
    
    if self._IsChallenge then
        self._Control:EnterFight(stageId)
    else
        self._Control:OpenSettlement(stageId, false)
    end
end

return XUiPanelSGStageList